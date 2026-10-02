CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;
CREATE TABLE audit_logs (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "UserId" uuid,
    "Action" text NOT NULL,
    "EntityType" text NOT NULL,
    "EntityId" text,
    "PayloadJson" text,
    "Ip" text,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_audit_logs" PRIMARY KEY ("Id")
);

CREATE TABLE branches (
    "Id" uuid NOT NULL,
    "Name" text NOT NULL,
    "Code" text NOT NULL,
    "Address" text,
    "IsActive" boolean NOT NULL,
    "TenantId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    "CreatedBy" uuid,
    CONSTRAINT "PK_branches" PRIMARY KEY ("Id")
);

CREATE TABLE categories (
    "Id" uuid NOT NULL,
    "NameAr" text NOT NULL,
    "NameEn" text NOT NULL,
    "ParentId" uuid,
    "IsActive" boolean NOT NULL,
    "SortOrder" integer NOT NULL,
    "BranchId" uuid,
    "TenantId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    "CreatedBy" uuid,
    CONSTRAINT "PK_categories" PRIMARY KEY ("Id")
);

CREATE TABLE customers (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "Name" text NOT NULL,
    "Phone" text,
    "Email" text,
    "CreditLimit" numeric NOT NULL,
    "IsActive" boolean NOT NULL,
    "IsDeleted" boolean NOT NULL,
    CONSTRAINT "PK_customers" PRIMARY KEY ("Id")
);

CREATE TABLE inventory_movements (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "BranchId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "Type" text NOT NULL,
    "QtyDelta" numeric NOT NULL,
    "RefType" text,
    "RefId" uuid,
    "CreatedBy" uuid,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_inventory_movements" PRIMARY KEY ("Id")
);

CREATE TABLE inventory_stocks (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "BranchId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "QtyOnHand" numeric NOT NULL,
    "LowStockThreshold" numeric NOT NULL,
    CONSTRAINT "PK_inventory_stocks" PRIMARY KEY ("Id")
);

CREATE TABLE product_barcodes (
    "Id" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "Barcode" text NOT NULL,
    "IsPrimary" boolean NOT NULL,
    CONSTRAINT "PK_product_barcodes" PRIMARY KEY ("Id")
);

CREATE TABLE products (
    "Id" uuid NOT NULL,
    "CategoryId" uuid NOT NULL,
    "NameAr" text NOT NULL,
    "NameEn" text NOT NULL,
    "Sku" text NOT NULL,
    "BarcodeMain" text,
    "Unit" text NOT NULL,
    "CostPrice" numeric NOT NULL,
    "SellPrice" numeric NOT NULL,
    "TaxRate" numeric NOT NULL,
    "IsActive" boolean NOT NULL,
    "IsDeleted" boolean NOT NULL,
    "DeletedAt" timestamp with time zone,
    "TenantId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    "CreatedBy" uuid,
    CONSTRAINT "PK_products" PRIMARY KEY ("Id")
);

CREATE TABLE purchases (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "BranchId" uuid NOT NULL,
    "SupplierId" uuid NOT NULL,
    "Status" text NOT NULL,
    "Subtotal" numeric NOT NULL,
    "TaxTotal" numeric NOT NULL,
    "GrandTotal" numeric NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "ReceivedAt" timestamp with time zone,
    CONSTRAINT "PK_purchases" PRIMARY KEY ("Id")
);

CREATE TABLE refresh_tokens (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "TokenHash" text NOT NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    "RevokedAt" timestamp with time zone,
    "CreatedByIp" text,
    CONSTRAINT "PK_refresh_tokens" PRIMARY KEY ("Id")
);

CREATE TABLE roles (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "Name" text NOT NULL,
    "CapabilitiesJson" text,
    CONSTRAINT "PK_roles" PRIMARY KEY ("Id")
);

CREATE TABLE sales (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "BranchId" uuid NOT NULL,
    "TerminalId" uuid,
    "CustomerId" uuid,
    "ReceiptNo" text NOT NULL,
    "Status" text NOT NULL,
    "Subtotal" numeric NOT NULL,
    "DiscountTotal" numeric NOT NULL,
    "TaxTotal" numeric NOT NULL,
    "GrandTotal" numeric NOT NULL,
    "PaidTotal" numeric NOT NULL,
    "CreatedBy" uuid,
    "CreatedAt" timestamp with time zone NOT NULL,
    "IdempotencyKey" text,
    CONSTRAINT "PK_sales" PRIMARY KEY ("Id")
);

CREATE TABLE shifts (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "BranchId" uuid NOT NULL,
    "TerminalId" uuid NOT NULL,
    "OpenedBy" uuid NOT NULL,
    "OpenedAt" timestamp with time zone NOT NULL,
    "ClosedAt" timestamp with time zone,
    "OpeningCash" numeric NOT NULL,
    "ClosingCash" numeric,
    "Status" text NOT NULL,
    CONSTRAINT "PK_shifts" PRIMARY KEY ("Id")
);

CREATE TABLE stock_count_lines (
    "Id" uuid NOT NULL,
    "StockCountId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "SystemQty" numeric NOT NULL,
    "CountedQty" numeric NOT NULL,
    CONSTRAINT "PK_stock_count_lines" PRIMARY KEY ("Id")
);

CREATE TABLE stock_counts (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "BranchId" uuid NOT NULL,
    "Status" text NOT NULL,
    "CountedAt" timestamp with time zone NOT NULL,
    "PostedAt" timestamp with time zone,
    CONSTRAINT "PK_stock_counts" PRIMARY KEY ("Id")
);

CREATE TABLE suppliers (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "Name" text NOT NULL,
    "Phone" text,
    "IsActive" boolean NOT NULL,
    CONSTRAINT "PK_suppliers" PRIMARY KEY ("Id")
);

CREATE TABLE tenant_settings (
    "TenantId" uuid NOT NULL,
    "LogoUrl" text,
    "BusinessName" text NOT NULL,
    "PrimaryColor" text NOT NULL,
    "SecondaryColor" text NOT NULL,
    "Language" text NOT NULL,
    "Currency" text NOT NULL,
    "ReceiptTemplateJson" text,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_tenant_settings" PRIMARY KEY ("TenantId")
);

CREATE TABLE tenants (
    "Id" uuid NOT NULL,
    "Name" text NOT NULL,
    "Slug" text NOT NULL,
    "IsActive" boolean NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_tenants" PRIMARY KEY ("Id")
);

CREATE TABLE terminals (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "BranchId" uuid NOT NULL,
    "Name" text NOT NULL,
    "DeviceId" text,
    "IsActive" boolean NOT NULL,
    CONSTRAINT "PK_terminals" PRIMARY KEY ("Id")
);

CREATE TABLE users (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "Email" text NOT NULL,
    "PasswordHash" text NOT NULL,
    "DisplayName" text NOT NULL,
    "IsActive" boolean NOT NULL,
    "FailedAttempts" integer NOT NULL,
    "LockedUntil" timestamp with time zone,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_users" PRIMARY KEY ("Id")
);

CREATE TABLE purchase_items (
    "Id" uuid NOT NULL,
    "PurchaseId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "Qty" numeric NOT NULL,
    "Cost" numeric NOT NULL,
    CONSTRAINT "PK_purchase_items" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_purchase_items_purchases_PurchaseId" FOREIGN KEY ("PurchaseId") REFERENCES purchases ("Id") ON DELETE CASCADE
);

CREATE TABLE payments (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "SaleId" uuid,
    "Method" text NOT NULL,
    "Provider" text,
    "ProviderRef" text,
    "Amount" numeric NOT NULL,
    "Status" text NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_payments" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_payments_sales_SaleId" FOREIGN KEY ("SaleId") REFERENCES sales ("Id")
);

CREATE TABLE sale_items (
    "Id" uuid NOT NULL,
    "SaleId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "Qty" numeric NOT NULL,
    "UnitPrice" numeric NOT NULL,
    "Discount" numeric NOT NULL,
    "Tax" numeric NOT NULL,
    "LineTotal" numeric NOT NULL,
    CONSTRAINT "PK_sale_items" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_sale_items_sales_SaleId" FOREIGN KEY ("SaleId") REFERENCES sales ("Id") ON DELETE CASCADE
);

CREATE TABLE user_roles (
    "UserId" uuid NOT NULL,
    "RoleId" uuid NOT NULL,
    CONSTRAINT "PK_user_roles" PRIMARY KEY ("UserId", "RoleId"),
    CONSTRAINT "FK_user_roles_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE INDEX "IX_audit_logs_TenantId_CreatedAt" ON audit_logs ("TenantId", "CreatedAt");

CREATE UNIQUE INDEX "IX_branches_TenantId_Code" ON branches ("TenantId", "Code");

CREATE INDEX "IX_branches_TenantId_IsActive" ON branches ("TenantId", "IsActive");

CREATE INDEX "IX_categories_TenantId_BranchId" ON categories ("TenantId", "BranchId");

CREATE INDEX "IX_customers_TenantId_Phone" ON customers ("TenantId", "Phone");

CREATE INDEX "IX_inventory_movements_TenantId_BranchId_ProductId_CreatedAt" ON inventory_movements ("TenantId", "BranchId", "ProductId", "CreatedAt");

CREATE UNIQUE INDEX "IX_inventory_stocks_TenantId_BranchId_ProductId" ON inventory_stocks ("TenantId", "BranchId", "ProductId");

CREATE INDEX "IX_payments_SaleId" ON payments ("SaleId");

CREATE UNIQUE INDEX "IX_product_barcodes_Barcode" ON product_barcodes ("Barcode");

CREATE INDEX "IX_products_BarcodeMain" ON products ("BarcodeMain");

CREATE UNIQUE INDEX "IX_products_TenantId_Sku" ON products ("TenantId", "Sku");

CREATE INDEX "IX_purchase_items_PurchaseId" ON purchase_items ("PurchaseId");

CREATE UNIQUE INDEX "IX_refresh_tokens_TokenHash" ON refresh_tokens ("TokenHash");

CREATE INDEX "IX_sale_items_SaleId" ON sale_items ("SaleId");

CREATE UNIQUE INDEX "IX_sales_ReceiptNo" ON sales ("ReceiptNo");

CREATE INDEX "IX_sales_TenantId_BranchId_CreatedAt" ON sales ("TenantId", "BranchId", "CreatedAt");

CREATE UNIQUE INDEX "IX_tenants_Slug" ON tenants ("Slug");

CREATE INDEX "IX_terminals_TenantId_BranchId" ON terminals ("TenantId", "BranchId");

CREATE UNIQUE INDEX "IX_users_TenantId_Email" ON users ("TenantId", "Email");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260824194928_001_initial', '10.0.0-preview.2.25163.8');

ALTER TABLE products ADD "Description" text;

ALTER TABLE products ADD "MinStockLevel" numeric NOT NULL DEFAULT 0.0;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260825195124_018_product_inventory', '10.0.0-preview.2.25163.8');

ALTER TABLE customers ADD "Balance" numeric NOT NULL DEFAULT 0.0;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260825200000_019_customer_balance', '10.0.0-preview.2.25163.8');

ALTER TABLE products ADD "ImageUrl" text;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260827215421_AddProductImageUrl', '10.0.0-preview.2.25163.8');

ALTER TABLE tenant_settings ADD "JoInvoiceActivityNumber" text;

ALTER TABLE tenant_settings ADD "JoInvoiceClientId" text;

ALTER TABLE tenant_settings ADD "JoInvoiceEnabled" boolean NOT NULL DEFAULT FALSE;

ALTER TABLE tenant_settings ADD "JoInvoiceEnvironment" text NOT NULL DEFAULT '';

ALTER TABLE tenant_settings ADD "JoInvoiceSecretKey" text;

ALTER TABLE sales ADD "JoInvoiceQrCode" text;

ALTER TABLE sales ADD "JoInvoiceResponse" text;

ALTER TABLE sales ADD "JoInvoiceStatus" text NOT NULL DEFAULT '';

ALTER TABLE sales ADD "JoInvoiceUuid" text;

ALTER TABLE customers ADD "Address" text;

ALTER TABLE customers ADD "NationalId" text;

ALTER TABLE customers ADD "TaxId" text;

CREATE TABLE accounts (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "Code" text NOT NULL,
    "NameAr" text NOT NULL,
    "NameEn" text NOT NULL,
    "Type" text NOT NULL,
    "ParentId" uuid,
    "IsGroup" boolean NOT NULL,
    "Balance" numeric NOT NULL,
    "IsActive" boolean NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_accounts" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_accounts_accounts_ParentId" FOREIGN KEY ("ParentId") REFERENCES accounts ("Id")
);

CREATE TABLE journal_entries (
    "Id" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "Date" timestamp with time zone NOT NULL,
    "Description" text NOT NULL,
    "ReferenceType" text,
    "ReferenceId" uuid,
    CONSTRAINT "PK_journal_entries" PRIMARY KEY ("Id")
);

CREATE TABLE journal_entry_lines (
    "Id" uuid NOT NULL,
    "JournalEntryId" uuid NOT NULL,
    "AccountId" uuid NOT NULL,
    "Debit" numeric NOT NULL,
    "Credit" numeric NOT NULL,
    CONSTRAINT "PK_journal_entry_lines" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_journal_entry_lines_journal_entries_JournalEntryId" FOREIGN KEY ("JournalEntryId") REFERENCES journal_entries ("Id") ON DELETE CASCADE
);

CREATE INDEX "IX_sales_CustomerId" ON sales ("CustomerId");

CREATE UNIQUE INDEX "IX_sales_JoInvoiceUuid" ON sales ("JoInvoiceUuid");

CREATE INDEX "IX_purchases_SupplierId" ON purchases ("SupplierId");

CREATE INDEX "IX_accounts_ParentId" ON accounts ("ParentId");

CREATE UNIQUE INDEX "IX_accounts_TenantId_Code" ON accounts ("TenantId", "Code");

CREATE INDEX "IX_journal_entry_lines_JournalEntryId" ON journal_entry_lines ("JournalEntryId");

ALTER TABLE purchases ADD CONSTRAINT "FK_purchases_suppliers_SupplierId" FOREIGN KEY ("SupplierId") REFERENCES suppliers ("Id") ON DELETE CASCADE;

ALTER TABLE sales ADD CONSTRAINT "FK_sales_customers_CustomerId" FOREIGN KEY ("CustomerId") REFERENCES customers ("Id");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261002170343_accounting_joinvoice_phase32', '10.0.0-preview.2.25163.8');

COMMIT;

