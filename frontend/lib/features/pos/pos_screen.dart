import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/money_display.dart';
import '../../core/sync_queue.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.api, required this.syncQueue});
  final ApiClient api;
  final SyncQueue syncQueue;
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<Map<String, dynamic>> _cart = [];
  List _products = [];
  String? _tenantId;
  String? _branchId;
  final _barcodeCtrl = TextEditingController();
  bool _paying = false;
  String? _msg;
  @override
  void initState() { super.initState(); _bootstrap(); }
  Future<void> _bootstrap() async {
    try {
      final tenants = await widget.api.get('/api/tenants');
      if (tenants['data'] is List && (tenants['data'] as List).isNotEmpty) {
        _tenantId = tenants['data'][0]['id'];
        final branches = await widget.api.get('/api/branches?tenantId=$_tenantId');
        final blist = branches['data'] ?? branches;
        if (blist is List && blist.isNotEmpty) _branchId = blist[0]['id'];
        if (_tenantId != null) {
          final prods = await widget.api.get('/api/products?tenantId=$_tenantId');
          setState(() => _products = prods['data'] ?? []);
        }
      }
    } catch (e) { setState(() => _msg = e.toString()); }
  }
  Future<void> _scanBarcode(String code) async {
    if (code.isEmpty || _tenantId == null) return;
    try {
      final res = await widget.api.get('/api/products/barcode/$code?tenantId=$_tenantId');
      final p = res['data'];
      if (p != null) _addToCart(p);
      _barcodeCtrl.clear();
    } catch (e) { setState(() => _msg = e.toString()); }
  }
  void _addToCart(Map p) {
    setState(() {
      final idx = _cart.indexWhere((e) => e['id'] == p['id']);
      if (idx >= 0) {
        _cart[idx]['qty'] = (_cart[idx]['qty'] as num) + 1;
      } else {
        _cart.add({'id': p['id'], 'name': p['nameAr'] ?? p['name_ar'] ?? p['nameEn'] ?? 'P', 'price': (p['sellPrice'] ?? p['sell_price'] ?? 0).toDouble(), 'qty': 1});
      }
    });
  }
  double get _total => _cart.fold(0.0, (s, e) => s + (e['price'] as double) * (e['qty'] as num));
  Future<void> _pay() async {
    if (_cart.isEmpty || _tenantId == null || _branchId == null) {
      setState(() => _msg = 'السلة فارغة او الفرع غير محدد');
      return;
    }
    setState(() { _paying = true; _msg = null; });
    final idem = 'idem-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final body = {'tenantId': _tenantId, 'branchId': _branchId, 'lines': _cart.map((e) => {'productId': e['id'], 'qty': e['qty']}).toList(), 'payments': [{'method': 'cash', 'amount': _total}]};
    try {
      final res = await widget.api.post('/api/sales', body, extraHeaders: {'Idempotency-Key': idem});
      if (res['data'] != null) {
        setState(() { _msg = 'تم البيع - ${res['data']['receiptNo'] ?? res['data']['receipt_no'] ?? ''}'; _cart.clear(); });
      } else if (res['error'] != null) {
        setState(() => _msg = res['error']['message'] ?? res.toString());
      } else {
        setState(() => _msg = res.toString());
      }
    } catch (e) {
      widget.syncQueue.enqueue(SyncItem(clientId: idem, type: 'sale', payloadJson: body.toString()));
      setState(() => _msg = 'غير متصل - حفظ محليا وسيتم المزامنة');
    }
    setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final grid = Expanded(
      flex: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _barcodeCtrl,
              decoration: InputDecoration(
                hintText: 'امسح الباركود ثم Enter',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => _scanBarcode(_barcodeCtrl.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _scanBarcode,
            ),
          ),
          Expanded(
            child: _products.isEmpty
                ? const Center(child: Text('لا توجد منتجات'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (_, i) {
                      final p = _products[i];
                      return Card(
                        child: InkWell(
                          onTap: () => _addToCart(p),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p['nameAr'] ?? p['name_ar'] ?? p['nameEn'] ?? 'P',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                MoneyDisplay(amount: (p['sellPrice'] ?? p['sell_price'] ?? 0).toDouble()),
                                Text(p['sku'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
    final cart = Expanded(
      child: Card(
        margin: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text('السلة', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView(
                children: _cart.asMap().entries.map((en) {
                  final e = en.value;
                  return ListTile(
                    title: Text(e['name']),
                    subtitle: Text('${e['price']} x ${e['qty']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (e['qty'] > 1) {
                                e['qty']--;
                              } else {
                                _cart.removeAt(en.key);
                              }
                            });
                          },
                        ),
                        IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => e['qty']++)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _cart.removeAt(en.key)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_msg != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _msg!,
                  style: TextStyle(color: _msg!.contains('تم') ? Colors.green : Colors.red, fontSize: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الاجمالي'), MoneyDisplay(amount: _total)]),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _paying ? null : _pay,
                      child: _paying
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('دفع نقدي'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('نقطة البيع')),
      body: isWide ? Row(children: [grid, cart]) : Column(children: [SizedBox(height: 280, child: grid), Expanded(child: cart)]),
    );
  }
}
