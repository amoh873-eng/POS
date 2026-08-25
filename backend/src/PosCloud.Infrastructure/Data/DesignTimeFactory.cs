using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace PosCloud.Infrastructure.Data;

public class DesignTimeFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var cs = Environment.GetEnvironmentVariable("ConnectionStrings__Default")
              ?? Environment.GetEnvironmentVariable("ConnectionStrings_Default")
              ?? Environment.GetEnvironmentVariable("ConnectionStrings:Default");
        if (string.IsNullOrWhiteSpace(cs))
            throw new InvalidOperationException(
                "DesignTimeFactory: No connection string found. Set environment variable 'ConnectionStrings__Default' (e.g. Host=localhost;Database=poscloud;Username=postgres;Password=...). Refusing to use hardcoded credentials.");
        var opts = new DbContextOptionsBuilder<AppDbContext>();
        opts.UseNpgsql(cs);
        return new AppDbContext(opts.Options);
    }
}
