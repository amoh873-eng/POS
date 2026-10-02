import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/money_display.dart';

class SalesInvoicesScreen extends StatefulWidget {
  const SalesInvoicesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<SalesInvoicesScreen> createState() => _SalesInvoicesScreenState();
}

class _SalesInvoicesScreenState extends State<SalesInvoicesScreen> {
  List _items = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  int _totalCount = 0;
  final int _pageSize = 15;
  
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final f = DateFormat('yyyy-MM-ddT00:00:00').format(_from);
      final t = DateFormat('yyyy-MM-ddT23:59:59').format(_to);
      
      final r = await widget.api.get('/api/sales?from=$f&to=$t&page=$_page&pageSize=$_pageSize');
      if (!mounted) return;
      setState(() {
        _items = r['data'] ?? [];
        _totalCount = r['meta']?['total'] ?? 0;
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6D5BD0),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
        _page = 1;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('سجل فواتير المبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSummaryCards(),
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _loading && _items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? _buildEmptyState()
                        : isWide ? _buildInvoicesTable() : _buildInvoicesList(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6D5BD0)),
          const SizedBox(width: 8),
          Text(
            'الفترة: ${DateFormat('yyyy/MM/dd').format(_from)} - ${DateFormat('yyyy/MM/dd').format(_to)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
            label: const Text('تغيير الفترة'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6D5BD0)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    double totalAmount = _items.fold(0.0, (sum, item) => sum + (item['grandTotal'] ?? 0.0));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _summaryCard('عدد الفواتير', '$_totalCount', Icons.receipt_long, Colors.blue),
          const SizedBox(width: 12),
          _summaryCard('إجمالي الفترة', MoneyDisplay.format(totalAmount), Icons.monetization_on, Colors.green),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('لا توجد فواتير في هذه الفترة', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildInvoicesTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('رقم الفاتورة')),
            DataColumn(label: Text('التاريخ والوقت')),
            DataColumn(label: Text('العميل')),
            DataColumn(label: Text('المبلغ')),
            DataColumn(label: Text('فاتورة جو')),
            DataColumn(label: Text('الإجراءات')),
          ],
          rows: _items.map((sale) {
            return DataRow(cells: [
              DataCell(Text(sale['receiptNo'], style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(sale['createdAt'])))),
              DataCell(Text(sale['customer']?['name'] ?? 'عميل نقدي')),
              DataCell(Text(MoneyDisplay.format(sale['grandTotal']), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
              DataCell(_statusBadge(sale['joInvoiceStatus'] ?? 'none')),
              DataCell(IconButton(icon: const Icon(Icons.visibility, color: Color(0xFF6D5BD0)), onPressed: () => _showDetails(sale))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final sale = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            onTap: () => _showDetails(sale),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Text(sale['receiptNo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(MoneyDisplay.format(sale['grandTotal']), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(sale['createdAt'])), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(sale['customer']?['name'] ?? 'عميل نقدي', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                _statusBadge(sale['joInvoiceStatus'] ?? 'none'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'submitted':
        color = Colors.green;
        label = 'جو: تم';
        break;
      case 'failed':
        color = Colors.red;
        label = 'جو: فشل';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'جو: معلق';
        break;
      default:
        color = Colors.grey;
        label = 'جو: لا يوجد';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPagination() {
    int maxPage = (_totalCount / _pageSize).ceil();
    if (maxPage <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('صفحة $_page من $maxPage'),
          IconButton(
            onPressed: _page < maxPage ? () { setState(() => _page++); _load(); } : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _showDetails(Map sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF6D5BD0)),
            const SizedBox(width: 8),
            Text('فاتورة رقم: ${sale['receiptNo']}'),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoRow('التاريخ', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(sale['createdAt']))),
                _infoRow('العميل', sale['customer']?['name'] ?? 'عميل نقدي'),
                _infoRow('الحالة', sale['status'] == 'completed' ? 'مكتملة' : sale['status']),
                _infoRow('تكامل فاتورة جو', sale['joInvoiceStatus'] ?? 'none'),
                if (sale['joInvoiceUuid'] != null)
                  _infoRow('UUID', sale['joInvoiceUuid'].toString(), isSmall: true),
                
                if (sale['joInvoiceQrCode'] != null)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 16.0),
                     child: Center(
                       child: Column(
                         children: [
                           const Text('رمز QR للفاتورة الضريبية:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 8),
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                             child: sale['joInvoiceQrCode'].toString().startsWith('http') 
                              ? Image.network(sale['joInvoiceQrCode'], height: 140, width: 140)
                              : const Icon(Icons.qr_code, size: 100, color: Colors.grey),
                           ),
                         ],
                       ),
                     ),
                   ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('تفاصيل الأصناف:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D5BD0))),
                ),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      ...((sale['items'] as List?) ?? []).map((item) => ListTile(
                        dense: true,
                        title: Text(item['productName'] ?? 'منتج رقم ${item['productId'].toString().substring(0,4)}'),
                        subtitle: Text('${item['qty']} وحدة × ${MoneyDisplay.format(item['unitPrice'])}'),
                        trailing: Text(MoneyDisplay.format(item['lineTotal']), style: const TextStyle(fontWeight: FontWeight.bold)),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _infoRow('المجموع الفرعي', MoneyDisplay.format(sale['subtotal'])),
                _infoRow('الضريبة (16%)', MoneyDisplay.format(sale['taxTotal'])),
                const SizedBox(height: 4),
                _infoRow('الإجمالي النهائي', MoneyDisplay.format(sale['grandTotal']), isBold: true, color: Colors.blue),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D5BD0), foregroundColor: Colors.white),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false, bool isSmall = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Flexible(
            child: Text(
              value, 
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isSmall ? 10 : 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
