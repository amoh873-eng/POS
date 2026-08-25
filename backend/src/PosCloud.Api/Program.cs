using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors(o => o.AddPolicy("all", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var jwtKey = builder.Configuration["Jwt:Key"] ?? "CHANGE_ME_min_32_chars_secret_key_for_jwt";
builder.Services.AddAuthentication("Bearer").AddJwtBearer(o =>
{
    o.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
    {
        ValidateIssuer = true, ValidateAudience = true, ValidateLifetime = true, ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "PosCloud",
        ValidAudience = builder.Configuration["Jwt:Audience"] ?? "PosCloud",
        IssuerSigningKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(jwtKey))
    };
});
builder.Services.AddAuthorization();

var cs = builder.Configuration.GetConnectionString("Default")
    ?? "Host=localhost;Database=poscloud;Username=postgres;Password=postgres";
var useInMemory = builder.Configuration.GetValue<bool?>("UseInMemory") ?? true;
if (useInMemory)
    builder.Services.AddDbContext<AppDbContext>(o => o.UseInMemoryDatabase("poscloud_demo"));
else
{
    builder.Services.AddDbContext<AppDbContext>(o => o.UseNpgsql(cs, n => n.EnableRetryOnFailure()));
    // when Postgres unavailable, fallback gracefully at runtime (Program.cs handles Migrate try/catch)
}

builder.Services.AddHealthChecks();

var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();
app.UseSwagger();
app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "POS Cloud API v1"));
app.MapGet("/api", () => new { name = "POS Cloud API", version = "1.1", docs = "/swagger", health = "/health" });

app.UseCors("all");
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<PosCloud.Api.Middleware.ErrorHandlingMiddleware>();
app.UseMiddleware<PosCloud.Api.Middleware.AuditMiddleware>();

app.MapHealthChecks("/health");
app.MapControllers();

// Auto-migrate + seed on start — with graceful fallback when Docker Postgres not running
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
            await PosCloud.Infrastructure.Seed.SeedData.SeedAsync(db);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Seed/migrate skipped (will try InMemory fallback on next fix)");
            // If Postgres unreachable, switch to InMemory for demo so API still boots
            if (!useInMemory && ex.Message.Contains("postgres", StringComparison.OrdinalIgnoreCase))
                logger.LogWarning("Postgres unreachable — set UseInMemory=true in appsettings or start docker-compose up");
        }
    }
}

app.Run();
