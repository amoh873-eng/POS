using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Infrastructure.Seed;

public static class SeedData
{
    public static async Task SeedAsync(AppDbContext db, bool seedDemoData = true)
    {
        // Always ensure at least one tenant/branch/admin exists — minimal production seed.
        // Demo seed (sample products etc.) only when seedDemoData=true (Development).
        var hasTenant = await db.Tenants.AnyAsync();
        if (!seedDemoData)
        {
            if (!hasTenant)
            {
                var tenant = new Tenant { Name = "Demo Business", Slug = "demo", IsActive = true };
                db.Tenants.Add(tenant);
                await db.SaveChangesAsync();
                var branch = new Branch { TenantId = tenant.Id, Name = "Main Branch", Code = "MAIN", IsActive = true };
                db.Branches.Add(branch);
                var settings = new TenantSettings { TenantId = tenant.Id, BusinessName = "Demo Business", PrimaryColor = "#6D5BD0", Currency = "JOD", Language = "ar" };
                db.TenantSettings.Add(settings);
                var roles = new[] { "Owner", "Administrator", "Manager", "Cashier", "Inventory", "Accountant" }
                    .Select(n => new Role { TenantId = tenant.Id, Name = n }).ToList();
                db.Roles.AddRange(roles);
                await db.SaveChangesAsync();
                var admin = new User { TenantId = tenant.Id, Email = "admin@demo.com", DisplayName = "Admin", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123") };
                db.Users.Add(admin);
                await db.SaveChangesAsync();
            }
            else
            {
                // Guard: fix legacy dummy hash even when demo seed is off
                var adminUser0 = await db.Users.FirstOrDefaultAsync(u => u.Email == "admin@demo.com");
                if (adminUser0 != null && !adminUser0.PasswordHash.StartsWith("$2"))
                {
                    adminUser0.PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123");
                    await db.SaveChangesAsync();
                }
                if (adminUser0 != null)
                {
                    try { if (!BCrypt.Net.BCrypt.Verify("Admin@123", adminUser0.PasswordHash)) { adminUser0.PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"); await db.SaveChangesAsync(); } } catch { adminUser0.PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"); await db.SaveChangesAsync(); }
                }
            }
            return;
        }
        if (!hasTenant)
        {
            var tenant = new Tenant { Name = "Demo Business", Slug = "demo", IsActive = true };
            db.Tenants.Add(tenant);
            await db.SaveChangesAsync();
            var branch = new Branch { TenantId = tenant.Id, Name = "Main Branch", Code = "MAIN", IsActive = true };
            db.Branches.Add(branch);
            var settings = new TenantSettings { TenantId = tenant.Id, BusinessName = "Demo Business", PrimaryColor = "#6D5BD0", Currency = "JOD", Language = "ar" };
            db.TenantSettings.Add(settings);
            var roles = new[] { "Owner", "Administrator", "Manager", "Cashier", "Inventory", "Accountant" }
                .Select(n => new Role { TenantId = tenant.Id, Name = n }).ToList();
            db.Roles.AddRange(roles);
            await db.SaveChangesAsync();
            var admin = new User { TenantId = tenant.Id, Email = "admin@demo.com", DisplayName = "Admin", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123") };
            db.Users.Add(admin);
            await db.SaveChangesAsync();
            // seed sample categories & products
            var catFood = new Category { TenantId = tenant.Id, BranchId = branch.Id, NameAr = "منتجات عامة", NameEn = "General", IsActive = true };
            db.Categories.Add(catFood);
            await db.SaveChangesAsync();
            var p1 = new Product { TenantId = tenant.Id, CategoryId = catFood.Id, NameAr = "منتج تجريبي 1", NameEn = "Sample Product 1", Sku = "SKU-001", BarcodeMain = "100001", Unit = "pcs", CostPrice = 5, SellPrice = 10, TaxRate = 0.16m, IsActive = true };
            var p2 = new Product { TenantId = tenant.Id, CategoryId = catFood.Id, NameAr = "منتج تجريبي 2", NameEn = "Sample Product 2", Sku = "SKU-002", BarcodeMain = "100002", Unit = "pcs", CostPrice = 8, SellPrice = 15, TaxRate = 0.16m, IsActive = true };
            var p3 = new Product { TenantId = tenant.Id, CategoryId = catFood.Id, NameAr = "منتج تجريبي 3", NameEn = "Sample Product 3", Sku = "SKU-003", BarcodeMain = "100003", Unit = "pcs", CostPrice = 3, SellPrice = 7, TaxRate = 0m, IsActive = true };
            db.Products.AddRange(p1, p2, p3);
            await db.SaveChangesAsync();
            db.InventoryStocks.AddRange(new InventoryStock { TenantId = tenant.Id, BranchId = branch.Id, ProductId = p1.Id, QtyOnHand = 100, LowStockThreshold = 10 }, new InventoryStock { TenantId = tenant.Id, BranchId = branch.Id, ProductId = p2.Id, QtyOnHand = 50, LowStockThreshold = 5 }, new InventoryStock { TenantId = tenant.Id, BranchId = branch.Id, ProductId = p3.Id, QtyOnHand = 200, LowStockThreshold = 20 });
            db.Customers.Add(new Customer { TenantId = tenant.Id, Name = "عميل نقدي", Phone = "0790000000", CreditLimit = 0, IsActive = true });
            db.Suppliers.Add(new Supplier { TenantId = tenant.Id, Name = "مورد افتراضي", Phone = "0790000001", IsActive = true });
            await db.SaveChangesAsync();
        }
        // ensure admin password is valid (fix legacy dummy hash)
        var adminUser = await db.Users.FirstOrDefaultAsync(u => u.Email == "admin@demo.com");
        if (adminUser != null && !adminUser.PasswordHash.StartsWith("$2"))
        {
            adminUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123");
            await db.SaveChangesAsync();
        }
        // also fix BCrypt dummy via Verify
        if (adminUser != null)
        {
            try { if (!BCrypt.Net.BCrypt.Verify("Admin@123", adminUser.PasswordHash)) { adminUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"); await db.SaveChangesAsync(); } } catch { adminUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"); await db.SaveChangesAsync(); }
        }
    }
}
