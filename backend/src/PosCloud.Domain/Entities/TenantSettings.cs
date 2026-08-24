namespace PosCloud.Domain.Entities;

public class TenantSettings
{
    public Guid TenantId { get; set; }
    public string? LogoUrl { get; set; }
    public string BusinessName { get; set; } = null!;
    public string PrimaryColor { get; set; } = "#6D5BD0";
    public string SecondaryColor { get; set; } = "#6B7280";
    public string Language { get; set; } = "ar";
    public string Currency { get; set; } = "JOD";
    public string? ReceiptTemplateJson { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
