using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/suppliers")]
public class SuppliersController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
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
