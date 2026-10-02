import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/money_display.dart';

class PurchaseInvoicesScreen extends StatefulWidget {
  const PurchaseInvoicesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<PurchaseInvoicesScreen> createState() => _PurchaseInvoicesScreenState();
}

class _PurchaseInvoicesScreenState extends State<PurchaseInvoicesScreen> {
  List _items = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.api.get('/api/purchases?page=$_page&pageSize=$_pageSize');
      if (!mounted) return;
      setState(() {
        _items = r['data'] ?? [];
        _total = r['meta']?['total'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _receive(String id) async {
    try {
      await widget.api.post('/api/purchases/$id/receive', {});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _createPurchase() async {
    List suppliers = [];
    List products = [];
    try {
      final sR = await widget.api.get('/api/suppliers');
      final pR = await widget.api.get('/api/products?pageSize=1000');
      suppliers = sR['data'] ?? [];
      products = pR['data'] ?? [];
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تحميل البيانات: $e')));
      return;
    }

    String? selectedSupplier;
    String? selectedBranch; // Need to fetch branches too? For now assume one or use a hardcoded one or fetch.
    List branches = [];
    try {
      final bR = await widget.api.get('/api/branches');
      branches = bR['data'] ?? [];
      if (branches.isNotEmpty) selectedBranch = branches[0]['id'];
    } catch (_) {}

    List<Map> lines = [];
    
    if (!mounted) return;

    final result = await showGeneralDialog<bool>(
      context: context,
      pageBuilder: (ctx, anim1, anim2) => StatefulBuilder(
        builder: (ctx, setS) => Scaffold(
          appBar: AppBar(
            title: const Text('إضافة فاتورة شراء'),
            actions: [
              TextButton(
                onPressed: (selectedSupplier != null && selectedBranch != null && lines.isNotEmpty)
                    ? () async {
                        try {
                          await widget.api.post('/api/purchases', {
                            'supplierId': selectedSupplier,
                            'branchId': selectedBranch,
                            'lines': lines.map((l) => {
                              'productId': l['productId'],
                              'qty': l['qty'],
                              'cost': l['cost'],
                            }).toList(),
                            'status': 'draft',
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx, true);
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                        }
                      }
                    : null,
                child: const Text('حفظ كمسودة', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (selectedSupplier != null && selectedBranch != null && lines.isNotEmpty)
                    ? () async {
                        try {
                          await widget.api.post('/api/purchases', {
                            'supplierId': selectedSupplier,
                            'branchId': selectedBranch,
                            'lines': lines.map((l) => {
                              'productId': l['productId'],
                              'qty': l['qty'],
                              'cost': l['cost'],
                            }).toList(),
                            'status': 'received',
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx, true);
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('استلام مباشر'),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSupplier,
                        decoration: const InputDecoration(labelText: 'المورد'),
                        items: suppliers.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']))).toList(),
                        onChanged: (v) => setS(() => selectedSupplier = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedBranch,
                        decoration: const InputDecoration(labelText: 'الفرع'),
                        items: branches.map<DropdownMenuItem<String>>((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']))).toList(),
                        onChanged: (v) => setS(() => selectedBranch = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'إضافة منتج'),
                        items: products.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['nameAr'] ?? p['name_ar']))).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          final p = products.firstWhere((element) => element['id'] == v);
                          setS(() {
                            lines.add({
                              'productId': p['id'],
                              'name': p['nameAr'] ?? p['name_ar'],
                              'qty': 1.0,
                              'cost': (p['costPrice'] ?? p['cost_price'] ?? 0.0).toDouble(),
                            });
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return ListTile(
                        title: Text(line['name']),
                        subtitle: Row(
                          children: [
                            const Text('الكمية: '),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (v) => setS(() => line['qty'] = double.tryParse(v) ?? 0),
                                controller: TextEditingController.fromValue(TextEditingValue(text: line['qty'].toString(), selection: TextSelection.collapsed(offset: line['qty'].toString().length))),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text('التكلفة: '),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (v) => setS(() => line['cost'] = double.tryParse(v) ?? 0),
                                controller: TextEditingController.fromValue(TextEditingValue(text: line['cost'].toString(), selection: TextSelection.collapsed(offset: line['cost'].toString().length))),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setS(() => lines.removeAt(index)),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('الإجمالي: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        MoneyDisplay.format(lines.fold(0.0, (sum, l) => sum + (l['qty'] * l['cost']))),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فواتير المشتريات'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPurchase,
        child: const Icon(Icons.add),
      ),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _loading && _items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = _items[index];
                          return ListTile(
                            title: Text(p['supplier']?['name'] ?? 'مورد غير معروف'),
                            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(p['createdAt']))),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(MoneyDisplay.format(p['grandTotal']), style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: p['status'] == 'received' ? Colors.green.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p['status'] == 'received' ? 'مستلم' : 'مسودة',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: p['status'] == 'received' ? Colors.green.shade900 : Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: p['status'] == 'draft'
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('تأكيد الاستلام'),
                                        content: const Text('هل تريد وضع علامة "مستلم" على هذه الفاتورة؟ سيتم تحديث المخزون.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _receive(p['id']);
                                            },
                                            child: const Text('استلام'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                    if (_total > _pageSize)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('صفحة $_page من ${(_total / _pageSize).ceil()}'),
                            IconButton(
                              onPressed: _page < (_total / _pageSize).ceil() ? () { setState(() => _page++); _load(); } : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
