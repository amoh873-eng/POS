using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/reports")]
public class ReportsController(AppDbContext db) : ControllerBase
{
    [HttpGet("daily-sales")]
    public async Task<IActionResult> DailySales([FromQuery] Guid tenantId, [FromQuery] DateTime? date, [FromQuery] Guid? branchId)
    {
        var d = (date ?? DateTime.UtcNow).Date;
        var q = db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt.Date == d && s.Status == "completed");
        if (branchId != null) q = q.Where(s => s.BranchId == branchId);
        var total = await q.SumAsync(s => s.GrandTotal);
        var count = await q.CountAsync();
        return Ok(new { data = new { date = d, total, count } });
    }

    [HttpGet("sales")]
    public async Task<IActionResult> Sales([FromQuery] Guid tenantId, [FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        var q = db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt >= from && s.CreatedAt <= to);
        var total = await q.SumAsync(s => s.GrandTotal);
        return Ok(new { data = new { from, to, total, count = await q.CountAsync() } });
    }

    [HttpGet("profit")]
    public async Task<IActionResult> Profit([FromQuery] Guid tenantId, [FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        var sales = await db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt >= from && s.CreatedAt <= to && s.Status == "completed").Include(s=>s.Items).ToListAsync();
        decimal revenue = sales.Sum(s=>s.GrandTotal);
        decimal cost = 0;
        foreach(var s in sales) foreach(var it in s.Items) {
            var p = await db.Products.FindAsync(it.ProductId);
            if(p!=null) cost += p.CostPrice * it.Qty;
        }
        return Ok(new { data = new { from, to, revenue, cost, profit = revenue - cost, margin = revenue==0?0:(revenue-cost)/revenue*100 } });
    }

    [HttpGet("inventory")]
    public async Task<IActionResult> Inventory([FromQuery] Guid tenantId, [FromQuery] Guid? branchId)
    {
        var q = db.InventoryStocks.Where(s=>s.TenantId==tenantId);
        if(branchId!=null) q=q.Where(s=>s.BranchId==branchId);
        var items = await q.Include(s=>s.ProductId).ToListAsync();
        // join manually for InMemory
        var prods = await db.Products.Where(p=>p.TenantId==tenantId).ToDictionaryAsync(p=>p.Id);
        var list = (await q.ToListAsync()).Select(s=>{
            prods.TryGetValue(s.ProductId, out var p);
            return new { productId=s.ProductId, sku=p?.Sku, name=p?.NameAr, qty=s.QtyOnHand, status= s.QtyOnHand==0?"out": s.QtyOnHand <= s.LowStockThreshold?"low":"ok" };
        });
        return Ok(new { data = list });
    }

    [HttpGet("top-products")]
    public async Task<IActionResult> TopProducts([FromQuery] Guid tenantId, [FromQuery] DateTime from, [FromQuery] DateTime to, [FromQuery] int take=5)
    {
        var sales = await db.Sales.Where(s=>s.TenantId==tenantId && s.CreatedAt>=from && s.CreatedAt<=to).Include(s=>s.Items).ToListAsync();
        var grouped = sales.SelectMany(s=>s.Items).GroupBy(i=>i.ProductId).Select(g=> new { productId=g.Key, qty=g.Sum(x=>x.Qty), total=g.Sum(x=>x.LineTotal) }).OrderByDescending(x=>x.qty).Take(take).ToList();
        return Ok(new { data = grouped });
    }
}
