using FluentAssertions;
using Xunit;

namespace PosCloud.Tests;

public class AuthTests
{
    [Theory]
    [InlineData("Admin@123", true)]
    [InlineData("wrong", false)]
    public void Hash_Verify_Works(string pwd, bool isAdmin)
    {
        var hash = BCrypt.Net.BCrypt.HashPassword("Admin@123");
        BCrypt.Net.BCrypt.Verify(pwd, hash).Should().Be(isAdmin);
    }
}
