import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AppIconKind { journey, words, progress, meku, menu, profile, settings }

/// Original line icons on a shared 24px grid. Labels belong to their controls.
class AppIcon extends StatelessWidget {
  final AppIconKind kind;
  final double size;
  final Color? color;
  const AppIcon(this.kind, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
              painter: _AppIconPainter(
                  kind,
                  color ??
                      IconTheme.of(context).color ??
                      Theme.of(context).colorScheme.onSurface))));
}

class _AppIconPainter extends CustomPainter {
  final AppIconKind kind;
  final Color color;
  const _AppIconPainter(this.kind, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case AppIconKind.journey:
        canvas.drawPath(
            Path()
              ..moveTo(3, 6)
              ..lineTo(9, 3)
              ..lineTo(15, 6)
              ..lineTo(21, 3)
              ..lineTo(21, 18)
              ..lineTo(15, 21)
              ..lineTo(9, 18)
              ..lineTo(3, 21)
              ..close(),
            pen);
        canvas.drawLine(const Offset(9, 3), const Offset(9, 18), pen);
        canvas.drawLine(const Offset(15, 6), const Offset(15, 21), pen);
      case AppIconKind.words:
        canvas.drawPath(
            Path()
              ..moveTo(5, 18)
              ..lineTo(4, 18)
              ..quadraticBezierTo(2, 18, 2, 16)
              ..lineTo(2, 4)
              ..quadraticBezierTo(2, 2, 4, 2)
              ..lineTo(15, 2),
            pen);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(6, 5, 15, 17), const Radius.circular(3)),
            pen);
        canvas.drawLine(const Offset(10, 10), const Offset(17, 10), pen);
        canvas.drawLine(const Offset(10, 14), const Offset(15, 14), pen);
      case AppIconKind.progress:
        canvas.drawPath(
            Path()
              ..moveTo(3, 4)
              ..lineTo(3, 20)
              ..lineTo(21, 20),
            pen);
        canvas.drawPath(
            Path()
              ..moveTo(7, 15)
              ..lineTo(11, 11)
              ..lineTo(15, 13)
              ..lineTo(21, 5),
            pen);
        canvas.drawPath(
            Path()
              ..moveTo(17, 5)
              ..lineTo(21, 5)
              ..lineTo(21, 9),
            pen);
      case AppIconKind.meku:
        canvas.drawPath(
            Path()
              ..moveTo(4, 11)
              ..lineTo(3, 3)
              ..lineTo(9, 7)
              ..quadraticBezierTo(12, 5, 15, 7)
              ..lineTo(21, 3)
              ..lineTo(20, 11)
              ..quadraticBezierTo(23, 17, 12, 22)
              ..quadraticBezierTo(1, 17, 4, 11)
              ..close(),
            pen);
        canvas.drawPath(
            Path()
              ..moveTo(7, 14)
              ..quadraticBezierTo(10, 15, 12, 19)
              ..quadraticBezierTo(14, 15, 17, 14),
            pen);
        canvas.drawLine(const Offset(7, 11), const Offset(8, 12), pen);
        canvas.drawLine(const Offset(17, 11), const Offset(16, 12), pen);
      case AppIconKind.menu:
        canvas.drawLine(const Offset(4, 6), const Offset(20, 6), pen);
        canvas.drawLine(const Offset(4, 12), const Offset(16, 12), pen);
        canvas.drawLine(const Offset(4, 18), const Offset(20, 18), pen);
      case AppIconKind.profile:
        canvas.drawCircle(const Offset(12, 7), 3.5, pen);
        canvas.drawPath(
            Path()
              ..moveTo(4, 21)
              ..lineTo(4, 19)
              ..cubicTo(4, 12, 20, 12, 20, 19)
              ..lineTo(20, 21),
            pen);
      case AppIconKind.settings:
        final gear = Path();
        for (var tooth = 0; tooth < 8; tooth++) {
          for (var corner = 0; corner < 4; corner++) {
            final angle = (tooth + corner / 4) * math.pi / 4 - math.pi / 2;
            final radius = corner == 0 || corner == 3 ? 7.5 : 10.0;
            final point = Offset(
                12 + math.cos(angle) * radius, 12 + math.sin(angle) * radius);
            if (tooth == 0 && corner == 0) {
              gear.moveTo(point.dx, point.dy);
            } else {
              gear.lineTo(point.dx, point.dy);
            }
          }
        }
        canvas.drawPath(gear..close(), pen);
        canvas.drawCircle(const Offset(12, 12), 3, pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AppIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
