import 'package:flutter/material.dart';

/// A small pill-shaped widget for displaying numeric stats or labels.
class StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;

  const StatBadge({
    Key? key,
    required this.label,
    required this.value,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colorScheme.primary.withOpacity(0.15);
    final textCol = textColor ?? colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textCol,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}