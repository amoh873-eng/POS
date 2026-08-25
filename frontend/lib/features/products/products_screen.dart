import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List _items = [];
  final _q = TextEditingController();
  String? _tid;
  String? _msg;
  Map? _sel;
  Future<void> _load() async {
    try { final t = await widget.api.get('/api/tenants'); if (t['data'] is List && (t['data'] as List).isNotEmpty) _tid = t['data'][0]['id']; } catch (_) {}
    final qp = _tid != null ? 'tenantId=$_tid' : '';
    final q = _q.text.isNotEmpty ? '&q=${Uri.encodeComponent(_q.text)}' : '';
    final url = qp.isNotEmpty ? '/api/products?$qp$q' : '/api/products?${q.isEmpty ? '' : q.substring(1)}';
    try { final r = await widget.api.get(url); setState(() { _items = r['data'] ?? []; _msg = null; }); } catch (e) { setState(() => _msg = e.toString()); }
  }
  Future<void> _form({Map? ex}) async {
    final ar = TextEditingController(text: ex?['nameAr'] ?? ex?['name_ar'] ?? '');
    final en = TextEditingController(text: ex?['nameEn'] ?? ex?['name_en'] ?? '');
    final sku = TextEditingController(text: ex?['sku'] ?? '');
    final bc = TextEditingController(text: ex?['barcodeMain'] ?? ex?['barcode_main'] ?? '');
    final cost = TextEditingController(text: '${ex?['costPrice'] ?? ex?['cost_price'] ?? ''}');
    final sell = TextEditingController(text: '${ex?['sellPrice'] ?? ex?['sell_price'] ?? ''}');
    final r2 = await showDialog<Map?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(ex == null ? 'اضافة منتج' : 'تعديل منتج'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: ar, decoration: const InputDecoration(labelText: 'الاسم عربي')), TextField(controller: en, decoration: const InputDecoration(labelText: 'الاسم انجليزي')), TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU *')), TextField(controller: bc, decoration: const InputDecoration(labelText: 'باركود')), TextField(controller: cost, decoration: const InputDecoration(labelText: 'التكلفة'), keyboardType: TextInputType.number), TextField(controller: sell, decoration: const InputDecoration(labelText: 'البيع'), keyboardType: TextInputType.number)])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('الغاء')), ElevatedButton(onPressed: () => Navigator.pop(context, {'nameAr': ar.text, 'nameEn': en.text, 'sku': sku.text, 'barcodeMain': bc.text.isEmpty ? null : bc.text, 'costPrice': double.tryParse(cost.text) ?? 0, 'sellPrice': double.tryParse(sell.text) ?? 0, 'unit': 'pcs', 'isActive': true}), child: const Text('حفظ'))],
      ),
    );
    if (r2 == null) return;
    try {
      final repo = ex == null ? await widget.api.post('/api/products', r2) : await widget.api.patch('/api/products/${ex['id']}', r2);
      if (repo['error'] != null) { setState(() => _msg = repo['error']['message'] ?? repo.toString()); return; }
      _load();
    } catch (e) { setState(() => _msg = e.toString()); }
  }

  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _q, decoration: const InputDecoration(hintText: 'بحث بالاسم / SKU / باركود...'), onSubmitted: (_) => _load())),
      body: Column(children: [
        if (_msg != null) Container(width: double.infinity, color: Colors.red.shade50, padding: const EdgeInsets.all(8), child: Text(_msg!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        Expanded(child: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) { final m = _items[i] as Map; final name = m['nameAr'] ?? m['name_ar'] ?? m['nameEn'] ?? ''; return ListTile(title: Text(name), subtitle: Text('SKU: ${m['sku'] ?? ''}  |  Barcode: ${m['barcodeMain'] ?? m['barcode_main'] ?? '-'}'), trailing: IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _form(ex: m)), onTap: () => setState(() => _sel = m)); })),
        if (_sel != null) Card(margin: const EdgeInsets.all(8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تفاصيل: ${_sel!['nameAr'] ?? _sel!['name_ar'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('SKU: ${_sel!['sku'] ?? ''}  Barcode: ${_sel!['barcodeMain'] ?? _sel!['barcode_main'] ?? '-'}'), Text('البيع: ${_sel!['sellPrice'] ?? _sel!['sell_price'] ?? 0}  التكلفة: ${_sel!['costPrice'] ?? _sel!['cost_price'] ?? 0}'), Text('الوصف: ${_sel!['description'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey))]))),
      ]),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [FloatingActionButton.small(heroTag: 'add', onPressed: () => _form(), child: const Icon(Icons.add)), const SizedBox(height: 8), FloatingActionButton.small(heroTag: 'refresh', onPressed: _load, child: const Icon(Icons.refresh))]),
    );
  }
}
