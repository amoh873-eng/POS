import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/money_display.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _daily;
  Map<String, dynamic>? _profit;
  List _top = [];
  List _inv = [];
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _loading = true;
  String? _err;
  String? _tid;
  Future<void> _bootstrap() async {
    try { final t = await widget.api.get('/api/tenants'); if (t['data'] is List && (t['data'] as List).isNotEmpty) _tid = t['data'][0]['id']; } catch (_) {}
    await _load();
  }
  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final qp = _tid != null ? 'tenantId=$_tid' : '';
      final daily = await widget.api.get('/api/reports/daily-sales?${qp.isNotEmpty ? "$qp&" : ""}date=${_to.toIso8601String()}');
      final profit = await widget.api.get('/api/reports/profit?${qp.isNotEmpty ? "$qp&" : ""}from=${_from.toIso8601String()}&to=${_to.toIso8601String()}');
      final top = await widget.api.get('/api/reports/top-products?${qp.isNotEmpty ? "$qp&" : ""}from=${_from.toIso8601String()}&to=${_to.toIso8601String()}&take=5');
      final inv = await widget.api.get('/api/reports/inventory?${qp.isNotEmpty ? qp : ""}');
      setState(() { _daily = daily['data']; _profit = profit['data']; _top = top['data'] ?? []; _inv = inv['data'] is List ? inv['data'] : []; });
    } catch (e) { setState(() => _err = e.toString()); }
    setState(() => _loading = false);
  }
  @override
  void initState() { super.initState(); _bootstrap(); }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_err != null) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12)))),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: Text('من ${_from.toString().substring(0,10)} الى ${_to.toString().substring(0,10)}')), TextButton(onPressed: () async { final dr = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 1)), initialDateRange: DateTimeRange(start: _from, end: _to)); if (dr != null) setState(() { _from = dr.start; _to = dr.end; }); _load(); }, child: const Text('تغيير الفترة'))]))),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _Kpi(title: 'مبيعات اليوم', value: double.tryParse('${_daily?['total'] ?? 0}') ?? 0, sub: '${_daily?['count'] ?? 0} فواتير'),
          _Kpi(title: 'الايراد', value: double.tryParse('${_profit?['revenue'] ?? 0}') ?? 0, sub: 'الفترة'),
          _Kpi(title: 'الربح', value: double.tryParse('${_profit?['profit'] ?? 0}') ?? 0, sub: 'هامش ${(_profit?['margin'] ?? 0).toStringAsFixed(1)}%'),
        ]),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('الاكثر مبيعا', style: TextStyle(fontWeight: FontWeight.bold)), ..._top.map((e) => ListTile(dense: true, title: Text('${e['productId']}'.substring(0, 8)), trailing: Text('qty ${e['qty']}'))), if (_top.isEmpty) const Text('لا بيانات', style: TextStyle(color: Colors.grey))]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('المخزون', style: TextStyle(fontWeight: FontWeight.bold)), ..._inv.take(10).map((e) => ListTile(dense: true, title: Text('${e['name'] ?? e['productId'] ?? ''}'), trailing: Text('${e['qty'] ?? e['qtyOnHand'] ?? 0} - ${e['status'] ?? ''}'))), if (_inv.isEmpty) const Text('لا بيانات مخزون', style: TextStyle(color: Colors.grey))]))),
      ]),
    );
  }
}
class _Kpi extends StatelessWidget { const _Kpi({required this.title, required this.value, required this.sub}); final String title; final double value; final String sub; @override Widget build(BuildContext context) => SizedBox(width: 160, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 6), MoneyDisplay(amount: value), Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey))])))); }
