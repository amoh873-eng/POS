# 01_ARCHITECTURE.md — POS Cloud Platform v1.1

> Architecture Diagrams + Logical Views — PHASE-00
> Status: Architecture Baseline | Stack: Flutter + ASP.NET Core + PostgreSQL/SQLite | Modular Monolith

---

## 1. Context View (C1)

```
  [Customer: Retail/Restaurant/Bakery/Pharmacy/Supermarket]
                          |
                    +-----+-----+
                    | Flutter POS |  (Android/iOS/Desktop/Web)
                    +-----+-----+
                          | REST/JWT (+ SignalR later)
                    +-----+-----+
                    | PosCloud.Api |  (ASP.NET Core Modular Monolith)
                    +-----+-----+
                          | EF Core
                    +-----+-----+
                    | PostgreSQL |  (Cloud)  +  SQLite (local on device)
                    +-----------+
                          |
                    External Providers (Payment Provider A/B — isolated)
```

## 2. Container View (C2) — Modular Monolith

```
PosCloud.Api (single deployable)
 ├── L7 Presentation (Flutter separately, API controllers here)
 ├── L6 Application (use-cases, DTOs, validators)
 ├── L5 Domain (entities, business rules)
 ├── L4 Engineering Cells (logical modules — NOT microservices)
 │    001 Foundation | 002 Identity | 003 Business | 004 Branch
 │    005 Product | 006 Inventory | 007 Customer | 008 Supplier
 │    009 Sales | 010 Payment | 011 Purchasing | 012 Reporting
 │    101 Restaurant | 102 Bakery | 103 Pharmacy | 104 Supermarket (extensions)
 ├── L3 Infrastructure (EF Core, PostgreSQL, SQLite sync, storage)
 ├── L2 Communication (REST, Sync Queue, future integrations)
 └── L1 Platform (OS, Docker, Cloud, Security infra)
```

**Rule:** Cells are **logical boundaries inside one backend**. No separate deployments in v1. Communication via clear contracts, not direct internal manipulation.

## 3. Seven Layers — Lightweight

```
L7 Presentation → Flutter screens/widgets/navigation/themes (+ API controllers as thin adapters)
L6 Application  → Use-cases / services per cell, orchestration, transactions
L5 Domain       → Entities + value objects + domain rules (no infra deps)
L4 Cells        → Grouping of L5+L6 per capability (same process, separate folders)
L3 Infrastructure → DbContext, repositories, file/storage, hardware adapters
L2 Communication → REST API, Sync Queue, webhooks/provider adapters
L1 Platform     → Hosting, Docker, secrets, TLS, backup, observability
```

Physical mapping (v1):
```
backend/src/PosCloud.Domain        → L5
backend/src/PosCloud.Application   → L6 (+ L4 grouping by folder)
backend/src/PosCloud.Infrastructure→ L3 + L2 impl
backend/src/PosCloud.Api           → L7 (controllers) + composition root
frontend/                          → L7 (Flutter)
```

No extra projects for every cell — folder grouping is enough until justified.

## 4. Offline / Sync

```
Flutter  → SQLite (local truth when offline)
        → Sync Queue [ Pending → Synced | Failed (retry) ]
        → Cloud API → PostgreSQL (cloud truth)
```

v1: simple queue, no Event Sourcing. Poll/push on connectivity restore. Conflict: last-write-wins for POS ops; sales are append-only (no edit after sync without audit).

## 5. Multi-Tenancy (v1 — logical isolation)

```
Tenant (business)
 └── Branch(es)
      └── Users / Terminals / Inventory / Sales (all FK TenantId + BranchId)
```

Every tenant-scoped table has `TenantId` (and usually `BranchId`). Queries filtered by tenant. No cross-tenant access. Index on `(TenantId, BranchId)`.

## 6. Payment Boundary (Method vs Provider)

```
Sale → PaymentEngine (method: Cash/Card/Transfer/Electronic/Credit/Mixed/Partial/Refund)
              |
              +→ IPaymentProvider (adapter) → Provider A / B / future
```

Sale module never contains provider-specific code. Sensitive card data NOT stored; token/reference only if required.

## 7. Security — Foundation

Auth: JWT (short-lived) + Refresh Token (rotated, stored hashed). Passwords: Argon2id/bcrypt. Tenant isolation + role/capability checks per endpoint. Input validation, HTTPS everywhere, audit log (see §9), secrets via env/KeyVault, daily backup.

## 8. Deployment View (v1)

```
Cloud: Docker → API + PostgreSQL (managed) + reverse proxy + TLS
Device: Flutter app with embedded SQLite
Sync: HTTPS REST; SignalR added only when real-time required (KDS etc.)
```

`docker-compose.yml` for local dev: `api + postgres + pgadmin` (optional).

## 9. Cross-Cutting

- Audit: login/logout, sale/refund/payment, price change, permission change — no secrets in logs.
- Observability: structured logs + correlation id + health checks (`/health`).
- Config before Dynamic UI: logo/name/colors/language/currency/receipt template in Tenant settings.

## 10. ADRs (from Master Spec)

ADR-001 Modular Monolith (no microservices v1) | ADR-002 Stack locked | ADR-003 Cells logical | ADR-004 Offline required | ADR-005 Payment in core | ADR-006 Limited UI config | ADR-007 Agents cannot change arch | ADR-008 State+Checkpoints | ADR-009 Minimal Context Loading

---

*Next: `02_ENGINEERING_CELLS.md`, `03_DATABASE.md`, `04_API_SPECIFICATION.md`*
*Architecture Status: UNCHANGED | Level: L0 doc*
