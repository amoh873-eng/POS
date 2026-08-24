using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;

namespace PosCloud.Infrastructure.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Tenant> Tenants => Set<Tenant>();
    public DbSet<TenantSettings> TenantSettings => Set<TenantSettings>();
    public DbSet<Branch> Branches => Set<Branch>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductBarcode> ProductBarcodes => Set<ProductBarcode>();
    public DbSet<InventoryStock> InventoryStocks => Set<InventoryStock>();
    public DbSet<InventoryMovement> InventoryMovements => Set<InventoryMovement>();
    public DbSet<StockCount> StockCounts => Set<StockCount>();
    public DbSet<StockCountLine> StockCountLines => Set<StockCountLine>();
    public DbSet<Sale> Sales => Set<Sale>();
    public DbSet<SaleItem> SaleItems => Set<SaleItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Supplier> Suppliers => Set<Supplier>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<Tenant>(e =>
        {
            e.ToTable("tenants");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.Slug).IsUnique();
            e.Property(x => x.Name).IsRequired();
        });
        b.Entity<Branch>(e =>
        {
            e.ToTable("branches");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.TenantId, x.Code }).IsUnique();
            e.HasIndex(x => new { x.TenantId, x.IsActive });
        });
        b.Entity<AuditLog>(e =>
        {
            e.ToTable("audit_logs");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.TenantId, x.CreatedAt });
        });
        b.Entity<TenantSettings>(e => { e.ToTable("tenant_settings"); e.HasKey(x => x.TenantId); });
        b.Entity<User>(e => { e.ToTable("users"); e.HasKey(x => x.Id); e.HasIndex(x => new { x.TenantId, x.Email }).IsUnique(); });
        b.Entity<Role>(e => { e.ToTable("roles"); e.HasKey(x => x.Id); });
        b.Entity<RefreshToken>(e => { e.ToTable("refresh_tokens"); e.HasKey(x => x.Id); e.HasIndex(x => x.TokenHash).IsUnique(); });
        b.Entity<Category>(e => { e.ToTable("categories"); e.HasKey(x => x.Id); e.HasIndex(x => new { x.TenantId, x.BranchId }); });
        b.Entity<Product>(e => { e.ToTable("products"); e.HasKey(x => x.Id); e.HasIndex(x => new { x.TenantId, x.Sku }).IsUnique(); e.HasIndex(x => x.BarcodeMain); });
        b.Entity<ProductBarcode>(e => { e.ToTable("product_barcodes"); e.HasKey(x => x.Id); e.HasIndex(x => x.Barcode).IsUnique(); });
        b.Entity<InventoryStock>(e => { e.ToTable("inventory_stocks"); e.HasKey(x => x.Id); e.HasIndex(x => new { x.TenantId, x.BranchId, x.ProductId }).IsUnique(); });
        b.Entity<InventoryMovement>(e => { e.ToTable("inventory_movements"); e.HasKey(x => x.Id); e.HasIndex(x => new { x.TenantId, x.BranchId, x.ProductId, x.CreatedAt }); });
        b.Entity<StockCount>(e => { e.ToTable("stock_counts"); e.HasKey(x => x.Id); });
        b.Entity<StockCountLine>(e => { e.ToTable("stock_count_lines"); e.HasKey(x => x.Id); });
        b.Entity<Sale>(e => { e.ToTable("sales"); e.HasKey(x => x.Id); e.HasIndex(x => x.ReceiptNo).IsUnique(); e.HasIndex(x => new { x.TenantId, x.BranchId, x.CreatedAt }); e.HasMany(x => x.Items).WithOne().HasForeignKey(x => x.SaleId); e.HasMany(x => x.Payments).WithOne().HasForeignKey(x => x.SaleId); });
        b.Entity<SaleItem>(e => { e.ToTable("sale_items"); e.HasKey(x => x.Id); });
        b.Entity<Payment>(e => { e.ToTable("payments"); e.HasKey(x => x.Id); });
        b.Entity<Customer>(e => { e.ToTable("customers"); e.HasKey(x => x.Id); e.HasIndex(x => new { x.TenantId, x.Phone }); });
        b.Entity<Supplier>(e => { e.ToTable("suppliers"); e.HasKey(x => x.Id); });
    }
}
