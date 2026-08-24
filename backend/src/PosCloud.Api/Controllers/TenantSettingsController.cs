using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/tenant-settings")]
public class TenantSettingsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] Guid tenantId)
    {
        var s = await db.TenantSettings.FindAsync(tenantId);
        return Ok(new { data = s });
    }

    [HttpPatch]
    [Authorize]
    public async Task<IActionResult> Patch([FromQuery] Guid tenantId, [FromBody] TenantSettings dto)
    {
        var s = await db.TenantSettings.FindAsync(tenantId);
        if (s == null) { dto.TenantId = tenantId; db.TenantSettings.Add(dto); }
        else
        {
            s.BusinessName = dto.BusinessName ?? s.BusinessName;
            s.LogoUrl = dto.LogoUrl ?? s.LogoUrl;
            s.PrimaryColor = dto.PrimaryColor ?? s.PrimaryColor;
            s.SecondaryColor = dto.SecondaryColor ?? s.SecondaryColor;
            s.Language = dto.Language ?? s.Language;
            s.Currency = dto.Currency ?? s.Currency;
            s.ReceiptTemplateJson = dto.ReceiptTemplateJson ?? s.ReceiptTemplateJson;
            s.UpdatedAt = DateTime.UtcNow;
        }
        await db.SaveChangesAsync();
        return Ok(new { data = await db.TenantSettings.FindAsync(tenantId) });
    }
}
