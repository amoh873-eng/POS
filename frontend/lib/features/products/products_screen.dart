import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/app_config.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List _items = [];
  final _q = TextEditingController();
  String? _msg;
  Map? _sel;
  Future<void> _load() async {
    final q = _q.text.isNotEmpty ? 'q=${Uri.encodeComponent(_q.text)}' : '';
    final url = q.isEmpty ? '/api/products?page=1&pageSize=50' : '/api/products?page=1&pageSize=50&$q';
    try { final r = await widget.api.get(url); if (!mounted) return; setState(() { _items = r['data'] ?? []; _msg = null; }); } catch (e) { if (mounted) setState(() => _msg = e.toString()); }
  }
  Future<void> _form({Map? ex}) async {
    final ar = TextEditingController(text: ex?['nameAr'] ?? ex?['name_ar'] ?? '');
    final en = TextEditingController(text: ex?['nameEn'] ?? ex?['name_en'] ?? '');
    final sku = TextEditingController(text: ex?['sku'] ?? '');
    final bc = TextEditingController(text: ex?['barcodeMain'] ?? ex?['barcode_main'] ?? '');
    final cost = TextEditingController(text: '${ex?['costPrice'] ?? ex?['cost_price'] ?? ''}');
    final sell = TextEditingController(text: '${ex?['sellPrice'] ?? ex?['sell_price'] ?? ''}');
    final img = TextEditingController(text: ex?['imageUrl'] ?? ex?['image_url'] ?? '');
    final desc = TextEditingController(text: ex?['description'] ?? '');
    final minStock = TextEditingController(text: '${ex?['minStockLevel'] ?? ex?['min_stock_level'] ?? 5}');
    Uint8List? pickedBytes;
    String? pickedName;
    double uploadProgress = 0;
    String? pendingImageUrl;
    bool picking = false;
    String? localErr;
    final repoId = ex?['id'] as String?;
    final r2 = await showDialog<Map?>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text(ex == null ? 'إضافة منتج' : 'تعديل منتج'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ar, decoration: const InputDecoration(labelText: 'الاسم عربي *', prefixIcon: Icon(Icons.label))),
          const SizedBox(height: 8),
          TextField(controller: en, decoration: const InputDecoration(labelText: 'الاسم إنجليزي')),
          const SizedBox(height: 8),
          TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU *', prefixIcon: Icon(Icons.qr_code))),
          const SizedBox(height: 8),
          TextField(controller: bc, decoration: const InputDecoration(labelText: 'باركود', prefixIcon: Icon(Icons.barcode_reader))),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: TextField(controller: cost, decoration: const InputDecoration(labelText: 'التكلفة'), keyboardType: TextInputType.number)), const SizedBox(width: 8), Expanded(child: TextField(controller: sell, decoration: const InputDecoration(labelText: 'البيع *'), keyboardType: TextInputType.number))]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ElevatedButton.icon(icon: picking ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_library, size: 18), label: Text(picking ? 'جاري...' : 'اختيار صورة (معرض/كاميرا)'), onPressed: picking ? null : () async {
              setD(() => picking = true);
              try {
                final picker = ImagePicker();
                // On mobile, allow user to choose gallery; on web, gallery is default. Keep quality bounded for upload.
                final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
                if (f != null) {
                  final bytes = await f.readAsBytes();
                  if (bytes.length > 2 * 1024 * 1024) { setD(() { localErr = 'الصورة كبيرة جداً (أكثر من 2MB) — اختر صورة أصغر'; picking = false; }); return; }
                  setD(() { pickedBytes = bytes; pickedName = f.name; pendingImageUrl = null; img.clear(); localErr = null; });
                }
              } catch (e) { setD(() => localErr = 'فشل اختيار الصورة: $e'); }
              setD(() => picking = false);
            })),
            const SizedBox(width: 8),
            if (pickedBytes != null || img.text.trim().isNotEmpty || (ex?['imageUrl'] != null && (ex!['imageUrl'] as String).isNotEmpty))
              TextButton(onPressed: () => setD(() { pickedBytes = null; pickedName = null; pendingImageUrl = null; img.clear(); }), child: const Text('إزالة')),
          ]),
          if (pickedBytes != null) Padding(padding: const EdgeInsets.only(top: 8), child: Column(children: [ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(pickedBytes!, height: 90, fit: BoxFit.cover)), const SizedBox(height: 4), Text(pickedName ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey))])),
          if (pickedBytes == null && img.text.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(AppConfig.resolveImageUrl(img.text.trim()), height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('رابط غير صالح', style: TextStyle(color: Colors.red, fontSize: 11))))),
          if (pendingImageUrl != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('تم رفع الصورة ✓', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600))),
          if (uploadProgress > 0 && uploadProgress < 1) Padding(padding: const EdgeInsets.only(top: 6), child: LinearProgressIndicator(value: uploadProgress)),
          const SizedBox(height: 8),
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'الوصف'), maxLines: 2),
          const SizedBox(height: 8),
          TextField(controller: minStock, decoration: const InputDecoration(labelText: 'الحد الأدنى للمخزون'), keyboardType: TextInputType.number),
          if (localErr != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(localErr!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), ElevatedButton(onPressed: () async {
          if (sku.text.trim().isEmpty) { setD(() => localErr = 'SKU مطلوب'); return; }
          if ((double.tryParse(sell.text) ?? -1) < 0) { setD(() => localErr = 'سعر البيع غير صالح'); return; }
          // If user picked a file, upload first then return with imageUrl
          String? finalImage = img.text.trim().isEmpty ? null : img.text.trim();
          if (pickedBytes != null) {
            setD(() => uploadProgress = 0.3);
            try {
              String targetId = repoId ?? '';
              if (targetId.isEmpty) {
                // Create placeholder product first to get id, then upload
                final tmp = await widget.api.post('/api/products', {'nameAr': ar.text.trim(), 'nameEn': en.text.trim(), 'sku': sku.text.trim(), 'barcodeMain': bc.text.trim().isEmpty ? null : bc.text.trim(), 'costPrice': double.tryParse(cost.text) ?? 0, 'sellPrice': double.tryParse(sell.text) ?? 0, 'unit': 'pcs', 'isActive': true, 'description': desc.text.trim().isEmpty ? null : desc.text.trim(), 'minStockLevel': double.tryParse(minStock.text) ?? 5});
                if (tmp['error'] != null) { setD(() { localErr = tmp['error']['message'] ?? tmp.toString(); uploadProgress = 0; }); return; }
                targetId = tmp['data']['id'];
                final b64 = base64Encode(pickedBytes!);
                final up = await widget.api.post('/api/products/$targetId/image', {'imageBase64': b64, 'fileName': pickedName ?? 'image.jpg'});
                if (up['error'] != null) { setD(() => localErr = up['error']['message'] ?? up.toString()); return; }
                if (mounted) Navigator.pop(context, {'__createdWithImage': true, 'id': targetId});
                return;
              } else {
                final b64 = base64Encode(pickedBytes!);
                final up = await widget.api.post('/api/products/$targetId/image', {'imageBase64': b64, 'fileName': pickedName ?? 'image.jpg'});
                if (up['error'] != null) { setD(() => localErr = up['error']['message'] ?? up.toString()); return; }
                finalImage = up['data']?['imageUrl'] ?? up['data']?['image_url'];
              }
            } catch (e) { setD(() { localErr = e.toString(); uploadProgress = 0; }); return; }
          }
          Navigator.pop(context, {'nameAr': ar.text.trim(), 'nameEn': en.text.trim(), 'sku': sku.text.trim(), 'barcodeMain': bc.text.trim().isEmpty ? null : bc.text.trim(), 'costPrice': double.tryParse(cost.text) ?? 0, 'sellPrice': double.tryParse(sell.text) ?? 0, 'unit': 'pcs', 'isActive': true, 'imageUrl': finalImage, 'description': desc.text.trim().isEmpty ? null : desc.text.trim(), 'minStockLevel': double.tryParse(minStock.text) ?? 5});
        }, child: const Text('حفظ'))],
      )),
    );
    if (r2 == null) return;
    if (r2['__createdWithImage'] == true) { if (mounted) _load(); return; }
    try {
      final repo = ex == null ? await widget.api.post('/api/products', r2) : await widget.api.patch('/api/products/${ex['id']}', r2);
      if (repo['error'] != null) { if (mounted) setState(() => _msg = repo['error']['message'] ?? repo.toString()); return; }
      if (mounted) _load();
    } catch (e) { if (mounted) setState(() => _msg = e.toString()); }
  }

  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _q, decoration: const InputDecoration(hintText: 'بحث بالاسم / SKU / باركود...'), onSubmitted: (_) => _load())),
      body: Column(children: [
        if (_msg != null) Container(width: double.infinity, color: Colors.red.shade50, padding: const EdgeInsets.all(8), child: Text(_msg!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        Expanded(child: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) { final m = _items[i] as Map; final name = m['nameAr'] ?? m['name_ar'] ?? m['nameEn'] ?? ''; final rawImg = m['imageUrl'] ?? m['image_url']; final img = rawImg != null && (rawImg as String).isNotEmpty ? AppConfig.resolveImageUrl(rawImg) : null; return ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: img != null ? Image.network(img, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: const Color(0xFFF0F0F5), child: const Icon(Icons.image, size: 20, color: Colors.grey))) : Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2, color: Colors.grey))), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('SKU: ${m['sku'] ?? ''}  |  Barcode: ${m['barcodeMain'] ?? m['barcode_main'] ?? '-'}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _form(ex: m)), IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('حذف المنتج'), content: Text('هل تريد حذف $name؟'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف'))])); if (ok == true) { try { final r = await widget.api.patch('/api/products/${m['id']}/deactivate', {}); if (r['error'] != null) { if (mounted) setState(() => _msg = r['error']['message'] ?? r.toString()); } else { _load(); } } catch (e) { if (mounted) setState(() => _msg = e.toString()); } } })]), onTap: () => setState(() => _sel = m)); })),
        if (_sel != null) Builder(builder: (_) { final rawSelImg = _sel!['imageUrl'] ?? _sel!['image_url']; final selImg = rawSelImg != null && (rawSelImg as String).isNotEmpty ? AppConfig.resolveImageUrl(rawSelImg) : null; return Card(margin: const EdgeInsets.all(8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (selImg != null) Center(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(selImg, height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40)))), const SizedBox(height: 8), Text('تفاصيل: ${_sel!['nameAr'] ?? _sel!['name_ar'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('SKU: ${_sel!['sku'] ?? ''}  Barcode: ${_sel!['barcodeMain'] ?? _sel!['barcode_main'] ?? '-'}'), Text('البيع: ${_sel!['sellPrice'] ?? _sel!['sell_price'] ?? 0}  التكلفة: ${_sel!['costPrice'] ?? _sel!['cost_price'] ?? 0}'), Text('الوصف: ${_sel!['description'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)), Text('الحد الأدنى: ${_sel!['minStockLevel'] ?? _sel!['min_stock_level'] ?? 0}', style: const TextStyle(fontSize: 11, color: Colors.orange))]))); }),
      ]),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [FloatingActionButton.small(heroTag: 'add', onPressed: () => _form(), child: const Icon(Icons.add)), const SizedBox(height: 8), FloatingActionButton.small(heroTag: 'refresh', onPressed: _load, child: const Icon(Icons.refresh))]),
    );
  }
}
