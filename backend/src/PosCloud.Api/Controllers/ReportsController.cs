using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/reports")]
public class ReportsController(AppDbContext db) : ControllerBase
{
    private Guid ResolveTid(Guid tid)
    {
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && ct != Guid.Empty) return ct;
        throw new UnauthorizedAccessException("Missing or invalid tenant claim");
    }
    [HttpGet("daily-sales")]
    public async Task<IActionResult> DailySales([FromQuery] Guid tenantId, [FromQuery] DateTime? date, [FromQuery] Guid? branchId)
    {
        tenantId = ResolveTid(tenantId);
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
        tenantId = ResolveTid(tenantId);
        var q = db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt >= from && s.CreatedAt <= to);
        var total = await q.SumAsync(s => s.GrandTotal);
        return Ok(new { data = new { from, to, total, count = await q.CountAsync() } });
    }

    [HttpGet("profit")]
    public async Task<IActionResult> Profit([FromQuery] Guid tenantId, [FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        tenantId = ResolveTid(tenantId);
        var sales = await db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt >= from && s.CreatedAt <= to && s.Status == "completed").Include(s=>s.Items).ToListAsync();
        decimal revenue = sales.Sum(s=>s.GrandTotal);
        var productIds = sales.SelectMany(s=>s.Items).Select(i=>i.ProductId).Distinct().ToList();
        var products = productIds.Count == 0 ? new Dictionary<Guid, PosCloud.Domain.Entities.Product>() : await db.Products.Where(p=>p.TenantId==tenantId && productIds.Contains(p.Id)).ToDictionaryAsync(p=>p.Id);
        decimal cost = 0;
        foreach(var s in sales) foreach(var it in s.Items) {
            if(products.TryGetValue(it.ProductId, out var p)) cost += p.CostPrice * it.Qty;
        }
        return Ok(new { data = new { from, to, revenue, cost, profit = revenue - cost, margin = revenue==0?0:(revenue-cost)/revenue*100 } });
    }

    [HttpGet("inventory")]
    public async Task<IActionResult> Inventory([FromQuery] Guid tenantId, [FromQuery] Guid? branchId)
    {
        tenantId = ResolveTid(tenantId);
        var q = db.InventoryStocks.Where(s=>s.TenantId==tenantId);
        if(branchId!=null) q=q.Where(s=>s.BranchId==branchId);
        // removed invalid Include(s=>s.ProductId) — ProductId is scalar, not navigation
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
        tenantId = ResolveTid(tenantId);
        var sales = await db.Sales.Where(s=>s.TenantId==tenantId && s.CreatedAt>=from && s.CreatedAt<=to).Include(s=>s.Items).ToListAsync();
        var grouped = sales.SelectMany(s=>s.Items).GroupBy(i=>i.ProductId).Select(g=> new { productId=g.Key, qty=g.Sum(x=>x.Qty), total=g.Sum(x=>x.LineTotal) }).OrderByDescending(x=>x.qty).Take(take).ToList();
        return Ok(new { data = grouped });
    }
}
