# CONTRIBUTING.md

> كيف تساهم بدون كسر المعمارية

1. اقرأ `docs/00_MASTER_SPECIFICATION.md` + `PROJECT_STATE.md`
2. حدد الخلية (001-012 أو 101-104) — لا تضف خلية جديدة بدون §51
3. L0/L1 مسموح — L2/L3 يحتاج مراجعة — L4+ تقرير تضارب معماري
4. اختبر: `dotnet test` + `flutter test` (إن متاحاً)
5. Commit: `feat(cell): ...` + حدّث `PROJECT_STATE.md`
