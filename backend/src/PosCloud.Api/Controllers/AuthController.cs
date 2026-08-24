using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(AppDbContext db, IConfiguration cfg) : ControllerBase
{
    public record LoginReq(string Email, string Password, string? TenantSlug);
    public record RefreshReq(string RefreshToken);

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginReq req)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == req.Email && u.IsActive);
        if (user == null) return Unauthorized(new { error = new { code = "UNAUTHORIZED", message = "Invalid credentials" } });
        if (user.LockedUntil != null && user.LockedUntil > DateTime.UtcNow)
            return Unauthorized(new { error = new { code = "LOCKED", message = "Account locked" } });
        if (!Verify(req.Password, user.PasswordHash))
        {
            user.FailedAttempts++;
            if (user.FailedAttempts >= 5) user.LockedUntil = DateTime.UtcNow.AddMinutes(15);
            await db.SaveChangesAsync();
            return Unauthorized(new { error = new { code = "UNAUTHORIZED", message = "Invalid credentials" } });
        }
        user.FailedAttempts = 0;
        var (access, refresh) = await IssueTokens(user);
        await db.SaveChangesAsync();
        return Ok(new { data = new { access_token = access, refresh_token = refresh, user = new { user.Id, user.Email, user.DisplayName } } });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshReq req)
    {
        var hash = Hash(req.RefreshToken);
        var rt = await db.RefreshTokens.FirstOrDefaultAsync(x => x.TokenHash == hash && x.RevokedAt == null);
        if (rt == null || rt.ExpiresAt < DateTime.UtcNow) return Unauthorized(new { error = new { code = "UNAUTHORIZED", message = "Invalid refresh token" } });
        rt.RevokedAt = DateTime.UtcNow;
        var user = await db.Users.FindAsync(rt.UserId);
        if (user == null) return Unauthorized();
        var (access, refresh) = await IssueTokens(user);
        await db.SaveChangesAsync();
        return Ok(new { data = new { access_token = access, refresh_token = refresh } });
    }

    private async Task<(string access, string refresh)> IssueTokens(User user)
    {
        var key = cfg["Jwt:Key"] ?? "CHANGE_ME_min_32_chars_secret_key_for_jwt";
        var creds = new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)), SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: cfg["Jwt:Issuer"] ?? "PosCloud",
            audience: cfg["Jwt:Audience"] ?? "PosCloud",
            claims: new[] { new Claim("uid", user.Id.ToString()), new Claim("tid", user.TenantId.ToString()), new Claim(ClaimTypes.Email, user.Email) },
            expires: DateTime.UtcNow.AddMinutes(int.Parse(cfg["Jwt:AccessTokenMinutes"] ?? "15")),
            signingCredentials: creds);
        var access = new JwtSecurityTokenHandler().WriteToken(token);
        var refreshRaw = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var hash = Hash(refreshRaw);
        db.RefreshTokens.Add(new RefreshToken { UserId = user.Id, TokenHash = hash, ExpiresAt = DateTime.UtcNow.AddDays(int.Parse(cfg["Jwt:RefreshTokenDays"] ?? "7")), CreatedByIp = HttpContext.Connection.RemoteIpAddress?.ToString() });
        return (access, refreshRaw);
    }

    private static string Hash(string s) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(s)));
    private static bool Verify(string password, string hash) => BCrypt.Net.BCrypt.Verify(password, hash);
}
