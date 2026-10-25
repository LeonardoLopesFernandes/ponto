import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessCheckAnimation extends StatefulWidget {
  final double size;

  const SuccessCheckAnimation({super.key, this.size = 120});

  @override
  State<SuccessCheckAnimation> createState() => _SuccessCheckAnimationState();
}

class _SuccessCheckAnimationState extends State<SuccessCheckAnimation>
    with SingleTickerProviderStateMixin {
  static const double _frames = 63;
  static const double _stopFrame = 50;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2625),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.animateTo(
        _stopFrame / _frames,
        duration: Duration(milliseconds: (_stopFrame / 24 * 1000).round()),
        curve: Curves.linear,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        'assets/check_success.json',
        controller: _controller,
        fit: BoxFit.contain,
      ),
    );
  }
}
