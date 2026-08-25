using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Application.Sales;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/sales")]
public class SalesController(AppDbContext db) : ControllerBase
{
    private Guid ResolveTid(Guid tid)
    {
        if (tid != Guid.Empty) return tid;
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct)) return ct;
        return db.Tenants.Select(t => t.Id).FirstOrDefault();
    }
    public record SaleLineReq(Guid ProductId, decimal Qty, decimal? UnitPrice, decimal? Discount);
    public record PaymentReq(string Method, decimal Amount, string? Provider, string? ProviderRef);
    public record CreateSaleReq(Guid BranchId, Guid TenantId, Guid? CustomerId, decimal? DiscountTotal, List<SaleLineReq> Lines, List<PaymentReq> Payments);

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateSaleReq req, [FromHeader(Name = "Idempotency-Key")] string? idempotencyKey)
    {
        req = req with { TenantId = ResolveTid(req.TenantId) };
        if (!string.IsNullOrEmpty(idempotencyKey))
        {
            var existing = await db.Sales.Include(s => s.Items).Include(s => s.Payments)
                .FirstOrDefaultAsync(s => s.IdempotencyKey == idempotencyKey && s.TenantId == req.TenantId);
            if (existing != null) return Ok(new { data = existing });
        }

        var products = await db.Products.Where(p => req.Lines.Select(l => l.ProductId).Contains(p.Id)).ToDictionaryAsync(p => p.Id);
        var lines = req.Lines.Select(l =>
        {
            var p = products[l.ProductId];
            return (l.Qty, unitPrice: l.UnitPrice ?? p.SellPrice, discount: l.Discount ?? 0, taxRate: p.TaxRate);
        }).ToList();

        var (subtotal, taxTotal, grandTotal) = SaleCalculator.Compute(lines, req.DiscountTotal ?? 0);
        var paid = req.Payments.Sum(p => p.Amount);
        // credit sale: allow unpaid if customer exists and within limit
        if (req.CustomerId != null)
        {
            var cust = await db.Customers.FindAsync(req.CustomerId.Value);
            if (cust != null)
            {
                var owed = grandTotal - paid;
                if (owed > 0)
                {
                    if (cust.Balance + owed > cust.CreditLimit && cust.CreditLimit > 0)
                        return UnprocessableEntity(new { error = new { code = "CREDIT_LIMIT", message = $"Credit limit exceeded: {cust.Balance}+{owed} > {cust.CreditLimit}" } });
                    cust.Balance += owed;
                }
            }
        }
        else if (paid != grandTotal)
            return UnprocessableEntity(new { error = new { code = "PAYMENT_MISMATCH", message = $"Paid {paid} != Grand {grandTotal}" } });

        var sale = new Sale
        {
            TenantId = req.TenantId,
            BranchId = req.BranchId,
            CustomerId = req.CustomerId,
            ReceiptNo = $"R-{DateTime.UtcNow:yyyyMMddHHmmss}-{Random.Shared.Next(1000, 9999)}",
            Subtotal = subtotal,
            TaxTotal = taxTotal,
            GrandTotal = grandTotal,
            PaidTotal = paid,
            IdempotencyKey = idempotencyKey,
        };

        foreach (var (l, idx) in req.Lines.Select((v, i) => (v, i)))
        {
            var calc = lines[idx];
            sale.Items.Add(new SaleItem
            {
                SaleId = sale.Id,
                ProductId = l.ProductId,
                Qty = l.Qty,
                UnitPrice = calc.unitPrice,
                Discount = calc.discount,
                Tax = (calc.Qty * calc.unitPrice - calc.discount) * calc.taxRate,
                LineTotal = calc.Qty * calc.unitPrice - calc.discount + (calc.Qty * calc.unitPrice - calc.discount) * calc.taxRate
            });
        }
        foreach (var p in req.Payments)
            sale.Payments.Add(new Payment { TenantId = req.TenantId, SaleId = sale.Id, Method = p.Method, Amount = p.Amount, Provider = p.Provider, ProviderRef = p.ProviderRef });

        // Simple stock check + deduction (transactional)
        using var tx = await db.Database.BeginTransactionAsync();
        foreach (var item in sale.Items)
        {
            var stock = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == req.TenantId && s.BranchId == req.BranchId && s.ProductId == item.ProductId);
            if (stock == null || stock.QtyOnHand < item.Qty)
            {
                await tx.RollbackAsync();
                return UnprocessableEntity(new { error = new { code = "INSUFFICIENT_STOCK", message = $"Product {item.ProductId} insufficient" } });
            }
            stock.QtyOnHand -= item.Qty;
            db.InventoryMovements.Add(new InventoryMovement
            {
                TenantId = req.TenantId, BranchId = req.BranchId, ProductId = item.ProductId, Type = "sale", QtyDelta = -item.Qty, RefType = "sale", RefId = sale.Id
            });
        }
        db.Sales.Add(sale);
        await db.SaveChangesAsync();
        await tx.CommitAsync();
        return Created($"/api/sales/{sale.Id}", new { data = sale });
    }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        tenantId = ResolveTid(tenantId);
        var q = db.Sales.Where(s => s.TenantId == tenantId).OrderByDescending(s => s.CreatedAt);
        var total = await q.CountAsync();
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).Include(s => s.Items).ToListAsync();
        return Ok(new { data = items, meta = new { page, page_size = pageSize, total } });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var s = await db.Sales.Include(x => x.Items).Include(x => x.Payments).FirstOrDefaultAsync(x => x.Id == id);
        if (s == null) return NotFound();
        return Ok(new { data = s });
    }

    [HttpPost("{id}/refund")]
    public async Task<IActionResult> Refund(Guid id, [FromBody] RefundReq req)
    {
        var orig = await db.Sales.Include(s => s.Items).Include(s => s.Payments).FirstOrDefaultAsync(s => s.Id == id);
        if (orig == null) return NotFound();
        if (orig.Status == "refunded") return BadRequest(new { error = new { code = "ALREADY_REFUNDED", message = "Already refunded" } });
        var refund = new Sale
        {
            TenantId = orig.TenantId, BranchId = orig.BranchId, CustomerId = orig.CustomerId,
            ReceiptNo = $"RF-{orig.ReceiptNo}", Status = "refunded",
            Subtotal = -orig.Subtotal, TaxTotal = -orig.TaxTotal, GrandTotal = -orig.GrandTotal, PaidTotal = -orig.PaidTotal,
        };
        foreach (var item in orig.Items)
        {
            refund.Items.Add(new SaleItem { SaleId = refund.Id, ProductId = item.ProductId, Qty = -item.Qty, UnitPrice = item.UnitPrice, Discount = -item.Discount, Tax = -item.Tax, LineTotal = -item.LineTotal });
            var stock = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == orig.TenantId && s.BranchId == orig.BranchId && s.ProductId == item.ProductId);
            if (stock == null) { stock = new InventoryStock { TenantId = orig.TenantId, BranchId = orig.BranchId, ProductId = item.ProductId, QtyOnHand = item.Qty }; db.InventoryStocks.Add(stock); }
            else stock.QtyOnHand += item.Qty;
            db.InventoryMovements.Add(new InventoryMovement { TenantId = orig.TenantId, BranchId = orig.BranchId, ProductId = item.ProductId, Type = "refund", QtyDelta = item.Qty, RefType = "refund", RefId = refund.Id });
        }
        foreach (var p in orig.Payments)
            refund.Payments.Add(new Payment { TenantId = orig.TenantId, SaleId = refund.Id, Method = p.Method, Amount = -p.Amount, Provider = p.Provider });
        orig.Status = "refunded";
        db.Sales.Add(refund);
        await db.SaveChangesAsync();
        return Ok(new { data = refund });
    }
    public record RefundReq(string? Reason);
}
