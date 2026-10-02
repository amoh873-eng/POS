# DEPLOYMENT_STATUS.md — POS Cloud (PHASE 32 / 32B)

> Status as shipped by PHASE 32 stabilization + PHASE 32B GitHub/CI gate.
> No secrets in this file.
> **VPS deployment is PENDING — not yet performed (PHASE 32C).**

| Field | Value |
|---|---|
| Application | POS Cloud Platform (isolated `pos-cloud` stack) |
| GitHub repository | `https://github.com/amoh873-eng/POS` (default branch `master` — untouched) |
| Working branch | `phase-32-pos-p0-docker` |
| Local commit | `6c42e0f` (PHASE 32 stabilization) + follow-ups to `e13e432` |
| Remote commit | `e13e43221ef140d770522dbcb7a7b9ec2a9254c7` (verified via `ls-remote`) |
| Deployable candidate | tag `pos-phase32-deploy-candidate` → `e13e432` |
| CI workflow | `.github/workflows/ci.yml` (backend / frontend / docker jobs) |
| CI run | `37047695245` |
| CI conclusion | **SUCCESS** (backend ✅ frontend ✅ docker ✅) on `e13e432` 2026-10-02T18:28:43Z |
| Server | OVH VPS (same host as ERP, separate namespace) — PENDING |
| Deployment path | `/home/dev/pos-cloud/` — PENDING |
| Docker network | `pos-net` (isolated; never joins erp/owner nets) |
| API container | `pos-api` (image `pos-cloud-api:phase32`, non-root `app` user) |
| Web container | `pos-web` (image `pos-cloud-web:phase32`, nginx SPA+proxy) |
| DB container | `pos-db` (postgres:16-alpine) |
| DB name | `POSCloudDb` (user `poscloud`) |
| DB volume | `pos-uploads` → images; `pos-pgdata` → database |
| Selected host port | API `8103` / Web `8104` — **verify free on VPS** |
| Health endpoint | `GET /health` (API) and `GET /health` via Web proxy |
| Frontend URL/IP | `http://<VPS-IP>:8104/` — PENDING |
| Backup location | `/home/dev/server-backups/pos/` — PENDING |
| DR status | Runbook prepared; isolated restore test — PENDING |
| Owner instance ID | `pos-cloud` (read-only registration — PHASE 32C pending) |
| Deployment time | — PENDING |

## Verification (executed locally + verified by GitHub Actions)

| Gate | Local | GitHub Actions (run 37047695245) |
|---|---|---|
| `dotnet build -c Release` (SDK 10.0.400) | ✅ 0 errors | ✅ backend job |
| `dotnet test --no-build -c Release` | ✅ 26/26 (11+15) | ✅ backend job |
| EF model ↔ migrations in sync | ✅ `has-pending-model-changes` = none | ✅ backend job |
| Production seed guard / fail-fast | ✅ | ✅ backend job |
| Security scan (no committed secrets) | ✅ | ✅ backend job |
| `flutter analyze` | ✅ 0 issues | ✅ frontend job |
| `flutter test` | ✅ 1/1 | ✅ frontend job |
| `flutter build web --release` | ✅ | ✅ frontend job |
| Docker compose config | ✅ (YAML quoting fixed) | ✅ docker job |
| Docker images build (API + Web) | ✅ (Dockerfile validated) | ✅ docker job (flutter image pinned ghcr `3.44.0`) |
| Live smoke (Development/InMemory) | ✅ /health 200, /api 200, login 200 | — |

## Known limitations (documented, PHASE 32/32B)

1. `SQLitePCLRaw.lib.e_sqlite3 2.1.11` still flagged (GHSA-2m69-gcr7-jv3q) by the local
   offline NuGet feed; a fully patched version or SQLitePCLRaw 3.x migration requires
   online restore. Not a runtime path in the production stack (PostgreSQL).
2. Jo-Invoice remains intentionally NOT production-ready: ISTD compliance requires a
   dedicated verification phase.
3. Docker Flutter build image pinned to `ghcr.io/cirruslabs/flutter:3.44.0` (the newest
   published stable tag); local SDK 3.47.1 is newer — acceptable, review on next bump.
4. **VPS deployment (PHASE 32C) is PENDING** — deploy `e13e432` / tag
   `pos-phase32-deploy-candidate` per `docs/DEPLOYMENT_RUNBOOK_PHASE32.md`, then
   run the smoke/backup/DR/Owner-read-only checklist. Deploy step requires SSH access.

