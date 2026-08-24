using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/inventory")]
public class InventoryController(AppDbContext db) : ControllerBase
{
    [HttpGet("stock")]
    public async Task<IActionResult> Stock([FromQuery] Guid tenantId, [FromQuery] Guid? branchId, [FromQuery] string? q)
    {
        var query = db.InventoryStocks.Where(s => s.TenantId == tenantId);
        if (branchId != null) query = query.Where(s => s.BranchId == branchId);
        // q filter by product name handled via join in full impl — simple v1: filter by product_id
        var items = await query.ToListAsync();
        return Ok(new { data = items });
    }

    [HttpPost("movements")]
    public async Task<IActionResult> Movement([FromBody] InventoryMovement dto)
    {
        var stock = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == dto.TenantId && s.BranchId == dto.BranchId && s.ProductId == dto.ProductId);
        if (stock == null)
        {
            stock = new InventoryStock { TenantId = dto.TenantId, BranchId = dto.BranchId, ProductId = dto.ProductId, QtyOnHand = 0 };
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
        using var tx = await db.Database.BeginTransactionAsync();
        foreach (var line in req.Lines)
        {
            var from = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == req.TenantId && s.BranchId == req.FromBranchId && s.ProductId == line.ProductId);
            if (from == null || from.QtyOnHand < line.Qty) { await tx.RollbackAsync(); return UnprocessableEntity(new { error = new { code = "INSUFFICIENT_STOCK", message = $"Insufficient {line.ProductId}" } }); }
            from.QtyOnHand -= line.Qty;
            var to = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == req.TenantId && s.BranchId == req.ToBranchId && s.ProductId == line.ProductId);
            if (to == null) { to = new InventoryStock { TenantId = req.TenantId, BranchId = req.ToBranchId, ProductId = line.ProductId, QtyOnHand = 0 }; db.InventoryStocks.Add(to); }
            to.QtyOnHand += line.Qty;
            db.InventoryMovements.Add(new InventoryMovement { TenantId = req.TenantId, BranchId = req.FromBranchId, ProductId = line.ProductId, Type = "transfer_out", QtyDelta = -line.Qty, RefType = "transfer" });
            db.InventoryMovements.Add(new InventoryMovement { TenantId = req.TenantId, BranchId = req.ToBranchId, ProductId = line.ProductId, Type = "transfer_in", QtyDelta = line.Qty, RefType = "transfer" });
        }
        await db.SaveChangesAsync();
        await tx.CommitAsync();
        return Ok(new { data = new { ok = true } });
    }

    public record TransferLine(Guid ProductId, decimal Qty);
    public record TransferReq(Guid TenantId, Guid FromBranchId, Guid ToBranchId, List<TransferLine> Lines);
}
