import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List _items = [];
  String? _msg;
  Future<void> _load() async {
    try {
      final r = await widget.api.get('/api/customers?page=1&pageSize=50');
      setState(() => _items = r['data'] ?? []);
    } catch (e) { setState(() => _msg = e.toString()); }
  }
  Future<void> _addCustomer() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('عميل جديد'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم *')), TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'الهاتف'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ'))]));
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    try {
      final r = await widget.api.post('/api/customers', {'name': nameCtrl.text.trim(), 'phone': phoneCtrl.text.trim()});
      if (r['error'] != null) { setState(() => _msg = r['error']['message'] ?? r.toString()); return; }
      await _load();
    } catch (e) { setState(() => _msg = e.toString()); }
  }
  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('العملاء'), actions: [IconButton(onPressed: _addCustomer, icon: const Icon(Icons.person_add)), IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]), body: Column(children: [if (_msg != null) Container(width: double.infinity, color: Colors.red.shade50, padding: const EdgeInsets.all(8), child: Text(_msg!, style: const TextStyle(color: Colors.red, fontSize: 12))), Expanded(child: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) => ListTile(title: Text(_items[i]['name'] ?? ''), subtitle: Text('هاتف: ${_items[i]['phone'] ?? '-'}  رصيد: ${_items[i]['balance'] ?? 0}'))))]));
  }
}
