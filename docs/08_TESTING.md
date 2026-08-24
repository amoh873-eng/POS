# 08_TESTING.md — POS Cloud Platform v1.1

> Testing strategy — PHASE-00 | Lightweight, cell-focused

---

## Levels

- **Unit:** Domain rules, algorithms (totals, stock, sync queue) — no DB.
- **Application:** Service + validation with in-memory or Testcontainers (Postgres) — per cell.
- **API:** Controller + auth + validation via `WebApplicationFactory` — happy + 401/403/422.
- **E2E (later):** Flutter driver + API full flow (create sale → refund → report).

## Per-Cell Minimum (Definition of Done)

```
entities OK + validators OK + service OK + controller OK
+ 5-10 unit tests + 3-5 API tests
+ no arch violation
```

## Must-Test Scenarios (core)

- Sale: totals server-side, insufficient stock 422, payment mismatch 422, idempotency.
- Inventory: no negative without adjust, transfer dual movements, count diff.
- Auth: lockout, refresh rotation, tenant isolation (cross-tenant 404/403).
- Sync: pending → synced, failed retry, last-write-wins for master data.

## Tooling

- Backend: `xUnit` + `FluentAssertions` + `WebApplicationFactory` + `Testcontainers.PostgreSql` (or in-memory for unit).
- Frontend: `flutter test` widget + unit; `integration_test` for POS flow.

## CI (PHASE-16)

`dotnet test` + `flutter test` on push; fail on broken. Coverage target >70% core.

---

*Status: UNCHANGED*
