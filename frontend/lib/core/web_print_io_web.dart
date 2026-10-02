// Web-only implementation: opens a new window rendering the receipt
// (ESC/POS 58/80mm) and auto-calls window.print() so the configured
// thermal driver prints directly. Only compiled for flutter.web.
//
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
//
// INTENT: Kept intentionally. Thermal printing executes a JS snippet through
// dart:js, which is web-only by definition and confined to this file behind
// the conditional import in web_print.dart. Migrating to dart:js_interop is
// deferred (cross-cutting PHASE-32 scope) and would not change behavior.
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

bool printThermalReceipt(String dataUri, {int mm = 80}) {
  if (!kIsWeb) return false;
  try {
    const script = '''
    (function(uri, mm){
      function go(u, m){
        try {
          var w = window.open("", "_blank", "width=340,height=800");
          if (!w) return false;
          w.document.write('<iframe src="'+u+'" style="width:'+m+'mm;height:100%;border:0;margin:0;"></iframe>');
          w.document.close();
          setTimeout(function(){ try { w.focus(); w.print(); } catch(e){} }, 900);
          return true;
        } catch(e){ return false; }
      }
      return go(uri, mm);
    })
    ''';
    final fn = js.context.callMethod('Function', [script]);
    final result = fn.callMethod('call', [js.context, dataUri, mm]);
    return result == true;
  } catch (_) {
    return false;
  }
}