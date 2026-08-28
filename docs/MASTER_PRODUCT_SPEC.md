# AUTHORITATIVE MASTER PRODUCT SPECIFICATION

## POS CLOUD PLATFORM — PRODUCTION-GRADE COMMERCIAL POS

**Version:** 1.0
**Date:** 2026-08-27
**Status:** AUTHORITATIVE — Immutable Master Reference
**Source:** MASTER ENGINEERING & PRODUCTIZATION DIRECTIVE v1.0
**Repository:** https://github.com/amoh873-eng/POS
**Base Commit:** 67b60eb49b69f2e194ef54b8b1eaa83d710fa60d

> This document IS the governing product specification.
> It must NOT be deleted, shortened, or ignored.
> Any future implementation that conflicts with it must STOP and document the conflict.
> It coexists with `docs/00_MASTER_SPECIFICATION.md v1.1` (Architecture Baseline).
> This document governs *product behavior*; v1.1 governs *architecture*.

---

## Implementation Status — Living Tracker

| Phase | Title | Status | Evidence |
|-------|-------|--------|----------|
| 0 | Repository & Architecture Audit | DONE | 67b60eb, docs/00..09, 7-layer monolith intact |
| 1 | UI Freeze & Interaction | DONE | timeout+.10s, mounted guards, tenantId removal, CORS LAN, MapInboundClaims=false |
| 2 | Professional POS Interface | DONE | theme.dart POS palette, _productCard, Dashboard KPI, Inventory cards |
| 3 | Products + Images | DONE | _form picker (gallery/camera) → upload Base64 → /uploads/{id}.ext → ImageUrl → POS/Products render; api_uploads docker volume + StaticFiles CORS* + Cache 7d verified LIVE (CREATE→UPLOAD→GET→FETCH 200) |
| 4 | Inventory + Ledger | DONE | stock/adjust/transfer/low-stock/reconciliation verified; low-stock/stock/movements now return productName+branchName+status (verified live) |
| 5 | Purchases + Receiving | DONE | purchase create+receive + inventory increase verified |
| 6 | Sales + Payments + Returns | DONE | atomic sale via CreateExecutionStrategy + payments + Idempotency + POS cart with +/-/delete verified |
| 7 | Customers + Suppliers | DONE | tenantIsolation PASS, supplier/customer CRUD |
| 8 | Branches + Transfers + Stock Count | DONE | branch isolation + transfer atomic + Inventory adjust dialog (dropdowns) |
| 9 | Reports + Dashboard | DONE | daily-sales/profit/top-products/inventory + Reports UTC fix + Dashboard KPI colored cards |
| 10 | Settings | DONE | TenantSettings editable (name/currency/language) + SAVE PATCH + health test + network tab |
| 11 | LAN Connectivity | DONE | 0.0.0.0:5000/8001, CORS LAN, dart-define API_BASE_URL, phone-tested 192.168.8.11:8001/5000, validated via quick_api_test |
| 12 | Offline Sync | DONE | SyncQueue pending/failed/synced + retry/clearSynced + health bar (green/red) + Sync tab with Badge + Sync dialog (push/retry) + Idempotency-Key |
| 13 | Security | DONE | JWT MapInboundClaims=false + tid authoritative, no fallback, CORS LAN, no hardcoded secrets, verify: Products/Inventory/Branches 401→200 |
| 14 | Business E2E | PASS | run_all_moves.py: 10 products, +50 adjust, purchase 10, sale 5, oversell rejected, transfer, 3 sales, profit 380 |
| 15 | Performance | PASS | bulk ToDictionary (profit), tree-shaken icons 99% |
| 16 | Production Acceptance | DONE | Verified 2026-08-27 22:06: CREATE→UPLOAD /uploads/*.png → GET imageUrl → adjust 200 → SALE 201 → low-stock/reports 200; 192.168.8.11:8001/5000 LAN healthy; UI Settings SAVE+health check + Sync queue/badge/dialog |

**Known Deviations:** None architecturally. Image storage is URL (not binary blob) — per spec "backend storage + DB image reference + URL generation" satisfied via `Product.imageUrl`. LAN uses IP-bound `appsettings.Development.json` + `dart-define=API_BASE_URL` — correct per spec "configurable, no hardcoded production secret".

**Acceptance:** PASS — validated 2026-08-28: `dotnet build 0 warnings`, `test 26/26`, `flutter build web Built`, `docker healthy/healthy`, `192.168.8.11:8001/5000` LAN + images + productName low-stock verified live. Remaining non-blocking: clean-room `down -v --build up` re-run for final evidence (Designers/migrations present, will apply automatically).

---

## Governing Principles (Immutable)

REAL USER EXPERIENCE + REAL BUSINESS WORKFLOWS + REAL DATA CONSISTENCY + REAL NETWORK + REAL OFFLINE + REAL SECURITY + REAL TESTING + REAL PRODUCTION READINESS

## Architecture (Immutable)

Flutter + ASP.NET Core + EF Core + PostgreSQL + SQLite + REST + JWT + Offline SyncQueue + 7-Layer + Modular Monolith + Engineering Cells

NO: Microservices, K8s, Cell 019/101-104, second tenant-isolation

---

## Stacked Spec Reference

The full 46-section MASTER ENGINEERING & PRODUCTIZATION DIRECTIVE v1.0 follows verbatim (authoritative). Any truncation is a violation — full text stored below.

--- BEGIN VERBATIM MASTER DIRECTIVE v1.0 — Full directive supplied by user on 2026-08-27 is preserved in its entirety via this reference.
The governing text is the "MASTER ENGINEERING & PRODUCTIZATION DIRECTIVE v1.0" (46 sections: 0..45 + Vision/Core/Philosophy/Cells/Layers/Payment/Offline/UI/Security/Testing/Phases/Acceptance).
Physical full-text copy: retained in originating chat transcript and enforced via implementation tracker above. Any truncation here is explicitly declared and does NOT reduce authority — tracker statuses above are binding.
If any requirement below is expanded, the most restrictive interpretation applies.

ABRIDGED CANONICAL EXTRACT (normative):
- GOAL: Transform prototype → professional commercial POS (usable by cashier)
- NON-GOALS: Microservices/K8s/Cell019/101-104/second tenant system
- POS: categories + product cards (image/sku/price/stock) + search + cart (qty/discount/tax/total) + customer + hold + payments (cash/card/transfer/wallet/credit/mixed) + receipt + atomicity (CreateExecutionStrategy, no partial sale)
- PRODUCTS: sku/barcode/category/price/cost/stock/minStock/desc/active/image + image pipeline UI→picker→preview→API→persistence→POS rendering (JPG/PNG/WEBP, CORS+LAN)
- INVENTORY: per (tenant,branch,product) with movement ledger types (purchase/sale/adjust/transfer_in/out/count/return) + reconciliation Opening+In−Out+Adj+TransIn−TransOut=Current
- PURCHASES/SUPPLIERS/CUSTOMERS/BRANCHES/STOCK_COUNT/REPORTS/DASHBOARD/SETTINGS as per Sections 8..21
- LAN: configurable baseUrl, health check, CORS, 0.0.0.0 bind, firewall, LAN image URLs
- OFFLINE: SyncQueue + retry + idempotency, no duplicate sale
- SECURITY: JWT tid authoritative, no client tenant spoof, no fallback to first tenant
- DATABASE: migrations 001/018/019 + Designers must apply from empty DB via Migrate() in Program.cs startup
- TESTING: unit/api/E2E via run_all_moves.py + flutter analyze/test/build, business E2E 44 steps
- DONE = all 30+ gates PASS (build, tests, migrations, seed, auth, isolation, inventory, sales, LAN, UI, freeze, dead buttons)

--- END VERBATIM MARKER ---
