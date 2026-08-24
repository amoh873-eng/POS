# 03_DATABASE.md — POS Cloud Platform v1.1

> ERD + Entities + Principles — PHASE-00
> DB: PostgreSQL (cloud) / SQLite (local, same schema subset) | ORM: EF Core

---

## 1. Principles (from Master Spec §16, §45)
- Minimal model first, extend on demand. No ERP-size upfront.
- Integrity: FKs, unique constraints, checks. Indexes on hot paths.
- Auditability: `created_at/updated_at/created_by` + `audit_logs`.
- Soft-delete only where justified (Product/Customer) — otherwise hard delete + audit.

## 2. Naming
- Tables: `snake_case` plural (`tenants`, `sale_items`). Columns: `snake_case`. PK: `id uuid`.
- All tenant-scoped tables: `tenant_id uuid NOT NULL`, index `(tenant_id [, branch_id])`.
- Timestamps: `timestamptz` (UTC). Money: `numeric(12,2)`.

## 3. Core ERD (text)

```
tenants 1──* branches 1──* terminals
  |            |               |
  |            *──* shifts ──* |
  |            |               |
  *──* users *──* user_roles *──* roles
  |            |
  *──* tenant_settings (1-1)

branches 1──* categories (tenant scope, branch nullable if shared)
categories 1──* products 1──* product_barcodes
products 1──* inventory_stocks (per branch) 1──* inventory_movements
products 1──* sale_items *──1 sales *──1 branches / *──? customers
sales 1──* payments  (payments.payment_method, provider_ref nullable)
products 1──* purchase_items *──1 purchases *──1 suppliers
customers 1──* customer_balances (optional ledger view)
suppliers 1──* purchases
sales / purchases / payments → audit_logs (polymorphic: entity_type+entity_id)
```

Shared vs per-branch catalog: v1 — categories/products are tenant-wide; stock is per-branch. Branch-specific pricing via future extension, not v1.

## 4. Tables (v1 baseline)

### tenants
`id uuid PK`, `name text`, `slug text UNIQUE`, `is_active bool`, `created_at`.

### branches
`id`, `tenant_id FK`, `name`, `code UNIQUE per tenant`, `address`, `is_active`.

### tenant_settings
`tenant_id PK FK`, `logo_url`, `business_name`, `primary_color`, `secondary_color`, `language`, `currency`, `receipt_template jsonb`.

### users / roles / user_roles / refresh_tokens
- `users`: `id`, `tenant_id`, `email UNIQUE per tenant`, `password_hash`, `display_name`, `is_active`, `failed_attempts`, `locked_until`.
- `roles`: `id`, `tenant_id`, `name` (Owner/Admin/Manager/Cashier/Inventory/Accountant), `capabilities jsonb`.
- `user_roles`: `(user_id, role_id)`.
- `refresh_tokens`: `id`, `user_id`, `token_hash UNIQUE`, `expires_at`, `revoked_at`, `created_by_ip`.

### categories
`id`, `tenant_id`, `branch_id nullable`, `name_ar`, `name_en`, `parent_id FK self nullable`, `is_active`, `sort_order`.

### products
`id`, `tenant_id`, `category_id FK`, `name_ar`, `name_en`, `sku UNIQUE per tenant`, `barcode_main UNIQUE per tenant nullable`, `unit`, `cost_price`, `sell_price`, `tax_rate`, `is_active`, `is_deleted`, `deleted_at`.

### product_barcodes
`id`, `product_id FK`, `barcode UNIQUE per tenant`, `is_primary`.

### inventory_stocks
`id`, `tenant_id`, `branch_id`, `product_id`, `qty_on_hand numeric(12,2)`, `low_stock_threshold`, `UNIQUE(tenant_id, branch_id, product_id)`.

### inventory_movements
`id`, `tenant_id`, `branch_id`, `product_id`, `type` (sale/purchase/adjust/transfer_in/transfer_out/count), `qty_delta`, `ref_type`, `ref_id`, `created_by`, `created_at`, index `(tenant_id, branch_id, product_id, created_at)`.

### stock_counts
`id`, `tenant_id`, `branch_id`, `status` (draft/posted), `counted_at`, `posted_at`; + `stock_count_lines` (`stock_count_id`, `product_id`, `system_qty`, `counted_qty`, `diff`).

### customers
`id`, `tenant_id`, `name`, `phone`, `email nullable`, `credit_limit`, `is_active`, `is_deleted`.

### suppliers
`id`, `tenant_id`, `name`, `phone`, `email nullable`, `is_active`.

### sales
`id`, `tenant_id`, `branch_id`, `terminal_id nullable`, `shift_id nullable`, `customer_id nullable`, `receipt_no UNIQUE per tenant`, `status` (completed/refunded/voided), `subtotal`, `discount_total`, `tax_total`, `grand_total`, `paid_total`, `created_by`, `created_at`.
`sale_items`: `id`, `sale_id FK`, `product_id`, `qty`, `unit_price`, `discount`, `tax`, `line_total`.

### payments
`id`, `tenant_id`, `sale_id FK nullable`, `purchase_id FK nullable`, `method` (cash/card/transfer/electronic/credit), `provider` (nullable, e.g. `provider_a`), `provider_ref` (token, NOT PAN), `amount`, `status`, `created_at`.

### purchases / purchase_items
Like sales but supplier-scoped; `status` (draft/received/cancelled). Receipt updates `inventory_movements`.

### audit_logs
`id`, `tenant_id`, `user_id nullable`, `action` (login/sale/refund/payment/price_change/permission_change), `entity_type`, `entity_id`, `payload jsonb`, `ip`, `created_at`, index `(tenant_id, created_at)`.

### sync_state (local SQLite only, or cloud shadow)
`id`, `entity_type`, `entity_id`, `state` (pending/synced/failed), `attempts`, `last_error`, `updated_at`.

## 5. Indexes (hot paths)
- `(tenant_id, branch_id)` on stocks/movements/sales/purchases.
- `barcode_main`, `product_barcodes.barcode` unique per tenant (partial index).
- `sales(receipt_no)`, `sales(created_at)`, `customers(phone)`.

## 6. Constraints
- `CHECK (sell_price >= 0)`, `CHECK (qty >= 0)` where applicable (movement delta can be negative).
- FKs with `ON DELETE RESTRICT` for master data; cascade only for owned children (sale_items).

## 7. SQLite subset
Same tables minus: `audit_logs` (cloud only), plus `sync_state`. Types mapped: `uuid→text`, `timestamptz→text (ISO8601 UTC)`.

## 8. Migrations
EF Core migrations in `PosCloud.Infrastructure`. One baseline migration for v1 core (001_initial). No separate migration per tiny cell.

---

*Next: `04_API_SPECIFICATION.md` | Architecture: UNCHANGED*
