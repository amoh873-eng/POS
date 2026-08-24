import 'package:flutter/material.dart';
import 'features/pos/pos_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() => runApp(const PosApp());

class PosApp extends StatefulWidget {
  const PosApp({super.key});
  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> {
  int _idx = 0;
  final _pages = const [DashboardScreen(), PosScreen(), Scaffold(body: Center(child: Text('Products — coming soon'))), Scaffold(body: Center(child: Text('Settings')))];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Cloud',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6D5BD0)),
      home: Scaffold(
        body: _pages[_idx],
        bottomNavigationBar: NavigationBar(selectedIndex: _idx, onDestinationSelected: (i) => setState(() => _idx = i), destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'POS'),
          NavigationDestination(icon: Icon(Icons.inventory), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ]),
      ),
    );
  }
}
