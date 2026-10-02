using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;
using PosCloud.Application.Accounting;

namespace PosCloud.Infrastructure.Accounting;

public class AccountingService(AppDbContext db) : IAccountingService
{
    public async Task AutoPostSaleAsync(Sale sale)
    {
        var accounts = await db.Accounts.Where(a => a.TenantId == sale.TenantId).ToDictionaryAsync(a => a.Code);

        var entry = new JournalEntry {
            TenantId = sale.TenantId,
            Date = sale.CreatedAt,
            Description = $"قيد مبيعات رقم {sale.ReceiptNo}",
            ReferenceType = "Sale",
            ReferenceId = sale.Id
        };

        // 1. Debit Cash (1101) or AR (1103)
        var debitCode = sale.CustomerId != null && sale.GrandTotal > sale.PaidTotal ? "1103" : "1101";
        if (accounts.TryGetValue(debitCode, out var debitAcc))
        {
            entry.Lines.Add(new JournalEntryLine { AccountId = debitAcc.Id, Debit = sale.GrandTotal });
            debitAcc.Balance += sale.GrandTotal;
        }

        // 2. Credit Sales (4101)
        if (accounts.TryGetValue("4101", out var salesAcc))
        {
            entry.Lines.Add(new JournalEntryLine { AccountId = salesAcc.Id, Credit = sale.GrandTotal });
            salesAcc.Balance += sale.GrandTotal;
        }

        // 3. COGS & Inventory
        var productIds = sale.Items.Select(i => i.ProductId).ToList();
        var products = await db.Products.Where(p => productIds.Contains(p.Id)).ToDictionaryAsync(p => p.Id);
        decimal totalCost = 0;
        foreach(var item in sale.Items) {
            if (products.TryGetValue(item.ProductId, out var p)) totalCost += p.CostPrice * item.Qty;
        }

        if (totalCost > 0)
        {
            if (accounts.TryGetValue("5101", out var cogsAcc))
            {
                entry.Lines.Add(new JournalEntryLine { AccountId = cogsAcc.Id, Debit = totalCost });
                cogsAcc.Balance += totalCost;
            }
            if (accounts.TryGetValue("1102", out var invAcc))
            {
                entry.Lines.Add(new JournalEntryLine { AccountId = invAcc.Id, Credit = totalCost });
                invAcc.Balance -= totalCost;
            }
        }

        db.JournalEntries.Add(entry);
        await db.SaveChangesAsync();
    }

    public async Task AutoPostPurchaseAsync(Purchase purchase)
    {
        if (purchase.Status != "received") return;

        var accounts = await db.Accounts.Where(a => a.TenantId == purchase.TenantId).ToDictionaryAsync(a => a.Code);

        var entry = new JournalEntry {
            TenantId = purchase.TenantId,
            Date = purchase.ReceivedAt ?? DateTime.UtcNow,
            Description = $"قيد مشتريات من مورد",
            ReferenceType = "Purchase",
            ReferenceId = purchase.Id
        };

        // 1. Debit Inventory (1102)
        if (accounts.TryGetValue("1102", out var invAcc))
        {
            entry.Lines.Add(new JournalEntryLine { AccountId = invAcc.Id, Debit = purchase.GrandTotal });
            invAcc.Balance += purchase.GrandTotal;
        }

        // 2. Credit AP (2101)
        if (accounts.TryGetValue("2101", out var apAcc))
        {
            entry.Lines.Add(new JournalEntryLine { AccountId = apAcc.Id, Credit = purchase.GrandTotal });
            apAcc.Balance += purchase.GrandTotal;
        }

        db.JournalEntries.Add(entry);
        await db.SaveChangesAsync();
    }
}
