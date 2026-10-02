using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/accounting")]
public class AccountingController(AppDbContext db) : ControllerBase
{
    private Guid ResolveTid()
    {
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct) && ct != Guid.Empty) return ct;
        throw new UnauthorizedAccessException("Missing or invalid tenant claim");
    }

    [HttpGet("accounts")]
    public async Task<IActionResult> GetAccounts()
    {
        var tid = ResolveTid();
        var accounts = await db.Accounts
            .Where(a => a.TenantId == tid)
            .OrderBy(a => a.Code)
            .ToListAsync();

        // Build tree locally for the response
        var rootAccounts = accounts.Where(a => a.ParentId == null).ToList();
        return Ok(new { data = rootAccounts });
    }

    [HttpPost("accounts")]
    public async Task<IActionResult> CreateAccount([FromBody] Account dto)
    {
        var tid = ResolveTid();
        dto.TenantId = tid;
        dto.Id = Guid.NewGuid();

        db.Accounts.Add(dto);
        await db.SaveChangesAsync();
        return Created("", new { data = dto });
    }

    [HttpGet("seed-basic")]
    public async Task<IActionResult> SeedBasic()
    {
        var tid = ResolveTid();
        if (await db.Accounts.AnyAsync(a => a.TenantId == tid))
            return BadRequest(new { error = "Accounts already seeded" });

        // 1. Assets
        var assets = new Account { TenantId = tid, Code = "1", NameAr = "الأصول", NameEn = "Assets", Type = "Asset", IsGroup = true };
        db.Accounts.Add(assets);
        await db.SaveChangesAsync();

        var currAssets = new Account { TenantId = tid, ParentId = assets.Id, Code = "11", NameAr = "الأصول المتداولة", NameEn = "Current Assets", Type = "Asset", IsGroup = true };
        db.Accounts.Add(currAssets);
        await db.SaveChangesAsync();

        var cash = new Account { TenantId = tid, ParentId = currAssets.Id, Code = "1101", NameAr = "الصندوق / النقدية", NameEn = "Cash", Type = "Asset", IsGroup = false };
        var inventory = new Account { TenantId = tid, ParentId = currAssets.Id, Code = "1102", NameAr = "المخزون", NameEn = "Inventory", Type = "Asset", IsGroup = false };
        var ar = new Account { TenantId = tid, ParentId = currAssets.Id, Code = "1103", NameAr = "ذمم مدينة (عملاء)", NameEn = "Accounts Receivable", Type = "Asset", IsGroup = false };
        db.Accounts.AddRange(cash, inventory, ar);

        // 2. Liabilities
        var liab = new Account { TenantId = tid, Code = "2", NameAr = "الخصوم", NameEn = "Liabilities", Type = "Liability", IsGroup = true };
        db.Accounts.Add(liab);
        await db.SaveChangesAsync();

        var ap = new Account { TenantId = tid, ParentId = liab.Id, Code = "2101", NameAr = "ذمم دائنة (موردين)", NameEn = "Accounts Payable", Type = "Liability", IsGroup = false };
        db.Accounts.Add(ap);

        // 3. Equity
        var equity = new Account { TenantId = tid, Code = "3", NameAr = "حقوق الملكية", NameEn = "Equity", Type = "Equity", IsGroup = true };
        db.Accounts.Add(equity);

        // 4. Revenue
        var revenue = new Account { TenantId = tid, Code = "4", NameAr = "الإيرادات", NameEn = "Revenue", Type = "Revenue", IsGroup = true };
        db.Accounts.Add(revenue);
        await db.SaveChangesAsync();

        var sales = new Account { TenantId = tid, ParentId = revenue.Id, Code = "4101", NameAr = "مبيعات بضاعة", NameEn = "Product Sales", Type = "Revenue", IsGroup = false };
        db.Accounts.Add(sales);

        // 5. Expenses
        var expenses = new Account { TenantId = tid, Code = "5", NameAr = "المصاريف", NameEn = "Expenses", Type = "Expense", IsGroup = true };
        db.Accounts.Add(expenses);
        await db.SaveChangesAsync();

        var cogs = new Account { TenantId = tid, ParentId = expenses.Id, Code = "5101", NameAr = "تكلفة البضاعة المباعة", NameEn = "COGS", Type = "Expense", IsGroup = false };
        db.Accounts.Add(cogs);

        await db.SaveChangesAsync();
        return Ok(new { message = "Comprehensive chart of accounts seeded successfully" });
    }
}
