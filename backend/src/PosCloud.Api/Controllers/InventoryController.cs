using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/inventory")]
public class InventoryController(AppDbContext db) : ControllerBase
{
    private Guid ResolveTid(Guid tid)
    {
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && ct != Guid.Empty) return ct;
        throw new UnauthorizedAccessException("Missing or invalid tenant claim");
    }
    [HttpGet("stock")]
    public async Task<IActionResult> Stock([FromQuery] Guid tenantId, [FromQuery] Guid? branchId, [FromQuery] string? q)
    {
        tenantId = ResolveTid(tenantId);
        var query = db.InventoryStocks.Where(s => s.TenantId == tenantId);
        if (branchId != null) query = query.Where(s => s.BranchId == branchId);
        var items = await query.ToListAsync();
        return Ok(new { data = items });
    }

    [HttpGet("movements")]
    public async Task<IActionResult> MovementsHistory([FromQuery] Guid tenantId, [FromQuery] Guid? branchId, [FromQuery] Guid? productId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        tenantId = ResolveTid(tenantId);
        var q = db.InventoryMovements.Where(m => m.TenantId == tenantId);
        if (branchId != null) q = q.Where(m => m.BranchId == branchId);
        if (productId != null) q = q.Where(m => m.ProductId == productId);
        var total = await q.CountAsync();
        var items = await q.OrderByDescending(m => m.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return Ok(new { data = items, meta = new { page, page_size = pageSize, total } });
    }
    [HttpGet("low-stock")]
    public async Task<IActionResult> LowStock([FromQuery] Guid tenantId, [FromQuery] Guid? branchId)
    {
        tenantId = ResolveTid(tenantId);
        var q = db.InventoryStocks.Where(s => s.TenantId == tenantId && s.QtyOnHand <= s.LowStockThreshold);
        if (branchId != null) q = q.Where(s => s.BranchId == branchId);
        var items = await q.ToListAsync();
        return Ok(new { data = items });
    }
    public record AdjustReq(Guid BranchId, Guid ProductId, decimal QtyDelta, string? Type);
    [HttpPost("adjust")]
    public async Task<IActionResult> Adjust([FromBody] AdjustReq req)
    {
        var tid = ResolveTid(Guid.Empty);
        var stock = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == tid && s.BranchId == req.BranchId && s.ProductId == req.ProductId);
        if (stock == null) { stock = new InventoryStock { TenantId = tid, BranchId = req.BranchId, ProductId = req.ProductId, QtyOnHand = 0, LowStockThreshold = 0 }; db.InventoryStocks.Add(stock); }
        stock.QtyOnHand += req.QtyDelta;
        if (stock.QtyOnHand < 0) return UnprocessableEntity(new { error = new { code = "INSUFFICIENT_STOCK", message = "Negative stock not allowed" } });
        var dto = new InventoryMovement { TenantId = tid, BranchId = req.BranchId, ProductId = req.ProductId, QtyDelta = req.QtyDelta, Type = "adjust", CreatedAt = DateTime.UtcNow };
        await db.SaveChangesAsync();
        return Ok(new { data = dto });
    }
    [HttpPost("movements")]
    public async Task<IActionResult> Movement([FromBody] InventoryMovement dto)
    {
        var tid = ResolveTid(Guid.Empty);
        dto.TenantId = tid;
        var stock = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == tid && s.BranchId == dto.BranchId && s.ProductId == dto.ProductId);
        if (stock == null)
        {
            stock = new InventoryStock { TenantId = tid, BranchId = dto.BranchId, ProductId = dto.ProductId, QtyOnHand = 0 };
            db.InventoryStocks.Add(stock);
        }
        stock.QtyOnHand += dto.QtyDelta;
        if (stock.QtyOnHand < 0) return UnprocessableEntity(new { error = new { code = "INSUFFICIENT_STOCK", message = "Negative stock not allowed" } });
        db.InventoryMovements.Add(dto);
        await db.SaveChangesAsync();
        return Ok(new { data = dto });
    }

    [HttpPost("transfer")]
    public async Task<IActionResult> Transfer([FromBody] TransferReq req)
    {
        var tid = ResolveTid(Guid.Empty);
        var strategy = db.Database.CreateExecutionStrategy();
        string? insufficient = null;
        await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await db.Database.BeginTransactionAsync();
            foreach (var line in req.Lines)
            {
                var from = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == tid && s.BranchId == req.FromBranchId && s.ProductId == line.ProductId);
                if (from == null || from.QtyOnHand < line.Qty) { insufficient = line.ProductId.ToString(); await tx.RollbackAsync(); return; }
                from.QtyOnHand -= line.Qty;
                var to = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == tid && s.BranchId == req.ToBranchId && s.ProductId == line.ProductId);
                if (to == null) { to = new InventoryStock { TenantId = tid, BranchId = req.ToBranchId, ProductId = line.ProductId, QtyOnHand = 0 }; db.InventoryStocks.Add(to); }
                to.QtyOnHand += line.Qty;
                db.InventoryMovements.Add(new InventoryMovement { TenantId = tid, BranchId = req.FromBranchId, ProductId = line.ProductId, Type = "transfer_out", QtyDelta = -line.Qty, RefType = "transfer" });
                db.InventoryMovements.Add(new InventoryMovement { TenantId = tid, BranchId = req.ToBranchId, ProductId = line.ProductId, Type = "transfer_in", QtyDelta = line.Qty, RefType = "transfer" });
            }
            if (insufficient != null) return;
            await db.SaveChangesAsync();
            await tx.CommitAsync();
        });
        if (insufficient != null) return UnprocessableEntity(new { error = new { code = "INSUFFICIENT_STOCK", message = $"Insufficient {insufficient}" } });
        return Ok(new { data = new { ok = true } });
    }

    public record TransferLine(Guid ProductId, decimal Qty);
    public record TransferReq(Guid TenantId, Guid FromBranchId, Guid ToBranchId, List<TransferLine> Lines);
}
