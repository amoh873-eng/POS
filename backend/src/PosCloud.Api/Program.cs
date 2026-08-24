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
// Fallback to InMemory when Postgres is unavailable (demo/dev) — override with real CS or set UseInMemory=false
var useInMemory = builder.Configuration.GetValue<bool?>("UseInMemory") ?? true;
if (useInMemory)
    builder.Services.AddDbContext<AppDbContext>(o => o.UseInMemoryDatabase("poscloud_demo"));
else
    builder.Services.AddDbContext<AppDbContext>(o => o.UseNpgsql(cs));

builder.Services.AddHealthChecks();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("all");
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<PosCloud.Api.Middleware.ErrorHandlingMiddleware>();
app.UseMiddleware<PosCloud.Api.Middleware.AuditMiddleware>();

app.MapHealthChecks("/health");
app.MapControllers();

// Auto-migrate + seed on start (dev only — remove for prod)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try
    {
        // db.Database.Migrate(); // enable after first migration is created
        await PosCloud.Infrastructure.Seed.SeedData.SeedAsync(db);
    }
    catch (Exception ex)
    {
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        logger.LogWarning(ex, "Seed/migrate skipped");
    }
}

app.Run();
