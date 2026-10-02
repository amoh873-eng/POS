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

    [HttpGet("dashboard-summary")]
    public async Task<IActionResult> DashboardSummary([FromQuery] Guid tenantId)
    {
        tenantId = ResolveTid(tenantId);
        var now = DateTime.UtcNow;
        var today = now.Date;
        var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var last7Days = now.AddDays(-7).Date;

        // Today KPIs
        var todaySales = await db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt.Date == today && s.Status == "completed").ToListAsync();
        var todayTotal = todaySales.Sum(s => s.GrandTotal);
        var todayCount = todaySales.Count;

        // Month Profit (cached-like simple calc)
        var monthSales = await db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt >= startOfMonth && s.Status == "completed").Include(s => s.Items).ToListAsync();
        decimal monthRevenue = monthSales.Sum(s => s.GrandTotal);

        // Inventory Alerts
        var lowStockCount = await db.InventoryStocks.CountAsync(s => s.TenantId == tenantId && s.QtyOnHand <= s.LowStockThreshold);

        // Sales Trend (Last 7 Days)
        var trendSales = await db.Sales
            .Where(s => s.TenantId == tenantId && s.CreatedAt >= last7Days && s.Status == "completed")
            .Select(s => new { s.CreatedAt, s.GrandTotal })
            .ToListAsync();

        var trend = trendSales
            .GroupBy(s => s.CreatedAt.Date)
            .Select(g => new { date = g.Key, total = g.Sum(s => s.GrandTotal) })
            .OrderBy(x => x.date)
            .ToList();

        // Payment Method Distribution (for Pie Chart)
        var payments = await db.Payments
            .Where(p => p.TenantId == tenantId && p.CreatedAt >= last7Days && p.Status == "completed")
            .GroupBy(p => p.Method)
            .Select(g => new { method = g.Key, total = g.Sum(p => p.Amount) })
            .ToListAsync();

        // Category Sales Distribution (for another Pie Chart)
        var categorySales = await db.SaleItems
            .Where(i => db.Sales.Any(s => s.Id == i.SaleId && s.TenantId == tenantId && s.CreatedAt >= last7Days && s.Status == "completed"))
            .GroupBy(i => i.ProductId)
            .Select(g => new { ProductId = g.Key, Total = g.Sum(x => x.Qty * x.UnitPrice - x.Discount) })
            .ToListAsync();

        var productsInfo = await db.Products.Where(p => p.TenantId == tenantId).ToDictionaryAsync(p => p.Id);
        var categoriesInfo = await db.Categories.Where(c => c.TenantId == tenantId).ToDictionaryAsync(c => c.Id);

        var byCategory = categorySales
            .Select(s => new {
                CategoryId = productsInfo.TryGetValue(s.ProductId, out var p) ? p.CategoryId : Guid.Empty,
                Total = s.Total
            })
            .GroupBy(x => x.CategoryId)
            .Select(g => new {
                category = categoriesInfo.TryGetValue(g.Key, out var c) ? c.NameAr : "غير مصنف",
                total = g.Sum(x => x.Total)
            })
            .ToList();

        return Ok(new { data = new {
            today = new { total = todayTotal, count = todayCount },
            month = new { revenue = monthRevenue },
            inventory = new { lowStockCount },
            trend,
            payments,
            categories = byCategory
        } });
    }

    [HttpGet("full-analytics")]
    public async Task<IActionResult> FullAnalytics([FromQuery] Guid tenantId, [FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        tenantId = ResolveTid(tenantId);
        var f = from.ToUniversalTime();
        var t = to.ToUniversalTime();

        var sales = await db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt >= f && s.CreatedAt <= t && s.Status == "completed").Include(s => s.Items).ToListAsync();

        // 1. Financial Summary
        decimal revenue = sales.Sum(s => s.GrandTotal);
        decimal tax = sales.Sum(s => s.TaxTotal);
        var productIds = sales.SelectMany(s => s.Items).Select(i => i.ProductId).Distinct().ToList();
        var products = productIds.Count == 0 ? new Dictionary<Guid, PosCloud.Domain.Entities.Product>() : await db.Products.Where(p => p.TenantId == tenantId && productIds.Contains(p.Id)).ToDictionaryAsync(p => p.Id);
        decimal cost = 0;
        foreach (var s in sales) foreach (var it in s.Items) if (products.TryGetValue(it.ProductId, out var p)) cost += p.CostPrice * it.Qty;
        decimal netProfit = revenue - tax - cost;

        // 2. Sales Trend (Daily)
        var trend = sales.GroupBy(s => s.CreatedAt.Date).Select(g => new { date = g.Key, total = g.Sum(s => s.GrandTotal) }).OrderBy(x => x.date).ToList();

        // 3. Payment Methods
        var payments = await db.Payments.Where(p => p.TenantId == tenantId && p.CreatedAt >= f && p.CreatedAt <= t && p.Status == "completed")
            .GroupBy(p => p.Method).Select(g => new { method = g.Key, total = g.Sum(p => p.Amount) }).ToListAsync();

        // 4. Top Products
        var topProds = sales.SelectMany(s => s.Items).GroupBy(i => i.ProductId).Select(g => {
            products.TryGetValue(g.Key, out var p);
            return new { name = p?.NameAr ?? "P", qty = g.Sum(x => x.Qty), total = g.Sum(x => x.LineTotal) };
        }).OrderByDescending(x => x.qty).Take(10).ToList();

        return Ok(new { data = new { revenue, cost, tax, netProfit, trend, payments, topProducts = topProds } });
    }
}
