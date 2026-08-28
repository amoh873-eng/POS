import 'package:flutter/foundation.dart';

class AppConfig {
  /// API base URL. When empty (default) the app uses the same origin it was
  /// served from (Flutter Web + API served together on :5000, perfect for LAN).
  /// For a separate API server you can override via --dart-define=API_BASE_URL=http://IP:5000
  static const _defined = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_defined.isNotEmpty) return _defined;
    if (kIsWeb) {
      // Serve UI and API from the same origin (recommended LAN setup).
      return Uri.base.origin;
    }
    return 'http://localhost:5000';
  }

  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (kIsWeb) {
      return Uri.base.origin + (url.startsWith('/') ? url : '/$url');
    }
    final base = Uri.parse(baseUrl);
    final hostPart = base.hasPort && base.port != 0 ? '${base.host}:${base.port}' : base.host;
    final path = url.startsWith('/') ? url : '/$url';
    return '${base.scheme}://$hostPart$path';
  }
}

