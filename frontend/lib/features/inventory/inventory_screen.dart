import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List _items = [];
  List _low = [];
  List _mov = [];
  String? _msg;
  Future<void> _load() async {
    try {
      final r = await widget.api.get('/api/inventory/stock');
      final lr = await widget.api.get('/api/inventory/low-stock');
      final mr = await widget.api.get('/api/inventory/movements?page=1&page_size=10');
      if (!mounted) return;
      setState(() {
        _items = r['data'] ?? [];
        _low = lr['data'] ?? [];
        _mov = mr['data'] ?? [];
      });
    } catch (e) {
      if (mounted) setState(() => _msg = e.toString());
    }
  }

  Future<void> _adjustDialog() async {
    List prods = [];
    List branches = [];
    String? selProd;
    String? selBranch;
    final qty = TextEditingController();
    String? localErr;
    try {
      final pr = await widget.api.get('/api/products?page=1&pageSize=50');
      final br = await widget.api.get('/api/branches');
      prods = pr['data'] ?? [];
      branches = br['data'] ?? [];
      if (prods.isNotEmpty) selProd = prods[0]['id'].toString();
      if (branches.isNotEmpty) selBranch = branches[0]['id'].toString();
    } catch (_) {}
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('تعديل المخزون'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: selProd, decoration: const InputDecoration(labelText: 'المنتج'), items: prods.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'].toString(), child: Text('${p['nameAr'] ?? p['nameEn'] ?? p['sku'] ?? 'P'}'))).toList(), onChanged: (v) => setD(() => selProd = v)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: selBranch, decoration: const InputDecoration(labelText: 'الفرع'), items: branches.map<DropdownMenuItem<String>>((b) => DropdownMenuItem(value: b['id'].toString(), child: Text('${b['name'] ?? b['code'] ?? 'B'}'))).toList(), onChanged: (v) => setD(() => selBranch = v)),
          const SizedBox(height: 8),
          TextField(controller: qty, decoration: const InputDecoration(labelText: 'الكمية (+/-) مثال: 10 أو -5'), keyboardType: TextInputType.number),
          if (localErr != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(localErr!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), ElevatedButton(onPressed: () { if (selProd == null || selBranch == null) { setD(() => localErr = 'اختر المنتج والفرع'); return; } if ((num.tryParse(qty.text) ?? 0) == 0) { setD(() => localErr = 'أدخل كمية غير صفر'); return; } Navigator.pop(ctx, true); }, child: const Text('تطبيق'))],
      )),
    );
    if (ok != true) return;
    try {
      final body = {'branchId': selBranch, 'productId': selProd, 'qtyDelta': num.tryParse(qty.text) ?? 0};
      final r = await widget.api.post('/api/inventory/adjust', body);
      if (r['error'] != null) { if (mounted) setState(() => _msg = r['error']['message'] ?? r.toString()); return; }
      if (mounted) { setState(() => _msg = '✓ تم التعديل'); _load(); }
    } catch (e) { if (mounted) setState(() => _msg = e.toString()); }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('المخزون'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh)), IconButton(onPressed: _adjustDialog, icon: const Icon(Icons.edit_note))]),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_msg != null) Container(decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(10), child: Text(_msg!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          if (_low.isNotEmpty)
            Card(
              color: Colors.amber.shade50,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20), const SizedBox(width: 6), const Text('تنبيه نقص مخزون', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
                  const SizedBox(height: 6),
                  ..._low.map((e) => Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${e['productName'] ?? 'منتج'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), if (e['productSku'] != null) Text('SKU: ${e['productSku']}', style: const TextStyle(fontSize: 10, color: Colors.grey))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(20)), child: Text('qty ${e['qtyOnHand'] ?? e['qty_on_hand'] ?? 0}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12))), if (e['branchName'] != null && e['branchName'].toString().isNotEmpty) Text('فرع: ${e['branchName']}', style: const TextStyle(fontSize: 9, color: Colors.grey))]) ]))),
                ]),
              ),
            ),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.warehouse, color: cs.primary)), const SizedBox(width: 12), const Expanded(child: Text('المخزون الحالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Text('${_items.length} صنف', style: const TextStyle(color: Colors.grey))]))),
          const SizedBox(height: 8),
          ..._items.map((e) {
            final qty = (e['qtyOnHand'] ?? e['qty_on_hand'] ?? 0) as num;
            final status = (e['status'] ?? (qty == 0 ? 'out' : (qty <= (e['lowStockThreshold'] ?? 0) ? 'low' : 'ok'))).toString();
            final low = status == 'low';
            final out = status == 'out';
            final name = e['productName'] ?? 'منتج';
            final sku = e['productSku'] ?? '';
            final branchName = e['branchName'] != null && e['branchName'].toString().isNotEmpty ? e['branchName'].toString() : (e['branchId'] ?? '').toString().substring(0, 8);
            final color = out ? Colors.red : (low ? Colors.orange : const Color(0xFF1D4ED8));
            final bg = out ? Colors.red.shade50 : (low ? Colors.orange.shade50 : const Color(0xFFEFF6FF));
            return Card(margin: const EdgeInsets.only(top: 8), child: ListTile(leading: CircleAvatar(backgroundColor: bg, child: Icon(Icons.inventory_2, color: color, size: 18)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text('${sku.isNotEmpty ? 'SKU: $sku  |  ' : ''}فرع: $branchName', style: const TextStyle(fontSize: 11)), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Text('$qty', style: TextStyle(fontWeight: FontWeight.w800, color: color)))));
          }),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.history, size: 18, color: cs.primary), const SizedBox(width: 6), const Text('حركة المخزون (آخر 10)', style: TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 8), ..._mov.map((e) => Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (e['type'] ?? '').toString().contains('sale') ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(20)), child: Text('${e['type'] ?? ''}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: (e['type'] ?? '').toString().contains('sale') ? Colors.red : Colors.green))), const SizedBox(width: 8), Text('${e['qtyDelta'] ?? e['qty_delta'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 8), Expanded(child: Text('${e['productName'] ?? e['productId'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)))])))]))),
        ],
      ),
    );
  }
}
