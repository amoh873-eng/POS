using FluentAssertions;
using PosCloud.Application.Sales;
using Xunit;

namespace PosCloud.Tests;

public class SaleCalculatorTests
{
    [Fact]
    public void Compute_Totals_Correct()
    {
        var lines = new[] { (1m, 100m, 0m, 0.15m), (2m, 50m, 10m, 0.15m) };
        var (subtotal, tax, grand) = SaleCalculator.Compute(lines, 5m);
        subtotal.Should().Be(190m); // 100 + 90
        tax.Should().Be(28.5m); // 15 + 13.5
        grand.Should().Be(213.5m);
    }
}
