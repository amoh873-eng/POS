// Conditional platform dispatcher for thermal receipt printing.
// Web builds use the dart:js implementation (browser print dialog); all other
// platforms resolve the no-op implementation (same contract as before:
// non-web printing returns false).
export 'web_print_io_vm.dart'
    if (flutter.web) 'web_print_io_web.dart';
