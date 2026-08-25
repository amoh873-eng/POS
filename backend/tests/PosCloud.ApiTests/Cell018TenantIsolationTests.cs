using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PosCloud.Infrastructure.Data;
using Xunit;

namespace PosCloud.ApiTests;

public class Cell018TenantIsolationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _f;
    public Cell018TenantIsolationTests(WebApplicationFactory<Program> f)
    {
        _f = f.WithWebHostBuilder(b =>
        {
            b.UseEnvironment("Development");
            b.ConfigureServices(s =>
            {
                var rm = s.Where(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>)).ToList();
                foreach (var d in rm) s.Remove(d);
                s.AddDbContext<AppDbContext>(o => o.UseInMemoryDatabase($"c18_{Guid.NewGuid()}"));
            });
        });
    }
    static string Jwt(Guid tid, Guid uid)
    {
        var k = "DEV_ONLY_NOT_FOR_PRODUCTION_32+_CHANGE_ME_LOCAL_DEV_KEY_1234567890";
        var creds = new Microsoft.IdentityModel.Tokens.SigningCredentials(
            new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(k)),
            Microsoft.IdentityModel.Tokens.SecurityAlgorithms.HmacSha256);
        var t = new System.IdentityModel.Tokens.Jwt.JwtSecurityToken(
            issuer: "PosCloud", audience: "PosCloud",
            claims: new[] { new System.Security.Claims.Claim("uid", uid.ToString()), new System.Security.Claims.Claim("tid", tid.ToString()) },
            expires: DateTime.UtcNow.AddMinutes(15), signingCredentials: creds);
        return new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler().WriteToken(t);
    }

    [Fact]
    public async Task CrossTenant_ProductDelete_Rejected()
    {
        using var sc = _f.Services.CreateScope();
        var db = sc.ServiceProvider.GetRequiredService<AppDbContext>();
        if (!await db.Tenants.AnyAsync()) return;
        var tidA = await db.Tenants.Select(x => x.Id).FirstAsync();
        var prodA = await db.Products.Where(p => p.TenantId == tidA).Select(p => p.Id).FirstOrDefaultAsync();
        if (prodA == Guid.Empty) return;
        var tidB = Guid.NewGuid();
        db.Tenants.Add(new PosCloud.Domain.Entities.Tenant { Id = tidB, Name = "CT", Slug = $"ct-{tidB:N}"[..12], IsActive = true });
        await db.SaveChangesAsync();
        var tok = Jwt(tidB, Guid.NewGuid());
        var cl = _f.CreateClient();
        cl.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", tok);
        var res = await cl.DeleteAsync($"/api/products/{prodA}");
        res.StatusCode.Should().Be(HttpStatusCode.NotFound);
        var still = await db.Products.FindAsync(prodA);
        still!.IsDeleted.Should().BeFalse();
    }

    [Fact]
    public async Task Inventory_Adjust_Ignores_Client_Tenant()
    {
        using var sc = _f.Services.CreateScope();
        var db = sc.ServiceProvider.GetRequiredService<AppDbContext>();
        if (!await db.Tenants.AnyAsync()) return;
        var tidA = await db.Tenants.Select(x => x.Id).FirstAsync();
        var brA = await db.Branches.Where(b => b.TenantId == tidA).Select(b => b.Id).FirstOrDefaultAsync();
        var pA = await db.Products.Where(p => p.TenantId == tidA).Select(p => p.Id).FirstOrDefaultAsync();
        if (brA == Guid.Empty || pA == Guid.Empty) return;
        var tidB = Guid.NewGuid();
        db.Tenants.Add(new PosCloud.Domain.Entities.Tenant { Id = tidB, Name = "CT2", Slug = $"ct2-{tidB:N}"[..12], IsActive = true });
        await db.SaveChangesAsync();
        var tok = Jwt(tidA, Guid.NewGuid());
        var cl = _f.CreateClient();
        cl.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", tok);
        var evil = new { tenantId = tidB, branchId = brA, productId = pA, qtyDelta = 1m, type = "adjust" };
        var res = await cl.PostAsJsonAsync("/api/inventory/adjust", evil);
        res.StatusCode.Should().Be(HttpStatusCode.OK);
        (await db.InventoryMovements.CountAsync(m => m.TenantId == tidB)).Should().Be(0);
    }

    [Fact]
    public async Task Inventory_Movement_Ignores_Client_Tenant()
    {
        using var sc = _f.Services.CreateScope();
        var db = sc.ServiceProvider.GetRequiredService<AppDbContext>();
        if (!await db.Tenants.AnyAsync()) return;
        var tidA = await db.Tenants.Select(x => x.Id).FirstAsync();
        var brA = await db.Branches.Where(b => b.TenantId == tidA).Select(b => b.Id).FirstOrDefaultAsync();
        var pA = await db.Products.Where(p => p.TenantId == tidA).Select(p => p.Id).FirstOrDefaultAsync();
        if (brA == Guid.Empty || pA == Guid.Empty) return;
        var tidB = Guid.NewGuid();
        db.Tenants.Add(new PosCloud.Domain.Entities.Tenant { Id = tidB, Name = "CT4", Slug = $"ct4-{tidB:N}"[..12], IsActive = true });
        await db.SaveChangesAsync();
        var tok = Jwt(tidA, Guid.NewGuid());
        var cl = _f.CreateClient();
        cl.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", tok);
        var evil = new { tenantId = tidB, branchId = brA, productId = pA, qtyDelta = 1m, type = "purchase" };
        var res = await cl.PostAsJsonAsync("/api/inventory/movements", evil);
        res.StatusCode.Should().Be(HttpStatusCode.OK);
        (await db.InventoryMovements.CountAsync(m => m.TenantId == tidB)).Should().Be(0);
    }

    [Fact]
    public async Task Inventory_Transfer_Ignores_Client_Tenant()
    {
        using var sc = _f.Services.CreateScope();
        var db = sc.ServiceProvider.GetRequiredService<AppDbContext>();
        if (!await db.Tenants.AnyAsync()) return;
        var tidA = await db.Tenants.Select(x => x.Id).FirstAsync();
        var branches = await db.Branches.Where(b => b.TenantId == tidA).Select(b => b.Id).ToListAsync();
        if (branches.Count == 0) return;
        var fromBr = branches[0];
        Guid toBr;
        if (branches.Count >= 2) toBr = branches[1];
        else { var nb = new PosCloud.Domain.Entities.Branch { TenantId = tidA, Name = "CT-BR2", Code = $"CT{Guid.NewGuid():N}"[..6], IsActive = true }; db.Branches.Add(nb); await db.SaveChangesAsync(); toBr = nb.Id; }
        var pA = await db.Products.Where(p => p.TenantId == tidA).Select(p => p.Id).FirstOrDefaultAsync();
        if (pA == Guid.Empty) return;
        var stock = await db.InventoryStocks.FirstOrDefaultAsync(s => s.TenantId == tidA && s.BranchId == fromBr && s.ProductId == pA);
        if (stock == null) { db.InventoryStocks.Add(new PosCloud.Domain.Entities.InventoryStock { TenantId = tidA, BranchId = fromBr, ProductId = pA, QtyOnHand = 10 }); await db.SaveChangesAsync(); }
        else if (stock.QtyOnHand < 2) { stock.QtyOnHand = 10; await db.SaveChangesAsync(); }
        var tidB = Guid.NewGuid();
        db.Tenants.Add(new PosCloud.Domain.Entities.Tenant { Id = tidB, Name = "CT3", Slug = $"ct3-{tidB:N}"[..12], IsActive = true });
        await db.SaveChangesAsync();
        var tok = Jwt(tidA, Guid.NewGuid());
        var cl = _f.CreateClient();
        cl.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", tok);
        var evil = new { tenantId = tidB, fromBranchId = fromBr, toBranchId = toBr, lines = new[] { new { productId = pA, qty = 1m } } };
        var res = await cl.PostAsJsonAsync("/api/inventory/transfer", evil);
        (res.StatusCode == HttpStatusCode.OK || res.StatusCode == HttpStatusCode.UnprocessableEntity).Should().BeTrue();
        (await db.InventoryMovements.CountAsync(m => m.TenantId == tidB)).Should().Be(0);
    }
}
