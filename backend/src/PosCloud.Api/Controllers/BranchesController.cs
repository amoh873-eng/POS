using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/branches")]
public class BranchesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid? tenantId)
    {
        var tid = GetTenantId();
        var list = await db.Branches.Where(b => b.TenantId == tid).ToListAsync();
        return Ok(new { data = list });
    }
    private Guid GetTenantId()
    {
        var tidClaim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(tidClaim, out var tid) && tid != Guid.Empty) return tid;
        throw new UnauthorizedAccessException("Missing or invalid tenant claim");
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Branch dto)
    {
        dto.TenantId = GetTenantId();
        db.Branches.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/branches/{dto.Id}", dto);
    }
}
