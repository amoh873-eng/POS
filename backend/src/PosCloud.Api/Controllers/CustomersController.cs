using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/customers")]
public class CustomersController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId, [FromQuery] string? q, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var query = db.Customers.Where(c => c.TenantId == tenantId && !c.IsDeleted);
        if (!string.IsNullOrWhiteSpace(q)) query = query.Where(c => c.Name.Contains(q) || (c.Phone != null && c.Phone.Contains(q)));
        var total = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return Ok(new { data = items, meta = new { page, page_size = pageSize, total } });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Customer dto)
    {
        db.Customers.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/customers/{dto.Id}", new { data = dto });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var c = await db.Customers.FindAsync(id);
        return c == null ? NotFound() : Ok(new { data = c });
    }

    [HttpPost("{id}/pay")]
    public async Task<IActionResult> Pay(Guid id, [FromBody] PayReq req)
    {
        var c = await db.Customers.FindAsync(id);
        if (c == null) return NotFound();
        c.Balance -= req.Amount;
        db.Payments.Add(new Payment { TenantId = c.TenantId, Method = "credit_settle", Amount = req.Amount, ProviderRef = $"customer:{id}" });
        await db.SaveChangesAsync();
        return Ok(new { data = c });
    }
    public record PayReq(decimal Amount);
}
