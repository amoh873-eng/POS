import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 3,
        children: const [
          Card(child: Center(child: Text('Net Sales'))),
          Card(child: Center(child: Text('Net Purchases'))),
          Card(child: Center(child: Text('Inventory Value'))),
        ],
      ),
    );
  }
}
