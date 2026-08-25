# DEP-003 — STAGING VERIFICATION GATE

> تاريخ: 2026-08-25 | مُحقق: Cline | مرجع: `e6a5c87` (DEP-002) + تصحيح `appsettings.json` اللاحق | البنية Approved Baseline UNCHANGED

## الخلاصة (عربي)

**VERIFICATION حقيقي — ليس محاكاة.**

**النتيجة: لم يُعلن `READY FOR STAGING`. الحالة: `AWAITING STAGING VERIFICATION` (معلق بسبب أدوات مفقودة).**

- P0=0, P1=0 محلياً (dotnet) — كل الحواجز الـ 12 أُغلقت في DEP-002 وتأكدت هنا.
- Backend: `dotnet build -c Release` 0W/0E، `16/16` اختبار — نجح.
- Docker + PostgreSQL + Flutter: **غير متوفرة على هذا الجهاز** — `docker --version` / `flutter --version` / `dart --version` تُرجع `not recognized`. حسب DEP-003: يُسجل `NOT VERIFIED — REQUIRED TOOL MISSING` ولا يُزيّف نجاح.
- Production config: تم التحقق من الملفات — لا `CHANGE_ME` في `appsettings.json` بعد التصحيح، ولا أسرار مرمزة في `docker-compose.yml` (يستخدم `${...:?required}` و `Production`).
- PWA/POS/Device: لم يُتحقق حياً (يتطلب Docker/Flutter/جهاز حقيقي).

**القرار:** يبقى المشروع `AWAITING STAGING VERIFICATION` حتى يُعاد هذا التحقق على مضيف يملك Docker + Compose + Postgres + Flutter/Dart + .NET SDK. لا يسمح بإعلان `READY FOR STAGING` قبل ذلك.

---

## STEP 1 — ENVIRONMENT

| الأداة | الإصدار | الحالة | الدليل |
|--------|---------|--------|--------|
| .NET SDK | `8.0.424` (`dotnet --version`, `dotnet --list-sdks`) | **PASS** | موجود |
| Docker | غير موجود | **NOT VERIFIED — REQUIRED TOOL MISSING** | `docker --version` → not recognized |
| Docker Compose | غير موجود | **NOT VERIFIED — REQUIRED TOOL MISSING** | `docker compose version` → not recognized |
| PostgreSQL (via Docker) | غير قابل | **NOT VERIFIED — REQUIRED TOOL MISSING** | يتطلب Docker |
| Flutter SDK | غير موجود | **NOT VERIFIED — REQUIRED TOOL MISSING** | `flutter --version` → not recognized |
| Dart SDK | غير موجود | **NOT VERIFIED — REQUIRED TOOL MISSING** | `dart --version` → not recognized |

## STEP 2 — BACKEND

| الفحص | النتيجة | الدليل |
|-------|---------|--------|
| `dotnet build -c Release` | **PASS** 0W/0E (بعد قتل عملية dotnet العالقة 532) | `PosCloud.Domain/Application/Infrastructure/Tests/Api/ApiTests` |
| `dotnet test` (PosCloud.Tests) | **PASS** 11/11 | `PosCloud.Tests.dll (net8.0)` |
| `dotnet test` (PosCloud.ApiTests) | **PASS** 5/5 | `PosCloud.ApiTests.dll` — يشمل 401/health/fail-fast |
| المجموع | **16/16 PASS** | `dotnet test PosCloud.sln --no-restore -c Release` |

## STEP 3 — DOCKER

| الفحص | النتيجة |
|-------|---------|
| `docker compose config` validation | **NOT VERIFIED — REQUIRED TOOL MISSING** (الملفات صالحة نحوياً وتستخدم `${POSTGRES_PASSWORD:?required}` / `${JWT_KEY:?required}`) |
| `docker compose build/up` | **NOT VERIFIED** — يتطلب Docker |
| PostgreSQL / API health | **NOT VERIFIED** — يتطلب Docker |

## STEP 4 — PRODUCTION CONFIGURATION

| الفحص | النتيجة |
|-------|---------|
| JWT `CHANGE_ME` | **PASS** — `appsettings.json:8` الآن `__REQUIRED_VIA_ENV...` (أُصلح في DEP-003)؛ `Program.cs:45` يرمي `Jwt:Key missing` في Production |
| CORS `AllowAnyOrigin` | **PASS** — مسار `app` يستخدم `Cors:AllowedOrigins[]`؛ `all` القديمة غير مستخدمة |
| Swagger in Production | **PASS** — `if (IsDevelopment())` guard |
| Demo seed | **PASS** — `SeedData.SeedAsync(db, seedDemoData)` + `SeedDemoData ?? IsDevelopment()` |
| Secrets عبر env | **PASS** — `docker-compose.yml` يطلب `${POSTGRES_PASSWORD:?required}` و `${JWT_KEY:?required}`؛ `.env.example` موجود |
| `UseInMemory=true` in Production | **PASS** — `if (isProd && useInMemory) throw` |
| `ConnectionStrings:Default` required | **PASS** — fail-fast في Production |

## STEP 5 — API SECURITY (integration)

| الفحص | النتيجة |
|-------|---------|
| Unauthenticated protected → 401 | **PASS** (عبر `WebApplicationFactory`) — `Unauthenticated_products/sales_returns_401` |
| Health → 200 | **PASS** — `Unauthenticated_health_still_200` |
| Authenticated → success | **PASS** عقدة Login يتحقق `access_token` |
| Production fail-fast | **PASS** — `Production` بدون مفتاح يرمي `Jwt:Key/ConnectionStrings` |
| Correlation ID | **PASS** — `CorrelationIdMiddleware` + `ErrorHandlingMiddleware` traceId |
| التحقق الحي ضد API مشغل | **NOT VERIFIED** — يتطلب Docker |

## STEP 6 — DATABASE

| الفحص | النتيجة |
|-------|---------|
| PostgreSQL connection | **NOT VERIFIED** — يتطلب Docker |
| Migrations file | **PASS** — `001_initial` 644 سطر يغطي كل الجداول |
| Auto-migrate | **PASS** كود — `if (!useInMemory) db.Database.Migrate()` |
| Tenant relationships | **PASS** كود — كل الكيانات تحمل `TenantId/BranchId` |
| Production لا يزرع demo | **PASS** — `appsettings.Production.json: SeedDemoData:false` |

## STEP 7 — FLUTTER

| الفحص | النتيجة |
|-------|---------|
| `flutter --version` / `dart --version` | **NOT VERIFIED — REQUIRED TOOL MISSING** |
| `flutter pub get / analyze / test` | **NOT VERIFIED** — يتطلب Flutter SDK |
| `API_BASE_URL` via `--dart-define` | **PASS** كود — `app_config.dart` + `main.dart` + `ci.yml` |
| Android real device | **NOT VERIFIED — REQUIRED TOOL MISSING** |

## STEP 8 — PWA

| الفحص | النتيجة |
|-------|---------|
| manifest | **PASS** ملف موجود (P3 — أيقونات ناقصة مؤجلة) |
| service worker / app shell / prod build | **NOT VERIFIED** — يتطلب `flutter build web` |

## STEP 9 — POS SMOKE TEST

| الخطوة Login→Business→Branch→Products→Cart→Total→Submit | **NOT VERIFIED** — يتطلب API حي + Flutter؛ الكود مربوط (`pos_screen.dart` + `SyncQueue` + `Idempotency-Key`) لكن لا smoke حي بدون Docker/Flutter |

---

## GATE — الحُكم

| الشرط | الحالة | الدليل |
|-------|--------|--------|
| P0 = 0 | ✅ PASS | `DEP-002` 5/5؛ `appsettings.json` لا `CHANGE_ME` |
| P1 = 0 | ✅ PASS (محلياً) | `appsettings.*`, `compose .env`, `demo guard`, `ApiTests`, `AppConfig` |
| Backend build | ✅ PASS | `0W/0E` |
| Backend tests | ✅ PASS | `16/16` |
| Docker build / Compose up / Postgres / API health | **NOT VERIFIED** | Docker غير مثبت |
| Production config | ✅ PASS (ملفات) | أعلاه |
| Security smoke | ✅ PASS (Factory) / حي **NOT VERIFIED** | 401/health |
| Flutter analysis/tests | **NOT VERIFIED** | Flutter غير مثبت |
| Docker+Postgres+Flutter تحقق فعلي | **NOT VERIFIED** | الأدوات مفقودة |

**الحكم:** بما أن Docker + PostgreSQL + Flutter لم يُتحقق منها فعلياً، **لا يجوز إعلان `READY FOR STAGING`**. الحالة تبقى `AWAITING STAGING VERIFICATION`.

**الخطوة التالية:** ثبت `Docker Desktop` + `Flutter SDK` على مضيف staging أو استخدم CI (`ci.yml` جاهز بـ Postgres service + Flutter action) وأعد الخطوات 2-9 هناك.



