import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_client.dart';
import '../../core/money_display.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _data;
  List _inventory = [];
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; });
    try {
      final f = _from.toUtc().toIso8601String();
      final t = _to.toUtc().toIso8601String();
      final res = await widget.api.get('/api/reports/full-analytics?from=$f&to=$t');
      final invRes = await widget.api.get('/api/reports/inventory');
      
      if (!mounted) return;
      setState(() { 
        _data = res['data']; 
        _inventory = invRes['data'] ?? [];
        _loading = false; 
      });
    } catch (e) { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('مركز التقارير الاحترافي', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'نظرة عامة'),
            Tab(icon: Icon(Icons.inventory), text: 'المخزون'),
            Tab(icon: Icon(Icons.receipt), text: 'المبيعات'),
          ],
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          TextButton.icon(
            onPressed: () async {
              final dr = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 1)), initialDateRange: DateTimeRange(start: _from, end: _to));
              if (dr != null) { setState(() { _from = dr.start; _to = dr.end; }); _load(); }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text('${_from.day}/${_from.month} - ${_to.day}/${_to.month}'),
          ),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabCtrl,
            children: [
              _buildOverviewTab(),
              _buildInventoryTab(),
              _buildSalesTab(),
            ],
          ),
    );
  }

  Widget _buildOverviewTab() {
    final trend = (_data?['trend'] as List?) ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKpiRow(),
        const SizedBox(height: 20),
        _buildSectionTitle('منحنى المبيعات'),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 250,
              child: trend.isEmpty 
                ? const Center(child: Text('لا بيانات'))
                : LineChart(_lineChartData(trend)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildPaymentPie()),
            const SizedBox(width: 16),
            Expanded(child: _buildTopProductsList()),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiBox(title: 'إجمالي المبيعات', value: _data?['revenue'] ?? 0, color: Colors.blue, icon: Icons.attach_money),
        _KpiBox(title: 'صافي الربح', value: _data?['netProfit'] ?? 0, color: Colors.green, icon: Icons.trending_up),
        _KpiBox(title: 'إجمالي الضريبة', value: _data?['tax'] ?? 0, color: Colors.orange, icon: Icons.account_balance),
        _KpiBox(title: 'تكلفة المواد', value: _data?['cost'] ?? 0, color: Colors.red, icon: Icons.shopping_cart),
      ],
    );
  }

  Widget _buildPaymentPie() {
    final payments = (_data?['payments'] as List?) ?? [];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('طرق الدفع', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: payments.isEmpty ? const Center(child: Text('لا بيانات')) : PieChart(
                PieChartData(
                  sections: payments.map((p) {
                    final total = double.tryParse('${p['total']}') ?? 0;
                    return PieChartSectionData(
                      value: total,
                      color: p['method'] == 'cash' ? Colors.green : Colors.blue,
                      title: p['method'] == 'cash' ? 'نقدي' : 'بطاقة',
                      radius: 40,
                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList() {
    final tops = (_data?['topProducts'] as List?) ?? [];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الأكثر مبيعاً', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ...tops.take(5).map((p) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(p['name'].toString(), style: const TextStyle(fontSize: 12)),
              trailing: Text('qty ${p['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('حالة المخزون الحالية'),
        DataTable(
          columns: const [
            DataColumn(label: Text('الصنف')),
            DataColumn(label: Text('الكمية')),
            DataColumn(label: Text('الحالة')),
          ],
          rows: _inventory.map((item) {
            final qty = item['qty'] ?? 0;
            return DataRow(cells: [
              DataCell(Text(item['name'] ?? 'P')),
              DataCell(Text('$qty')),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: qty < 5 ? Colors.red.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(qty < 5 ? 'منخفض' : 'جيد', style: TextStyle(color: qty < 5 ? Colors.red : Colors.green, fontSize: 10)),
              )),
            ]);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSalesTab() {
    return const Center(child: Text('تقارير المبيعات التفصيلية (قيد التطوير)'));
  }

  Widget _buildSectionTitle(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

  LineChartData _lineChartData(List trend) {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), double.tryParse('${e.value['total']}') ?? 0)).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
        ),
      ],
    );
  }
}

class _KpiBox extends StatelessWidget {
  const _KpiBox({required this.title, required this.value, required this.color, required this.icon});
  final String title; final dynamic value; final Color color; final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          MoneyDisplay(amount: double.tryParse(value.toString()) ?? 0, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
