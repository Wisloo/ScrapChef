import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/ui_constants.dart';
import '../services/sound_service.dart';

/// A reusable button widget that follows the app's theming.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? elevation;
  final Gradient? gradient;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.elevation,
    this.gradient,
    this.fullWidth = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Default gradient: primary to secondary
    final Gradient defaultGradient = LinearGradient(
      colors: [
        isDarkMode ? colorScheme.primary : colorScheme.primary,
        isDarkMode ? colorScheme.secondary : colorScheme.secondary,
      ],
    );

    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: widget.fullWidth ? double.infinity : null,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: widget.gradient ?? defaultGradient,
              borderRadius: BorderRadius.circular(UIConstants.kButtonBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: (widget.gradient ?? defaultGradient).colors.first.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(UIConstants.kButtonBorderRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.kButtonHorizontalPadding,
                  vertical: UIConstants.kButtonVerticalPadding,
                ),
                constraints: const BoxConstraints(
                  minHeight: UIConstants.kButtonMinHeight,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon for camera button
                    if (_shouldShowIcon())
                      Icon(
                        _getIconForText(),
                        color: Colors.white,
                        size: 24,
                      ),
                    if (_shouldShowIcon())
                      const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowIcon() {
    // Show icon for specific actions
    return widget.text == 'Open camera' || widget.text == 'Find Recipes';
  }

  IconData _getIconForText() {
    if (widget.text == 'Open camera') return Icons.camera_alt_rounded;
    if (widget.text == 'Find Recipes') return Icons.restaurant_menu_rounded;
    return Icons.check_circle_rounded;
  }
}
