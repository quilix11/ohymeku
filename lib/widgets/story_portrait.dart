import 'package:flutter/material.dart';

/// Bundled vector cast artwork; no network request or character-image fallback.
class StoryPortrait extends StatelessWidget {
  final String name;
  final double size;
  const StoryPortrait({super.key, required this.name, this.size = 64});
  @override
  Widget build(BuildContext context) => Semantics(
      image: true,
      label: name,
      child: SizedBox.square(
          dimension: size, child: CustomPaint(painter: _Portrait(name))));
}

class _Portrait extends CustomPainter {
  final String name;
  _Portrait(this.name);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80, size.height / 80);
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(1, 1, 78, 78)));
    final palette = switch (name) {
      'Nora' => const [Color(0xFF9F6070), Color(0xFF684236), Color(0xFFF5CFAD)],
      'Elias' => const [
          Color(0xFF536F95),
          Color(0xFF373557),
          Color(0xFFE8BB96)
        ],
      'Iris' => const [Color(0xFF4C8277), Color(0xFFB06E49), Color(0xFFF3C3A1)],
      'Sol' => const [Color(0xFF7E729B), Color(0xFFDAD2E5), Color(0xFFB88062)],
      _ => const [Color(0xFF8F68A7), Color(0xFF4F355F), Color(0xFFE6BDA4)],
    };
    final p = Paint()..color = palette[0].withValues(alpha: .15);
    canvas.drawCircle(const Offset(40, 40), 39, p);
    p.color = palette[0];
    canvas.drawOval(const Rect.fromLTWH(13, 54, 54, 37), p);
    p.color = palette[1];
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(19, 15, 42, 48), const Radius.circular(21)),
        p);
    if (name == 'Nora') canvas.drawCircle(const Offset(53, 17), 10, p);
    p.color = palette[2];
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 23, 32, 35), const Radius.circular(14)),
        p);
    p.color = palette[1];
    canvas.drawArc(const Rect.fromLTWH(22, 16, 36, 29), 3.14, 3.14, true, p);
    if (name == 'Elias' || name == 'Iris') {
      p.color = palette[0];
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(19, 16, 42, 15), const Radius.circular(7)),
          p);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(17, 27, 47, 5), const Radius.circular(2)),
          p);
      p.color = const Color(0xFFF2D69A);
      canvas.drawCircle(const Offset(40, 23), 3, p);
    }
    p.color = const Color(0xFF37263D);
    canvas.drawCircle(const Offset(33, 39), 1.6, p);
    canvas.drawCircle(const Offset(47, 39), 1.6, p);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.5;
    p.strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(35, 43, 10, 7), .2, 2.7, false, p);
    if (name == 'Sol') {
      canvas.drawCircle(const Offset(32, 39), 6, p);
      canvas.drawCircle(const Offset(48, 39), 6, p);
      canvas.drawLine(const Offset(38, 39), const Offset(42, 39), p);
    }
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFFF8F3ED);
    canvas.drawPath(
        Path()
          ..moveTo(31, 58)
          ..lineTo(40, 67)
          ..lineTo(49, 58)
          ..lineTo(45, 75)
          ..lineTo(35, 75)
          ..close(),
        p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Portrait oldDelegate) =>
      oldDelegate.name != name;
}
