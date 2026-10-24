import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedLockIcon extends StatefulWidget {
  final bool locked;
  final double size;
  final Color color;

  const AnimatedLockIcon({
    super.key,
    required this.locked,
    this.size = 24,
    this.color = const Color(0xFF0109B2),
  });

  @override
  State<AnimatedLockIcon> createState() => _AnimatedLockIconState();
}

class _AnimatedLockIconState extends State<AnimatedLockIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.locked ? 0 : 1,
    );
  }

  @override
  void didUpdateWidget(AnimatedLockIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locked != widget.locked) {
      if (widget.locked) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: Size.square(widget.size),
        painter: _LockPainter(t: _controller.value, color: widget.color),
      ),
    );
  }
}

class _LockPainter extends CustomPainter {
  final double t;
  final Color color;

  _LockPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.17 * s, 0.45 * s, 0.66 * s, 0.47 * s),
      Radius.circular(0.13 * s),
    );

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.085 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pivot = Offset(0.30 * s, 0.50 * s);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(-0.55 * t);
    canvas.translate(-pivot.dx, -pivot.dy);
    final shackle = Path()
      ..moveTo(0.30 * s, 0.53 * s)
      ..lineTo(0.30 * s, 0.30 * s)
      ..arcTo(
        Rect.fromCircle(center: Offset(0.50 * s, 0.30 * s), radius: 0.20 * s),
        math.pi,
        math.pi,
        false,
      )
      ..lineTo(0.70 * s, 0.53 * s);
    canvas.drawPath(shackle, stroke);
    canvas.restore();

    canvas.drawRRect(body, Paint()..color = color);

    final keyhole = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(0.50 * s, 0.665 * s), 0.062 * s, keyhole);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.468 * s, 0.68 * s, 0.064 * s, 0.11 * s),
        Radius.circular(0.03 * s),
      ),
      keyhole,
    );
  }

  @override
  bool shouldRepaint(covariant _LockPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
