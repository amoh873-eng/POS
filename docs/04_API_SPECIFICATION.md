# 04_API_SPECIFICATION.md — POS Cloud Platform v1.1

> REST API — PHASE-00 | Base: `/api` | Auth: JWT Bearer + Refresh | Version: v1 (header `X-Api-Version: 1`)

---

## 1. Conventions

- **Style:** REST, JSON, `snake_case` fields, `kebab-case` routes where needed; pagination `?page=1&page_size=20`.
- **Envelope (success):** `{ "data": <T>, "meta": { "page", "page_size", "total" } }` for lists; single object for `GET /{id}`.
- **Envelope (error):** `{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }` + proper HTTP status.
- **Auth:** `Authorization: Bearer <jwt>`; `POST /api/auth/refresh` with `refresh_token` (httpOnly cookie or body — v1 body).
- **Tenant:** resolved from JWT `tenant_id` claim; `branch_id` from claim or header `X-Branch-Id` when user has multi-branch.
- **Idempotency (sales):** `Idempotency-Key` header for `POST /api/sales` — dedup by key 24h.
- **Validation:** FluentValidation; 400 on invalid. Business rule failures → 422.
- **Rate limit:** login/refresh strict; others soft.

## 2. Auth

### POST /api/auth/login
Req: `{ "email", "password", "tenant_slug"? }` → Res: `{ "access_token", "refresh_token", "expires_in", "user": { "id","email","display_name","roles" } }` | Errors: 401

### POST /api/auth/refresh
Req: `{ "refresh_token" }` → Res: new tokens | 401 if rotated/revoked

### POST /api/auth/logout
Auth → revokes refresh token.

## 3. Tenants / Branches / Settings

- `GET /api/tenants/me` — current tenant
- `GET/POST /api/branches` | `GET/PATCH/DELETE /api/branches/{id}` (Admin)
- `GET /api/branches/{id}/terminals` etc. (see Cells)
- `GET /api/tenant-settings` | `PATCH /api/tenant-settings` (Admin/Owner)

## 4. Users / Roles

- `GET/POST /api/users` | `GET/PATCH /api/users/{id}` | `POST /api/users/{id}/roles`
- `GET /api/roles` — list capabilities

## 5. Products / Categories

- `GET /api/categories?parent_id=&branch_id=` | `POST /api/categories` | `PATCH/DELETE /api/categories/{id}`
- `GET /api/products?q=&category_id=&is_active=&page=&page_size=` | `POST /api/products` | `GET /api/products/{id}` | `PATCH /api/products/{id}` | `DELETE /api/products/{id}` (soft)
- `GET /api/products/barcode/{code}` — lookup (for scanner)
- Product body: `{ "sku","barcode_main","barcodes[]","name_ar","name_en","category_id","unit","cost_price","sell_price","tax_rate","is_active" }`

## 6. Inventory

- `GET /api/inventory/stock?branch_id=&q=` → `{ product_id, qty_on_hand, low_stock_threshold }`
- `POST /api/inventory/movements` — adjust/transfer (type in body)
- `POST /api/inventory/transfer` — `{ "from_branch_id","to_branch_id","lines":[{product_id,qty}] }`
- `GET/POST /api/stock-counts` | `POST /api/stock-counts/{id}/post`

## 7. Customers / Suppliers

- `GET/POST /api/customers` | `GET/PATCH/DELETE /api/customers/{id}` — `q` search by name/phone
- `GET/POST /api/suppliers` | `GET/PATCH /api/suppliers/{id}`

## 8. Sales (POS)

- `POST /api/sales` — create sale
  Req: `{ "branch_id","customer_id?","discount_total?","lines":[{ "product_id","qty","unit_price?","discount?"}], "payments":[{ "method","amount","provider?","provider_ref?" }], "idempotency_key"? }`
  Server computes totals/tax; validates stock; deducts via inventory; creates payments; returns `{ sale, receipt_no, receipt_url }`.
  Errors: 422 `INSUFFICIENT_STOCK`, 422 `PAYMENT_MISMATCH` (paid ≠ grand_total unless credit allowed).

- `GET /api/sales?q=&from=&to=&branch_id=&page=` | `GET /api/sales/{id}` | `GET /api/sales/{id}/receipt`
- `POST /api/sales/{id}/refund` — partial/full refund (creates negative sale + payment reversal + stock return)
- `POST /api/sales/{id}/void` — void before sync (if allowed by role)

## 9. Payments

- `GET /api/payment-methods` — list enabled methods per tenant
- Payments are created via sale; standalone `POST /api/payments` only for supplier payments / credit settlement.

## 10. Purchasing

- `GET/POST /api/purchases` | `GET /api/purchases/{id}` | `POST /api/purchases/{id}/receive` — lines `{ product_id,qty,cost }` → posts inventory movements.

## 11. Reports

- `GET /api/reports/daily-sales?date=&branch_id=` | `GET /api/reports/sales?from=&to=&group_by=day|product` | `GET /api/reports/inventory?branch_id=` | `GET /api/reports/purchases?from=&to=` | `GET /api/reports/payments?from=&to=` | `GET /api/reports/cashier-summary?from=&to=`

## 12. Sync (offline)

- `POST /api/sync/push` — batch upload pending entities (sales/movements) — idempotent by client-generated `client_id`.
- `GET /api/sync/pull?since=` — delta pull (products/customers/settings updated since).
- States mirrored in `sync_state`; device retries `failed`.

## 13. Error Codes (sample)

`VALIDATION_ERROR` 400 | `UNAUTHORIZED` 401 | `FORBIDDEN` 403 | `NOT_FOUND` 404 | `CONFLICT` 409 (duplicate barcode/sku) | `INSUFFICIENT_STOCK` 422 | `PAYMENT_MISMATCH` 422 | `REFUND_NOT_ALLOWED` 422 | `RATE_LIMITED` 429

## 14. OpenAPI

Generated via Swashbuckle/Scalar at `/swagger` (dev). Single version v1; breaking changes → `X-Api-Version: 2`.

---

*Architecture: UNCHANGED | Next: 05_ALGORITHMS.md*
