# 07_BUSINESS_CELLS.md — POS Cloud Platform v1.1

> Business-specific cells 101-104 — extensions on Core POS | Add only on demand

---

See `02_ENGINEERING_CELLS.md` for summaries. This file is the **detailed** extension point — kept intentionally thin in v1.

## When to Create a Business Cell

Per Master Spec §51: identify owner cell → does it exist? → can existing design hold it? → new cell only if justified.

## 101 Restaurant — placeholder
- Tables: `restaurant_tables (id, branch_id, label, status, current_sale_id)`
- Orders: extends `sales` with `order_type` (dine-in/takeaway), `table_id`, `kitchen_status`
- KDS: SignalR `kitchen:orders` channel (add only here, not core).
- Modifiers/Combos: `product_modifiers`, `modifier_options` (only if needed).

## 102 Bakery
- `recipes (product_id → lines: ingredient_product_id, qty)`, `productions`, `production_batches (cost, expiry)`.
- Production posts inventory: consume ingredients → produce finished.

## 103 Pharmacy
- `pharmacy_batches (product_id, branch_id, batch_no, expiry_date, qty)` — expiry enforced on sale.
- `prescriptions` (header + lines, image nullable) — optional.

## 104 Supermarket
- `promotions (type: percent/buyXgetY, scope, from/to)` applied at sale compute.
- `scale_products` (PLU → product) for scale barcode parsing.

## Rule
No business cell may duplicate Core Cells or bypass tenancy/stock/payment rules. Each extension is reviewed (L2+) before implementation.

---

*Status: UNCHANGED | Level: L0 doc — details expand per implementation*
