using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Domain.Entities;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/terminals")]
public class TerminalsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid tenantId, [FromQuery] Guid? branchId)
    {
        var q = db.Set<Terminal>().Where(t => t.TenantId == tenantId);
        if (branchId != null) q = q.Where(t => t.BranchId == branchId);
        return Ok(new { data = await q.ToListAsync() });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Terminal dto)
    {
        db.Set<Terminal>().Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/terminals/{dto.Id}", new { data = dto });
    }
}

[ApiController]
[Authorize]
[Route("api/shifts")]
public class ShiftsController(AppDbContext db) : ControllerBase
{
    [HttpPost("open")]
    public async Task<IActionResult> Open([FromBody] Shift dto)
    {
        dto.Status = "open";
        dto.OpenedAt = DateTime.UtcNow;
        db.Set<Shift>().Add(dto);
        await db.SaveChangesAsync();
        return Created($"/api/shifts/{dto.Id}", new { data = dto });
    }

    [HttpPost("{id}/close")]
    public async Task<IActionResult> Close(Guid id, [FromBody] CloseShiftReq req)
    {
        var s = await db.Set<Shift>().FindAsync(id);
        if (s == null) return NotFound();
        s.Status = "closed";
        s.ClosedAt = DateTime.UtcNow;
        s.ClosingCash = req.ClosingCash;
        await db.SaveChangesAsync();
        return Ok(new { data = s });
    }

    public record CloseShiftReq(decimal ClosingCash);
}
