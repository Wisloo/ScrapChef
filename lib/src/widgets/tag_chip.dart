import 'package:flutter/material.dart';

/// A rounded chip widget for displaying labels/tags.
class TagChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final VoidCallback? onPressed;

  const TagChip({
    Key? key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colorScheme.secondary.withOpacity(0.15);
    final textCol = textColor ?? colorScheme.onSecondary;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textCol,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}