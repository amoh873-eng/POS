import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_client.dart';
import '../../core/money_display.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  List _topProducts = [];
  String? _err;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _err = null; });
    try {
      final summaryRes = await widget.api.get('/api/reports/dashboard-summary');
      
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1).toIso8601String();
      final to = now.toIso8601String();
      final topRes = await widget.api.get('/api/reports/top-products?from=$from&to=$to&take=5');

      if (!mounted) return;
      setState(() { 
        _summary = summaryRes['data'];
        _topProducts = topRes['data'] ?? [];
      });
    } catch (e) { if (mounted) setState(() => _err = e.toString()); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cs = Theme.of(context).colorScheme;
    
    final today = _summary?['today'];
    final month = _summary?['month'];
    final inv = _summary?['inventory'];
    final trend = (_summary?['trend'] as List?) ?? [];
    final payments = (_summary?['payments'] as List?) ?? [];
    final categories = (_summary?['categories'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: const Text('لوحة المؤشرات الذكية', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_err != null) _ErrorCard(message: _err!),
            
            // KPI Grid
            LayoutBuilder(builder: (_, constraints) {
              final cols = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 2 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 600 ? 1.8 : 1.4,
                children: [
                  _KpiCard(
                    title: 'مبيعات اليوم',
                    value: '${today?['total'] ?? 0}',
                    subtitle: '${today?['count'] ?? 0} عملية',
                    icon: Icons.shopping_bag,
                    color: const Color(0xFF6D5BD0),
                    isMoney: true,
                  ),
                  _KpiCard(
                    title: 'إيراد الشهر',
                    value: '${month?['revenue'] ?? 0}',
                    subtitle: 'من بداية الشهر',
                    icon: Icons.auto_graph,
                    color: const Color(0xFF00BFA6),
                    isMoney: true,
                  ),
                  _KpiCard(
                    title: 'نقص المخزون',
                    value: '${inv?['lowStockCount'] ?? 0}',
                    subtitle: 'أصناف تحت الحد',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    isAlert: (inv?['lowStockCount'] ?? 0) > 0,
                  ),
                  const _KpiCard(
                    title: 'حالة النظام',
                    value: 'نشط',
                    subtitle: 'متصل بالسحابة',
                    icon: Icons.cloud_done,
                    color: Colors.blue,
                  ),
                ],
              );
            }),
            
            const SizedBox(height: 20),

            // Charts Section
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Sales Trend (Line Chart)
                  SizedBox(
                    width: isWide ? (constraints.maxWidth / 1.6) - 16 : constraints.maxWidth,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('منحنى المبيعات (آخر 7 أيام)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: trend.isEmpty 
                                ? const Center(child: Text('لا توجد بيانات كافية للرسم البياني', style: TextStyle(color: Colors.grey)))
                                : LineChart(
                                    LineChartData(
                                      gridData: const FlGridData(show: false),
                                      titlesData: const FlTitlesData(show: false),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), double.tryParse('${e.value['total']}') ?? 0)).toList(),
                                          isCurved: true,
                                          color: const Color(0xFF6D5BD0),
                                          barWidth: 4,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: true),
                                          belowBarData: BarAreaData(show: true, color: const Color(0xFF6D5BD0).withValues(alpha: 0.1)),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Payment Methods (Pie Chart)
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - (constraints.maxWidth / 1.6)) / 2 - 16 : constraints.maxWidth,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('طرق الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 160,
                              child: payments.isEmpty
                                ? const Center(child: Text('لا بيانات'))
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 30,
                                      sections: payments.map((p) {
                                        final method = p['method']?.toString() ?? 'other';
                                        final total = double.tryParse('${p['total']}') ?? 0;
                                        final color = method == 'cash' ? Colors.green : (method == 'card' ? Colors.blue : Colors.orange);
                                        return PieChartSectionData(
                                          color: color,
                                          value: total,
                                          title: method == 'cash' ? 'نقدي' : (method == 'card' ? 'بطاقة' : 'أخرى'),
                                          radius: 40,
                                          titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Categories (Pie Chart)
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - (constraints.maxWidth / 1.6)) / 2 - 16 : constraints.maxWidth,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المبيعات حسب التصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 160,
                              child: categories.isEmpty
                                ? const Center(child: Text('لا بيانات'))
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 30,
                                      sections: categories.asMap().entries.map((e) {
                                        final cat = e.value;
                                        final total = double.tryParse('${cat['total']}') ?? 0;
                                        final colors = [Colors.purple, Colors.orange, Colors.teal, Colors.pink, Colors.indigo];
                                        return PieChartSectionData(
                                          color: colors[e.key % colors.length],
                                          value: total,
                                          title: cat['category']?.toString() ?? 'P',
                                          radius: 40,
                                          titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 20),

            // Top Products and Quick Actions
            LayoutBuilder(builder: (context, innerBox) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: cs.primary, size: 20),
                                const SizedBox(width: 8),
                                const Text('الأكثر مبيعاً هذا الشهر', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            if (_topProducts.isEmpty) 
                              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('لا توجد مبيعات بعد')))
                            else
                              ..._topProducts.map((p) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                                  child: Text('${_topProducts.indexOf(p) + 1}', style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                title: Text('صنف #${p['productId'].toString().substring(0, 5)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                trailing: Text('باع ${p['qty']} قطعة', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (innerBox.maxWidth > 800) const SizedBox(width: 16),
                  if (innerBox.maxWidth > 800)
                    Expanded(
                      child: Column(
                        children: [
                          _QuickAction(icon: Icons.add_shopping_cart, label: 'بيع سريع', color: cs.primary),
                          const SizedBox(height: 12),
                          const _QuickAction(icon: Icons.inventory, label: 'جرد المخزون', color: Colors.blue),
                          const SizedBox(height: 12),
                          const _QuickAction(icon: Icons.person_add, label: 'عميل جديد', color: Colors.orange),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color, this.isMoney = false, this.isAlert = false});
  final String title; final String value; final String subtitle; final IconData icon; final Color color; final bool isMoney; final bool isAlert;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                if (isAlert) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            isMoney ? MoneyDisplay(amount: double.tryParse(value) ?? 0, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                    : Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, color: isAlert ? Colors.red : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color});
  final IconData icon; final String label; final Color color;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 12))));
}
