import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PosUiSettings {
  double gridColumns;
  double cardHeight;
  bool showImages;
  bool showSku;
  String backgroundColor;
  double shadowDepth;
  bool cartOnRight;

  PosUiSettings({
    this.gridColumns = 6,
    this.cardHeight = 100,
    this.showImages = true,
    this.showSku = false,
    this.backgroundColor = 'F4F7FE',
    this.shadowDepth = 3,
    this.cartOnRight = true,
  });

  Map<String, dynamic> toJson() => {
    'gridColumns': gridColumns,
    'cardHeight': cardHeight,
    'showImages': showImages,
    'showSku': showSku,
    'backgroundColor': backgroundColor,
    'shadowDepth': shadowDepth,
    'cartOnRight': cartOnRight,
  };

  factory PosUiSettings.fromJson(Map<String, dynamic> json) => PosUiSettings(
    gridColumns: (json['gridColumns'] ?? 6).toDouble(),
    cardHeight: (json['cardHeight'] ?? 100).toDouble(),
    showImages: json['showImages'] ?? true,
    showSku: json['showSku'] ?? false,
    backgroundColor: json['backgroundColor'] ?? 'F4F7FE',
    shadowDepth: (json['shadowDepth'] ?? 3).toDouble(),
    cartOnRight: json['cartOnRight'] ?? true,
  );

  static Future<PosUiSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pos_ui_v1');
    if (raw == null) return PosUiSettings();
    try { return PosUiSettings.fromJson(jsonDecode(raw)); } catch (_) { return PosUiSettings(); }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pos_ui_v1', jsonEncode(toJson()));
  }
}
