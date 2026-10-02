import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/app_config.dart';
import '../../core/printer_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api, required this.onLocaleChanged});
  final ApiClient api;
  final ValueChanged<String> onLocaleChanged;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _settings;
  String? _err;
  bool _loading = true;
  String _locale = 'ar';
  String _serverStatus = '';
  bool _testing = false;
  final _nameCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  final _joClientIdCtrl = TextEditingController();
  final _joSecretKeyCtrl = TextEditingController();
  final _joActivityCtrl = TextEditingController();
  bool _joEnabled = false;
  String _joEnv = 'sandbox';
  bool _saving = false;
  // Printer settings
  PrinterSettings _printer = PrinterSettings();
  final _printerNameCtrl = TextEditingController();
  final _kitchenNameCtrl = TextEditingController();
  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _err = null; });
    try {
      final r = await widget.api.get('/api/tenant-settings');
      final data = r['data'] ?? r;
      if (mounted) {
        setState(() { 
        _settings = data; 
        _nameCtrl.text = (data?['businessName'] ?? data?['business_name'] ?? '').toString(); 
        _currencyCtrl.text = (data?['currency'] ?? 'JOD').toString(); 
        _locale = (data?['language'] ?? 'ar').toString(); 
        _joEnabled = data?['joInvoiceEnabled'] ?? data?['jo_invoice_enabled'] ?? false;
        _joClientIdCtrl.text = (data?['joInvoiceClientId'] ?? data?['jo_invoice_client_id'] ?? '').toString();
        _joSecretKeyCtrl.text = (data?['joInvoiceSecretKey'] ?? data?['jo_invoice_secret_key'] ?? '').toString();
        _joActivityCtrl.text = (data?['joInvoiceActivityNumber'] ?? data?['jo_invoice_activity_number'] ?? '').toString();
        _joEnv = (data?['joInvoiceEnvironment'] ?? data?['jo_invoice_environment'] ?? 'sandbox').toString();
      });
      }
    } catch (e) { if (mounted) setState(() => _err = e.toString()); }
    if (mounted) setState(() => _loading = false);
  }
  Future<void> _save() async {
    setState(() { _saving = true; _err = null; });
    try {
      final r = await widget.api.patch('/api/tenant-settings', {
        'businessName': _nameCtrl.text.trim(), 
        'currency': _currencyCtrl.text.trim(), 
        'language': _locale,
        'joInvoiceEnabled': _joEnabled,
        'joInvoiceClientId': _joClientIdCtrl.text.trim(),
        'joInvoiceSecretKey': _joSecretKeyCtrl.text.trim(),
        'joInvoiceActivityNumber': _joActivityCtrl.text.trim(),
        'joInvoiceEnvironment': _joEnv,
      });
      if (r['error'] != null) { setState(() => _err = r['error']['message'] ?? r.toString()); } else { setState(() { _settings = r['data'] ?? r; _err = '✓ تم الحفظ'; }); widget.onLocaleChanged(_locale); }
    } catch (e) { setState(() => _err = e.toString()); }
    setState(() => _saving = false);
  }
  Future<void> _testConnection() async {
    setState(() { _testing = true; _serverStatus = 'جاري الفحص...'; });
    try {
      final r = await widget.api.get('/health');
      if (r.toString().contains('Healthy') || r.toString().contains('ok')) {
        setState(() => _serverStatus = '🟢 متصل: ${AppConfig.baseUrl}');
      } else {
        setState(() => _serverStatus = '🟠 استجابة غير متوقعة');
      }
    } catch (e) { setState(() => _serverStatus = '🔴 فشل: ${e.toString().split('\n').first}'); }
    setState(() => _testing = false);
  }
  @override
  void initState() { super.initState(); _load(); _loadPrinter(); }

  Future<void> _loadPrinter() async {
    final p = await PrinterSettingsStore.load();
    if (mounted) {
      setState(() {
        _printer = p;
        _printerNameCtrl.text = p.receiptPrinter;
        _kitchenNameCtrl.text = p.kitchenPrinter;
      });
    }
  }

  Future<void> _savePrinter() async {
    final copy = PrinterSettings();
    copy.receiptPrinter = _printerNameCtrl.text.trim().isEmpty ? 'ESCPOS Receipt' : _printerNameCtrl.text.trim();
    copy.kitchenPrinter = _kitchenNameCtrl.text.trim().isEmpty ? 'KITCHEN-PRINTER' : _kitchenNameCtrl.text.trim();
    copy.paperSize = _printer.paperSize;
    copy.printKitchen = _printer.printKitchen;
    copy.customerCopies = _printer.customerCopies;
    copy.fontSize = _printer.fontSize;
    copy.boldHeader = _printer.boldHeader;
    await PrinterSettingsStore.save(copy);
    if (mounted) setState(() { _printer = copy; _err = '✓ تم حفظ إعدادات الطابعة'; });
  }

  Future<void> _testPrinter() async {
    if (mounted) setState(() => _err = 'اختبار الطباعة يُفتح نافذة تأكيد — شغّل فترة تجريبية من POS إن أمكن');
  }

  @override
  void dispose() { 
    _nameCtrl.dispose(); 
    _currencyCtrl.dispose(); 
    _printerNameCtrl.dispose(); 
    _kitchenNameCtrl.dispose(); 
    _joClientIdCtrl.dispose();
    _joSecretKeyCtrl.dispose();
    _joActivityCtrl.dispose();
    super.dispose(); 
  }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_err != null) Card(color: _err!.startsWith('✓') ? Colors.green.shade50 : Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_err!, style: TextStyle(color: _err!.startsWith('✓') ? Colors.green.shade700 : Colors.red, fontSize: 12)))),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.store, color: cs.primary)), const SizedBox(width: 10), const Text('المتجر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم النشاط *', prefixIcon: Icon(Icons.business), border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: TextField(controller: _currencyCtrl, decoration: const InputDecoration(labelText: 'العملة', prefixIcon: Icon(Icons.attach_money)))), const SizedBox(width: 10), Expanded(child: DropdownButtonFormField<String>(initialValue: _locale, decoration: const InputDecoration(labelText: 'اللغة'), items: const [DropdownMenuItem(value: 'ar', child: Text('العربية')), DropdownMenuItem(value: 'en', child: Text('English'))], onChanged: (v) { if (v != null) setState(() => _locale = v); }))]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save), label: const Text('حفظ'))),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.wifi, color: cs.primary), const SizedBox(width: 8), const Text('الشبكة والخادم', style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          Text('الخادم الحالي: ${AppConfig.baseUrl}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _testing ? null : _testConnection, icon: _testing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_done, size: 18), label: const Text('اختبار الاتصال')))]),
          if (_serverStatus.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_serverStatus, style: const TextStyle(fontSize: 12))),
          const SizedBox(height: 6),
          const Text('للموبايل استخدم IP الشبكة مثل http://192.168.8.11:5000 ثم أعد بناء الواجهة بـ --dart-define=API_BASE_URL', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_long, color: Colors.blue)), const SizedBox(width: 10), const Text('الربط مع الفوترة الوطنية (الأردن)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 12),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('تفعيل الربط الإلكتروني مع JoFotara', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('إرسال الفواتير لحظياً لدائرة الضريبة', style: TextStyle(fontSize: 12)), value: _joEnabled, onChanged: (v) => setState(() => _joEnabled = v)),
          if (_joEnabled) ...[
            const SizedBox(height: 10),
            TextField(controller: _joClientIdCtrl, decoration: const InputDecoration(labelText: 'رقم المستخدم (Client ID) *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _joSecretKeyCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'المفتاح السري (Secret Key) *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _joActivityCtrl, decoration: const InputDecoration(labelText: 'رقم تسلسل مصدر الدخل *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(initialValue: _joEnv, decoration: const InputDecoration(labelText: 'بيئة العمل'), items: const [DropdownMenuItem(value: 'sandbox', child: Text('بيئة التجربة (Sandbox)')), DropdownMenuItem(value: 'production', child: Text('البيئة الفعلية (Production)'))], onChanged: (v) { if (v != null) setState(() => _joEnv = v); }),
          ],
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.cloud_upload), label: const Text('حفظ إعدادات الفوترة'))),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFAE7DC9).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.print, color: Color(0xFF8A4FB0))), const SizedBox(width: 10), const Text('الطابعة (ESCPOS/Thermal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 12),
          TextField(controller: _printerNameCtrl, decoration: const InputDecoration(labelText: 'طابعة الفواتير (الزبون)', hintText: 'e.g. ESCPOS Receipt / 80mm Thermal', prefixIcon: Icon(Icons.receipt), border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _kitchenNameCtrl, decoration: const InputDecoration(labelText: 'طابعة المطبخ', hintText: 'e.g. KITCHEN-PRINTER', prefixIcon: Icon(Icons.restaurant), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(initialValue: _printer.paperSize, decoration: const InputDecoration(labelText: 'حجم الورق*', prefixIcon: Icon(Icons.straighten)), items: const [DropdownMenuItem(value: '80mm', child: Text('80mm (قياسي)')), DropdownMenuItem(value: '58mm', child: Text('58mm (صغير)'))], onChanged: (v) { if (v != null) setState(() => _printer.paperSize = v); })),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField<int>(initialValue: _printer.fontSize, decoration: const InputDecoration(labelText: 'حجم الخط'), items: const [DropdownMenuItem(value: 10, child: Text('صغير 10')), DropdownMenuItem(value: 12, child: Text('عادي 12')), DropdownMenuItem(value: 14, child: Text('كبير 14'))], onChanged: (v) { if (v != null) setState(() => _printer.fontSize = v); })),
          ]),
          const SizedBox(height: 10),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('✔ طباعة أمر المطبخ تلقائياً', style: TextStyle(fontSize: 13)), value: _printer.printKitchen, onChanged: (v) => setState(() => _printer.printKitchen = v)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('✔ عنوان الفاتورة بخط عريض', style: TextStyle(fontSize: 13)), value: _printer.boldHeader, onChanged: (v) => setState(() => _printer.boldHeader = v)),
          Row(children: [
            Expanded(child: Text('عدد نسخ فاتورة الزبون: ${_printer.customerCopies}', style: const TextStyle(fontSize: 12))),
            IconButton(onPressed: () => setState(() { if (_printer.customerCopies > 1) _printer.customerCopies--; }), icon: const Icon(Icons.remove_circle_outline)),
            IconButton(onPressed: () => setState(() { if (_printer.customerCopies < 4) _printer.customerCopies++; }), icon: const Icon(Icons.add_circle_outline)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: _savePrinter, icon: const Icon(Icons.save), label: const Text('حفظ الإعدادات'))),
            const SizedBox(width: 10),
            OutlinedButton.icon(onPressed: _testPrinter, icon: const Icon(Icons.print), label: const Text('اختبار')),
          ]),
          const SizedBox(height: 6),
          const Text('عند إتمام بيع تتم طباعة فاتورة الزبون (باأسعار والإجمالي) + أمر المطبخ (الأصناف والكميات فقط) بنفس رقم الإيصال.', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const Text('اختر الطابعة 80mm أو 58mm الحرارية وفق عرض الشريط الورقي.', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(_settings.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
      ]),
    );
  }
}
