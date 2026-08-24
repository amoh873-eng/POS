using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Infrastructure.Seed;

public static class SeedData
{
    public static async Task SeedAsync(AppDbContext db)
    {
        if (!await db.Tenants.AnyAsync())
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
            var admin = new User { TenantId = tenant.Id, Email = "admin@demo.com", DisplayName = "Admin", PasswordHash = "$2a$11$dummyHashForSeedPlaceholder/admin123" };
            db.Users.Add(admin);
            await db.SaveChangesAsync();
        }
    }
}
