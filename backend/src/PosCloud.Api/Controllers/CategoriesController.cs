using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/categories")]
public class CategoriesController(AppDbContext db) : ControllerBase
{
    private Guid ResolveTid(Guid _ignored)
    {
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && ct != Guid.Empty) return ct;
        throw new UnauthorizedAccessException("Missing or invalid tenant claim");
    }
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId)
    {
        tenantId = ResolveTid(tenantId);
        return Ok(new { data = await db.Categories.Where(c => c.TenantId == tenantId).OrderBy(c => c.SortOrder).ToListAsync() });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Category dto)
    {
        dto.TenantId = ResolveTid(dto.TenantId);
        db.Categories.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/categories/{dto.Id}", new { data = dto });
    }
}
