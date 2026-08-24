using PosCloud.Domain.Common;

namespace PosCloud.Domain.Entities;

public class Branch : BaseEntity
{
    public string Name { get; set; } = null!;
    public string Code { get; set; } = null!;
    public string? Address { get; set; }
    public bool IsActive { get; set; } = true;
}
