using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Infrastructure.Seed;

public static class SeedData
{
    public static async Task SeedAsync(AppDbContext db, bool seedDemoData = true)
    {
        // =====================================================================
        // PRODUCTION GUARD (PHASE 32 — P0 #4)
        // =====================================================================
        // When seedDemoData is false (Production / SeedDemoData=false):
        //   - No demo tenant is auto-created.
        //   - No default admin (admin@demo.com / Admin@123) is created.
        //   - No demo products/customers/suppliers or random demo sales.
        //   - The known demo password is NEVER written or force-reset.
        // Initial tenant provisioning on a fresh Production DB is an explicit,
        // documented operator step (setup API / manual SQL) — never automatic.
        if (!seedDemoData)
            return;

        var hasTenant = await db.Tenants.AnyAsync();
        Tenant? existingTenant = null;
        Branch? existingBranch = null;

        if (!hasTenant)
        {
            existingTenant = new Tenant { Name = "Smart POS Enterprise", Slug = "demo", IsActive = true };
            db.Tenants.Add(existingTenant);
            await db.SaveChangesAsync();

            existingBranch = new Branch { TenantId = existingTenant.Id, Name = "مركز المدينة", Code = "MAIN", IsActive = true };
            db.Branches.Add(existingBranch);

            var settings = new TenantSettings {
                TenantId = existingTenant.Id,
                BusinessName = "شركة سمارت للتجارة",
                PrimaryColor = "#6D5BD0",
                Currency = "JOD",
                Language = "ar",
                // Jo-Invoice is DISABLED by default with no credentials.
                // Real ClientId/SecretKey/ActivityNumber must be provided by the
                // tenant operator; never ship demo/fake ISTD keys (PHASE 32).
                JoInvoiceEnabled = false,
                JoInvoiceEnvironment = "sandbox",
                JoInvoiceClientId = null,
                JoInvoiceSecretKey = null,
                JoInvoiceActivityNumber = null
            };
            db.TenantSettings.Add(settings);

            var roles = new[] { "Owner", "Administrator", "Manager", "Cashier", "Inventory", "Accountant" }
                .Select(n => new Role { TenantId = existingTenant.Id, Name = n }).ToList();
            db.Roles.AddRange(roles);
            await db.SaveChangesAsync();

            var admin = new User { TenantId = existingTenant.Id, Email = "admin@demo.com", DisplayName = "مدير النظام", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123") };
            db.Users.Add(admin);

            // Seed 20 Professional Products
            var catFood = new Category { TenantId = existingTenant.Id, BranchId = existingBranch.Id, NameAr = "الوجبات السريعة", NameEn = "Fast Food", IsActive = true };
            var catDrinks = new Category { TenantId = existingTenant.Id, BranchId = existingBranch.Id, NameAr = "المشروبات", NameEn = "Beverages", IsActive = true };
            var catElectronics = new Category { TenantId = existingTenant.Id, BranchId = existingBranch.Id, NameAr = "قسم الإلكترونيات", NameEn = "Electronics", IsActive = true };
            db.Categories.AddRange(catFood, catDrinks, catElectronics);
            await db.SaveChangesAsync();

            var products = new List<Product> {
                new() { NameAr = "وجبة برجر دبل", NameEn = "Double Burger Meal", Sku = "B-001", SellPrice = 5.50m, CostPrice = 2.20m, CategoryId = catFood.Id, ImageUrl = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400", TaxRate = 0.16m },
                new() { NameAr = "بيتزا خضار كبير", NameEn = "Veggie Pizza Large", Sku = "P-001", SellPrice = 7.00m, CostPrice = 3.00m, CategoryId = catFood.Id, ImageUrl = "https://images.unsplash.com/photo-1574071318508-1cdbad80ad50?w=400", TaxRate = 0.16m },
                new() { NameAr = "ساندوتش دجاج", NameEn = "Chicken Sandwich", Sku = "S-001", SellPrice = 3.25m, CostPrice = 1.10m, CategoryId = catFood.Id, ImageUrl = "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400", TaxRate = 0.16m },
                new() { NameAr = "كوكا كولا 330 مل", NameEn = "Coca Cola 330ml", Sku = "D-001", SellPrice = 0.50m, CostPrice = 0.28m, CategoryId = catDrinks.Id, ImageUrl = "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400", TaxRate = 0.16m },
                new() { NameAr = "عصير مانجو طبيعي", NameEn = "Fresh Mango Juice", Sku = "D-002", SellPrice = 2.00m, CostPrice = 0.80m, CategoryId = catDrinks.Id, ImageUrl = "https://images.unsplash.com/photo-1534353436294-0dbd4bdac845?w=400", TaxRate = 0.16m },
                new() { NameAr = "آيفون 15 برو", NameEn = "iPhone 15 Pro", Sku = "E-001", SellPrice = 950.00m, CostPrice = 820.00m, CategoryId = catElectronics.Id, ImageUrl = "https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400", TaxRate = 0.16m },
                new() { NameAr = "سماعات سوني MX5", NameEn = "Sony WH-1000XM5", Sku = "E-002", SellPrice = 280.00m, CostPrice = 210.00m, CategoryId = catElectronics.Id, ImageUrl = "https://images.unsplash.com/photo-1644151756531-1e967a15cc47?w=400", TaxRate = 0.16m },
                new() { NameAr = "شاحن لاسلكي", NameEn = "Wireless Charger", Sku = "E-003", SellPrice = 25.00m, CostPrice = 12.00m, CategoryId = catElectronics.Id, ImageUrl = "https://images.unsplash.com/photo-1615526675159-e248c3021d3f?w=400", TaxRate = 0.16m },
                new() { NameAr = "قهوة لاتيه حار", NameEn = "Caffe Latte Hot", Sku = "D-003", SellPrice = 3.50m, CostPrice = 0.90m, CategoryId = catDrinks.Id, ImageUrl = "https://images.unsplash.com/photo-1541167760496-162955ed8a9f?w=400", TaxRate = 0.16m },
                new() { NameAr = "كيكة شوكولاتة", NameEn = "Chocolate Cake", Sku = "F-005", SellPrice = 4.00m, CostPrice = 1.50m, CategoryId = catFood.Id, ImageUrl = "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400", TaxRate = 0.16m },
                new() { NameAr = "ماوس أبل سحري", NameEn = "Apple Magic Mouse", Sku = "E-004", SellPrice = 85.00m, CostPrice = 65.00m, CategoryId = catElectronics.Id, ImageUrl = "https://images.unsplash.com/photo-1527443224154-c4a3942d3490?w=400", TaxRate = 0.16m },
                new() { NameAr = "شاشة سامسونج 27", NameEn = "Samsung 27 Monitor", Sku = "E-005", SellPrice = 160.00m, CostPrice = 130.00m, CategoryId = catElectronics.Id, ImageUrl = "https://images.unsplash.com/photo-1527443224154-c4a3942d3490?w=400", TaxRate = 0.16m },
                new() { NameAr = "سلطة فواكه", NameEn = "Fruit Salad", Sku = "F-006", SellPrice = 2.50m, CostPrice = 1.00m, CategoryId = catFood.Id, ImageUrl = "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400", TaxRate = 0m },
                new() { NameAr = "مياه غازية", NameEn = "Sparkling Water", Sku = "D-004", SellPrice = 1.20m, CostPrice = 0.60m, CategoryId = catDrinks.Id, ImageUrl = "https://images.unsplash.com/photo-1551731589-709873d9646b?w=400", TaxRate = 0.16m },
                new() { NameAr = "لابتوب ديل XPS", NameEn = "Dell XPS 13", Sku = "E-006", SellPrice = 1200.00m, CostPrice = 1050.00m, CategoryId = catElectronics.Id, ImageUrl = "https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=400", TaxRate = 0.16m },
                new() { NameAr = "فلاشة 64 جيجا", NameEn = "USB Drive 64GB", Sku = "E-007", SellPrice = 10.00m, CostPrice = 4.00m, CategoryId = catElectronics.Id, ImageUrl = "https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=400", TaxRate = 0.16m },
                new() { NameAr = "كابل آيفون أصلي", NameEn = "Lightning Cable", Sku = "E-008", SellPrice = 15.00m, CostPrice = 7.00m, CategoryId = catElectronics.Id, ImageUrl = "https://images.unsplash.com/photo-1586952518485-11b180e92764?w=400", TaxRate = 0.16m },
                new() { NameAr = "وجبة ستيك مشوي", NameEn = "Grilled Steak Meal", Sku = "F-007", SellPrice = 18.00m, CostPrice = 9.00m, CategoryId = catFood.Id, ImageUrl = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400", TaxRate = 0.16m },
                new() { NameAr = "باستا فيتوتشيني", NameEn = "Fettuccine Pasta", Sku = "F-008", SellPrice = 6.50m, CostPrice = 2.80m, CategoryId = catFood.Id, ImageUrl = "https://images.unsplash.com/photo-1473093226795-af9932fe5856?w=400", TaxRate = 0.16m },
                new() { NameAr = "شاي عدني", NameEn = "Adani Tea", Sku = "D-005", SellPrice = 1.00m, CostPrice = 0.20m, CategoryId = catDrinks.Id, ImageUrl = "https://images.unsplash.com/photo-1594631252845-29fc458695d7?w=400", TaxRate = 0.16m }
            };

            foreach (var p in products) { p.TenantId = existingTenant.Id; db.Products.Add(p); }
            await db.SaveChangesAsync();

            // Initial Stock: 20 per item
            foreach (var p in products)
            {
                db.InventoryStocks.Add(new InventoryStock { TenantId = existingTenant.Id, BranchId = existingBranch.Id, ProductId = p.Id, QtyOnHand = 20, LowStockThreshold = 5 });
            }

            // Seed Default Customers/Suppliers
            db.Customers.Add(new Customer { TenantId = existingTenant.Id, Name = "علي محمد", Phone = "0791234567", CreditLimit = 100 });
            db.Suppliers.Add(new Supplier { TenantId = existingTenant.Id, Name = "شركة التوريد الوطنية", Phone = "065555555" });

            await db.SaveChangesAsync();
        }

        // --- DEMO SALES SEED (Self-Healing) ---
        existingTenant ??= await db.Tenants.FirstOrDefaultAsync();
        existingBranch ??= await db.Branches.FirstOrDefaultAsync();
        if (existingTenant != null && existingBranch != null && !await db.Sales.AnyAsync())
        {
            var prods = await db.Products.Where(p => p.TenantId == existingTenant.Id).ToListAsync();
            if (prods.Any())
            {
                var rnd = new Random();
                for (int i = 0; i < 15; i++)
                {
                    var saleDate = DateTime.UtcNow.AddDays(-rnd.Next(0, 8)).AddHours(-rnd.Next(0, 23));
                    var sale = new Sale
                    {
                        Id = Guid.NewGuid(),
                        TenantId = existingTenant.Id,
                        BranchId = existingBranch.Id,
                        ReceiptNo = $"DEMO-{DateTime.Now.Year}{i:D5}",
                        Status = "completed",
                        CreatedAt = saleDate,
                        Items = new List<SaleItem>()
                    };

                    int itemsCount = rnd.Next(1, 5);
                    decimal subtotal = 0;
                    for (int j = 0; j < itemsCount; j++)
                    {
                        var p = prods[rnd.Next(prods.Count)];
                        var qty = rnd.Next(1, 4);
                        var item = new SaleItem
                        {
                            Id = Guid.NewGuid(),
                            SaleId = sale.Id,
                            ProductId = p.Id,
                            Qty = qty,
                            UnitPrice = p.SellPrice,
                            LineTotal = p.SellPrice * qty
                        };
                        sale.Items.Add(item);
                        subtotal += item.LineTotal;
                    }
                    sale.Subtotal = subtotal;
                    sale.TaxTotal = subtotal * 0.16m;
                    sale.GrandTotal = subtotal + sale.TaxTotal;
                    sale.PaidTotal = sale.GrandTotal;

                    db.Sales.Add(sale);
                    db.Payments.Add(new Payment {
                        TenantId = existingTenant.Id,
                        SaleId = sale.Id,
                        Amount = sale.GrandTotal,
                        Method = rnd.Next(2) == 0 ? "cash" : "card",
                        Status = "completed",
                        CreatedAt = saleDate
                    });
                }
                await db.SaveChangesAsync();
            }
        }

        // Self-healing (Development/Test only, unreachable when seedDemoData=false):
        // make sure the DEMO admin has a valid BCrypt hash. Never rewrites a valid
        // hash; never runs in Production.
        var adminUser = await db.Users.FirstOrDefaultAsync(u => u.Email == "admin@demo.com");
        if (adminUser != null)
        {
            if (string.IsNullOrEmpty(adminUser.PasswordHash) || !adminUser.PasswordHash.StartsWith("$2"))
            {
                adminUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123");
                await db.SaveChangesAsync();
            }
        }
    }
}
