import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/app_config.dart';
import '../../core/money_display.dart';
import '../../core/sync_queue.dart';
import '../../core/printer_settings.dart';
import '../../core/web_print.dart' as webprint;

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
      final tenants = await widget.api.get('/api/tenants/me');
      final meData = tenants['data'];
      if (meData != null && meData['id'] != null) {
        _tenantId = meData['id'];
      } else if (tenants['data'] is List && (tenants['data'] as List).isNotEmpty) {
        _tenantId = tenants['data'][0]['id'];
      }
      final branches = await widget.api.get('/api/branches');
      final blist = branches['data'] ?? branches;
      if (blist is List && blist.isNotEmpty) _branchId = blist[0]['id'];
      if (_tenantId != null || _branchId != null) {
        final prods = await widget.api.get('/api/products?page=1&pageSize=50');
        if (!mounted) return;
        setState(() => _products = prods['data'] ?? []);
      }
    } catch (e) { if (mounted) setState(() => _msg = e.toString()); }
  }
  Future<void> _scanBarcode(String code) async {
    if (code.isEmpty) return;
    try {
      final res = await widget.api.get('/api/products/barcode/$code');
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
    // Snapshot cart items (with names/prices) BEFORE any clear, so the receipt keeps real product names
    final soldItems = List<Map<String, dynamic>>.from(_cart);
    setState(() { _paying = true; _msg = null; });
    final idem = 'idem-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final body = {'tenantId': _tenantId, 'branchId': _branchId, 'lines': _cart.map((e) => {'productId': e['id'], 'qty': e['qty']}).toList(), 'payments': [{'method': 'cash', 'amount': _total}]};
    try {
      final res = await widget.api.post('/api/sales', body, extraHeaders: {'Idempotency-Key': idem});
      if (res['data'] != null) {
        final receipt = res['data'];
        if (mounted) { setState(() { _msg = 'تم البيع - ${receipt['receiptNo'] ?? receipt['receipt_no'] ?? ''}'; _cart.clear(); }); _showReceipt(receipt, 'نقدي', soldItems); }
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

  Future<void> _payCard([String method = 'card']) async {
    if (_cart.isEmpty || _tenantId == null || _branchId == null) { setState(() => _msg = 'السلة فارغة'); return; }
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('دفع بـ $method'),
      content: Text('المبلغ: ${_total.toStringAsFixed(2)} JOD\nطريقة الدفع: $method'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد'))],
    ));
    if (confirm != true) return;
    final soldItems = List<Map<String, dynamic>>.from(_cart);
    setState(() { _paying = true; _msg = null; });
    final idem = 'idem-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final body = {'tenantId': _tenantId, 'branchId': _branchId, 'lines': _cart.map((e) => {'productId': e['id'], 'qty': e['qty']}).toList(), 'payments': [{'method': method, 'amount': _total}]};
    try {
      final res = await widget.api.post('/api/sales', body, extraHeaders: {'Idempotency-Key': idem});
      if (res['data'] != null) { final receipt = res['data']; if (mounted) { setState(() { _msg = 'تم البيع ب$method - ${receipt['receiptNo'] ?? receipt['receipt_no'] ?? ''}'; _cart.clear(); }); _showReceipt(receipt, method, soldItems); } }
      else if (res['error'] != null) { setState(() => _msg = res['error']['message'] ?? res.toString()); }
      else { setState(() => _msg = res.toString()); }
    } catch (e) { widget.syncQueue.enqueue(SyncItem(clientId: idem, type: 'sale', payloadJson: body.toString())); setState(() => _msg = 'غير متصل - حفظ محليا'); }
    setState(() => _paying = false);
  }

  void _showReceipt(Map sale, String method, List<Map<String, dynamic>> soldItems) {
    final items = (sale['items'] ?? []) as List;
    final names = soldItems.map((e) => e['name'].toString()).toList();
    final receiptNo = sale['receiptNo'] ?? sale['receipt_no'] ?? '';
    final grand = sale['grandTotal'] ?? sale['grand_total'] ?? 0;
    final total = sale['total'] ?? grand;
    // Build line rows combining sale item qty/price with captured product name
    final rows = items.asMap().entries.map((en) {
      final it = en.value;
      final nm = en.key < names.length ? names[en.key] : '${it['productId']}'.toString().substring(0, 8);
      final qty = it['qty'] ?? 1;
      final price = it['unitPrice'] ?? it['unit_price'] ?? 0;
      final line = double.tryParse('${it['lineTotal'] ?? it['line_total'] ?? 0}') ?? 0;
      return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(nm, style: const TextStyle(fontSize: 11))), Text('${qty} x $price', style: const TextStyle(fontSize: 11)), Text('$line', style: const TextStyle(fontSize: 11))]));
    }).toList();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.receipt_long, color: Colors.green), SizedBox(width: 8), Text('فاتورة', style: TextStyle(fontWeight: FontWeight.bold))]),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Text(receiptNo, style: const TextStyle(fontWeight: FontWeight.bold))), const Divider(),
        ...rows,
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('المجموع'), Text('$total JOD', style: const TextStyle(fontWeight: FontWeight.w800))]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('طريقة الدفع'), Text(method == 'cash' ? 'نقدي' : method, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8), const Center(child: Text('شكراً لزيارتكم', style: TextStyle(fontWeight: FontWeight.bold))),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')), ElevatedButton.icon(onPressed: () { Navigator.pop(ctx); _printThermal(names, items, receiptNo, total, method); }, icon: const Icon(Icons.print), label: const Text('طباعة حرارية'))],
    ));
  }

  // Direct thermal (ESC/POS style) print via browser print window sized for 80mm receipt
  Future<void> _printThermal(List<String> names, List items, String receiptNo, double total, String method) async {
    final settings = await PrinterSettingsStore.load();
    final mm = settings.mm;
    final now = DateTime.now().toString().substring(0, 19);
    // Shared cell style helpers sized per paper width
    final fs = settings.fontSize;
    final itemFs = fs - 1;
    // Build line rows (product / qty x price / line)
    StringBuffer rows() {
      final b = StringBuffer();
      var i = 0;
      for (final it in items) {
        final nm = names.isNotEmpty && i < names.length ? names[i] : '${it['productId']}'.toString().substring(0, 8);
        final qty = it['qty'] ?? 1;
        final price = it['unitPrice'] ?? it['unit_price'] ?? 0;
        final line = double.tryParse('${it['lineTotal'] ?? it['line_total'] ?? 0}') ?? 0;
        b.writeln('<tr><td style="font-family:Arial,Tahoma,sans-serif;font-size:${itemFs}px;word-break:break-word;padding:1px 0;">$nm</td><td style="font-family:monospace;font-size:${itemFs}px;text-align:right;white-space:nowrap;">$qty x $price</td><td style="font-family:monospace;font-size:${itemFs}px;text-align:right;white-space:nowrap;">$line</td></tr>');
        i++;
      }
      return b;
    }
    final methodLabel = method == 'cash' ? 'نقدي' : (method == 'card' ? 'بطاقة' : (method == 'transfer' ? 'تحويل' : (method == 'wallet' ? 'محفظة' : method)));

    // ---- CUSTOMER RECEIPT (full: prices + totals) ----
    final custHtml = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head><meta charset="utf-8"><title>فاتورة $receiptNo</title></head>
<body style="width:${mm}mm;margin:0 auto;font-family:Arial,Tahoma,sans-serif;">
  <div style="text-align:center;">
    <div style="font-size:${fs + 3}px;font-weight:${settings.boldHeader ? 'bold' : 'normal'};">نقطة البيع</div>
    <div style="font-size:${fs}px;">فاتورة الزبون</div>
    <div style="font-size:${fs}px;font-weight:bold;">$receiptNo</div>
    <div style="font-size:${itemFs}px;color:#666;">$now</div>
  </div>
  <hr style="border-top:1px dashed #000;">
  <table style="width:100%;border-collapse:collapse;">
    <tr><th style="text-align:right;font-size:${itemFs}px;border-bottom:1px solid #000;">الصنف</th><th style="text-align:right;font-size:${itemFs}px;border-bottom:1px solid #000;">كمية</th><th style="text-align:right;font-size:${itemFs}px;border-bottom:1px solid #000;">إجمالي</th></tr>
    ${rows()}
  </table>
  <hr style="border-top:1px dashed #000;">
  <div style="display:flex;justify-content:space-between;font-size:${fs + 2}px;font-weight:bold;"><span>المجموع</span><span>$total</span></div>
  <div style="display:flex;justify-content:space-between;font-size:${fs}px;"><span>طريقة الدفع</span><span>$methodLabel</span></div>
  <div style="display:flex;justify-content:space-between;font-size:${fs}px;"><span>المدفوع</span><span>$total</span></div>
  <br>
  <div style="text-align:center;font-size:${fs}px;font-weight:bold;">شكراً لزيارتكم</div>
</body>
</html>''';

    // ---- KITCHEN TICKET (order only: qty + product, no prices) ----
    StringBuffer kitchenRows() {
      final b = StringBuffer();
      var i = 0;
      for (final it in items) {
        final nm = names.isNotEmpty && i < names.length ? names[i] : '${it['productId']}'.toString().substring(0, 8);
        final qty = it['qty'] ?? 1;
        b.writeln('<tr><td style="font-family:Arial,Tahoma,sans-serif;font-size:${fs}px;padding:3px 0;font-weight:bold;">$nm</td><td style="text-align:center;font-size:${fs + 3}px;font-weight:bold;color:#cc0000;">$qty</td></tr>');
        i++;
      }
      return b;
    }
    final kitchenHtml = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head><meta charset="utf-8"><title>مطبخ $receiptNo</title></head>
<body style="width:${mm}mm;margin:0 auto;font-family:Arial,Tahoma,sans-serif;">
  <div style="text-align:center;">
    <div style="font-size:${fs + 5}px;font-weight:bold;">أمر مطبخ</div>
    <div style="font-size:${fs + 1}px;font-weight:bold;">$receiptNo</div>
    <div style="font-size:${itemFs}px;color:#666;">$now</div>
  </div>
  <hr style="border-top:1px dashed #000;">
  <table style="width:100%;border-collapse:collapse;">
    <tr><th style="text-align:right;font-size:${itemFs}px;border-bottom:1px solid #000;">الصنف</th><th style="text-align:center;font-size:${itemFs}px;border-bottom:1px solid #000;">كمية</th></tr>
    ${kitchenRows()}
  </table>
  <hr style="border-top:1px dashed #000;">
  <div style="text-align:center;font-size:${fs}px;font-weight:bold;">الرجاء تجهيز الطلب</div>
</body>
</html>''';

    // Print customer receipt (N copies) then kitchen ticket (same receipt number)
    final custUri = 'data:text/html;base64,${base64Encode(utf8.encode(custHtml))}';
    var copies = settings.customerCopies < 1 ? 1 : settings.customerCopies;
    for (var c = 0; c < copies; c++) {
      Future.delayed(Duration(milliseconds: c * 500), () {
        webprint.printThermalReceipt(custUri, mm: mm);
      });
    }
    if (settings.printKitchen) {
      Future.delayed(Duration(milliseconds: copies * 500 + 400), () {
        webprint.printThermalReceipt('data:text/html;base64,${base64Encode(utf8.encode(kitchenHtml))}', mm: mm);
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الطباعة: ✓ فاتورة الزبون${settings.printKitchen ? ' + أمر المطبخ' : ''} — $receiptNo')));
    }
  }

  Widget _productCard(Map p, BuildContext context) {
    final price = (p['sellPrice'] ?? p['sell_price'] ?? 0).toDouble();
    final sku = p['sku'] ?? '';
    final name = p['nameAr'] ?? p['name_ar'] ?? p['nameEn'] ?? 'منتج';
    final rawImg = p['imageUrl'] ?? p['image_url'];
    final img = rawImg != null && (rawImg as String).isNotEmpty ? AppConfig.resolveImageUrl(rawImg.toString()) : null;
    final inCart = _cart.any((e) => e['id'] == p['id']);
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: inCart ? cs.primary : Colors.transparent, width: inCart ? 2 : 0)),
      child: InkWell(
        onTap: () => _addToCart(p),
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF6D5BD0).withOpacity(0.10), const Color(0xFF00BFA6).withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Center(child: img != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: 34, color: Colors.grey.shade400))) : Icon(Icons.inventory_2_rounded, size: 36, color: Colors.grey.shade400)))),
          Container(padding: const EdgeInsets.fromLTRB(8, 8, 8, 8), color: Colors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)), child: Text('${price.toStringAsFixed(2)} JOD', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)))), const Spacer(), if (inCart) const Icon(Icons.check_circle, size: 16, color: Colors.green)]), Text(sku, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey))]))]))); }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final mobileCols = MediaQuery.of(context).size.width < 400 ? 2 : (MediaQuery.of(context).size.width < 600 ? 3 : null);
    final cols = mobileCols ?? (isWide ? 4 : 2);
    final grid = Expanded(
      flex: 2,
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: TextField(controller: _barcodeCtrl, decoration: InputDecoration(hintText: 'بحث الاسم / SKU / امسح الباركود ثم Enter', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => _scanBarcode(_barcodeCtrl.text)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: const Color(0xFFF9F9FB)), onSubmitted: _scanBarcode)),
        Expanded(child: _products.isEmpty ? const Center(child: Text('لا توجد منتجات — أضف من المنتجات')) : GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, childAspectRatio: isWide ? 0.82 : 0.72, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _products.length, itemBuilder: (_, i) => _productCard(_products[i] as Map, context))) ]));
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
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _payBtn('💵 نقدي', Icons.payments, _paying ? null : () => _pay()),
                    _payBtn('💳 بطاقة', Icons.credit_card, _paying ? null : () => _payCard('card')),
                    _payBtn('🏦 تحويل', Icons.account_balance, _paying ? null : () => _payCard('transfer')),
                    _payBtn('📱 محفظة', Icons.wallet, _paying ? null : () => _payCard('wallet')),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFAE7DC9),
      appBar: AppBar(title: const Text('نقطة البيع')),
      body: isWide ? Row(children: [grid, cart]) : Column(children: [SizedBox(height: 280, child: grid), Expanded(child: cart)]),
    );
  }

  Widget _payBtn(String label, IconData icon, VoidCallback? onPressed) {
    return SizedBox(
      width: _cartLayoutCompact() ? 110 : 130,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6D5BD0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  bool _cartLayoutCompact() => MediaQuery.of(context).size.width < 700;
}
