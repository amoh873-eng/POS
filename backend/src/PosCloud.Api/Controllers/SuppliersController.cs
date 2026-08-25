using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/suppliers")]
public class SuppliersController(AppDbContext db) : ControllerBase
{
    private Guid ResolveTid(Guid tid)
    {
        if (tid != Guid.Empty) return tid;
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct)) return ct;
        return db.Tenants.Select(t => t.Id).FirstOrDefault();
    }
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        tenantId = ResolveTid(tenantId);
        var q = db.Suppliers.Where(s => s.TenantId == tenantId);
        var total = await q.CountAsync();
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return Ok(new { data = items, meta = new { page, page_size = pageSize, total } });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Supplier dto)
    {
        db.Suppliers.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/suppliers/{dto.Id}", new { data = dto });
    }
}
