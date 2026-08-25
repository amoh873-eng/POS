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
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId) => Ok(new { data = await db.Categories.Where(c => c.TenantId == tenantId).OrderBy(c => c.SortOrder).ToListAsync() });

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Category dto)
    {
        db.Categories.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/categories/{dto.Id}", new { data = dto });
    }
}
