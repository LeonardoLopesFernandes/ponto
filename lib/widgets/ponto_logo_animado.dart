import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

// Mesmo ícone de assets/ic_ponto.svg (viewBox 0 0 512 512), convertido em
// paths para a animação de desenho.
const String _bgPathData =
    'M100,0 H412 A100,100 0 0 1 512,100 V412 A100,100 0 0 1 412,512 H100 A100,100 0 0 1 0,412 V100 A100,100 0 0 1 100,0 Z';
const String _clock = 'M256,90 A100,100 0 0 1 256,290 A100,100 0 0 1 256,90';
const String _hands = 'M256,120 L256,190 L300,220';
const String _checkCircle =
    'M290,265 A45,45 0 0 1 380,265 A45,45 0 0 1 290,265';
const String _check = 'M315,265 L330,280 L355,250';

const Color _brand = Color(0xFF0300A2);

class _Part {
  final Path path;
  final Color color;
  final bool fill;
  final double strokeWidth;
  const _Part(this.path, this.color,
      {this.fill = false, this.strokeWidth = 8});
}

/// Desenha o ícone do app (relógio + check + "REGISTRAR PONTO") traçando os
/// paths e preenchendo cada parte, como a animação do ml_teste.
class PontoLogoAnimado extends StatefulWidget {
  final double size;
  const PontoLogoAnimado({super.key, this.size = 190});

  @override
  State<PontoLogoAnimado> createState() => _PontoLogoAnimadoState();
}

class _PontoLogoAnimadoState extends State<PontoLogoAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Part> _parts;
  late final List<List<PathMetric>> _metrics;
  late final List<double> _lengths;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
    _parts = [
      _Part(parseSvgPathData(_clock), Colors.white, strokeWidth: 20),
      _Part(parseSvgPathData(_hands), Colors.white, strokeWidth: 16),
      _Part(parseSvgPathData(_checkCircle), Colors.white,
          fill: true, strokeWidth: 8),
      _Part(parseSvgPathData(_check), _brand, strokeWidth: 12),
    ];
    _metrics = _parts.map((p) => p.path.computeMetrics().toList()).toList();
    _lengths = _metrics
        .map((ms) => ms.fold(0.0, (s, m) => s + m.length))
        .toList();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        size: Size.square(widget.size),
        painter: _PontoLogoPainter(
          parts: _parts,
          metrics: _metrics,
          lengths: _lengths,
          t: _c.value,
        ),
      ),
    );
  }
}

class _PontoLogoPainter extends CustomPainter {
  final List<_Part> parts;
  final List<List<PathMetric>> metrics;
  final List<double> lengths;
  final double t;

  static final Path _bgPath = parseSvgPathData(_bgPathData);

  _PontoLogoPainter({
    required this.parts,
    required this.metrics,
    required this.lengths,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = lengths.fold(0.0, (a, b) => a + b);
    if (total <= 0) return;
    final s = size.width / 512.0;
    canvas.save();
    canvas.scale(s);

    // Fundo arredondado já preenchido (fica igual ao ícone original).
    canvas.drawPath(
      _bgPath,
      Paint()
        ..color = _brand
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    final drawP = (t / 0.82).clamp(0.0, 1.0);
    var restante = total * drawP;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final len = lengths[i];
      if (restante > 0) {
        final stroke = Paint()
          ..color = part.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = part.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;
        var r = math.min(restante, len);
        for (final m in metrics[i]) {
          if (r <= 0) break;
          final l = math.min(m.length, r);
          canvas.drawPath(m.extractPath(0, l), stroke);
          r -= l;
        }
      }
      if (restante >= len && part.fill) {
        canvas.drawPath(
          part.path,
          Paint()
            ..color = part.color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );
      }
      restante -= len;
    }

    final textAlpha = ((t - 0.8) / 0.2).clamp(0.0, 1.0);
    if (textAlpha > 0) {
      _drawText(canvas, 'REGISTRAR', 390, textAlpha);
      _drawText(canvas, 'PONTO', 445, textAlpha);
    }

    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, double baseline, double alpha) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: alpha),
          fontSize: 52,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = 256 - tp.width / 2;
    final dy = baseline -
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _PontoLogoPainter old) => old.t != t;
}
