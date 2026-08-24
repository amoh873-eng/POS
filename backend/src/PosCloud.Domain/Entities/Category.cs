using PosCloud.Domain.Common;

namespace PosCloud.Domain.Entities;

public class Category : BaseEntity
{
    public string NameAr { get; set; } = null!;
    public string NameEn { get; set; } = null!;
    public Guid? ParentId { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
    public Guid? BranchId { get; set; }
}
