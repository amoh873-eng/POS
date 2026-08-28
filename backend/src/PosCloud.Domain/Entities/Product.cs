using PosCloud.Domain.Common;

namespace PosCloud.Domain.Entities;

public class Product : BaseEntity
{
    public Guid CategoryId { get; set; }
    public string NameAr { get; set; } = null!;
    public string NameEn { get; set; } = null!;
    public string Sku { get; set; } = null!;
    public string? BarcodeMain { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public string Unit { get; set; } = "pcs";
    public decimal CostPrice { get; set; }
    public decimal SellPrice { get; set; }
    public decimal TaxRate { get; set; }
    public decimal MinStockLevel { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }
}

public class ProductBarcode
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ProductId { get; set; }
    public string Barcode { get; set; } = null!;
    public bool IsPrimary { get; set; }
}
