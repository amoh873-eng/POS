using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/branches")]
public class BranchesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId)
    {
        var list = await db.Branches.Where(b => b.TenantId == tenantId).ToListAsync();
        return Ok(new { data = list });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Branch dto)
    {
        db.Branches.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/branches/{dto.Id}", dto);
    }
}
