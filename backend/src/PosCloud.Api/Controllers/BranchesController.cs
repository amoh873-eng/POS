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
    public async Task<IActionResult> List([FromQuery] Guid? tenantId)
    {
        var tid = tenantId ?? GetTenantId();
        var list = await db.Branches.Where(b => b.TenantId == tid).ToListAsync();
        return Ok(new { data = list });
    }
    private Guid GetTenantId()
    {
        var tidClaim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(tidClaim, out var tid)) return tid;
        return db.Tenants.Select(t => t.Id).FirstOrDefault();
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Branch dto)
    {
        db.Branches.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/branches/{dto.Id}", dto);
    }
}
