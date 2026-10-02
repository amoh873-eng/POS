using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Xml.Linq;
using PosCloud.Domain.Entities;

namespace PosCloud.Infrastructure.Integrations.JoInvoice;

public class JoInvoiceService(HttpClient httpClient) : IJoInvoiceService
{
    private const string SandboxUrl = "https://preprod.jofotara.gov.jo/api/invoices"; // Example sandbox URL
    private const string ProductionUrl = "https://portal.jofotara.gov.jo/api/invoices";

    public async Task<JoInvoiceResult> SubmitSaleAsync(Sale sale, TenantSettings settings)
    {
        try
        {
            if (!settings.JoInvoiceEnabled)
                return new JoInvoiceResult(false, null, null, "Jo-Invoice not enabled for this tenant.");

            // Fail-safe: never call an external ISTD endpoint without a fully
            // configured credential set. Missing/orphaned config fails locally.
            if (string.IsNullOrWhiteSpace(settings.JoInvoiceClientId) ||
                string.IsNullOrWhiteSpace(settings.JoInvoiceSecretKey) ||
                string.IsNullOrWhiteSpace(settings.JoInvoiceActivityNumber))
                return new JoInvoiceResult(false, null, null, "Jo-Invoice credentials not configured for this tenant.");

            var xml = GenerateUblXml(sale, settings);
            var payload = new
            {
                invoice = Convert.ToBase64String(Encoding.UTF8.GetBytes(xml.ToString())),
                // Add other metadata required by JoFotara
            };

            var request = new HttpRequestMessage(HttpMethod.Post,
                settings.JoInvoiceEnvironment == "production" ? ProductionUrl : SandboxUrl);

            request.Headers.Add("client-id", settings.JoInvoiceClientId);
            request.Headers.Add("secret-key", settings.JoInvoiceSecretKey);
            request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var response = await httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                using var doc = JsonDocument.Parse(content);
                var root = doc.RootElement;
                return new JoInvoiceResult(
                    true,
                    root.GetProperty("uuid").GetString(),
                    root.GetProperty("qrCode").GetString(),
                    content);
            }

            return new JoInvoiceResult(false, null, null, content);
        }
        catch (Exception ex)
        {
            return new JoInvoiceResult(false, null, null, ex.Message);
        }
    }

    private XDocument GenerateUblXml(Sale sale, TenantSettings settings)
    {
        // This is a simplified UBL 2.1 Invoice XML structure
        // In a real scenario, this would follow the full ISTD schema
        XNamespace cbc = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2";
        XNamespace cac = "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2";
        XNamespace ns = "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2";

        var doc = new XDocument(
            new XDeclaration("1.0", "utf-8", null),
            new XElement(ns + "Invoice",
                new XAttribute(XNamespace.Xmlns + "cbc", cbc),
                new XAttribute(XNamespace.Xmlns + "cac", cac),
                new XElement(cbc + "ID", sale.ReceiptNo),
                new XElement(cbc + "IssueDate", sale.CreatedAt.ToString("yyyy-MM-dd")),
                new XElement(cbc + "InvoiceTypeCode", "388"), // 388 = Tax Invoice
                new XElement(cac + "AccountingSupplierParty",
                    new XElement(cac + "Party",
                        new XElement(cac + "PartyName", new XElement(cbc + "Name", settings.BusinessName))
                        // Add Seller Tax ID etc.
                    )
                ),
                new XElement(cac + "LegalMonetaryTotal",
                    new XElement(cbc + "LineExtensionAmount", sale.Subtotal),
                    new XElement(cbc + "TaxExclusiveAmount", sale.Subtotal),
                    new XElement(cbc + "TaxInclusiveAmount", sale.GrandTotal),
                    new XElement(cbc + "PayableAmount", sale.GrandTotal)
                )
                // Add Sale Items (cac:InvoiceLine)
            )
        );

        return doc;
    }
}
