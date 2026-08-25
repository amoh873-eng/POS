using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/sync")]
public class SyncController(AppDbContext db) : ControllerBase
{
    public record PushItem(string ClientId, string Type, string PayloadJson);
    public record PushReq(List<PushItem> Items);

    [HttpPost("push")]
    public async Task<IActionResult> Push([FromBody] PushReq req)
    {
        // v1: idempotent by ClientId stored in Sale.IdempotencyKey — just acknowledge
        // Full impl would upsert by client_id; here we return mapped ids if already exist
        var results = new List<object>();
        foreach (var item in req.Items)
        {
            var existing = item.Type == "sale" ? await db.Sales.FirstOrDefaultAsync(s => s.IdempotencyKey == item.ClientId) : null;
            results.Add(new { client_id = item.ClientId, server_id = existing?.Id, status = existing != null ? "synced" : "pending" });
        }
        return Ok(new { data = results });
    }

    private Guid ResolveTid(Guid tid)
    {
        if (tid != Guid.Empty) return tid;
        var claim = User.FindFirst("tid")?.Value;
        if (Guid.TryParse(claim, out var ct)) return ct;
        return db.Tenants.Select(t => t.Id).FirstOrDefault();
    }
    [HttpGet("pull")]
    public async Task<IActionResult> Pull([FromQuery] Guid tenantId, [FromQuery] DateTime? since)
    {
        tenantId = ResolveTid(tenantId);
        var s = since ?? DateTime.UtcNow.AddDays(-7);
        var products = await db.Products.Where(p => p.TenantId == tenantId && p.UpdatedAt >= s).ToListAsync();
        var customers = await db.Customers.Where(c => c.TenantId == tenantId).ToListAsync(); // add UpdatedAt to customer later
        var settings = await db.TenantSettings.FindAsync(tenantId);
        return Ok(new { data = new { products, customers, settings, since = s } });
    }
}
