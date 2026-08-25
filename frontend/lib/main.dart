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

  @override
  Widget build(BuildContext context) {
    if (!_authed) {
      return MaterialApp(
        title: 'POS Cloud',
        theme: posTheme(),
        home: LoginScreen(api: api, onLogin: () => setState(() => _authed = true)),
      );
    }
    final pages = [
      DashboardScreen(api: api),
      PosScreen(api: api, syncQueue: syncQueue),
      ProductsScreen(api: api),
      InventoryScreen(api: api),
      CustomersScreen(api: api),
      ReportsScreen(api: api),
      SettingsScreen(api: api, onLocaleChanged: (l) => setState(() => _locale = l)),
    ];
    return MaterialApp(
      title: 'POS Cloud',
      theme: posTheme(),
      locale: Locale(_locale),
      home: Scaffold(
        body: pages[_idx],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'POS'),
            NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.warehouse), label: 'Inventory'),
            NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
