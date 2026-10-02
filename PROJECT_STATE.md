# PROJECT_STATE.md — POS Cloud Platform

> حالة المشروع المشتركة — يقرأها ويحدّثها كل AI Agents
> هذا الملف هو المرجع الحيّ للاستمرارية (Controlled Continuity) — لا تعيد فحص المشروع كاملاً، اقرأ هذا الملف فقط.

| البند | القيمة |
|-------|--------|
| Project | POS Cloud Platform |
| Version | 1.1 |
| Architecture | Approved Baseline |
| Architecture Status | UNCHANGED (Modular Monolith preserved — PHASE 32 did not alter architecture/stack) |
| Development Status | STABILIZED — POS READY FOR DOCKER DEPLOYMENT (PHASE 32 passed: build 0 err, tests 26/26, analyze 0, flutter test PASS, live smoke PASS) |
| Last Updated | 2026-10-02 (PHASE 32 — POS P0 stabilization + isolated Docker stack) |
| Updated By | Cline -- PHASE 32 branch `phase-32-pos-p0-docker` |
| Current Phase | PHASE-32 (POS P0 Stabilization + Docker Deployment) -- local stabilized; VPS deploy pending SSH |
| Current Cell | PHASE 32 closed P0 #1 (POSplan.doc recovered), P0 #2 (Flutter platform separation), P0 #3 (EF migrations accounting+JoInvoice), P0 #4 (Production seed guard) + hardening (CORS/AllowedHosts/ForwardedHeaders/uploads/CI .NET 10/packages) |
| Current Task | 32B COMPLETE: branch pushed `e13e432` + CI run 37047695245 GREEN (backend+frontend+docker) + tag pos-phase32-deploy-candidate → READY FOR PHASE 32C (VPS deployment per docs/DEPLOYMENT_RUNBOOK_PHASE32.md) |
| Blocked | VPS deployment step needs SSH credentials/access (standing task, not an architecture block) |

## Completed
- [x] Project Vision
- [x] Core Business Model
- [x] Technology Stack (Flutter + ASP.NET Core + PostgreSQL + SQLite)
- [x] Seven Layers
- [x] Engineering Cells (001-012 + 101-104)
- [x] Payment Engine (Method vs Provider)
- [x] Offline Architecture
- [x] UI/UX Principles + Design System + Adaptive UI
- [x] Multi-Agent Model
- [x] AI Agent Governance
- [x] Architectural Change Control
- [x] Checkpoint System + Git Strategy
- [x] Task Resumption Protocol + Minimal Context Loading
- [x] Master Specification stored in `docs/00_MASTER_SPECIFICATION.md`
- [x] Project scaffold created in `D:\POS`

## Next (DEP-001 — PRODUCTION READINESS)
- [x] Resolve P0 (5): JWT secret hard-fail in Production + [Authorize] on all controllers + CORS per-env + Swagger env-guard + error message redaction — CLOSED (DEP-002)
- [x] Resolve P1 (7): appsettings.Production.json + compose .env secrets + demo seed guard + tenant isolation ApiTests + Flutter AppConfig baseUrl + HTTPS/HSTS + logging scrubbing — CLOSED (DEP-002, 16/16 tests)
- [x] 01_ARCHITECTURE.md — Architecture Diagrams
- [x] 03_DATABASE.md — ERD + Entities
- [x] 02_ENGINEERING_CELLS.md — Cell Specifications
- [x] 04_API_SPECIFICATION.md — REST API Spec
- [x] 05_ALGORITHMS.md
- [x] 06_UI_UX.md — UI/UX Specification
- [x] 07_BUSINESS_CELLS.md — Business-specific Cells
- [x] 08_TESTING.md — Testing Strategy
- [x] 09_IMPLEMENTATION_PLAN.md
- [x] Backend scaffold (ASP.NET Core Modular Monolith) — Domain/Application/Infrastructure/Api + BaseEntity/Tenant/Branch/AuditLog + AppDbContext + Health + Swagger
- [x] Frontend scaffold (Flutter) — pubspec + main.dart
- [x] Docker / docker-compose — postgres + api
- [x] DEP-001 audit — docs/DEPLOYMENT_READINESS_AUDIT.md (P0/P1/P2/P3) — ver 2026-08-25
- [x] DEP-002 plan+resolution — P0=0 P1=0 (local 16/16)
- [x] DEP-003 staging verification -- docs/DEP-003-STAGING-VERIFICATION.md -- READY FOR STAGING (Docker 29.7.2 + Flutter 3.47.1, all gates PASS)

## Next Phase
- PHASE-17 PROMOTED: DEP-003 + Cell 018 f903113 CI GREEN (run 32896369066 success 20:37→20:38 UTC: backend build+test+fail-fast + frontend flutter pub get+analyze+test) → Development Status promoted READY FOR STAGING → READY FOR PRODUCTION (this L0 commit, no code/arch change)
- Next per DEP-001: cloud deploy (P2/P3 runbook FINDING-019 + business cells 101-104 ONLY on demand per Master Spec §51) — do NOT invent Cell 019
- See `docs/DEP-002-BLOCKER-RESOLUTION.md` for P0/P1 closure; `docs/DEP-003-STAGING-VERIFICATION.md` for staging gate; CI log: https://github.com/amoh873-eng/POS/actions/runs/32896369066
- CELL-018 hardens 005/006 (Description/MinStockLevel + tenant isolation + Balance via 019) — architecture UNCHANGED

## Coverage (file-level)
- Backend: all core cells 001-012 entities + controllers + AppDbContext + Seed + JWT + sale TX + inventory tx -- 0 warnings, 16 tests (Release 11+5 ApiTests green) -- P0/P1 closed (DEP-002), DEP-003 READY
- Frontend: Dashboard/POS/Products/Reports + ApiClient + SyncQueue + Theme + Nav + AppConfig (API_BASE_URL) -- flutter analyze/test/build web PASS (D:\flutter 3.47.1)
- Docs: 00-09 complete + DEP-001 audit + DEP-002 plan/resolution + DEP-003 verification (READY FOR STAGING)
- Tests: 11 unit + 5 ApiTests + 1 widget_test -- all PASS -- D:\flutter build/web exists

- Backend: all core cells 001-012 entities + controllers + AppDbContext + Seed + JWT + sale TX + inventory tx — 0 warnings, 16 tests (Release 11+5 ApiTests green) — P0/P1 closed (DEP-002)
- Frontend: Dashboard/POS/Products/Reports + ApiClient + SyncQueue + Theme + Nav + AppConfig (API_BASE_URL) — Flutter not on this host (CI will verify)
- Docs: 00-09 complete + DEP-001 audit + DEP-002 plan/resolution
- Tests: 11 unit + 5 ApiTests (tenant isolation + auth + fail-fast) — P2/P3 deferred

## Architectural Decisions (ADRs)
- ADR-001: Lightweight Modular Monolith — no microservices in v1
- ADR-002: Flutter + ASP.NET Core + PostgreSQL + SQLite — لا يغيّرها Agent دون موافقة L3
- ADR-003: Seven Layers are logical boundaries only

## Blocked`r`nNone -- READY FOR STAGING (Android/Windows doctor warnings NON-BLOCKING)`r`n
AWAITING STAGING VERIFICATION — Flutter SDK REQUIRED TOOL MISSING on this host (Docker/Postgres/API now healthy — see DEP-003 verification). Do not claim READY FOR STAGING until Flutter verifies.

## Checkpoints
- CP-2026-08-24-001: Initial scaffold — Master Spec extracted and stored
- CP-2026-08-24-002: PHASE-00 docs + backend/frontend scaffold committed
- CP-2026-08-24-003: Core domain expansion — awaiting dotnet SDK
- CP-2026-08-24-004: Auth JWT wiring + full CRUD controllers — PHASE-01 file-level near-complete
- CP-2026-08-24-005: Full scaffold to end — Purchases/Terminals/Shifts/StockCounts/Users/Roles + Seed + Flutter products/reports/theme + all phases 00-11 file-level — SDK build pending
- CP-2026-08-24-006: Hardening — Error/Audit middleware + BusinessCells 101-104 stubs + Login/Inventory screens + MoneyDisplay + CI workflow + docker-compose override — still awaiting dotnet/flutter SDK build
- CP-2026-08-24-007: Build green — dotnet 8.0.424 installed, PosCloud.sln fixed, PATH injected, middleware moved to Api, Sales qty fix, UserRole key, migrations 001_initial generated, build + tests pass (3/3) — commit 4edf957
- CP-2026-08-24-008: Extra screens (Settings/Customers) + widget_test + AuthTests (5 tests pass) — build+tests re-verified green
- CP-2026-08-24-009: POS full + 1+2+3+4+5 (inventory/credit/purchasing/reports) + refund + restaurant design 3-pane + business switcher 5 types + PWA installable — server on 0.0.0.0:5000 (192.168.100.15) — pushed to GitHub POS.git — 2026-08-24
- CP-2026-08-25-010: Hardening batch 1 — BCrypt seed fix + sample data + TenantsController + Program.cs Migrate on UseInMemory=false + BranchesController tid fallback + Flutter main/Dashboard/POS/Reports/Settings/Customers wired + ApiClient+SyncQueue+Theme — build green 11/11 tests — UseInMemory false ready for docker postgres
- CP-2026-08-25-011: Hardening batch 2 — Products/Reports tid fallback + docker healthcheck (postgres+api) + Jwt 32+ + api_client empty-body guard + Inventory/Products tid dynamic — build green — 2 commits ahead of origin
- CP-2026-08-25-012: Hardening batch 3 — Sales/Customers/Suppliers/Purchases/Sync full ResolveTid + AuthController zero-warnings + widget_test fixed — build 0 warnings 11 tests green — ready for PHASE-17
- CP-2026-08-25-013: DEP-001 READINESS AUDIT (read-only) — docs/DEPLOYMENT_READINESS_AUDIT.md + Findings companion — 5×P0 + 7×P1 + 7×P2 + 3×P3 — PRODUCTION READINESS: BLOCKED — no arch conflict — project status set to AUDITED/BLOCKED
- CP-2026-08-25-014: DEP-002 P0/P1 RESOLUTION — P0=0 P1=0 locally — appsettings env split + JWT fail-fast + [Authorize]×15 + CORS per-env + Swagger guard + error redaction + compose .env + demo guard + audit/correlation + ApiTests (5) + HTTPS/HSTS + Flutter AppConfig — dotnet 16/16 — docs/DEP-002-BLOCKER-PLAN/RESOLUTION — awaiting staging host
- CP-2026-08-25-015: DEP-003 STAGING VERIFICATION — live verification on this host — dotnet 16/16 PASS, appsettings.json CHANGE_ME → __REQUIRED__ fixed, Docker/Flutter NOT VERIFIED (missing tools) — AWAITING STAGING HOST — docs/DEP-003-STAGING-VERIFICATION.md
- CP-2026-08-25-016: DEP-003 (continued) -- Docker 29.7.2 READY -- backend/Dockerfile verified -- docker compose config/build/up PASS, postgres+api healthy, /health 200, /api 200, products 401 anon / 200 authed, swagger 404, login 200, SeedData minimal fix verified, dotnet 16/16 -- Flutter verified at end of this round
- CP-2026-08-25-017: DEP-003 FLUTTER -- D:\flutter 3.47.1 LIVE -- customers_screen widget.api fix + sync_queue + pos_screen braces + web platform -- flutter analyze PASS (No issues), flutter test PASS (1/1), flutter build web PASS (build/web) -- AppConfig intact -- DEP-003 READY FOR STAGING
- CP-2026-08-25-018: CELL-018 Products+Inventory -- tenant isolation FIX (Inventory Adjust/Movement/Transfer + Products Delete/Create), DesignTimeFactory env-only, migration 018 Products-only + 019 Balance, 4 tenant-isolation ApiTests -- git diff/check clean -- f903113 feat(products): complete products and inventory core -- pushed origin/master (HEAD==origin) -- backend CI PASS / frontend rate-limited manual check https://github.com/amoh873-eng/POS/actions/runs/32896369066
- CP-2026-08-25-019: PHASE-17 CONTINUITY -- Cell 019 determined UNDEFINED per 00/02/09 docs (no approved scope, 001-012 already hardened) -- no code change; PROJECT_STATE.md synced to reflect continuity -- CI for Cell 018 then GREEN → cleared for promotion
- CP-2026-08-25-020: PHASE-17 L0 PROMOTION -- GitHub Actions 32896369066 GREEN verified (status completed, conclusion success, backend+frontend success, head_sha f9031136a4eed46f6fb4f8796f12b03a13088472) -- PROJECT_STATE.md promoted READY FOR STAGING → READY FOR PRODUCTION (L0 doc-only, no controller/domain/migration/test/flutter/docker/CI/arch change) -- Cell 019 remains UNDEFINED
- CP-2026-10-02-021: PHASE-32 POS P0 STABILIZATION -- branch `phase-32-pos-p0-docker` (safety snapshot `git stash create` 6a01322a) -- P0-1 POSplan.doc recovered from blob 6e9eaa (65,004 B, commit fc38f48) -- P0-2 Flutter platform separation (conditional imports: printer_settings_io_*/web_print_io_*; dart:html/dart:js confined to web-only files) -- flutter analyze 45→0, flutter test PASS, flutter build web PASS -- P0-3 EF migration `20261002170343_accounting_joinvoice_phase32` (accounts/journal_entries/journal_entry_lines + Sale/TenantSettings JoInvoice + Customer TaxId/NationalId/Address + FKs/indexes); model↔migrations in sync; `backend/migrations-pos-cloud.sql` generated -- P0-4 Production seed guard (SeedDemoData=false → no demo tenant/admin/products/sales/password-reset) -- JoInvoice disabled-by-default + credentials fail-safe (no fake keys) -- packages realigned (NU1603 cleared; SQLitePCLRaw pinned 2.1.11 — advisory fix beyond 2.1.x needs online feed, documented) -- ForwardedHeaders KnownIPNetworks, CORS single policy, AllowedHosts fail-fast, uploads unified to configurable root (Docker volume /app/uploads) + magic-byte validation -- CI → .NET 10 + migration sync gate -- Docker: backend Dockerfile (.NET 10, non-root app user, healthcheck) + frontend Dockerfile (Flutter web → nginx SPA+proxy) + isolated compose (`pos-cloud` namespace: pos-net/pos-db/pos-api/pos-web, volumes pos-pgdata/pos-uploads, ports 8103/8104) -- backend build 0 errors, tests 26/26, live smoke /health 200 /api 200 login 200 -- docs: DEPLOYMENT_RUNBOOK_PHASE32.md + DEPLOYMENT_STATUS.md -- VPS deploy pending SSH (required: /home/dev/pos-cloud) -- Architecture UNCHANGED
- CP-2026-10-02-022: PHASE-32B GITHUB+CI GATE -- pushed `phase-32-pos-p0-docker` (HEAD e13e432 = 6c42e0f + CI gates + compose quoting fix + flutter image pin ghcr 3.44.0); CI run 37047695245 **GREEN** (backend: build+test 26/26+fail-fast+migrations sync+security scan / frontend: analyze 0+test+web build / docker: compose config+API build+Web build) -- least-privilege `contents: read` -- tag `pos-phase32-deploy-candidate` → e13e432 pushed -- no secrets in tree, master UNTOUCHED -- VPS deployment remains **PENDING (PHASE 32C)** -- Architecture UNCHANGED

## How to Resume
1. Read this file
2. Read `docs/00_MASTER_SPECIFICATION.md` section relevant to your task
3. Read `docs/<relevant>.md` for your cell
4. Continue from Current Phase/Cell/Task — do NOT re-analyze everything

## Agent Rules Reminder
- L0/L1: Agent may proceed
- L2/L3: Requires review / explicit approval — stop and report conflict
- Every meaningful unit: git status → diff → tests → commit → update this file
