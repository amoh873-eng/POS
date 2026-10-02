import 'package:flutter/material.dart';

class MoneyDisplay extends StatelessWidget {
  const MoneyDisplay({super.key, required this.amount, this.currency = 'JOD', this.style});
  final double amount;
  final String currency;
  final TextStyle? style;
  static String format(dynamic amount, {String currency = 'JOD'}) {
    final val = double.tryParse(amount.toString()) ?? 0.0;
    return '${val.toStringAsFixed(2)} $currency';
  }
  @override
  Widget build(BuildContext context) {
    return Text(format(amount, currency: currency), style: style ?? const TextStyle(fontWeight: FontWeight.w600));
  }
}
