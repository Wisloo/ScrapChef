import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';

// Earthy color palette for food scrap theme
const Color kPrimary = Color(0xFF8B7355); // Warm earth brown
const Color kPrimaryLight = Color(0xFFA89070); // Light earth brown
const Color kSecondary = Color(0xFF6B8E23); // Olive green
const Color kAccent = Color(0xFFD2691E); // Chocolate orange
const Color kBackground = Color(0xFFF5F0E6); // Creamy beige
const Color kSurface = Color(0xFFFFFFFF); // White
const Color kText = Color(0xFF4A3F35); // Dark earth brown
const Color kTextLight = Color(0xFF6B5D52); // Medium earth brown
const Color kDivider = Color(0xFFE0D5C5); // Light beige

// Dark theme colors (earthy dark mode)
const Color kDarkBackground = Color(0xFF2A2520); // Dark earth brown
const Color kDarkSurface = Color(0xFF3A3530); // Dark brown surface
const Color kDarkText = Color(0xFFE8E0D8); // Light cream text
const Color kDarkTextLight = Color(0xFFB8B0A8); // Medium cream text
const Color kDarkDivider = Color(0xFF4A4540); // Dark divider

/// Animated button with scale press effect + ripple
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = kPrimary,
    this.height = 56,
    this.borderRadius = 16,
    this.shadow = true,
    this.soundEnabled = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double height;
  final double borderRadius;
  final bool shadow;
  final bool soundEnabled;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    if (widget.soundEnabled) {
      // Haptic feedback removed
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTap() {
    if (widget.onPressed != null) {
      if (widget.soundEnabled) {
        SoundService.playClick();
      }
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.shadow && !_isPressed
                    ? [
                        BoxShadow(
                          color: widget.color.withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    // Ripple effect
                    child!,
                    // Ripple overlay when pressed
                    if (_isPressed)
                      Container(
                        color: Colors.white.withAlpha(30),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Center(child: widget.child),
      ),
    );
  }
}

/// Secondary animated button (outline style)
class AnimatedSecondaryButton extends StatefulWidget {
  const AnimatedSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = kText,
    this.height = 56,
    this.borderRadius = 16,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double height;
  final double borderRadius;

  @override
  State<AnimatedSecondaryButton> createState() => _AnimatedSecondaryButtonState();
}

class _AnimatedSecondaryButtonState extends State<AnimatedSecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    // Haptic feedback removed
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTap() {
    if (widget.onPressed != null) {
      SoundService.playClick();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: _isPressed ? widget.color.withAlpha(20) : Colors.white,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: _isPressed ? widget.color : widget.color.withAlpha(60),
                  width: _isPressed ? 2 : 1.5,
                ),
                boxShadow: _isPressed
                    ? null
                    : [
                        BoxShadow(
                          color: widget.color.withAlpha(15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}

/// Icon button with scale animation
class AnimatedIconButton extends StatefulWidget {
  const AnimatedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.iconColor = kText,
    this.size = 48,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color iconColor;
  final double size;

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    // Haptic feedback removed
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (widget.onPressed != null) {
      SoundService.playClick();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? (isDark ? kDarkSurface : kSurface),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: textColor.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 24),
            ),
          );
        },
      ),
    );
  }
}
