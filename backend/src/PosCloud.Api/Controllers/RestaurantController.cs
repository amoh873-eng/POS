using Microsoft.AspNetCore.Mvc;
using PosCloud.Domain.Entities;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/restaurant")]
public class RestaurantController : ControllerBase
{
    private static readonly List<RestaurantTable> Tables = new();
    [HttpGet("tables")]
    public IActionResult List([FromQuery] Guid tenantId) => Ok(new { data = Tables.Where(t => t.TenantId == tenantId).ToList() });
    [HttpPost("tables")]
    public IActionResult Create([FromBody] RestaurantTable dto) { Tables.Add(dto); return Created($"/api/restaurant/tables/{dto.Id}", new { data = dto }); }
    [HttpPost("tables/{id}/occupy")]
    public IActionResult Occupy(Guid id, [FromQuery] Guid saleId) { var t = Tables.FirstOrDefault(x => x.Id == id); if (t == null) return NotFound(); t.Status = "occupied"; t.CurrentSaleId = saleId; return Ok(new { data = t }); }
}
