using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/suppliers")]
public class SuppliersController(AppDbContext db) : ControllerBase
{
    private Guid ResolveTid(Guid _ignored)
    {
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && ct != Guid.Empty) return ct;
        throw new UnauthorizedAccessException("Missing or invalid tenant claim");
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
        dto.TenantId = ResolveTid(dto.TenantId);
        db.Suppliers.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/suppliers/{dto.Id}", new { data = dto });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var s = await db.Suppliers.FindAsync(id);
        if (s == null) return NotFound();
        var tid = ResolveTid(Guid.Empty);
        if (s.TenantId != tid) return NotFound();
        return Ok(new { data = s });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] Supplier dto)
    {
        var s = await db.Suppliers.FindAsync(id);
        if (s == null) return NotFound();
        var tid = ResolveTid(Guid.Empty);
        if (s.TenantId != tid) return NotFound();
        s.Name = string.IsNullOrWhiteSpace(dto.Name) ? s.Name : dto.Name;
        s.Phone = dto.Phone ?? s.Phone;
        await db.SaveChangesAsync();
        return Ok(new { data = s });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var s = await db.Suppliers.FindAsync(id);
        if (s == null) return NotFound();
        var tid = ResolveTid(Guid.Empty);
        if (s.TenantId != tid) return NotFound();
        db.Suppliers.Remove(s);
        await db.SaveChangesAsync();
        return Ok(new { data = s });
    }
}
