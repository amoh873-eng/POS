import 'package:flutter/material.dart';
import '../../core/api_client.dart';

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
  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final tenants = await widget.api.get('/api/tenants');
      final tid = (tenants['data'] is List && (tenants['data'] as List).isNotEmpty) ? tenants['data'][0]['id'] : null;
      final r = await widget.api.get(tid != null ? '/api/tenant-settings?tenantId=$tid' : '/api/tenant-settings');
      setState(() => _settings = r['data'] ?? r);
    } catch (e) { setState(() => _err = e.toString()); }
    setState(() => _loading = false);
  }
  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('الاعدادات'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_err != null) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12)))),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الاعمال: ${_settings?['businessName'] ?? _settings?['business_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('العملة: ${_settings?['currency'] ?? 'JOD'}'),
          Text('اللغة: ${_settings?['language'] ?? 'ar'}'),
          Text('اللون: ${_settings?['primaryColor'] ?? _settings?['primary_color'] ?? '#6D5BD0'}'),
          const SizedBox(height: 12),
          Row(children: [
            const Text('اللغة: '),
            DropdownButton<String>(value: _locale, items: const [DropdownMenuItem(value: 'ar', child: Text('العربية')), DropdownMenuItem(value: 'en', child: Text('English'))], onChanged: (v) { if (v != null) { setState(() => _locale = v); widget.onLocaleChanged(v); }}),
          ]),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(_settings.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)))),
      ]),
    );
  }
}
