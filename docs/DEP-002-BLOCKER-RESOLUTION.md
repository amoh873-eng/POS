# DEP-002 — BLOCKER RESOLUTION (CP-014)

> يوثق إغلاق 5×P0 و 7×P1 من `DEPLOYMENT_READINESS_AUDIT.md` (CP-013). المرجع: `DEP-002-BLOCKER-PLAN.md`.
> التاريخ: 2026-08-25 | P0=0, P1=0 محلياً (dotnet 16/16) | Docker/Flutter يُتحقق على مضيف SDK | البنية Approved Baseline لم تتغير

## الملخص

- كل P0/P1 أُغلق بأصغر إصلاح آمن. لا تضارب معماري — لم يُنشأ `ARCHITECTURAL_CONFLICT_REPORT.md`.
- التحقق المحلي: `dotnet build -c Release` 0W/0E، `dotnet test` 16/16 (11 وحدة + 5 ApiTests).
- Docker/Flutter غير مثبتين على هذا المضيف — الملفات صحيحة وتُتحقق في CI/Host.

## التفصيل — P0 (5)

**P0-1 JWT** — `Program.cs` يرمي `Jwt:Key missing` في Production عند placeholder/غياب؛ >=32 حرف؛ متغير البيئة `Jwt__Key`؛ `appsettings.Production.json` حامل `__REQUIRED__`. ملفات: `Program.cs`, `appsettings.*.json`, `docker-compose.yml`. اختبار: `ASPNETCORE_ENVIRONMENT=Production` بدون مفتاح → فشل؛ ApiTests تؤكد.

**P0-2 [Authorize]** — أُضيف `[Authorize]` لكل 15 controller؛ `Auth Login/Refresh` و `Health` و `/api` و `/health` بـ `AllowAnonymous` صراحة. ملفات: `Controllers/*.cs` (15) + `AuthController`. اختبار: Unauthed 401؛ health 200.

**P0-3 CORS** — قراءة `Cors:AllowedOrigins[]`؛ Development يملأ localhost؛ Production فارغ (لا origin حتى يُضبط). ملفات: `Program.cs`, `appsettings.*.json`.

**P0-4 Swagger** — ملفوف بـ `if (IsDevelopment())`; compose الأساس صار `Production`. ملفات: `Program.cs`, `compose`.

**P0-5 Error** — `ErrorHandlingMiddleware` يحجب الرسالة في Production + `traceId`؛ `CorrelationIdMiddleware` يضيف `X-Correlation-ID`. ملفات: `ErrorHandlingMiddleware.cs`, `CorrelationIdMiddleware.cs` جديد.

## التفصيل — P1 (7)

**P1-1 env split** — أُنشئ `appsettings.Development/Production.json`؛ `.gitignore` أُصلح ليُحفظ Development؛ Production يتطلب `ConnectionStrings:Default` + `Jwt:Key` وإلا fail-fast.

**P1-2/3 Compose** — `docker-compose.yml` يستخدم `${POSTGRES_PASSWORD:?required}` و `${JWT_KEY:?required}` و `Production`؛ override يعيد `Development` + pgadmin. ملف جديد `.env.example`.

**P1-4 Demo seed** — `SeedData.SeedAsync(db, seedDemo)`؛ `Program.cs` يمرر `SeedDemoData ?? IsDevelopment()`.

**P1-5 Scrubbing** — `AuditMiddleware` يوثق never-log + correlationId؛ `CorrelationIdMiddleware` يضبط الهيدر.

**P1-6 ApiTests** — مشروع `PosCloud.ApiTests` بـ `WebApplicationFactory<Program>` (InMemory) — 5 اختبارات؛ `Program` صار partial للـ factory؛ `.sln` و `ci.yml` محدثان.

**P1-7 HTTPS/HSTS** — `UseHsts()` + `UseHttpsRedirection()` خارج Development؛ `ForwardedHeadersOptions` مع Clear()؛ TLS موثق في proxy.

**P1-7 alt Flutter** — `app_config.dart` `String.fromEnvironment('API_BASE_URL')`؛ `main.dart` يستخدمه؛ `ci.yml` يختبر `dart-define`.

## التحقق النهائي المحلي

- `dotnet build -c Release` 0W/0E ✅
- `dotnet test -c Release` 16/16 ✅
- `docker compose config/build/up` — غير قابل هنا (Docker غير مثبت) — الملفات صحيحة وتشترط `.env`.
- `flutter analyze/test` — غير مثبت هنا — يُتحقق في CI.

## ما تبقى (P2/P3 مؤجل)

- FINDING-014 SyncQueue, 017 PWA icons, 018 override, 019 runbook, 021 Pull since, 015 ordering — كلها P2/P3 لا تمنع staging (P2-016 Swagger JWT و P2-022 rate limit أُغلقا مبكراً في هذا الدفعة).



