using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Middleware;

public class AuditMiddleware(RequestDelegate next)
{
    public async Task Invoke(HttpContext ctx, AppDbContext db)
    {
        await next(ctx);
        // Simple audit for mutating verbs — skip secrets
        if (ctx.Request.Method is "POST" or "PUT" or "PATCH" or "DELETE" && ctx.Response.StatusCode < 400)
        {
            var tid = ctx.User.FindFirst("tid")?.Value;
            if (Guid.TryParse(tid, out var tenantId))
            {
                var uid = ctx.User.FindFirst("uid")?.Value;
                Guid.TryParse(uid, out var userId);
                db.AuditLogs.Add(new AuditLog
                {
                    TenantId = tenantId,
                    UserId = userId == Guid.Empty ? null : userId,
                    Action = $"{ctx.Request.Method} {ctx.Request.Path}",
                    EntityType = "http",
                    EntityId = ctx.TraceIdentifier,
                    Ip = ctx.Connection.RemoteIpAddress?.ToString()
                });
                try { await db.SaveChangesAsync(); } catch { /* audit best-effort */ }
            }
        }
    }
}
