import 'package:flutter/material.dart';

class MoneyDisplay extends StatelessWidget {
  const MoneyDisplay({super.key, required this.amount, this.currency = 'JOD'});
  final double amount;
  final String currency;
  @override
  Widget build(BuildContext context) {
    return Text('${amount.toStringAsFixed(2)} $currency', style: const TextStyle(fontWeight: FontWeight.w600));
  }
}
