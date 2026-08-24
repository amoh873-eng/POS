# 05_ALGORITHMS.md — POS Cloud Platform v1.1

> Core algorithms (pseudocode) — PHASE-00 | Keep simple, server-side truth

---

## 1. Sale Total Calculation

```
function computeSale(lines, discountTotal):
  subtotal = sum(line.qty * line.unit_price for line)
  // line discount already in unit_price or line.discount
  taxTotal = sum(lineTax(line) for line) // v1: tax_rate * (qty*price - line.discount)
  grandTotal = subtotal - lineDiscounts + taxTotal - discountTotal
  // discountTotal is header-level
  return { subtotal, taxTotal, grandTotal }
  // All computed server-side; client values ignored except qty/product_id
```

## 2. Create Sale (transactional)

```
POST /api/sales  (Idempotency-Key)
  if exists sale with idempotency_key → return it (idempotent)
  validate lines (product exists, active, qty>0)
  compute totals (above)
  validate payments sum == grandTotal OR customer credit allowed
  BEGIN TX
    lock inventory_stocks rows FOR UPDATE (per product/branch)
    for each line: check qty_on_hand >= qty; else throw INSUFFICIENT_STOCK
    insert sales + sale_items (receipt_no = next per-tenant sequence)
    for each line: update inventory_stocks qty -= qty; insert inventory_movement (type=sale)
    insert payments (method/provider)
    commit
  return sale
  // failure → rollback, 422
```

Receipt number: `tenant_seq` table or `SELECT MAX(receipt_no)+1` with row lock — simple v1.

## 3. Refund / Void

```
refund(saleId, linesToRefund):
  assert sale.status == completed
  create refundSale (negative amounts, ref to original)
  for each line: inventory_stocks qty += refundQty; movement type=refund
  create negative payment(s)
  set original sale refunded_amount
void: only if sale not yet synced beyond branch and role allows; else refund
```

## 4. Stock Adjustment / Transfer / Count

```
adjust(product, branch, delta, reason):
  update stock qty += delta; movement type=adjust (+audit reason)

transfer(fromBranch, toBranch, lines):
  TX: for each line: deduct fromBranch, add toBranch, two movements (out/in)

postStockCount(countId):
  for each line: diff = counted - system; if diff!=0 adjust + movement type=count
```

## 5. Low-Stock Alert

```
after any stock update: if qty_on_hand <= low_stock_threshold → emit alert (poll or push later)
report: SELECT * FROM inventory_stocks WHERE qty_on_hand <= threshold
```

## 6. Sync (simple queue)

```
device queue: table sync_state(client_id, entity_type, entity_id, state=pending, payload)
on online:
  push: POST /api/sync/push { items: [{client_id, type, payload}] }
    server: upsert by client_id (idempotent), process in TX, return {client_id → server_id, errors}
    device: mark synced/failed
  pull: GET /api/sync/pull?since=timestamp → { products, customers, settings changed }

conflict: sales are append-only, no conflict. Master data: last-write-wins (updated_at).
retry: exponential backoff for failed (max 5).
```

## 7. Auth — Refresh Rotation

```
login → issue access (15m) + refresh (7d, stored hash)
refresh → verify hash & not revoked & not expired → revoke old → issue new pair
logout → revoke refresh
lockout after 5 failed in 15m
```

---

*No Event Sourcing v1. Keep algorithms testable and deterministic. Next: 06_UI_UX.md*
