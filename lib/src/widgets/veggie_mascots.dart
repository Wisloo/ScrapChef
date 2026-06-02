import 'package:flutter/material.dart';

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

// Vegetable-specific colors (kept for mascot designs)
const Color kCarrotOrange = Color(0xFFFF8C42);
const Color kTomatoRed = Color(0xFFE85D4E);
const Color kBroccoliGreen = Color(0xFF5A9A65);
const Color kRadishPink = Color(0xFFFFB6C1);

/// Cute veggie mascot widget base
class VeggieMascot extends StatelessWidget {
  const VeggieMascot({super.key, required this.child, this.size = 120});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bgColor = kSurface;
    final textColor = kText;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: textColor.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Sad empty bin veggie mascot
class EmptyBinMascot extends StatelessWidget {
  const EmptyBinMascot({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return VeggieMascot(
      size: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _SadCarrotPainter(),
      ),
    );
  }
}

/// Happy cooking veggie mascot
class HappyCookingMascot extends StatelessWidget {
  const HappyCookingMascot({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return VeggieMascot(
      size: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _HappyTomatoPainter(),
      ),
    );
  }
}

/// No recipes veggie mascot
class NoRecipesMascot extends StatelessWidget {
  const NoRecipesMascot({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return VeggieMascot(
      size: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ThinkingBroccoliPainter(),
      ),
    );
  }
}

/// Success confetti veggie mascot
class SuccessMascot extends StatelessWidget {
  const SuccessMascot({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return VeggieMascot(
      size: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _CelebratingRadishPainter(),
      ),
    );
  }
}

/// Painter for sad carrot (empty bin) - Cute version!
class _SadCarrotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    final paint = Paint()..style = PaintingStyle.fill;

    // Carrot body (rounder, cuter shape)
    paint.color = kCarrotOrange;
    final carrotPath = Path()
      ..moveTo(center.dx, center.dy - 35)
      ..quadraticBezierTo(center.dx - 30, center.dy - 10, center.dx - 22, center.dy + 25)
      ..quadraticBezierTo(center.dx, center.dy + 35, center.dx + 22, center.dy + 25)
      ..quadraticBezierTo(center.dx + 30, center.dy - 10, center.dx, center.dy - 35)
      ..close();
    canvas.drawPath(carrotPath, paint);

    // Carrot highlight (shiny)
    paint.color = Colors.white.withAlpha(100);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 8, center.dy - 5), width: 8, height: 20),
      paint,
    );

    // Carrot lines (texture)
    paint.color = kAccent.withAlpha(80);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx - 10, center.dy + 5),
      Offset(center.dx + 10, center.dy + 5),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - 6, center.dy + 15),
      Offset(center.dx + 6, center.dy + 15),
      paint,
    );

    // Carrot top leaves (cuter, fuller)
    paint.style = PaintingStyle.fill;
    paint.color = kSecondary;
    // Left leaf
    final leftLeaf = Path()
      ..moveTo(center.dx - 5, center.dy - 32)
      ..quadraticBezierTo(center.dx - 20, center.dy - 55, center.dx - 8, center.dy - 65)
      ..quadraticBezierTo(center.dx - 2, center.dy - 55, center.dx - 5, center.dy - 32)
      ..close();
    canvas.drawPath(leftLeaf, paint);
    // Right leaf
    final rightLeaf = Path()
      ..moveTo(center.dx + 5, center.dy - 32)
      ..quadraticBezierTo(center.dx + 20, center.dy - 55, center.dx + 8, center.dy - 65)
      ..quadraticBezierTo(center.dx + 2, center.dy - 55, center.dx + 5, center.dy - 32)
      ..close();
    canvas.drawPath(rightLeaf, paint);
    // Center leaf
    final centerLeaf = Path()
      ..moveTo(center.dx, center.dy - 35)
      ..quadraticBezierTo(center.dx - 3, center.dy - 60, center.dx, center.dy - 70)
      ..quadraticBezierTo(center.dx + 3, center.dy - 60, center.dx, center.dy - 35)
      ..close();
    canvas.drawPath(centerLeaf, paint);

    // Rosy cheeks
    paint.color = Colors.pink.withAlpha(60);
    canvas.drawCircle(Offset(center.dx - 15, center.dy + 2), 6, paint);
    canvas.drawCircle(Offset(center.dx + 15, center.dy + 2), 6, paint);

    // Sad eyes (bigger, cuter)
    paint.color = kText;
    // Left eye
    canvas.drawCircle(Offset(center.dx - 10, center.dy - 8), 5, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx - 11, center.dy - 10), 2, paint);
    paint.color = kText;
    // Right eye
    canvas.drawCircle(Offset(center.dx + 10, center.dy - 8), 5, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx + 9, center.dy - 10), 2, paint);

    // Sad mouth (small wobbly frown)
    paint.color = kText;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(center.dx - 6, center.dy + 12)
      ..quadraticBezierTo(center.dx, center.dy + 6, center.dx + 6, center.dy + 12);
    canvas.drawPath(mouthPath, paint);

    // Cute tear drop (bigger, blue)
    final tearPaint = Paint()
      ..color = Colors.lightBlue.withAlpha(180)
      ..style = PaintingStyle.fill;
    final tearCenter = Offset(center.dx + 18, center.dy - 5);
    // Tear body
    final tearPath = Path()
      ..moveTo(tearCenter.dx, tearCenter.dy - 8)
      ..quadraticBezierTo(tearCenter.dx + 6, tearCenter.dy, tearCenter.dx, tearCenter.dy + 8)
      ..quadraticBezierTo(tearCenter.dx - 6, tearCenter.dy, tearCenter.dx, tearCenter.dy - 8)
      ..close();
    canvas.drawPath(tearPath, tearPaint);
    // Tear highlight
    tearPaint.color = Colors.white.withAlpha(200);
    canvas.drawCircle(Offset(tearCenter.dx - 2, tearCenter.dy - 2), 2, tearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for happy tomato (cooking) - Cute version!
class _HappyTomatoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    final paint = Paint()..style = PaintingStyle.fill;

    // Tomato body (rounder, slightly pear-shaped for cuteness)
    paint.color = kTomatoRed;
    final tomatoPath = Path()
      ..moveTo(center.dx, center.dy - 38)
      ..quadraticBezierTo(center.dx - 32, center.dy - 20, center.dx - 30, center.dy + 10)
      ..quadraticBezierTo(center.dx - 30, center.dy + 32, center.dx, center.dy + 35)
      ..quadraticBezierTo(center.dx + 30, center.dy + 32, center.dx + 30, center.dy + 10)
      ..quadraticBezierTo(center.dx + 32, center.dy - 20, center.dx, center.dy - 38)
      ..close();
    canvas.drawPath(tomatoPath, paint);

    // Shiny highlight (big oval)
    paint.color = Colors.white.withAlpha(80);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 12, center.dy - 12), width: 15, height: 22),
      paint,
    );

    // Stem (green, thicker)
    paint.color = kSecondary;
    final stemPath = Path()
      ..moveTo(center.dx - 4, center.dy - 35)
      ..lineTo(center.dx - 10, center.dy - 55)
      ..lineTo(center.dx - 5, center.dy - 50)
      ..lineTo(center.dx, center.dy - 58)
      ..lineTo(center.dx + 5, center.dy - 50)
      ..lineTo(center.dx + 10, center.dy - 55)
      ..lineTo(center.dx + 4, center.dy - 35)
      ..close();
    canvas.drawPath(stemPath, paint);

    // Rosy cheeks (kawaii style)
    paint.color = Colors.pink.withAlpha(100);
    canvas.drawCircle(Offset(center.dx - 18, center.dy + 5), 8, paint);
    canvas.drawCircle(Offset(center.dx + 18, center.dy + 5), 8, paint);

    // Happy eyes (sparkly, bigger)
    paint.color = kText;
    // Left eye (filled circle)
    canvas.drawCircle(Offset(center.dx - 11, center.dy - 8), 6, paint);
    // Eye highlight
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx - 13, center.dy - 10), 2.5, paint);
    // Right eye
    paint.color = kText;
    canvas.drawCircle(Offset(center.dx + 11, center.dy - 8), 6, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx + 9, center.dy - 10), 2.5, paint);

    // Happy open mouth (D-shape)
    paint.color = kText;
    final mouthPath = Path()
      ..moveTo(center.dx - 10, center.dy + 10)
      ..quadraticBezierTo(center.dx, center.dy + 22, center.dx + 10, center.dy + 10)
      ..lineTo(center.dx + 6, center.dy + 10)
      ..quadraticBezierTo(center.dx, center.dy + 16, center.dx - 6, center.dy + 10)
      ..close();
    canvas.drawPath(mouthPath, paint);
    // Tongue
    paint.color = Colors.pink.withAlpha(150);
    canvas.drawCircle(Offset(center.dx, center.dy + 14), 4, paint);

    // Chef hat (cuter, tilted)
    paint.color = Colors.white;
    final hatPath = Path()
      ..moveTo(center.dx - 18, center.dy - 42)
      ..lineTo(center.dx - 22, center.dy - 68)
      ..quadraticBezierTo(center.dx - 12, center.dy - 75, center.dx - 2, center.dy - 68)
      ..lineTo(center.dx + 2, center.dy - 68)
      ..quadraticBezierTo(center.dx + 12, center.dy - 75, center.dx + 22, center.dy - 68)
      ..lineTo(center.dx + 18, center.dy - 42)
      ..quadraticBezierTo(center.dx, center.dy - 38, center.dx - 18, center.dy - 42)
      ..close();
    canvas.drawPath(hatPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for thinking broccoli (no recipes) - Cute version!
class _ThinkingBroccoliPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    final paint = Paint()..style = PaintingStyle.fill;

    // Broccoli body (rounder, cuter)
    paint.color = kBroccoliGreen;
    final bodyPath = Path()
      ..moveTo(center.dx - 28, center.dy + 15)
      ..lineTo(center.dx - 28, center.dy - 8)
      ..quadraticBezierTo(center.dx - 32, center.dy - 28, center.dx - 18, center.dy - 32)
      ..quadraticBezierTo(center.dx, center.dy - 42, center.dx + 18, center.dy - 32)
      ..quadraticBezierTo(center.dx + 32, center.dy - 28, center.dx + 28, center.dy - 8)
      ..lineTo(center.dx + 28, center.dy + 15)
      ..quadraticBezierTo(center.dx + 22, center.dy + 28, center.dx, center.dy + 28)
      ..quadraticBezierTo(center.dx - 22, center.dy + 28, center.dx - 28, center.dy + 15)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Stem (rounder)
    paint.color = kSecondary;
    final stemPath = Path()
      ..moveTo(center.dx - 8, center.dy + 25)
      ..lineTo(center.dx - 8, center.dy + 42)
      ..quadraticBezierTo(center.dx - 8, center.dy + 48, center.dx, center.dy + 48)
      ..quadraticBezierTo(center.dx + 8, center.dy + 48, center.dx + 8, center.dy + 42)
      ..lineTo(center.dx + 8, center.dy + 25)
      ..close();
    canvas.drawPath(stemPath, paint);

    // Rosy cheeks
    paint.color = Colors.pink.withAlpha(70);
    canvas.drawCircle(Offset(center.dx - 16, center.dy + 5), 7, paint);
    canvas.drawCircle(Offset(center.dx + 16, center.dy + 5), 7, paint);

    // Eyes (looking up - thinking, bigger)
    paint.color = kText;
    // Left eye (looking up-right)
    canvas.drawCircle(Offset(center.dx - 11, center.dy - 8), 4, paint);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = Colors.white.withAlpha(180);
    canvas.drawCircle(Offset(center.dx - 9, center.dy - 10), 2.5, paint);
    
    // Right eye (looking up-left)
    paint.style = PaintingStyle.fill;
    paint.color = kText;
    canvas.drawCircle(Offset(center.dx + 11, center.dy - 8), 4, paint);
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.white.withAlpha(180);
    canvas.drawCircle(Offset(center.dx + 9, center.dy - 10), 2.5, paint);

    // Thinking mouth (small cute o)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.color = kText;
    canvas.drawCircle(Offset(center.dx, center.dy + 8), 4, paint);

    // Thought bubble (bigger, cuter)
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + 45, center.dy - 42), 18, paint);
    canvas.drawCircle(Offset(center.dx + 32, center.dy - 26), 6, paint);
    canvas.drawCircle(Offset(center.dx + 24, center.dy - 18), 4, paint);

    // Question mark in bubble (bigger)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: kPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx + 37, center.dy - 54));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for celebrating radish (success)
class _CelebratingRadishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Radish body (white circle)
    paint.color = Colors.white;
    canvas.drawCircle(center, 30, paint);

    // Radish blush
    paint.color = Colors.pink.withAlpha(80);
    canvas.drawCircle(Offset(center.dx - 12, center.dy + 5), 6, paint);
    canvas.drawCircle(Offset(center.dx + 12, center.dy + 5), 6, paint);

    // Happy eyes (closed with joy)
    paint.color = kText;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    // Left eye (upside down arc)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx - 10, center.dy - 5), width: 12, height: 8),
      0,
      3.14,
      false,
      paint,
    );
    // Right eye
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + 10, center.dy - 5), width: 12, height: 8),
      0,
      3.14,
      false,
      paint,
    );

    // Big smile
    paint.style = PaintingStyle.fill;
    final smilePath = Path()
      ..moveTo(center.dx - 15, center.dy + 8)
      ..quadraticBezierTo(center.dx, center.dy + 22, center.dx + 15, center.dy + 8)
      ..quadraticBezierTo(center.dx, center.dy + 15, center.dx - 15, center.dy + 8)
      ..close();
    canvas.drawPath(smilePath, paint);

    // Leaves (green, raised up like arms)
    paint.color = kSecondary;
    // Left leaf (waving)
    final leftLeafPath = Path()
      ..moveTo(center.dx - 20, center.dy - 25)
      ..quadraticBezierTo(center.dx - 35, center.dy - 50, center.dx - 25, center.dy - 60)
      ..quadraticBezierTo(center.dx - 15, center.dy - 50, center.dx - 10, center.dy - 25)
      ..close();
    canvas.drawPath(leftLeafPath, paint);
    // Right leaf (waving)
    final rightLeafPath = Path()
      ..moveTo(center.dx + 20, center.dy - 25)
      ..quadraticBezierTo(center.dx + 35, center.dy - 50, center.dx + 25, center.dy - 60)
      ..quadraticBezierTo(center.dx + 15, center.dy - 50, center.dx + 10, center.dy - 25)
      ..close();
    canvas.drawPath(rightLeafPath, paint);
    // Center leaf
    final centerLeafPath = Path()
      ..moveTo(center.dx, center.dy - 28)
      ..quadraticBezierTo(center.dx, center.dy - 55, center.dx, center.dy - 65)
      ..quadraticBezierTo(center.dx - 5, center.dy - 55, center.dx, center.dy - 28)
      ..close();
    canvas.drawPath(centerLeafPath, paint);

    // Confetti dots around
    final confettiColors = [kPrimary, kSecondary, Colors.yellow, Colors.orange];
    for (int i = 0; i < 8; i++) {
      paint.color = confettiColors[i % confettiColors.length];
      const radius = 50.0;
      final x = center.dx + radius * 0.8 * (i % 2 == 0 ? 1 : -1) + (i * 5);
      final y = center.dy - 50 + (i * 3);
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Empty state widget with mascot
class EmptyStateWithMascot extends StatelessWidget {
  const EmptyStateWithMascot({
    super.key,
    required this.mascot,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final Widget mascot;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cardColor = kSurface;
    final textColor = kText;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            mascot,
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: textColor.withAlpha(140),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimary, kPrimaryLight.withAlpha(200)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
