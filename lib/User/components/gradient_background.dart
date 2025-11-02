import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const GradientBackground({
    super.key,
    required this.child,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F1419),
                  const Color(0xFF243443),
                  const Color(0xFF1A1A2E),
                ]
              : [
                  const Color(0xFFFAFAFA),
                  const Color(0xFFFEF5D8),
                  const Color(0xFFD8D9DD).withOpacity(0.3),
                ],
        ),
      ),
      child: child,
    );
  }
}

class FootballPatternPaint extends CustomPainter {
  final bool isDark;

  FootballPatternPaint({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark 
          ? const Color(0xFF2596BE) 
          : const Color(0xFF2596BE))
          .withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 5; i++) {
      final radius = size.width * (0.2 + i * 0.15);
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint,
      );
    }

    for (var i = 0; i < 4; i++) {
      final radius = size.width * (0.15 + i * 0.12);
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.7),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF243443).withOpacity(0.7),
                  const Color(0xFF2596BE).withOpacity(0.3),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  const Color(0xFFFEF5D8).withOpacity(0.5),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark 
                ? const Color(0xFF2596BE) 
                : const Color(0xFF243443))
                .withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
