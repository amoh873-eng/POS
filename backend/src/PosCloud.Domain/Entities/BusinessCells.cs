// Business-specific cells stubs — 101-104 — extend only on demand per Master Spec §22, §51
// These are placeholders to show extension point without building unused tables.

namespace PosCloud.Domain.Entities;

// 101 Restaurant
public class RestaurantTable
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public string Label { get; set; } = null!;
    public string Status { get; set; } = "available"; // available/occupied/reserved
    public Guid? CurrentSaleId { get; set; }
}

// 102 Bakery
public class Recipe
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid ProductId { get; set; } // finished product
    public List<RecipeLine> Lines { get; set; } = new();
}
public class RecipeLine { public Guid IngredientProductId { get; set; } public decimal Qty { get; set; } }

// 103 Pharmacy
public class PharmacyBatch
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public Guid ProductId { get; set; }
    public string BatchNo { get; set; } = null!;
    public DateTime ExpiryDate { get; set; }
    public decimal Qty { get; set; }
}

// 104 Supermarket
public class Promotion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public string Name { get; set; } = null!;
    public string Type { get; set; } = "percent"; // percent/buyXgetY
    public decimal Value { get; set; }
    public DateTime From { get; set; }
    public DateTime To { get; set; }
    public bool IsActive { get; set; } = true;
}
