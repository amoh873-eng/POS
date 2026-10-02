namespace PosCloud.Domain.Entities;

public class Account
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public string Code { get; set; } = null!; // e.g., 1, 11, 1101
    public string NameAr { get; set; } = null!;
    public string NameEn { get; set; } = null!;
    public string Type { get; set; } = "Asset"; // Asset, Liability, Equity, Revenue, Expense
    public Guid? ParentId { get; set; }
    public bool IsGroup { get; set; } // If true, can't have transactions, only children
    public decimal Balance { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<Account> Children { get; set; } = new();
}

public class JournalEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TenantId { get; set; }
    public DateTime Date { get; set; } = DateTime.UtcNow;
    public string Description { get; set; } = null!;
    public string? ReferenceType { get; set; } // Sale, Purchase, Manual
    public Guid? ReferenceId { get; set; }
    public List<JournalEntryLine> Lines { get; set; } = new();
}

public class JournalEntryLine
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid JournalEntryId { get; set; }
    public Guid AccountId { get; set; }
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
}
