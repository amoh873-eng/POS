import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/app_config.dart';
import 'core/theme.dart';
import 'core/sync_queue.dart';
import 'features/auth/login_screen.dart';
import 'features/pos/pos_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/products/products_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/customers/customers_screen.dart';
import 'features/settings/settings_screen.dart';

void main() => runApp(const PosApp());

class PosApp extends StatefulWidget {
  const PosApp({super.key});
  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> {
  final api = ApiClient(AppConfig.baseUrl);
  final syncQueue = SyncQueue();
  bool _authed = false;
  int _idx = 0;
  String _locale = 'ar';
  bool _healthOk = true;
  String _healthMsg = '';
  @override
  void initState() {
    super.initState();
    _checkHealth();
  }
  Future<void> _checkHealth() async {
    try {
      final r = await api.get('/health');
      if (!mounted) return;
      final ok = r.toString().contains('Healthy') || r.toString().contains('ok');
      setState(() { _healthOk = ok; _healthMsg = ok ? 'متصل' : 'استجابة غير متوقعة'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _healthOk = false; _healthMsg = e.toString().split('\n').first; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authed) {
      return MaterialApp(
        title: 'POS Cloud',
        theme: posTheme(),
        home: LoginScreen(api: api, onLogin: () => setState(() => _authed = true)),
      );
    }
    Widget syncDialog = Builder(builder: (ctx) => AlertDialog(
          title: const Text('قائمة المزامنة'),
          content: SizedBox(width: 400, child: syncQueue.all.isEmpty ? const Text('لا توجد عمليات قيد الانتظار') : ListView.builder(shrinkWrap: true, itemCount: syncQueue.all.length, itemBuilder: (_, i) { final it = syncQueue.all[i]; return ListTile(dense: true, title: Text('${it.type} — ${it.clientId.substring(0, 8)}'), subtitle: Text(it.state == SyncState.synced ? 'تمت المزامنة ✓' : it.state == SyncState.failed ? 'فشلت: ${it.lastError ?? ''}' : 'قيد الانتظار', style: TextStyle(color: it.state == SyncState.failed ? Colors.red : Colors.grey, fontSize: 11)), trailing: it.state == SyncState.failed ? IconButton(icon: const Icon(Icons.refresh, size: 16), onPressed: () { syncQueue.retry(it.clientId); Navigator.pop(ctx); setState(() {}); }) : null); })),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')), if (syncQueue.pendingCount > 0) ElevatedButton(onPressed: () async { Navigator.pop(ctx); for (final it in List.from(syncQueue.pending)) { try { final r = await api.post('/api/sync/push', {'items': [{'clientId': it.clientId, 'type': it.type, 'payloadJson': it.payloadJson}]}); if (r['error'] == null) syncQueue.markSynced(it.clientId); } catch (e) { syncQueue.markFailed(it.clientId, e.toString()); } } setState(() {}); }, child: const Text('مزامنة الآن')), TextButton(onPressed: () { syncQueue.clearSynced(); Navigator.pop(ctx); setState(() {}); }, child: const Text('مسح المكتملة'))],
        ));
    final pages = [
      DashboardScreen(api: api),
      PosScreen(api: api, syncQueue: syncQueue),
      ProductsScreen(api: api),
      InventoryScreen(api: api),
      CustomersScreen(api: api),
      ReportsScreen(api: api),
      SettingsScreen(api: api, onLocaleChanged: (l) => setState(() => _locale = l)),
      Builder(builder: (ctx) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sync, size: 64, color: Theme.of(ctx).colorScheme.primary), const SizedBox(height: 12), Text('قيد الانتظار: ${syncQueue.pendingCount}  |  فشلت: ${syncQueue.failed.length}  |  تمت: ${syncQueue.all.where((e) => e.state == SyncState.synced).length}'), const SizedBox(height: 12), ElevatedButton(onPressed: () => showDialog(context: ctx, builder: (_) => syncDialog), child: const Text('عرض التفاصيل')), const SizedBox(height: 8), const Text('العمليات تتم مزامنتها عند عودة الشبكة', style: TextStyle(color: Colors.grey, fontSize: 12))]))),
    ];
    final syncBadge = syncQueue.pendingCount;
    return MaterialApp(
      title: 'POS Cloud',
      theme: posTheme(),
      locale: Locale(_locale),
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 32,
          backgroundColor: _healthOk ? Colors.green.shade50 : Colors.red.shade50,
          elevation: 0,
          title: Row(children: [
            Icon(_healthOk ? Icons.cloud_done : Icons.cloud_off, size: 14, color: _healthOk ? Colors.green : Colors.red),
            const SizedBox(width: 6),
            Text(_healthOk ? 'متصل: ${AppConfig.baseUrl} — قيد الانتظار: $syncBadge' : 'غير متصل: $_healthMsg', style: TextStyle(fontSize: 11, color: _healthOk ? Colors.green.shade700 : Colors.red.shade700)),
            const Spacer(),
            if (syncBadge > 0) InkWell(onTap: () async { final pending = syncQueue.pending; if (pending.isEmpty) return; for (final it in pending) { try { final body = Map<String, dynamic>.from(<String, dynamic>{}); body['payload'] = it.payloadJson; final r = await api.post('/api/sync/push', {'items': [{'clientId': it.clientId, 'type': it.type, 'payloadJson': it.payloadJson}]}); if (r['error'] == null) { syncQueue.markSynced(it.clientId); } } catch (e) { syncQueue.markFailed(it.clientId, e.toString()); } } setState(() {}); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)), child: Text('مزامنة ($syncBadge)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
          ]),
        ),
        body: pages[_idx],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            const NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'POS'),
            const NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Products'),
            const NavigationDestination(icon: Icon(Icons.warehouse), label: 'Inventory'),
            const NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
            const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
            const NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
            NavigationDestination(icon: Badge(label: Text('$syncBadge'), isLabelVisible: syncBadge > 0, child: const Icon(Icons.sync)), label: 'Sync'),
          ],
        ),
      ),
    );
  }
}
