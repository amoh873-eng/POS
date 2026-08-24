import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _data = '';
  Future<void> _load() async {
    final r = await api.get('/api/reports/daily-sales?tenantId=00000000-0000-0000-0000-000000000000');
    setState(() => _data = r.toString());
  }
  late final ApiClient api;
  @override
  void initState() { super.initState(); api = widget.api; _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Reports')), body: Padding(padding: const EdgeInsets.all(16), child: Text(_data)));
  }
}
