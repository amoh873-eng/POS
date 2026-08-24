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
  Future<void> _load() async {
    final r = await widget.api.get('/api/inventory/stock?tenantId=00000000-0000-0000-0000-000000000000');
    setState(() => _items = r['data'] ?? []);
  }
  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Inventory'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]), body: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) => ListTile(title: Text(_items[i]['productId']?.toString() ?? ''), trailing: Text('${_items[i]['qtyOnHand'] ?? _items[i]['qty_on_hand'] ?? 0}'))));
  }
}
