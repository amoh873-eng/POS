using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PosCloud.Infrastructure.Data;

namespace PosCloud.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/sales/{id}/receipt")]
public class ReceiptController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(Guid id)
    {
        var sale = await db.Sales
            .Include(s => s.Items)
            .Include(s => s.Payments)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (sale == null) return NotFound();

        var tenant = await db.TenantSettings.FindAsync(sale.TenantId);
        var customer = sale.CustomerId.HasValue
            ? await db.Customers.FindAsync(sale.CustomerId.Value)
            : null;

        return Ok(new {
            data = new {
                sale,
                tenant = new {
                    tenant?.BusinessName,
                    tenant?.LogoUrl,
                    tenant?.PrimaryColor,
                    sale.ReceiptNo
                },
                customer = customer != null ? new {
                    customer.Name,
                    customer.TaxId,
                    customer.NationalId,
                    customer.Address
                } : null
            }
        });
    }
}
