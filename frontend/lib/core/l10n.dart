import 'package:flutter/material.dart';

class AppL10n {
  static const supportedLocales = [Locale('ar'), Locale('en')];
  static String t(String key, String locale) {
    const ar = {'dashboard': 'لوحة التحكم', 'pos': 'نقطة البيع', 'products': 'المنتجات', 'settings': 'الإعدادات'};
    const en = {'dashboard': 'Dashboard', 'pos': 'POS', 'products': 'Products', 'settings': 'Settings'};
    final map = locale == 'ar' ? ar : en;
    return map[key] ?? key;
  }
}
