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
  Future<void> _load() async {
    try { final t = await widget.api.get('/api/tenants'); if (t['data'] is List && (t['data'] as List).isNotEmpty) _tid = t['data'][0]['id']; } catch (_) {}
    final qp = _tid != null ? 'tenantId=$_tid' : 'tenantId=00000000-0000-0000-0000-000000000000';
    final res = await widget.api.get('/api/products?$qp&q=${_q.text}');
    setState(() => _items = res['data'] ?? []);
  }
  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _q, decoration: const InputDecoration(hintText: 'Search...'), onSubmitted: (_) => _load())),
      body: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) => ListTile(title: Text(_items[i]['nameAr'] ?? _items[i]['name_ar'] ?? ''), subtitle: Text(_items[i]['sku'] ?? ''))),
      floatingActionButton: FloatingActionButton(onPressed: _load, child: const Icon(Icons.refresh)),
    );
  }
}
