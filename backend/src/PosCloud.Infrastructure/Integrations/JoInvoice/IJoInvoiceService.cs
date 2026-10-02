using PosCloud.Domain.Entities;

namespace PosCloud.Infrastructure.Integrations.JoInvoice;

public interface IJoInvoiceService
{
    Task<JoInvoiceResult> SubmitSaleAsync(Sale sale, TenantSettings settings);
}

public record JoInvoiceResult(bool Success, string? Uuid, string? QrCode, string? ResponseRaw);
