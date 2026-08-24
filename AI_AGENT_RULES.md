# AI_AGENT_RULES.md — POS Cloud Platform v1.1

> قواعد عمل جميع AI Agents — مخالفتها = تضارب معماري يستوجب الإيقاف

## 1. المرجع الوحيد
- المرجع الرسمي: `docs/00_MASTER_SPECIFICATION.md` + `PROJECT_STATE.md` + ملفات `docs/*.md`
- لا يملك أي Agent حق إعادة تصميم النظام منفرداً.

## 2. قبل أي مهمة — إلزامي عند كل تشغيل
> ⚠️ Агент يقرأ هذا تلقائياً عند كل Run — لا تتجاوز هذه الخطوة
1. اقرأ `docs/00_MASTER_SPECIFICATION.md` (المواصفة الكاملة 62 بند — المرجع الوحيد)
2. اقرأ `PROJECT_STATE.md` (الحالة الحية — Phase/Cell/Task/Checkpoint)
3. حدد Current Phase / Cell / Task من PROJECT_STATE.md
4. اقرأ المقطع ذي الصلة من Master Spec فقط + ملفات الخلية المعنية
5. لا تحمّل ملفات غير ذات صلة (Minimal Context Loading)

## 3. مستويات التغيير
| Level | الوصف | صلاحية Agent |
|-------|-------|-------------|
| L0 | Simple code change | مسموح |
| L1 | Local improvement | مسموح |
| L2 | Cell-level change | يحتاج مراجعة — أوقف ونبّه |
| L3 | Architecture change (stack, monolith→microservices, 7 layers, multi-tenancy) | يحتاج موافقة صريحة — أوقف فوراً + تقرير تضارب |

## 4. ممنوعات
- تغيير Technology Stack (Flutter/ASP.NET/PostgreSQL/SQLite/EF Core/REST/JWT)
- تحويل Modular Monolith إلى Microservices
- إضافة خلايا جديدة دون مبرر عمل
- بناء GenericRepository/GenericService... دون حاجة حقيقية
- بناء Dynamic UI Builder كامل في v1
- تخزين بيانات بطاقات حساسة

## 5. دورة العمل
```
Understand → Design → Document → Implement → Test → Review → Integrate → Checkpoint
```

## 6. Checkpoint
بعد كل وحدة ذات معنى:
```
git status
git diff
run tests
git commit -m "feat(cell): description"
update PROJECT_STATE.md
```

## 7. الاستئناف — Resume Instead of Restart
- عند انقطاع النت/VS Code/Agent: اقرأ PROJECT_STATE.md + آخر Checkpoint وواصل
- لا تعيد فحص المشروع كاملاً إلا إذا: طُلب صراحة، أو حالة غير متسقة، أو تضارب معماري

## 8. كفاءة التوكنز
- لا تكرر المواصفة كاملة
- لا تعيد توليد كود موجود
- لا تشرح وحدات لم تتغير
- مهمة واحدة مركّزة لكل جلسة

## 9. صيغة المهمة المثالية
```
TASK ID: PROD-API-001
CELL: CELL-005 Product
PHASE: PHASE-01
OBJECTIVE:
ALLOWED FILES:
RELEVANT DOCUMENTS:
EXPECTED RESULT:
TEST REQUIREMENTS:
ARCHITECTURAL RESTRICTIONS:
NEXT CHECKPOINT:
```

## 10. عند الفشل أو التضارب
- احفظ الكود الحالي
- سجّل الفشل في PROJECT_STATE.md
- واصل من آخر Checkpoint صالح
- إن كان تضارباً معمارياً: أوقف التنفيذ وأنشئ تقرير Architectural Conflict Report
