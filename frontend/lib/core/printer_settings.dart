import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:html' as html;

/// Receipt printer configuration, persisted in localStorage on web.
class PrinterSettings {
  String receiptPrinter = 'ESCPOS Receipt';
  String kitchenPrinter = 'KITCHEN-PRINTER';
  String paperSize = '80mm'; // 58mm | 80mm
  bool printKitchen = true;
  int customerCopies = 1;
  int fontSize = 12;
  bool boldHeader = true;

  static const _key = 'pos_printer_settings';

  int get mm => paperSize.contains('58') ? 58 : 80;

  PrinterSettings();

  Map<String, dynamic> toJson() => {
        'receiptPrinter': receiptPrinter,
        'kitchenPrinter': kitchenPrinter,
        'paperSize': paperSize,
        'printKitchen': printKitchen,
        'customerCopies': customerCopies,
        'fontSize': fontSize,
        'boldHeader': boldHeader,
      };

  factory PrinterSettings.fromJson(Map<String, dynamic> j) {
    final s = PrinterSettings();
    s.receiptPrinter = j['receiptPrinter']?.toString() ?? s.receiptPrinter;
    s.kitchenPrinter = j['kitchenPrinter']?.toString() ?? s.kitchenPrinter;
    s.paperSize = j['paperSize']?.toString() ?? s.paperSize;
    s.printKitchen = j['printKitchen'] is bool ? (j['printKitchen'] as bool) : s.printKitchen;
    s.customerCopies = (j['customerCopies'] as num?)?.toInt() ?? 1;
    s.fontSize = (j['fontSize'] as num?)?.toInt() ?? 12;
    s.boldHeader = j['boldHeader'] is bool ? (j['boldHeader'] as bool) : s.boldHeader;
    return s;
  }
}

class PrinterSettingsStore {
  static PrinterSettings? _mem;

  static Future<PrinterSettings> load() async {
    if (kIsWeb) {
      try {
        final raw = html.window.localStorage[PrinterSettings._key];
        if (raw != null && raw.isNotEmpty) {
          return PrinterSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    return _mem ?? PrinterSettings();
  }

  static Future<void> save(PrinterSettings s) async {
    _mem = s;
    if (kIsWeb) {
      try {
        html.window.localStorage[PrinterSettings._key] = jsonEncode(s.toJson());
      } catch (_) {}
    }
  }
}