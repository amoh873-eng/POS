# DEPLOYMENT READINESS — DETAILED FINDINGS (DEP-001 Companion)

> Companion to `DEPLOYMENT_READINESS_AUDIT.md`. Each finding: Problem, Evidence, File, Risk, Fix, Test.

## P0 — Critical Blockers

### FINDING-001 — JWT `CHANGE_ME` fallback — P0
- Problem: Production JWT signing key has weak public default.
- Evidence: `Program.cs:11` `builder.Configuration["Jwt:Key"] ?? "CHANGE_ME..."`; `appsettings.json:8`; `docker-compose.yml:22`.
- File: `Program.cs`, `appsettings.json`, `docker-compose.yml`
- Risk: Forged admin tokens, tenant impersonation.
- Fix: Throw `InvalidOperationException("Jwt:Key missing")` in Production; env/KeyVault; >=32 random bytes; fail-fast.
- Test: Start without `Jwt:Key` in Production → fail; valid key → login OK; forged → 401.

### FINDING-002 — Zero [Authorize] — P0
- Evidence: `Select-String "[Authorize]"` → 0 hits; `AddAuthorization()` never applied.
- File: `Controllers/*.cs`, `Program.cs`
- Risk: Anonymous reads/writes.
- Fix: `[Authorize]` at controller/base level; `[AllowAnonymous]` only on Login/Refresh/Health.
- Test: Unauthed `GET /api/products` → 401; authed → 200.

### FINDING-003 — CORS AllowAnyOrigin global — P0
- Evidence: `Program.cs:9` + `app.UseCors("all")` unconditional.
- Risk: Cross-site exfiltration.
- Fix: `Cors:AllowedOrigins` per env; never `AllowAnyOrigin` in prod.

### FINDING-004 — Swagger exposed in Production — P0
- Evidence: `Program.cs:41-42` unconditional; compose forces `Development`.
- Fix: Guard with `if (IsDevelopment())`; base compose → Production.

### FINDING-005 — Error middleware leaks ex.Message — P0
- Evidence: `ErrorHandlingMiddleware.cs:16`.
- Fix: Generic + traceId in Production; log full server-side.

## P1 — Production Blockers

### FINDING-006 — No appsettings.Production.json — P1
- Evidence: `appsettings.Development.json` not found.
- Fix: Create Development + Production files; require env in Production.

### FINDING-007 — Compose ships hard-coded secrets — P1
- Evidence: `docker-compose.yml:5-7,19-22` `POSTGRES_PASSWORD=postgres`.
- Fix: `${POSTGRES_PASSWORD}` / `${JWT_KEY}` from `.env` (gitignored).

### FINDING-008 — Base compose defaults to Development — P1
- Fix: Base → Production; override → Development.

### FINDING-009 — Demo credentials seeded in all envs — P1
- Evidence: `SeedData.cs:13,24` always.
- Fix: Guard with `IsDevelopment()` or `SeedDemoData` flag.

### FINDING-010 — No scrubbing policy — P1
- Evidence: `AuditMiddleware.cs` only Method+Path but unguarded future.
- Fix: Never-log list + `X-Correlation-ID`.

### FINDING-011 — No tenant isolation API tests — P1
- Evidence: 11 unit only; no `WebApplicationFactory`.
- Fix: Add `PosCloud.ApiTests` with isolation suite.

### FINDING-012 — No HTTPS/HSTS/ForwardedHeaders — P1
- Fix: Document TLS at reverse proxy; `UseHsts()` in Production.

### FINDING-013 — Flutter base URL hard-coded localhost — P1
- Evidence: `main.dart:23` `ApiClient('http://localhost:5000')`.
- Fix: `AppConfig.baseUrl` via `--dart-define=API_BASE_URL`.

## P2/P3 — Important/Improvement

### FINDING-014 — SyncQueue in-memory only — P2
- Evidence: `sync_queue.dart` no sqflite.
- Fix: Persist + retry.

### FINDING-015 — Error middleware ordering — P2
- Evidence: `Program.cs:45-49` not outermost.
- Fix: Move to top; add correlation.

### FINDING-016 — Swagger no JWT Bearer — P2
- Evidence: `Program.cs:8` bare `AddSwaggerGen()`.

### FINDING-017 — PWA manifest incomplete — P3
- Evidence: `wwwroot/manifest.json` inline SVG.
- Fix: Flutter `web/manifest.json` canonical.

### FINDING-018 — docker-compose.override minimal — P3
- Evidence: Only pgadmin.

### FINDING-019 — Migration runbook missing — P2
- Evidence: `001_initial` auto-migrates, no docs.
- Fix: Document auto-migrate + `pg_dump` daily.

### FINDING-020 — PROJECT_STATE.md stale — P2
- Evidence: Duplicate headers; old Next section.
- Fix: Normalized via CP-013.

### FINDING-021 — SyncController.Pull ignores since — P2
- Evidence: `SyncController.cs:32-35`.

### FINDING-022 — No rate limiting on login — P2
- Evidence: `AuthController.cs` per-user only.
- Fix: `PartitionedRateLimiter` per IP.

