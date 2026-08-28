using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo { Title = "POS Cloud API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Paste JWT access_token"
    });
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        { new Microsoft.OpenApi.Models.OpenApiSecurityScheme { Reference = new Microsoft.OpenApi.Models.OpenApiReference { Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme, Id = "Bearer" } }, Array.Empty<string>() }
    });
});
// CORS — per-env: never AllowAnyOrigin in Production. Values from Cors:AllowedOrigins array.
var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
var isDevelopment = builder.Environment.IsDevelopment();
if (isDevelopment && corsOrigins.Length == 0)
    corsOrigins = new[] { "http://localhost:5000", "http://localhost:5173", "http://localhost:3000", "http://127.0.0.1:5000" };
builder.Services.AddCors(o =>
{
    o.AddPolicy("app", p =>
    {
        if (corsOrigins.Length == 0)
            p.WithOrigins(corsOrigins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
        else
            p.WithOrigins(corsOrigins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
        // Note: when corsOrigins is empty, no origin is allowed — intentional in Production until configured.
    });
    // keep legacy "all" for backward compat but deprecated — logs warning in Production
    o.AddPolicy("all", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

// JWT — fail-fast in Production if missing or placeholder; Development allows dev key.
var jwtKey = builder.Configuration["Jwt:Key"];
var isProd = builder.Environment.IsProduction();
if (string.IsNullOrWhiteSpace(jwtKey) || jwtKey.Contains("CHANGE_ME") || jwtKey.Contains("__REQUIRED"))
{
    if (isProd)
        throw new InvalidOperationException("Jwt:Key is missing or placeholder in Production. Set env var Jwt__Key (>=32 random chars).");
    jwtKey = "DEV_ONLY_NOT_FOR_PRODUCTION_32+_CHANGE_ME_LOCAL_DEV_KEY_1234567890";
}
if (jwtKey.Length < 32)
    throw new InvalidOperationException("Jwt:Key must be >=32 characters.");
builder.Services.AddAuthentication("Bearer").AddJwtBearer(o =>
{
    o.MapInboundClaims = false;
    o.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
    {
        ValidateIssuer = true, ValidateAudience = true, ValidateLifetime = true, ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "PosCloud",
        ValidAudience = builder.Configuration["Jwt:Audience"] ?? "PosCloud",
        IssuerSigningKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(jwtKey)),
        NameClaimType = "uid",
        RoleClaimType = "role",
        ClockSkew = TimeSpan.FromMinutes(1)
    };
    o.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
    {
        OnAuthenticationFailed = ctx =>
        {
            // Kept minimal to avoid log noise in prod — Development only
            if (builder.Environment.IsDevelopment())
                Console.WriteLine($"[JWT FAIL] {ctx.Exception.GetType().Name}: {ctx.Exception.Message}");
            return Task.CompletedTask;
        }
    };
});
builder.Services.AddAuthorization();

// Rate limiting — per-IP for auth endpoints (P1-022 remediation, harmless to add now)
builder.Services.AddRateLimiter(o =>
{
    o.AddPolicy("auth-ip", ctx => System.Threading.RateLimiting.RateLimitPartition.GetFixedWindowLimiter(
        partitionKey: ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        factory: _ => new System.Threading.RateLimiting.FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});

var cs = builder.Configuration.GetConnectionString("Default");
if (string.IsNullOrWhiteSpace(cs) || cs.Contains("__REQUIRED"))
{
    if (isProd)
        throw new InvalidOperationException("ConnectionStrings:Default is missing in Production. Set env var ConnectionStrings__Default.");
    cs = "Host=localhost;Database=poscloud;Username=postgres;Password=postgres";
}
var useInMemory = builder.Configuration.GetValue<bool?>("UseInMemory") ?? true;
if (isProd && useInMemory)
    throw new InvalidOperationException("UseInMemory=true is not allowed in Production.");
if (useInMemory)
    builder.Services.AddDbContext<AppDbContext>(o => o.UseInMemoryDatabase("poscloud_demo"));
else
{
    builder.Services.AddDbContext<AppDbContext>(o => o.UseNpgsql(cs, n => n.EnableRetryOnFailure()));
}

builder.Services.AddHealthChecks();

var app = builder.Build();

// Middleware ordering: correlation + error outermost, then forwarded headers, then rest
app.UseMiddleware<PosCloud.Api.Middleware.CorrelationIdMiddleware>();
app.UseMiddleware<PosCloud.Api.Middleware.ErrorHandlingMiddleware>();
if (!isDevelopment)
{
    app.UseHsts();
    app.UseHttpsRedirection();
}
var forwarded = new Microsoft.AspNetCore.Builder.ForwardedHeadersOptions
{
    ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedFor | Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto
};
forwarded.KnownNetworks.Clear();
forwarded.KnownProxies.Clear();
app.UseForwardedHeaders(forwarded);

app.UseDefaultFiles();
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        // CORS for images served via /uploads — allow any origin for product images (safe for LAN)
        if (ctx.Context.Request.Path.StartsWithSegments("/uploads"))
        {
            ctx.Context.Response.Headers["Access-Control-Allow-Origin"] = "*";
            ctx.Context.Response.Headers["Access-Control-Allow-Methods"] = "GET, OPTIONS";
        }
        // Cache product images for 7 days on client
        if (ctx.Context.Request.Path.StartsWithSegments("/uploads/products"))
            ctx.Context.Response.Headers["Cache-Control"] = "public,max-age=604800";
    }
});
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "POS Cloud API v1"));
}
app.MapGet("/api", () => new { name = "POS Cloud API", version = "1.1", docs = "/swagger", health = "/health" }).AllowAnonymous();

app.UseCors("app");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.UseMiddleware<PosCloud.Api.Middleware.AuditMiddleware>();

app.MapHealthChecks("/health").AllowAnonymous();
app.MapControllers();

// Auto-migrate + seed on start — P1-4: demo seed guarded by IsDevelopment/SeedDemoData
using (var scope = app.Services.CreateScope())
{
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    AppDbContext? db = null;
    try { db = scope.ServiceProvider.GetRequiredService<AppDbContext>(); } catch (Exception ex) { logger.LogWarning(ex, "DbContext resolve failed"); }
    if (db != null)
    {
        try
        {
            if (!useInMemory) db.Database.Migrate();
            var seedDemo = builder.Configuration.GetValue<bool?>("SeedDemoData") ?? app.Environment.IsDevelopment();
            await PosCloud.Infrastructure.Seed.SeedData.SeedAsync(db, seedDemo);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Seed/migrate skipped");
            if (!useInMemory && ex.Message.Contains("postgres", StringComparison.OrdinalIgnoreCase))
                logger.LogWarning("Postgres unreachable — set UseInMemory=true in appsettings.Development.json or start docker-compose up");
        }
    }
}

app.Run();

// Expose Program for WebApplicationFactory (ApiTests) — top-level statements need explicit partial class
public partial class Program { }
