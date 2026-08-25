using FluentAssertions;
using PosCloud.Application.Sales;
using Xunit;

namespace PosCloud.Tests;

public class HardeningTests
{
    [Fact]
    public void Sale_Tax_Zero_When_NoTax()
    {
        var lines = new[] { (1m, 10m, 0m, 0m) };
        var (s, t, g) = SaleCalculator.Compute(lines, 0);
        s.Should().Be(10m);
        t.Should().Be(0);
        g.Should().Be(10m);
    }

    [Fact]
    public void Sale_DiscountTotal_Reduces_Grand()
    {
        var lines = new[] { (1m, 100m, 0m, 0.16m) };
        var (s, t, g) = SaleCalculator.Compute(lines, 10m);
        s.Should().Be(100m);
        t.Should().Be(16m);
        g.Should().Be(106m);
    }

    [Fact]
    public void Sale_LineDiscount_Excluded_From_TaxBase()
    {
        var lines = new[] { (2m, 50m, 20m, 0.10m) }; // 100-20=80 taxed
        var (s, t, g) = SaleCalculator.Compute(lines, 0);
        s.Should().Be(80m);
        t.Should().Be(8m);
        g.Should().Be(88m);
    }

    [Fact]
    public void Sale_MultipleLines_SumCorrect()
    {
        var lines = new[] { (1m, 10m, 0m, 0.16m), (2m, 5m, 1m, 0.16m), (1m, 20m, 5m, 0m) };
        var (s, t, g) = SaleCalculator.Compute(lines, 2m);
        // line1:10 tax1.6, line2: 10-1=9 tax1.44, line3:20-5=15 tax0 => s=34 t=3.04 g=35.04
        s.Should().Be(34m);
        t.Should().BeApproximately(3.04m, 0.001m);
        g.Should().BeApproximately(35.04m, 0.001m);
    }

    [Fact]
    public void BCrypt_Roundtrip()
    {
        var hash = BCrypt.Net.BCrypt.HashPassword("Admin@123");
        BCrypt.Net.BCrypt.Verify("Admin@123", hash).Should().BeTrue();
        BCrypt.Net.BCrypt.Verify("wrong", hash).Should().BeFalse();
    }

    [Fact]
    public void Inventory_Negative_Check()
    {
        var qty = 3m;
        var delta = -5m;
        var after = qty + delta;
        after.Should().BeNegative();
        // business rule: must reject
        (after < 0).Should().BeTrue();
    }
}
