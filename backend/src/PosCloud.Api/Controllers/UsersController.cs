using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId)
        => Ok(new { data = await db.Users.Where(u => u.TenantId == tenantId).ToListAsync() });

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] User dto)
    {
        dto.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.PasswordHash);
        db.Users.Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/users/{dto.Id}", new { data = dto });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var u = await db.Users.FindAsync(id);
        return u == null ? NotFound() : Ok(new { data = u });
    }
}

[ApiController]
[Route("api/roles")]
public class RolesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId)
        => Ok(new { data = await db.Roles.Where(r => r.TenantId == tenantId).ToListAsync() });
}
