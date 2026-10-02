# Implementation Plan: Jo-Invoice (Jordanian E-Invoicing) Integration

Integrating the Jordanian National E-Invoicing System (Jo-Invoice / JoFotara) into the POS Cloud Platform. This allows real-time submission of sales invoices to the Income and Sales Tax Department (ISTD) and displaying the required QR code on receipts.

## User Review Required

> [!IMPORTANT]
> To enable this feature in Production, the tenant must provide:
> 1. **Client ID** (رقم المستخدم)
> 2. **Secret Key** (المفتاح السري)
> 3. **Activity Number** (رقم تسلسل مصدر الدخل)
> These are obtained from the [Jo-Invoice Portal](https://portal.jofotara.gov.jo).

## Proposed Changes

### 1. Domain Layer (Entities)

#### [MODIFY] [Sale.cs](file:///D:/POS/backend/src/PosCloud.Domain/Entities/Sale.cs)
- Add `JoInvoiceUuid` (string?): Unique ID returned by ISTD.
- Add `JoInvoiceQrCode` (string?): Base64 or URL of the QR code.
- Add `JoInvoiceStatus` (string): Status of submission (Pending, Submitted, Failed).
- Add `JoInvoiceResponse` (string?): Raw response or error message from ISTD.

#### [MODIFY] [Customer.cs](file:///D:/POS/backend/src/PosCloud.Domain/Entities/Sale.cs)
- Add `TaxId` (string?): Tax Identification Number for businesses.
- Add `NationalId` (string?): National ID for individuals.
- Add `Address` (string?): Required for invoices above 10,000 JOD.

#### [MODIFY] [TenantSettings.cs](file:///D:/POS/backend/src/PosCloud.Domain/Entities/TenantSettings.cs)
- Add `JoInvoiceEnabled` (bool).
- Add `JoInvoiceClientId` (string?).
- Add `JoInvoiceSecretKey` (string?).
- Add `JoInvoiceActivityNumber` (string?).
- Add `JoInvoiceEnvironment` (string: Sandbox/Production).

---

### 2. Infrastructure Layer (Integration)

#### [NEW] `IJoInvoiceService` and `JoInvoiceService`
- **Location:** `D:/POS/backend/src/PosCloud.Infrastructure/Integrations/JoInvoice/`
- **Functionality:**
    - Generate UBL 2.1 XML for the sale.
    - Encode XML into JSON payload.
    - Authenticate using Client ID / Secret Key.
    - Post to ISTD API.
    - Parse response for UUID and QR Code.

---

### 3. API Layer

#### [MODIFY] [SalesController.cs](file:///D:/POS/backend/src/PosCloud.Api/Controllers/SalesController.cs)
- Trigger `JoInvoiceService.SubmitAsync(sale)` after the sale is successfully committed to the database.

#### [MODIFY] [ReceiptController.cs](file:///D:/POS/backend/src/PosCloud.Api/Controllers/ReceiptController.cs)
- Include `JoInvoiceUuid` and `JoInvoiceQrCode` in the receipt response data.

---

### 4. Frontend Layer (Flutter)

#### [MODIFY] `D:/POS/frontend/lib/features/sales/checkout_screen.dart` (or equivalent)
- Add fields for Customer Tax ID / National ID if applicable.

#### [MODIFY] `D:/POS/frontend/lib/features/sales/receipt_dialog.dart` (or equivalent)
- Display the Jo-Invoice QR code if available.

#### [MODIFY] `D:/POS/frontend/lib/features/settings/tenant_settings_screen.dart`
- Add a section to configure Jo-Invoice credentials.

## Verification Plan

### Automated Tests
- Unit tests for `JoInvoiceService` XML generation.
- Integration test for `JoInvoiceService` against the Sandbox environment (if credentials provided or mocked).

### Manual Verification
- Create a sale and verify that the `JoInvoiceUuid` is populated in the database.
- Print/View a receipt and scan the QR code to ensure it contains the correct tax information.
