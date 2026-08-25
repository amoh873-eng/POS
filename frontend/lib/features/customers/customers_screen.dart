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
  String? _tid;
  Future<void> _load() async {
    try { final t = await api.get('/api/tenants'); if (t['data'] is List && (t['data'] as List).isNotEmpty) _tid = t['data'][0]['id']; } catch (_) {}
    final r = await api.get(_tid != null ? '/api/customers?tenantId=$_tid' : '/api/customers');
    setState(() => _items = r['data'] ?? []);
  }
  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Customers'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]), body: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) => ListTile(title: Text(_items[i]['name'] ?? ''), subtitle: Text(_items[i]['phone'] ?? ''))));
  }
}
