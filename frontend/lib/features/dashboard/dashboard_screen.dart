import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/money_display.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _daily;
  Map<String, dynamic>? _profit;
  List _top = [];
  String? _err;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1).toIso8601String();
      final to = now.toIso8601String();
      // tenantId will be resolved from JWT in hardened backend; fallback demo tenant lookup
      final tenants = await widget.api.get('/api/tenants').catchError((e) => {'data': []});
      final tid = (tenants['data'] is List && (tenants['data'] as List).isNotEmpty) ? tenants['data'][0]['id'] : null;
      final qp = tid != null ? 'tenantId=$tid' : '';
      final daily = await widget.api.get('/api/reports/daily-sales?${qp.isNotEmpty ? "$qp&" : ""}date=${now.toIso8601String()}');
      final profit = await widget.api.get('/api/reports/profit?${qp.isNotEmpty ? "$qp&" : ""}from=$from&to=$to');
      final top = await widget.api.get('/api/reports/top-products?${qp.isNotEmpty ? "$qp&" : ""}from=$from&to=$to&take=5');
      setState(() { _daily = daily['data']; _profit = profit['data']; _top = top['data'] ?? []; });
    } catch (e) { setState(() => _err = e.toString()); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_err != null) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_err!, style: const TextStyle(color: Colors.red)))),
        LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 900 ? 3 : c.maxWidth > 600 ? 2 : 1;
          return GridView.count(crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 2.2, children: [
            _KpiCard(title: 'مبيعات اليوم', value: MoneyDisplay(amount: double.tryParse('${_daily?['total'] ?? 0}') ?? 0), subtitle: '${_daily?['count'] ?? 0} فواتير'),
            _KpiCard(title: 'الإيراد (الشهر)', value: MoneyDisplay(amount: double.tryParse('${_profit?['revenue'] ?? 0}') ?? 0), subtitle: 'التكلفة ${(_profit?['cost'] ?? 0)}'),
            _KpiCard(title: 'الربح', value: MoneyDisplay(amount: double.tryParse('${_profit?['profit'] ?? 0}') ?? 0), subtitle: 'هامش ${(_profit?['margin'] ?? 0).toStringAsFixed(1)}%'),
          ]);
        }),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('الأكثر مبيعا', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._top.map((e) => ListTile(dense: true, title: Text('${e['productId']}'), trailing: Text('qty ${e['qty']}'))),
          if (_top.isEmpty) const Text('لا توجد بيانات بعد', style: TextStyle(color: Colors.grey)),
        ]))),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value, required this.subtitle});
  final String title; final Widget value; final String subtitle;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 8), value, const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))])) );
}
