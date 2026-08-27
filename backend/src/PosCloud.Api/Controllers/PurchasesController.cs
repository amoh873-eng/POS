using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/purchases")]
public class PurchasesController(AppDbContext db) : ControllerBase
{
    public record PurchaseLine(Guid ProductId, decimal Qty, decimal Cost);
    public record CreatePurchaseReq(Guid TenantId, Guid BranchId, Guid SupplierId, List<PurchaseLine> Lines);

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
        var q = db.Set<Purchase>().Where(p => p.TenantId == tenantId).OrderByDescending(p => p.CreatedAt);
        var total = await q.CountAsync();
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).Include(p => p.Items).ToListAsync();
        return Ok(new { data = items, meta = new { page, page_size = pageSize, total } });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePurchaseReq req)
    {
        var tid = ResolveTid(req.TenantId);
        var purchase = new Purchase { TenantId = tid, BranchId = req.BranchId, SupplierId = req.SupplierId };
        foreach (var l in req.Lines)
            purchase.Items.Add(new PurchaseItem { PurchaseId = purchase.Id, ProductId = l.ProductId, Qty = l.Qty, Cost = l.Cost });
        purchase.Subtotal = purchase.Items.Sum(i => i.LineTotal);
        purchase.GrandTotal = purchase.Subtotal;
        db.Set<Purchase>().Add(purchase);
        await db.SaveChangesAsync();
        return Created($"/api/purchases/{purchase.Id}", new { data = purchase });
    }

    [HttpPost("{id}/receive")]
    public async Task<IActionResult> Receive(Guid id)
    {
        var p = await db.Set<Purchase>().Include(x => x.Items).FirstOrDefaultAsync(x => x.Id == id);
        if (p == null) return NotFound();
        var tid = ResolveTid(Guid.Empty);
        if (p.TenantId != tid) return NotFound();
        if (p.Status == "received") return BadRequest(new { error = new { code = "ALREADY_RECEIVED", message = "Already received" } });
        using var tx = await db.Database.BeginTransactionAsync();
        foreach (var item in p.Items)
        {
            var stock = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == p.TenantId && s.BranchId == p.BranchId && s.ProductId == item.ProductId);
            if (stock == null) { stock = new InventoryStock { TenantId = p.TenantId, BranchId = p.BranchId, ProductId = item.ProductId, QtyOnHand = 0 }; db.InventoryStocks.Add(stock); }
            stock.QtyOnHand += item.Qty;
            db.InventoryMovements.Add(new InventoryMovement { TenantId = p.TenantId, BranchId = p.BranchId, ProductId = item.ProductId, Type = "purchase", QtyDelta = item.Qty, RefType = "purchase", RefId = p.Id });
        }
        p.Status = "received";
        p.ReceivedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        await tx.CommitAsync();
        return Ok(new { data = p });
    }
}
