import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/scenario.dart';

/// Original storybook teacher illustration, drawn at any size without a backdrop.
class WillowPortrait extends StatelessWidget {
  final double width, height;
  final NpcEmotion emotion;
  final bool excludeFromSemantics;
  const WillowPortrait(
      {super.key,
      required this.width,
      required this.height,
      this.emotion = NpcEmotion.neutral,
      this.excludeFromSemantics = false});
  @override
  Widget build(BuildContext context) => Semantics(
      image: true,
      label:
          excludeFromSemantics ? null : 'Ms Willow · ${emotionLabel(emotion)}',
      excludeSemantics: excludeFromSemantics,
      child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(painter: _WillowPainter(emotion))));
}

class _WillowPainter extends CustomPainter {
  final NpcEmotion emotion;
  _WillowPainter(this.emotion);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = (size.width / 180).clamp(0.0, size.height / 220);
    canvas.translate(
        (size.width - 180 * scale) / 2, (size.height - 220 * scale) / 2);
    canvas.scale(scale);
    void oval(Rect r, Color c) => canvas.drawOval(r, Paint()..color = c);
    const hair = Color(0xFF583D31),
        skin = Color(0xFFF2C4A3),
        coat = Color(0xFF6C8C75),
        ink = Color(0xFF2F3D35);
    oval(const Rect.fromLTWH(33, 15, 112, 150), hair);
    oval(const Rect.fromLTWH(113, 4, 42, 44), hair);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(45, 126, 98, 90), const Radius.circular(30)),
        Paint()..color = coat);
    canvas.drawPath(
        Path()
          ..moveTo(75, 129)
          ..lineTo(108, 129)
          ..lineTo(92, 182)
          ..close(),
        Paint()..color = const Color(0xFFFFF5DD));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(80, 107, 24, 34), const Radius.circular(10)),
        Paint()..color = skin);
    oval(const Rect.fromLTWH(43, 33, 94, 92), skin);
    canvas.drawPath(
        Path()
          ..moveTo(43, 65)
          ..quadraticBezierTo(49, 15, 95, 23)
          ..quadraticBezierTo(145, 17, 142, 72)
          ..quadraticBezierTo(120, 54, 115, 38)
          ..quadraticBezierTo(86, 64, 43, 65),
        Paint()..color = hair);
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(71, 76), 15, line);
    canvas.drawCircle(const Offset(112, 76), 15, line);
    canvas.drawLine(const Offset(86, 76), const Offset(97, 76), line);
    if (emotion == NpcEmotion.happy ||
        emotion == NpcEmotion.laughing ||
        emotion == NpcEmotion.proud) {
      canvas.drawArc(
          const Rect.fromLTWH(63, 74, 15, 10), 3.14, 3.14, false, line);
      canvas.drawArc(
          const Rect.fromLTWH(104, 74, 15, 10), 3.14, 3.14, false, line);
    } else {
      oval(const Rect.fromLTWH(67, 70, 7, 11), ink);
      oval(const Rect.fromLTWH(108, 70, 7, 11), ink);
    }
    oval(const Rect.fromLTWH(52, 90, 17, 9), const Color(0xFFDF9A92));
    oval(const Rect.fromLTWH(115, 90, 17, 9), const Color(0xFFDF9A92));
    if (emotion == NpcEmotion.surprised || emotion == NpcEmotion.shocked) {
      oval(const Rect.fromLTWH(84, 99, 14, 17), ink);
    } else if (emotion == NpcEmotion.angry ||
        emotion == NpcEmotion.sad ||
        emotion == NpcEmotion.worried) {
      canvas.drawArc(
          const Rect.fromLTWH(80, 108, 23, 12), 3.14, 3.14, false, line);
    } else {
      canvas.drawArc(const Rect.fromLTWH(79, 93, 25, 20), 0, 3.14, false, line);
    }
    canvas.save();
    canvas.translate(113, 172);
    canvas.rotate(-.15);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-27, -13, 57, 45), const Radius.circular(4)),
        Paint()..color = const Color(0xFF8F4856));
    canvas.drawLine(
        const Offset(1, -10),
        const Offset(1, 28),
        Paint()
          ..color = const Color(0xFFFFEACB)
          ..strokeWidth = 3);
    canvas.restore();
    oval(const Rect.fromLTWH(102, 183, 27, 15), skin);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WillowPainter old) => old.emotion != emotion;
}
