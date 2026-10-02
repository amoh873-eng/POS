# DEPLOYMENT_STATUS.md — POS Cloud (PHASE 32)

> Status as shipped by PHASE 32 stabilization. Update on every real VPS deployment.
> No secrets in this file.

| Field | Value |
|---|---|
| Application | POS Cloud Platform (isolated `pos-cloud` stack) |
| Commit | `—` (set to the PHASE 32 commit SHA after push) |
| Server | OVH VPS (same host as ERP, separate namespace) |
| Deployment path | `/home/dev/pos-cloud/` |
| Docker network | `pos-net` (isolated; never joins erp/owner nets) |
| API container | `pos-api` (image `pos-cloud-api:phase32`, non-root `app` user) |
| Web container | `pos-web` (image `pos-cloud-web:phase32`, nginx SPA+proxy) |
| DB container | `pos-db` (postgres:16-alpine) |
| DB name | `POSCloudDb` (user `poscloud`) |
| DB volume | `pos-uploads` → images; `pos-pgdata` → database |
| Selected host port | API `8103` / Web `8104` — **verify free on VPS before final choice** |
| Health endpoint | `GET /health` (API) and `GET /health` via Web proxy |
| Frontend URL/IP | `http://<VPS-IP>:8104/` |
| Backup location | `/home/dev/server-backups/pos/` |
| DR status | Backup tested in isolated restore env (`owner-recovery-pos-*`), never on live `pos-db` |
| Owner instance ID | `pos-cloud` (registered read-only — Phase 32) |
| Deployment time | `—` |

## Verification (local, this machine — run before VPS push)

| Gate | Result |
|---|---|
| `dotnet build -c Release` (SDK 10.0.400) | ✅ 0 errors |
| `dotnet test --no-build -c Release` | ✅ 26/26 (11 unit + 15 API) |
| EF model ↔ migrations in sync | ✅ `has-pending-model-changes` = none |
| PostgreSQL migration SQL generation | ✅ `backend/migrations-pos-cloud.sql` (5 migrations, transactional) |
| Production seed guard | ✅ no demo tenant/admin/products when `SeedDemoData=false` |
| Jo-Invoice | ✅ disabled + credentials-required fail-safe; no fake keys |
| `flutter analyze` | ✅ 0 issues |
| `flutter test` | ✅ 1/1 |
| `flutter build web --release` | ✅ build/web |
| Live smoke (Development/InMemory) | ✅ /health 200, /api 200, login 200 |
| CORS / AllowedHosts / ForwardedHeaders | ✅ cleaned + fail-fast in Production |

## Known limitations (documented, PHASE 32)

1. `SQLitePCLRaw.lib.e_sqlite3 2.1.11` still flagged (GHSA-2m69-gcr7-jv3q) by the local
   offline NuGet feed; a fully patched version or SQLitePCLRaw 3.x migration requires
   online restore. Not a runtime path used by the production stack (PostgreSQL).
2. Jo-Invoice remains intentionally NOT production-ready: ISTD compliance requires a
   dedicated verification phase (credentials, UBL schema, environment validation).
3. VPS deployment (compose build/up, health checks, Owner read-only registration,
   backup+DR on the VPS) requires SSH access — executed in the next step after this
   commit lands and credentials are provided.
