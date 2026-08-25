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
  String? _tid;
  String? _msg;
  Future<void> _load() async {
    try {
      final t = await widget.api.get('/api/tenants');
      if (t['data'] is List && (t['data'] as List).isNotEmpty) _tid = t['data'][0]['id'];
    } catch (_) {}
    final qp = _tid != null ? 'tenantId=$_tid' : '';
    final qpStr = qp.isEmpty ? '' : '?$qp';
    try {
      final r = await widget.api.get('/api/inventory/stock${qpStr.isEmpty ? '' : qpStr}');
      final lr = await widget.api.get('/api/inventory/low-stock${qpStr.isEmpty ? '' : qpStr}');
      final mr = await widget.api.get('/api/inventory/movements${qpStr.isEmpty ? '' : '$qpStr&'}page=1&page_size=10');
      setState(() {
        _items = r['data'] ?? [];
        _low = lr['data'] ?? [];
        _mov = mr['data'] ?? [];
      });
    } catch (e) {
      setState(() => _msg = e.toString());
    }
  }

  Future<void> _adjustDialog() async {
    final pid = TextEditingController();
    final qty = TextEditingController();
    final branch = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل المخزون'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: pid, decoration: const InputDecoration(labelText: 'ProductId (انسخ من الجدول)')),
          TextField(controller: branch, decoration: const InputDecoration(labelText: 'BranchId')),
          TextField(controller: qty, decoration: const InputDecoration(labelText: 'Quantity delta (+/-)'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تطبيق')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final body = {'tenantId': _tid, 'branchId': branch.text, 'productId': pid.text, 'qtyDelta': num.tryParse(qty.text) ?? 0, 'type': 'adjust'};
      final r = await widget.api.post('/api/inventory/adjust', body);
      if (r['error'] != null) {
        setState(() => _msg = r['error']['message'] ?? r.toString());
        return;
      }
      _load();
    } catch (e) {
      setState(() => _msg = e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh)), IconButton(onPressed: _adjustDialog, icon: const Icon(Icons.edit))]),
      body: ListView(
        children: [
          if (_msg != null) Container(color: Colors.red.shade50, padding: const EdgeInsets.all(8), child: Text(_msg!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          if (_low.isNotEmpty)
            Card(
              color: Colors.amber.shade50,
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('تنبيه نقص مخزون', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ..._low.map((e) => Text('${e['productId']}  qty=${e['qtyOnHand'] ?? e['qty_on_hand'] ?? 0}')),
                ]),
              ),
            ),
          const Padding(padding: EdgeInsets.all(8), child: Text('المخزون الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
          ..._items.map((e) => ListTile(
                title: Text('${e['productId']?.toString().substring(0, 8) ?? ''}...'),
                subtitle: Text('فرع: ${e['branchId'] ?? e['branch_id'] ?? ''}'),
                trailing: Text('${e['qtyOnHand'] ?? e['qty_on_hand'] ?? 0}', style: TextStyle(fontWeight: FontWeight.bold, color: (e['qtyOnHand'] ?? e['qty_on_hand'] ?? 0) == 0 ? Colors.red : Colors.black)),
              )),
          const Divider(),
          const Padding(padding: EdgeInsets.all(8), child: Text('حركة المخزون (آخر 10)', style: TextStyle(fontWeight: FontWeight.bold))),
          ..._mov.map((e) => ListTile(dense: true, title: Text('${e['type'] ?? ''}  ${e['qtyDelta'] ?? e['qty_delta'] ?? ''}'), subtitle: Text('${e['productId'] ?? ''}'))),
        ],
      ),
    );
  }
}
