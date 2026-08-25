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
    private bool IsSkuDup(Guid tid, string sku, Guid? exclude = null) => db.Products.Any(p => p.TenantId == tid && p.Sku == sku && !p.IsDeleted && (exclude == null || p.Id != exclude));
    private bool IsBarcodeDup(Guid tid, string? bc, Guid? exclude = null) => !string.IsNullOrWhiteSpace(bc) && db.Products.Any(p => p.TenantId == tid && p.BarcodeMain == bc && !p.IsDeleted && (exclude == null || p.Id != exclude));
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid? tenantId, [FromQuery] string? q, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var tid = ResolveTenant(tenantId);
        var query = db.Products.Where(p => p.TenantId == tid && !p.IsDeleted);
        if (!string.IsNullOrWhiteSpace(q))
            query = query.Where(p => p.NameAr.Contains(q) || p.NameEn.Contains(q) || p.Sku.Contains(q) || (p.BarcodeMain != null && p.BarcodeMain.Contains(q)) || (p.Description != null && p.Description.Contains(q)));
        var total = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return Ok(new { data = items, meta = new { page, page_size = pageSize, total } });
    }
    [HttpGet("{id}")]
    public async Task<IActionResult> Details(Guid id)
    {
        var p = await db.Products.FindAsync(id);
        if (p == null || p.IsDeleted) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var tid) && p.TenantId != tid) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        return Ok(new { data = p });
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
        // FIX tenant isolation: do not trust client TenantId
        var tidClaim = User.FindFirst("tid")?.Value;
        var tid = Guid.TryParse(tidClaim, out var ct) ? ct : ResolveTenant(null);
        dto.TenantId = tid;
        if (string.IsNullOrWhiteSpace(dto.Sku)) return BadRequest(new { error = new { code = "VALIDATION_ERROR", message = "SKU required" } });
        if (dto.SellPrice < 0 || dto.CostPrice < 0) return BadRequest(new { error = new { code = "VALIDATION_ERROR", message = "Price must be >= 0" } });
        if (string.IsNullOrWhiteSpace(dto.NameAr) && string.IsNullOrWhiteSpace(dto.NameEn)) return BadRequest(new { error = new { code = "VALIDATION_ERROR", message = "NameAr or NameEn required" } });
        if (IsSkuDup(tid, dto.Sku)) return Conflict(new { error = new { code = "CONFLICT", message = "SKU already exists" } });
        if (IsBarcodeDup(tid, dto.BarcodeMain)) return Conflict(new { error = new { code = "CONFLICT", message = "Barcode already exists" } });
        dto.Id = Guid.NewGuid(); dto.TenantId = tid; dto.CreatedAt = DateTime.UtcNow; dto.UpdatedAt = DateTime.UtcNow;
        db.Products.Add(dto);
        var branches = await db.Branches.Where(b => b.TenantId == tid).ToListAsync();
        foreach (var br in branches)
            db.InventoryStocks.Add(new PosCloud.Domain.Entities.InventoryStock { TenantId = tid, BranchId = br.Id, ProductId = dto.Id, QtyOnHand = 0, LowStockThreshold = dto.MinStockLevel });
        await db.SaveChangesAsync();
        return Created($"/api/products/{dto.Id}", new { data = dto });
    }
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] PosCloud.Domain.Entities.Product dto)
    {
        var p = await db.Products.FindAsync(id);
        if (p == null || p.IsDeleted) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && p.TenantId != ct) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        if (!string.IsNullOrWhiteSpace(dto.Sku) && dto.Sku != p.Sku && IsSkuDup(p.TenantId, dto.Sku, id)) return Conflict(new { error = new { code = "CONFLICT", message = "SKU already exists" } });
        if (!string.IsNullOrWhiteSpace(dto.BarcodeMain) && dto.BarcodeMain != p.BarcodeMain && IsBarcodeDup(p.TenantId, dto.BarcodeMain, id)) return Conflict(new { error = new { code = "CONFLICT", message = "Barcode already exists" } });
        p.NameAr = string.IsNullOrWhiteSpace(dto.NameAr) ? p.NameAr : dto.NameAr;
        p.NameEn = string.IsNullOrWhiteSpace(dto.NameEn) ? p.NameEn : dto.NameEn;
        p.Description = dto.Description ?? p.Description;
        p.Sku = string.IsNullOrWhiteSpace(dto.Sku) ? p.Sku : dto.Sku;
        p.BarcodeMain = dto.BarcodeMain ?? p.BarcodeMain;
        if (dto.SellPrice >= 0) p.SellPrice = dto.SellPrice;
        if (dto.CostPrice >= 0) p.CostPrice = dto.CostPrice;
        p.TaxRate = dto.TaxRate;
        p.Unit = string.IsNullOrWhiteSpace(dto.Unit) ? p.Unit : dto.Unit;
        if (dto.CategoryId != Guid.Empty) p.CategoryId = dto.CategoryId;
        p.MinStockLevel = dto.MinStockLevel;
        p.IsActive = dto.IsActive;
        p.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return Ok(new { data = p });
    }
    [HttpPatch("{id}")]
    public async Task<IActionResult> Patch(Guid id, [FromBody] PosCloud.Domain.Entities.Product dto) => await Update(id, dto);
    [HttpPost("{id}/activate")]
    public async Task<IActionResult> Activate(Guid id)
    {
        var p = await db.Products.FindAsync(id);
        if (p == null || p.IsDeleted) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && p.TenantId != ct) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        p.IsActive = true; p.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return Ok(new { data = p });
    }
    [HttpPost("{id}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        var p = await db.Products.FindAsync(id);
        if (p == null || p.IsDeleted) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && p.TenantId != ct) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        p.IsActive = false; p.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return Ok(new { data = p });
    }
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var p = await db.Products.FindAsync(id);
        if (p == null || p.IsDeleted) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && p.TenantId != ct) return NotFound(new { error = new { code = "NOT_FOUND", message = "Product not found" } });
        p.IsDeleted = true; p.DeletedAt = DateTime.UtcNow; p.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return Ok(new { data = p });
    }
}
