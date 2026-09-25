import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

class AnimatedFinancialCounter extends StatelessWidget {
  final double amount;
  final TextStyle style;
  final Duration duration;
  final bool compact;
  final String? symbol;

  const AnimatedFinancialCounter({
    super.key,
    required this.amount,
    required this.style,
    this.duration = const Duration(milliseconds: 700),
    this.compact = false,
    this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          AppUtils.formatAmount(value, compact: compact, symbol: symbol),
          style: style,
        );
      },
    );
  }
}
