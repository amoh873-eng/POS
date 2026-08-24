using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/products")]
public class ProductsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId, [FromQuery] string? q, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var query = db.Products.Where(p => p.TenantId == tenantId && !p.IsDeleted);
        if (!string.IsNullOrWhiteSpace(q))
            query = query.Where(p => p.NameAr.Contains(q) || p.NameEn.Contains(q) || p.Sku.Contains(q));
        var total = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return Ok(new { data = items, meta = new { page, page_size = pageSize, total } });
    }

    [HttpGet("barcode/{code}")]
    public async Task<IActionResult> ByBarcode(string code, [FromQuery] Guid tenantId)
    {
        var p = await db.Products.FirstOrDefaultAsync(x => x.TenantId == tenantId && x.BarcodeMain == code && !x.IsDeleted);
        if (p == null) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        return Ok(new { data = p });
    }
}
