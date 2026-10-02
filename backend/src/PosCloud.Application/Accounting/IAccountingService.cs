using PosCloud.Domain.Entities;

namespace PosCloud.Application.Accounting;

public interface IAccountingService
{
    Task AutoPostSaleAsync(Sale sale);
    Task AutoPostPurchaseAsync(Purchase purchase);
}
