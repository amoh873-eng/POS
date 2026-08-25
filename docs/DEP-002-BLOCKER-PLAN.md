# DEP-002 — BLOCKER PLAN

> المصدر: `DEPLOYMENT_READINESS_AUDIT.md` + `DEPLOYMENT_READINESS_FINDINGS.md` (CP-013)
> التاريخ: 2026-08-25 | الحالة: AUDITED — BLOCKED | القاعدة: P0 أولاً ثم P1، مع مراعاة التبعيات

## التبعيات والترتيب الآمن

- P1-1 (appsettings فصل البيئات) يمهّد لـ P0-1 (fail-fast للمفتاح).
- P0-3 (CORS) و P0-4 (Swagger) يعتمدان على P1-2/P1-3 (compose .env + بيئة Production).
- لذا الترتيب التنفيذي المعتمد: **P1-1 → P0-1 → P0-2 → P0-3 → P0-4 → P0-5 → P1-2+P1-3 → P1-4 → P1-5 → P1-6 → P1-7**
- لا تغيير معماري — أي حاجة لتغيير tenancy/DB/offline/cells/stack تُوقف كتضارب.

## P0 — Critical (5)

### P0-1 — JWT fallback CHANGE_ME
- ID: P0-1 | Problem: مفتاح JWT يسقط على قيمة عامة معروفة.
- Root cause: `Program.cs:11` `?? "CHANGE_ME"`؛ `appsettings.json:8`؛ `compose:22`.
- Files: `Program.cs`, `appsettings.json`, `docker-compose.yml`
- Fix: إزالة السقوط؛ في Production ارمِ `InvalidOperationException("Jwt:Key missing")`؛ env/KeyVault؛ >=32 بايت؛ fail-fast.
- Security: تجاوز مصادقة كامل. Data: لا. Regression: منخفض.
- Tests: Production بلا مفتاح → فشل؛ مع مفتاح → login OK؛ مزور → 401. Verify: `ASPNETCORE_ENVIRONMENT=Production dotnet run`.

### P0-2 — Zero [Authorize]
- Problem: لا `[Authorize]` — وصول مجهول.
- Root cause: `AddAuthorization()` بلا تطبيق؛ 20 controller بلا حماية.
- Files: `Controllers/*.cs` (20), `Program.cs`
- Fix: `[Authorize]` على كل controller؛ `[AllowAnonymous]` فقط Login/Refresh/Health.
- Tests: Unauthed `GET /api/products` → 401؛ authed → 200؛ cross-tenant → 403/404.

### P0-3 — CORS AllowAnyOrigin
- Problem: سياسة تسمح بأي origin.
- Root: `Program.cs:9` + `UseCors("all")` غير مشروط.
- Files: `Program.cs`, `appsettings.*.json`, `docker-compose.*.yml`
- Fix: `Cors:AllowedOrigins` لكل بيئة؛ لا `AllowAnyOrigin` في الإنتاج.
- Tests: Preflight محظور → مرفوض.

### P0-4 — Swagger in Production
- Problem: `UseSwagger/UseSwaggerUI` بلا حارس.
- Root: `Program.cs:41-42`؛ compose يفرض `Development`.
- Files: `Program.cs`, `docker-compose.yml`
- Fix: `if (IsDevelopment())`; الأساس Production.

### P0-5 — Error leaks ex.Message
- Problem: `ErrorHandlingMiddleware.cs:16` يعيد الخام.
- Fix: Generic + traceId في الإنتاج؛ log كامل server-side.

## P1 — Production Blockers (7)

### P1-1 — No env split (مقدم كتمهيد)
- Problem: فقط `appsettings.json` (localhost + placeholder).
- Files: `appsettings.json`, `Program.cs`, جديد `appsettings.*.json`
- Fix: إنشاء `Development` + `Production`؛ الأخير يتطلب env ويُفشل سريعاً.

### P1-2/3 — Compose hard-coded secrets + Development default
- Problem: `POSTGRES_PASSWORD=postgres` + `Jwt__Key=CHANGE_ME`; env Development في الأساس.
- Files: `docker-compose.yml`, `docker-compose.override.yml`, `.env.example` جديد
- Fix: `${POSTGRES_PASSWORD}` / `${JWT_KEY}` من `.env`؛ الأساس Production.

### P1-4 — Demo credentials seeded always
- Problem: `SeedData.cs:13,24` + استدعاء غير مشروط.
- Files: `SeedData.cs`, `Program.cs`
- Fix: فقط عند `IsDevelopment()` أو `SeedDemoData=true`.

### P1-5 — No scrubbing policy
- Files: `AuditMiddleware.cs`, `Program.cs` (correlation)
- Fix: Never-log list + `X-Correlation-ID`.

### P1-6 — No tenant isolation API tests
- Problem: 11 وحدة فقط.
- Files: `backend/tests/PosCloud.ApiTests/*` جديد، `PosCloud.sln`, `ci.yml`
- Fix: `WebApplicationFactory` isolation suite.

### P1-7 — No HTTPS/HSTS/ForwardedHeaders
- Files: `Program.cs`, docs
- Fix: `UseHsts()` في Production + `ForwardedHeadersOptions`; توثيق TLS في proxy.

### P1-7 alt — Flutter base URL localhost (FINDING-013)
- Evidence: `main.dart:23` `ApiClient('http://localhost:5000')`.
- Fix: `AppConfig.baseUrl` via `--dart-define=API_BASE_URL`.
- ملاحظة عدّ: إذا اعتُبرت 012 هي P1-7، فـ Flutter يُرحل كـ P2 لاحقاً؛ سيُوثق عند التنفيذ.



