using System.Net;
using System.Text.Json;

namespace PosCloud.Api.Middleware;

public class ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger, IWebHostEnvironment env)
{
    public async Task Invoke(HttpContext ctx)
    {
        try { await next(ctx); }
        catch (UnauthorizedAccessException ex)
        {
            ctx.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
            ctx.Response.ContentType = "application/json";
            var payload = new { error = new { code = "UNAUTHORIZED", message = ex.Message, traceId = ctx.TraceIdentifier } };
            await ctx.Response.WriteAsync(JsonSerializer.Serialize(payload));
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled {TraceId} {Path}", ctx.TraceIdentifier, ctx.Request.Path);
            ctx.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            ctx.Response.ContentType = "application/json";
            var message = env.IsDevelopment() ? ex.Message : "An unexpected error occurred.";
            var payload = new { error = new { code = "INTERNAL_ERROR", message, traceId = ctx.TraceIdentifier } };
            await ctx.Response.WriteAsync(JsonSerializer.Serialize(payload));
        }
    }
}
