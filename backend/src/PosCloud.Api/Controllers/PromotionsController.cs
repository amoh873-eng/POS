using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PosCloud.Domain.Entities;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/promotions")]
public class PromotionsController : ControllerBase
{
    private static readonly List<Promotion> Store = new();
    [HttpGet]
    public IActionResult List([FromQuery] Guid tenantId) => Ok(new { data = Store.Where(p => p.TenantId == tenantId).ToList() });
    [HttpPost]
    public IActionResult Create([FromBody] Promotion dto) { Store.Add(dto); return Created($"/api/promotions/{dto.Id}", new { data = dto }); }
    [HttpGet("active")]
    public IActionResult Active([FromQuery] Guid tenantId) {
        var now = DateTime.UtcNow;
        return Ok(new { data = Store.Where(p => p.TenantId == tenantId && p.IsActive && p.From <= now && p.To >= now).ToList() });
    }
}
