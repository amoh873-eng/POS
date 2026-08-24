using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Route("api/reports")]
public class ReportsController(AppDbContext db) : ControllerBase
{
    [HttpGet("daily-sales")]
    public async Task<IActionResult> DailySales([FromQuery] Guid tenantId, [FromQuery] DateTime? date, [FromQuery] Guid? branchId)
    {
        var d = (date ?? DateTime.UtcNow).Date;
        var q = db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt.Date == d && s.Status == "completed");
        if (branchId != null) q = q.Where(s => s.BranchId == branchId);
        var total = await q.SumAsync(s => s.GrandTotal);
        var count = await q.CountAsync();
        return Ok(new { data = new { date = d, total, count } });
    }

    [HttpGet("sales")]
    public async Task<IActionResult> Sales([FromQuery] Guid tenantId, [FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        var q = db.Sales.Where(s => s.TenantId == tenantId && s.CreatedAt >= from && s.CreatedAt <= to);
        var total = await q.SumAsync(s => s.GrandTotal);
        return Ok(new { data = new { from, to, total, count = await q.CountAsync() } });
    }
}
