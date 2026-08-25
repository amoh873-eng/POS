using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/products")]
[Authorize]
public class ProductsController(AppDbContext db) : ControllerBase
{
    private Guid ResolveTenant(Guid? qTid)
    {
        if (qTid != null && qTid != Guid.Empty) return qTid.Value;
        var tidClaim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(tidClaim, out var tid)) return tid;
        return db.Tenants.Select(t => t.Id).FirstOrDefault();
    }
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid? tenantId, [FromQuery] string? q, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var tid = ResolveTenant(tenantId);
        var query = db.Products.Where(p => p.TenantId == tid && !p.IsDeleted);
        if (!string.IsNullOrWhiteSpace(q))
            query = query.Where(p => p.NameAr.Contains(q) || p.NameEn.Contains(q) || p.Sku.Contains(q));
        var total = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return Ok(new { data = items, meta = new { page, page_size = pageSize, total } });
    }

    [HttpGet("barcode/{code}")]
    public async Task<IActionResult> ByBarcode(string code, [FromQuery] Guid? tenantId)
    {
        var tid = ResolveTenant(tenantId);
        var p = await db.Products.FirstOrDefaultAsync(x => x.TenantId == tid && x.BarcodeMain == code && !x.IsDeleted);
        if (p == null) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        return Ok(new { data = p });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] PosCloud.Domain.Entities.Product dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Sku)) return BadRequest(new { error = new { code = "VALIDATION_ERROR", message = "SKU required" } });
        dto.Id = Guid.NewGuid();
        db.Products.Add(dto);
        // init stock per branches
        var branches = await db.Branches.Where(b => b.TenantId == dto.TenantId).ToListAsync();
        foreach (var br in branches)
            db.InventoryStocks.Add(new PosCloud.Domain.Entities.InventoryStock { TenantId = dto.TenantId, BranchId = br.Id, ProductId = dto.Id, QtyOnHand = 0 });
        await db.SaveChangesAsync();
        return Created($"/api/products/{dto.Id}", new { data = dto });
    }

    [HttpPatch("{id}")]
    public async Task<IActionResult> Patch(Guid id, [FromBody] PosCloud.Domain.Entities.Product dto)
    {
        var p = await db.Products.FindAsync(id);
        if (p == null) return NotFound();
        p.NameAr = dto.NameAr ?? p.NameAr; p.NameEn = dto.NameEn ?? p.NameEn;
        p.Sku = dto.Sku ?? p.Sku; p.BarcodeMain = dto.BarcodeMain ?? p.BarcodeMain;
        p.SellPrice = dto.SellPrice != 0 ? dto.SellPrice : p.SellPrice;
        p.CostPrice = dto.CostPrice != 0 ? dto.CostPrice : p.CostPrice;
        p.TaxRate = dto.TaxRate; p.IsActive = dto.IsActive;
        await db.SaveChangesAsync();
        return Ok(new { data = p });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var p = await db.Products.FindAsync(id);
        if (p == null) return NotFound();
        p.IsDeleted = true; p.DeletedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return Ok(new { data = p });
    }
}
