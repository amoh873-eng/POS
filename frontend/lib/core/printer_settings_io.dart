// Conditional platform dispatcher for PrinterSettings persistence.
// Web builds (flutter.web) resolve localStorage via dart:html.
// All other platforms (Android/iOS/Desktop/VM tests) use the in-memory
// implementation so web-only libraries never enter native/test compilations.
export 'printer_settings_io_vm.dart'
    if (flutter.web) 'printer_settings_io_web.dart';