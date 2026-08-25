using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/tenants")]
public class TenantsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List()
    {
        var list = await db.Tenants.ToListAsync();
        return Ok(new { data = list });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var t = await db.Tenants.FindAsync(id);
        if (t == null) return NotFound(new { error = new { code = "NOT_FOUND", message = "Tenant not found" } });
        return Ok(new { data = t });
    }

    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var tidClaim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(tidClaim, out var tid))
        {
            var t = await db.Tenants.FindAsync(tid);
            if (t != null) return Ok(new { data = t });
        }
        var first = await db.Tenants.FirstOrDefaultAsync();
        if (first == null) return NotFound(new { error = new { code = "NOT_FOUND", message = "No tenant" } });
        return Ok(new { data = first });
    }
}
