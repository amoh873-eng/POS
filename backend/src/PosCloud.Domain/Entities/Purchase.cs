namespace PosCloud.Domain.Entities;

public class Purchase
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public Guid SupplierId { get; set; }
    public string Status { get; set; } = "draft"; // draft/received/cancelled
    public decimal Subtotal { get; set; }
    public decimal TaxTotal { get; set; }
    public decimal GrandTotal { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReceivedAt { get; set; }
    public List<PurchaseItem> Items { get; set; } = new();
}

public class PurchaseItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PurchaseId { get; set; }
    public Guid ProductId { get; set; }
    public decimal Qty { get; set; }
    public decimal Cost { get; set; }
    public decimal LineTotal => Qty * Cost;
}

public class Terminal
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public string Name { get; set; } = null!;
    public string? DeviceId { get; set; }
    public bool IsActive { get; set; } = true;
}

public class Shift
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public Guid TerminalId { get; set; }
    public Guid OpenedBy { get; set; }
    public DateTime OpenedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ClosedAt { get; set; }
    public decimal OpeningCash { get; set; }
    public decimal? ClosingCash { get; set; }
    public string Status { get; set; } = "open";
}
