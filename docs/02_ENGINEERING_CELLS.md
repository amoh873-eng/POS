# 02_ENGINEERING_CELLS.md — POS Cloud Platform v1.1

> Cell Specifications — PHASE-00 | Lightweight Modular Monolith | 7 Layers

---

## Conventions
- Each cell = logical module (folder grouping in `Application` + `Domain` + `Api`), NOT a separate service.
- Contract: DTOs + interfaces exposed; no direct cross-cell entity manipulation.
- Dependencies arrow `A → B` means A may call B's contract.

---

## CORE CELLS

### CELL-001 Foundation
- **Purpose:** Tenancy, cross-cutting, audit, clock, result pattern.
- **Responsibilities:** Tenant/Branch seeding, base entity (`Id, TenantId, CreatedAt`), audit log, error handling.
- **DB:** `tenants`, `branches`, `audit_logs`
- **APIs:** `/api/tenants`, `/api/branches`, `/health`
- **Depends:** none. **Used by:** all.

### CELL-002 Identity
- **Purpose:** AuthZ/AuthN.
- **Responsibilities:** User, Role, login, JWT+refresh, password hash, capability checks.
- **DB:** `users`, `roles`, `user_roles`, `refresh_tokens`
- **APIs:** `/api/auth/login`, `/api/auth/refresh`, `/api/users`, `/api/roles`
- **Rules:** Lockout after N fails; refresh rotated; no plain passwords.
- **Depends:** 001.

### CELL-003 Business (+ Tenant Settings)
- **Purpose:** Business profile + adaptive config (v1 minimal).
- **Responsibilities:** logo, name, colors, language, currency, receipt template.
- **DB:** `tenant_settings`
- **APIs:** `/api/tenant-settings`
- **Depends:** 001, 002 (admin only writes).

### CELL-004 Branch / Terminal
- **Purpose:** Branches + POS terminals, shift.
- **Responsibilities:** Branch CRUD, terminal registration, shift open/close.
- **DB:** `branches` (from 001), `terminals`, `shifts`
- **APIs:** `/api/branches`, `/api/terminals`, `/api/shifts`
- **Depends:** 001, 002.

### CELL-005 Product
- **Purpose:** Catalog.
- **Responsibilities:** Product, Category, barcode, price, tax, active flag.
- **DB:** `categories`, `products`, `product_barcodes`
- **APIs:** `/api/categories`, `/api/products`, `/api/products/barcode/{code}`
- **Rules:** Barcode unique per tenant; price ≥ 0; VAT handling simple v1.
- **Depends:** 001, 004 (branch scoping).

### CELL-006 Inventory
- **Purpose:** Stock per branch, movements, adjustments.
- **Responsibilities:** Stock ledger, transfer, count, low-stock alerts.
- **DB:** `inventory_stocks`, `inventory_movements`, `stock_counts`
- **APIs:** `/api/inventory/stock`, `/api/inventory/movements`, `/api/stock-counts`
- **Rules:** No negative deduction without explicit adjustment; every change is a movement row.
- **Depends:** 005.

### CELL-007 Customer
- **Purpose:** Customer master + credit.
- **Responsibilities:** Customer CRUD, balance/credit, price group (v1 simple).
- **DB:** `customers`, `customer_balances`
- **APIs:** `/api/customers`
- **Depends:** 001.

### CELL-008 Supplier
- **Purpose:** Supplier master.
- **DB:** `suppliers`
- **APIs:** `/api/suppliers`
- **Depends:** 001.

### CELL-009 Sales
- **Purpose:** POS sale — cart → sale → receipt.
- **Responsibilities:** Create sale, lines, totals, discounts, tax, inventory deduction (via 006), receipt number.
- **DB:** `sales`, `sale_items`
- **APIs:** `/api/sales`, `/api/sales/{id}/receipt`
- **Rules:** Totals computed server-side; inventory deducted transactionally; sale is append-only after completion.
- **Depends:** 005, 006, 007, 010, 004.

### CELL-010 Payment
- **Purpose:** Payment engine.
- **Responsibilities:** Methods (Cash/Card/Transfer/Electronic/Credit), Mixed/Partial/Refund; provider isolation.
- **DB:** `payments`, `payment_provider_refs`
- **APIs:** `/api/payments` (via sale), `/api/payment-methods`
- **Rules:** Method ≠ Provider; no card PAN stored; provider behind `IPaymentProvider`.
- **Depends:** 009 (called by).

### CELL-011 Purchasing
- **Purpose:** Purchase orders / goods receipt.
- **DB:** `purchases`, `purchase_items`
- **APIs:** `/api/purchases`, `/api/purchases/{id}/receive`
- **Depends:** 005, 006, 008.

### CELL-012 Reporting
- **Purpose:** Operational reports.
- **Responsibilities:** Daily sales, sales by period, product sales, inventory, purchases, payments, cashier summary, basic profit.
- **DB:** read from 005-011 (no separate warehouse v1).
- **APIs:** `/api/reports/*`
- **Depends:** 005-011 (read-only).

---

## BUSINESS-SPECIFIC CELLS (extensions — added only when needed)

### CELL-101 Restaurant
Tables, orders, kitchen/KDS, modifiers, reservations. Depends: 005, 009, 006. Adds `restaurant_tables`, `kitchen_orders`.

### CELL-102 Bakery
Recipes, production batches, batch cost, expiry. Adds `recipes`, `productions`, `production_batches`.

### CELL-103 Pharmacy
Batches, expiry, prescriptions. Adds `pharmacy_batches`, `prescriptions`. Strict expiry enforcement.

### CELL-104 Supermarket
Scale, promotions, fast checkout optimizations. Adds `promotions`, `scale_products`.

> New cells require business justification per §51 of Master Spec. No generic “add cell for every idea”.

---

## Adding a New Cell — Checklist

1. Which business requirement → which cell owns it? Can existing cell handle it?
2. Define Purpose / Responsibilities / Rules / DB / APIs / Tests / Dependencies.
3. L2+ change → needs review (see AI_AGENT_RULES).

## Physical Layout (example)

```
backend/src/PosCloud.Application/Cells/Products/
  ProductDtos.cs, IProductService.cs, ProductService.cs, ProductValidators.cs
backend/src/PosCloud.Domain/Cells/Products/
  Product.cs, Category.cs
backend/src/PosCloud.Api/Cells/Products/
  ProductsController.cs
```

Until a cell grows large, `Cells/<Name>/` can be just a folder inside Application/Domain/Api — no extra csproj.

---

*Architecture Status: UNCHANGED | Level: L0 doc*
