import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Opens a new window rendering the receipt (ESC/POS 58/80mm) and auto-calls
/// window.print() so the configured thermal driver prints directly.
/// On non-web returns false.
/// `mm` width in millimetres for the ticket (58 or 80).
bool printThermalReceipt(String dataUri, {int mm = 80}) {
  if (!kIsWeb) return false;
  try {
    final script = '''
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
