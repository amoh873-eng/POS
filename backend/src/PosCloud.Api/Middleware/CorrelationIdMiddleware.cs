namespace PosCloud.Api.Middleware;

public class CorrelationIdMiddleware(RequestDelegate next)
{
    public async Task Invoke(HttpContext ctx)
    {
        var cid = ctx.Request.Headers["X-Correlation-ID"].FirstOrDefault() ?? ctx.TraceIdentifier;
        ctx.Response.Headers["X-Correlation-ID"] = cid;
        ctx.Items["CorrelationId"] = cid;
        await next(ctx);
    }
}
