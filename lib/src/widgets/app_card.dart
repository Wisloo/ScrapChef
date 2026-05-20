import 'package:flutter/material.dart';

/// A reusable card widget that follows the app's theming.
class AppCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final Border? border;
  final EdgeInsetsGeometry padding;

  const AppCard({
    Key? key,
    required this.child,
    this.elevation,
    this.border,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    final color = cardTheme.color ?? Colors.transparent;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: border ?? Border.fromBorderSide(
          BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: elevation!,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}