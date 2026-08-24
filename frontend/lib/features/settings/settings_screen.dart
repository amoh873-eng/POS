import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _cur = 'Loading...';
  Future<void> _load() async {
    final r = await api.get('/api/tenant-settings?tenantId=00000000-0000-0000-0000-000000000000');
    setState(() => _cur = r.toString());
  }
  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Settings')), body: Padding(padding: const EdgeInsets.all(16), child: SelectableText(_cur)));
  }
}
