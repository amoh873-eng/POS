# 06_UI_UX.md — POS Cloud Platform v1.1

> UI/UX Specification — PHASE-00 | Flutter | Modern simple, touch+desktop, RTL+LTR

---

## 1. Principles (Master Spec §19-21)
- Modern simple — professional, not flashy. Fast, clear, responsive.
- Touch-first for POS pad, but desktop-friendly. Adaptive layout (phone → tablet → desktop).
- One Design System across all screens.

## 2. Design System (tokens)

- **Colors:** primary (tenant `primary_color` fallback `#6D5BD0`), neutral grays, success/amber/error. Light/dark mode via ThemeMode.
- **Typography:** Cairo/Tajawal + Inter; `Cairo` for Arabic, `Inter` for English. Scale: 12/14/16/20/24.
- **Spacing:** 4/8/12/16/24/32. Radius 10-12. Elevation 0-2 (flat modern, not heavy).
- **Components:** Button (filled/outline), Card (1px border `#E5E7EB`), TextField (outlined), Dialog, Table (Mud-like simple), Navigation (top tabs + rail on desktop).
- **Icons:** Material Icons; accent per section (Sales 🛒, Inventory 📦, etc.).

## 3. Adaptive Layout

- **Breakpoints:** `<600 phone`, `600-1024 tablet`, `>1024 desktop`.
- **POS screen:** left products grid, right cart+payment; on phone cart is bottom sheet.
- **Navigation:** top nav (web/desktop), bottom nav (phone), nav rail (tablet).
- **RTL:** `Directionality` by locale; `MudRTLProvider` equivalent in Flutter via `Directionality(textDirection: rtl)`.

## 4. Screens (v1 core)

- **Login** — tenant slug + email + password,remember me, lockout message.
- **Dashboard** — Net Sales / Net Purchases / Inventory Value cards + Top Selling Items (bar) + Sales vs Purchases (donut).
- **Products** — list (search, category filter), CRUD, barcode scan field, low-stock badge.
- **POS** — product grid, scanner input, cart lines (qty±, discount), totals (MoneyDisplay), payments (Cash/Card/Transfer/Credit + Mixed), hold/resume.
- **Sales / Purchases** — list with filters (date range), detail, refund/void.
- **Inventory** — stock per branch, movements, stock count.
- **Customers/Suppliers** — list + CRUD.
- **Reports** — date range picker + popup, GenericReportTable, Excel/print.
- **Settings** — language (ar/en via locale), currency (display-only), branch/terminal.

## 5. Adaptive Config (v1 minimal — Tenant Settings)

Logo, business name, primary/secondary color, language, currency, receipt template. Stored in `tenant_settings`. Applied via Theme + `MoneyDisplay`.

Do NOT build full Dynamic UI Builder v1 — config only, then extend incrementally.

## 6. POS UX Details

- Scanner: focused field, `onSubmitted` adds to cart; quantity steppers; stock check inline.
- Cart: swipe-to-remove (phone), keyboard shortcuts (desktop: F2 pay, Del remove).
- Payment: mixed payment splits; change calculation; credit requires customer.
- Receipt: 80mm template, tenant header, lines, totals, QR (sale id), footer.

## 7. i18n

- `flutter_localizations` + `intl`; ARB files `lib/l10n/app_ar.arb`, `app_en.arb`.
- Currency via `CurrencyLookup` (same as backend); `MoneyDisplay` widget.

## 8. State

- `Riverpod` or `Bloc` (choose one, keep lightweight — Riverpod recommended for simplicity). No over-engineering.

---

*Next: 09_IMPLEMENTATION_PLAN.md | Status: UNCHANGED*
