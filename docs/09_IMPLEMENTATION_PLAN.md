# 09_IMPLEMENTATION_PLAN.md — POS Cloud Platform v1.1

> Phased plan — PHASE-00 baseline | Modular Monolith | Checkpoints per phase

---

## Overview

Phases match Master Spec §52. Each phase ends with: tests + docs + `PROJECT_STATE.md` update + git checkpoint. No phase starts without prior checkpoint clean.

## Phase Details

| Phase | Name | Scope | Key Artefacts | Exit Criteria |
|-------|------|-------|---------------|---------------|
| 00 | Architecture & Docs | This baseline (01-06) + plan | docs/0x.md | All docs committed, arch UNCHANGED |
| 01 | Foundation | Tenant/Branch/Settings, audit, health, base entity | Domain+Api tenant | Branch CRUD + health OK |
| 02 | Identity | User/Role/Auth JWT+refresh, guards | Auth cell | Login/refresh, role guards pass |
| 03 | Business + Branch | Tenant settings UI linkage, branches/terminals/shifts | Branch cell | Shifts open/close |
| 04 | Products | Category/Product/barcode | Product cell | Product CRUD + barcode lookup |
| 05 | Inventory | Stock/movements/count/transfer | Inventory cell | Stock correct, no negative without adjust |
| 06 | POS (UI) | Flutter POS screen, scanner, cart | frontend POS | Cart+scan works (mock API) |
| 07 | Sales + Payments | Sale TX, payments (method vs provider), receipt | Sales+Payment cells | Sale TX + idempotency + refund |
| 08 | Offline + Sync | SQLite, sync queue, push/pull | Sync | Offline sale → sync OK |
| 09 | Purchasing | Purchase orders, goods receipt | Purchasing cell | Receive updates stock |
| 10 | Customers+Suppliers | CRUD, credit | Customer/Supplier cells | Credit-aware sale |
| 11 | Reports | Daily/period/product/inventory/purchases/payments | Reporting cell | Reports with date range |
| 12 | Restaurant | Tables/orders/KDS (extension) | CELL-101 | Only if customer need |
| 13 | Bakery | Recipes/batches (extension) | CELL-102 | Only if needed |
| 14 | Pharmacy | Batches/expiry (extension) | CELL-103 | Only if needed |
| 15 | Supermarket | Scale/promos (extension) | CELL-104 | Only if needed |
| 16 | Testing + Hardening | E2E, security, perf, backup | Tests | Coverage + audit pass |
| 17 | Deployment | Docker, CI, cloud deploy | Compose/CI | Deployable |

## Ordering Rule

- Foundation → Identity → Product → Inventory → Sales is the dependency chain; do not invert.
- Extensions (12-15) are optional, one at a time, only on demand.

## Per-Phase Checklist

```
Understand (cell spec) → Design (entities/APIs) → Document (update cell doc if needed)
→ Implement (Domain → Application → Infrastructure → Api) → Test (unit+api)
→ Review (arch unchanged?) → Integrate → Checkpoint (git + PROJECT_STATE)
```

## Risks & Mitigations

- Sync complexity → keep v1 simple (push/pull, no CRDT).
- Payment providers → isolate behind interface, no card data.
- Scope creep (ERP) — reject; extend via cells only when justified.

## Next Steps (immediate)

1. Backend scaffold: `dotnet new sln` + 4 projects + EF Core + JWT + Swagger.
2. Frontend scaffold: `flutter create` + l10n + theme + MoneyDisplay.
3. Docker compose (api+postgres).
4. Then PHASE-01 Foundation.

---

*Version 1.1 | Architecture: UNCHANGED | Level: L0*
