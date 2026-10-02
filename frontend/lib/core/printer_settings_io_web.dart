// Web-only implementation: persists printer settings in localStorage.
// This file is only compiled when targeting flutter.web (dart:html available).
//
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
//
// INTENT: Kept intentionally. This is the web-only persistence backend and
// must use dart:html (localStorage). It is isolated behind the conditional
// import in printer_settings_io.dart so no web-only code enters native/test
// builds. Migrating to package:web / dart:js_interop is deliberately deferred
// (cross-cutting refactor outside PHASE 32 scope) and confined to this file.
import 'dart:html' as html;

class PrinterSettingsIo {
  static const _key = 'pos_printer_settings';

  static Future<String?> read() async {
    final raw = html.window.localStorage[_key];
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  static Future<void> write(String value) async {
    html.window.localStorage[_key] = value;
  }
}