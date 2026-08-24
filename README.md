# POS Cloud Platform — v1.1

> منصة نقاط بيع سحابية متعددة المنصات — الأساس أولاً | البساطة | قابلية الصيانة | قابلية التوسع

**المواصفات الكاملة:** [`docs/00_MASTER_SPECIFICATION.md`](docs/00_MASTER_SPECIFICATION.md)  
**حالة المشروع الحيّة:** [`PROJECT_STATE.md`](PROJECT_STATE.md)  
**قواعد AI Agents:** [`AI_AGENT_RULES.md`](AI_AGENT_RULES.md)  
**الخطة الأصلية:** `POSplan.pdf` + `POSplan.doc` (محفوظة في هذا المجلد)

## التقنيات

| Layer | Stack |
|-------|-------|
| Frontend | Flutter / Dart |
| Backend | ASP.NET Core / C# |
| Database | PostgreSQL |
| Local DB | SQLite |
| ORM | Entity Framework Core |
| API | REST |
| Auth | JWT + Refresh Token |
| Architecture | Lightweight Modular Monolith |
| 7 Layers | L7 Presentation → L1 Platform |
| Cells | 001-012 Core + 101-104 Business-specific |

## هيكل المجلدات

```
D:\POS\
├── POSplan.pdf / POSplan.doc    # الخطة الأصلية
├── docs/
│   └── 00_MASTER_SPECIFICATION.md
├── PROJECT_STATE.md             # حالة المشروع (يقرأها كل Agent)
├── AI_AGENT_RULES.md            # حوكمة الوكلاء
├── backend/                     # ASP.NET Core (يُنشأ عند تثبيت dotnet)
│   └── src/
│       ├── PosCloud.Api
│       ├── PosCloud.Application
│       ├── PosCloud.Domain
│       └── PosCloud.Infrastructure
├── frontend/                    # Flutter (يُنشأ عند تثبيت Flutter)
│   └── lib/
└── .vscode/
    └── settings.json
```

## البدء (VS Code)

1. افتح المجلد `D:\POS` في VS Code
2. اقرأ `PROJECT_STATE.md` لمعرفة Current Phase/Cell/Task
3. اتبع `AI_AGENT_RULES.md` للعمل

## متطلبات التثبيت (قبل توليد الكود)

- [.NET SDK 8+](https://dotnet.microsoft.com/download)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [PostgreSQL](https://www.postgresql.org/download/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (اختياري)

بعد التثبيت، سيتم تهيئة:

```powershell
# Backend
dotnet new sln -n PosCloud
dotnet new webapi -n PosCloud.Api
dotnet new classlib -n PosCloud.Domain
dotnet new classlib -n PosCloud.Application
dotnet new classlib -n PosCloud.Infrastructure

# Frontend
flutter create frontend
```

## الفلسفة

> نبني الأساس والأعمدة والسقف والخدمات الأساسية أولاً — ثم نضيف الميزات حسب حاجة العميل الحقيقية.  
> **Design for extension, not for complexity.**

## المراحل القادمة

- PHASE-00: Architecture Diagrams, ERD, Cell Specs, API Spec, UI/UX Spec, Implementation Plan
- PHASE-01: Foundation + Identity + Business Cells
- ... حسب `PROJECT_STATE.md`

---
*Generated 2026-08-24 — Spec v1.1 Architecture Baseline*
