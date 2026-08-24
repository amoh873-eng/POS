namespace PosCloud.Domain.Entities;

public class InventoryStock
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public Guid ProductId { get; set; }
    public decimal QtyOnHand { get; set; }
    public decimal LowStockThreshold { get; set; }
}

public class InventoryMovement
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public Guid ProductId { get; set; }
    public string Type { get; set; } = null!; // sale/purchase/adjust/transfer_in/transfer_out/count/refund
    public decimal QtyDelta { get; set; }
    public string? RefType { get; set; }
    public Guid? RefId { get; set; }
    public Guid? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class StockCount
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public string Status { get; set; } = "draft";
    public DateTime CountedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PostedAt { get; set; }
}

public class StockCountLine
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid StockCountId { get; set; }
    public Guid ProductId { get; set; }
    public decimal SystemQty { get; set; }
    public decimal CountedQty { get; set; }
    public decimal Diff => CountedQty - SystemQty;
}
