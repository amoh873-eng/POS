using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/stock-counts")]
public class StockCountsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId, [FromQuery] Guid? branchId)
    {
        var q = db.StockCounts.Where(s => s.TenantId == tenantId);
        if (branchId != null) q = q.Where(s => s.BranchId == branchId);
        return Ok(new { data = await q.ToListAsync() });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] StockCount dto)
    {
        db.StockCounts.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/stock-counts/{dto.Id}", new { data = dto });
    }

    [HttpPost("{id}/post")]
    public async Task<IActionResult> Post(Guid id)
    {
        var sc = await db.StockCounts.FindAsync(id);
        if (sc == null) return NotFound();
        var lines = await db.StockCountLines.Where(l => l.StockCountId == id).ToListAsync();
        foreach (var line in lines)
        {
            var diff = line.CountedQty - line.SystemQty;
            if (diff == 0) continue;
            var stock = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == sc.TenantId && s.BranchId == sc.BranchId && s.ProductId == line.ProductId);
            if (stock == null) { stock = new InventoryStock { TenantId = sc.TenantId, BranchId = sc.BranchId, ProductId = line.ProductId, QtyOnHand = 0 }; db.InventoryStocks.Add(stock); }
            stock.QtyOnHand += diff;
            db.InventoryMovements.Add(new InventoryMovement { TenantId = sc.TenantId, BranchId = sc.BranchId, ProductId = line.ProductId, Type = "count", QtyDelta = diff, RefType = "stock_count", RefId = sc.Id });
        }
        sc.Status = "posted";
        sc.PostedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return Ok(new { data = sc });
    }
}
