using Microsoft.AspNetCore.Mvc;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => Ok(new { status = "ok", version = "1.1", phase = "PHASE-00" });
}
