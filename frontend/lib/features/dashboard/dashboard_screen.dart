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
    if (!mounted) return;
    setState(() { _loading = true; _err = null; });
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1).toIso8601String();
      final to = now.toIso8601String();
      final daily = await widget.api.get('/api/reports/daily-sales?date=${now.toIso8601String()}');
      final profit = await widget.api.get('/api/reports/profit?from=$from&to=$to');
      final top = await widget.api.get('/api/reports/top-products?from=$from&to=$to&take=5');
      if (!mounted) return;
      setState(() { _daily = daily['data']; _profit = profit['data']; _top = top['data'] ?? []; });
    } catch (e) { if (mounted) setState(() => _err = e.toString()); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_err != null) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_err!, style: const TextStyle(color: Colors.red)))),
        LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 900 ? 3 : c.maxWidth > 600 ? 2 : 1;
          return GridView.count(
            crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.1,
            children: [
              _KpiCard(title: 'مبيعات اليوم', icon: Icons.today, color: const Color(0xFF6D5BD0), value: MoneyDisplay(amount: double.tryParse('${_daily?['total'] ?? 0}') ?? 0), subtitle: '${_daily?['count'] ?? 0} فواتير'),
              _KpiCard(title: 'الإيراد (الشهر)', icon: Icons.trending_up, color: const Color(0xFF00BFA6), value: MoneyDisplay(amount: double.tryParse('${_profit?['revenue'] ?? 0}') ?? 0), subtitle: 'التكلفة ${(_profit?['cost'] ?? 0)}'),
              _KpiCard(title: 'الربح', icon: Icons.account_balance_wallet, color: const Color(0xFFFF8A00), value: MoneyDisplay(amount: double.tryParse('${_profit?['profit'] ?? 0}') ?? 0), subtitle: 'هامش ${(_profit?['margin'] ?? 0).toStringAsFixed(1)}%'),
            ],
          );
        }),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.star, size: 18, color: cs.primary), const SizedBox(width: 6), const Text('الأكثر مبيعاً', style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          ..._top.map((e) => ListTile(dense: true, leading: CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(Icons.inventory_2, size: 16, color: cs.onPrimaryContainer)), title: Text('${e['productId']}'.toString().substring(0, 8)), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(20)), child: Text('qty ${e['qty']}')))),
          if (_top.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('لا توجد بيانات بعد', style: TextStyle(color: Colors.grey))),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(Icons.groups, color: cs.primary), const SizedBox(width: 8), const Text('المبيعات تُحدّث لحظياً من قاعدة البيانات', style: TextStyle(fontSize: 12, color: Colors.grey))]))),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});
  final String title; final Widget value; final String subtitle; final IconData icon; final Color color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12))) ]), const SizedBox(height: 10), value, const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))])) );
}
