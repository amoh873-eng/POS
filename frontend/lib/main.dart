import 'package:flutter/material.dart';

void main() => runApp(const PosApp());

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Cloud',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6D5BD0)),
      home: const Scaffold(body: Center(child: Text('POS Cloud — PHASE-00 scaffold'))),
    );
  }
}
