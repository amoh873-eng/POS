using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Middleware;

public class AuditMiddleware(RequestDelegate next)
{
    // Never log: password, refresh_token, Authorization header, Jwt:Key — only Method+Path+Ip+TraceId
    public async Task Invoke(HttpContext ctx, AppDbContext db)
    {
        await next(ctx);
        if (ctx.Request.Method is "POST" or "PUT" or "PATCH" or "DELETE" && ctx.Response.StatusCode < 400)
        {
            var tid = ctx.User.FindFirst("tid")?.Value;
            if (Guid.TryParse(tid, out var tenantId))
            {
                var uid = ctx.User.FindFirst("uid")?.Value;
                Guid.TryParse(uid, out var userId);
                var cid = ctx.Items["CorrelationId"] as string ?? ctx.TraceIdentifier;
                db.AuditLogs.Add(new AuditLog
                {
                    TenantId = tenantId,
                    UserId = userId == Guid.Empty ? null : userId,
                    Action = $"{ctx.Request.Method} {ctx.Request.Path}",
                    EntityType = "http",
                    EntityId = cid,
                    Ip = ctx.Connection.RemoteIpAddress?.ToString()
                });
                try { await db.SaveChangesAsync(); } catch { /* audit best-effort */ }
            }
        }
    }
}
