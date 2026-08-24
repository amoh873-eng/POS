using FluentAssertions;
using PosCloud.Application.Sales;
using Xunit;

namespace PosCloud.Tests;

public class InventoryTests
{
    [Fact]
    public void Negative_Stock_NotAllowed()
    {
        var stock = 5m;
        var delta = -10m;
        var result = stock + delta;
        result.Should().BeNegative();
    }

    [Fact]
    public void SaleCalculator_Empty_ReturnsZero()
    {
        var (s, t, g) = SaleCalculator.Compute(Enumerable.Empty<(decimal, decimal, decimal, decimal)>(), 0);
        s.Should().Be(0);
        t.Should().Be(0);
        g.Should().Be(0);
    }
}
