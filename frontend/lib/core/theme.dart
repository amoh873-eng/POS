import 'package:flutter/material.dart';

ThemeData posTheme({Color seed = const Color(0xFF6D5BD0)}) => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: const Color(0xFFF5F4F8),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A2E),
        titleTextStyle: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
