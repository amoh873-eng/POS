using PosCloud.Domain.Entities;

namespace PosCloud.Application.Sales;

public static class SaleCalculator
{
    public static (decimal subtotal, decimal taxTotal, decimal grandTotal) Compute(
        IEnumerable<(decimal qty, decimal unitPrice, decimal discount, decimal taxRate)> lines,
        decimal discountTotal)
    {
        decimal subtotal = 0, taxTotal = 0;
        foreach (var l in lines)
        {
            var lineNet = l.qty * l.unitPrice - l.discount;
            subtotal += lineNet;
            taxTotal += lineNet * l.taxRate;
        }
        var grandTotal = subtotal + taxTotal - discountTotal;
        return (subtotal, taxTotal, grandTotal);
    }
}
