import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hk_stock_app/models/kline_data.dart';

/// K-line Chart Component using CustomPainter
/// Renders candlestick OHLC bars with volume and MA lines
class KlineChart extends StatelessWidget {
  final List<KlineData> klines;
  final bool isGainer;
  final double height;
  final bool showVolume;

  const KlineChart({
    required this.klines,
    required this.isGainer,
    this.height = 300,
    this.showVolume = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (klines.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No chart data available',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _KlinePainter(klines: klines, showVolume: showVolume),
        child: Container(),
      ),
    );
  }
}

/// Simplified mini K-line chart
class MiniKlineChart extends StatelessWidget {
  final List<KlineData> klines;
  final bool isGainer;
  final double height;

  const MiniKlineChart({
    required this.klines,
    required this.isGainer,
    this.height = 150,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (klines.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No data', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _KlinePainter(klines: klines, showVolume: false, mini: true),
        child: Container(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CustomPainter implementation
// ─────────────────────────────────────────────
class _KlinePainter extends CustomPainter {
  final List<KlineData> klines;
  final bool showVolume;
  final bool mini;

  static const _upColor = Color(0xFFE74C3C);
  static const _downColor = Color(0xFF27AE60);
  static const _ma5Color = Color(0xFFF39C12);
  static const _ma20Color = Color(0xFF3498DB);
  static const _gridColor = Color(0xFF2C3E50);
  static const _textColor = Color(0xFFAAAAAA);

  _KlinePainter({
    required this.klines,
    this.showVolume = true,
    this.mini = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty) return;

    final chartH = showVolume ? size.height * 0.7 : size.height;
    final volH = showVolume ? size.height * 0.28 : 0.0;
    final volTop = size.height - volH;

    // Price range
    double maxH = klines.map((k) => k.high).reduce(math.max);
    double minL = klines.map((k) => k.low).reduce(math.min);
    final priceRange = maxH - minL;
    if (priceRange == 0) return;

    // Volume range
    final maxVol = klines.map((k) => k.volume.toDouble()).reduce(math.max);

    final barCount = klines.length;
    final barWidth = size.width / barCount;
    final candleW = math.max(barWidth * 0.6, 1.0);

    // Draw grid (skip in mini mode)
    if (!mini) {
      final gridPaint = Paint()
        ..color = _gridColor.withValues(alpha: 0.3)
        ..strokeWidth = 0.5;
      for (var i = 1; i < 4; i++) {
        final y = chartH * i / 4;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Draw candles
    for (var i = 0; i < klines.length; i++) {
      final kline = klines[i];
      final isUp = kline.close >= kline.open;
      final color = isUp ? _upColor : _downColor;

      final x = (i + 0.5) * barWidth;
      final yHigh =
          chartH * (1 - (kline.high - minL) / priceRange);
      final yLow =
          chartH * (1 - (kline.low - minL) / priceRange);
      final yOpen =
          chartH * (1 - (kline.open - minL) / priceRange);
      final yClose =
          chartH * (1 - (kline.close - minL) / priceRange);

      final candlePaint = Paint()
        ..color = color
        ..strokeWidth = 1.0;

      // Wick
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), candlePaint);

      // Body
      final bodyTop = math.min(yOpen, yClose);
      final bodyBot = math.max(yOpen, yClose);
      final bodyH = math.max(bodyBot - bodyTop, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(x - candleW / 2, bodyTop, candleW, bodyH),
        Paint()..color = color,
      );

      // Volume bars
      if (showVolume && maxVol > 0) {
        final volBarH = volH * (kline.volume / maxVol);
        canvas.drawRect(
          Rect.fromLTWH(
            x - candleW / 2,
            volTop + volH - volBarH,
            candleW,
            volBarH,
          ),
          Paint()..color = color.withValues(alpha: 0.5),
        );
      }
    }

    // MA lines
    _drawMA(canvas, size, chartH, minL, priceRange,
        klines.map((k) => k.ma5).toList(), _ma5Color, barWidth);
    _drawMA(canvas, size, chartH, minL, priceRange,
        klines.map((k) => k.ma20).toList(), _ma20Color, barWidth);

    // Price labels (skip in mini mode)
    if (!mini) {
      final labelPaint = TextPainter(textDirection: TextDirection.ltr);
      for (var i = 0; i < 4; i++) {
        final price = minL + priceRange * (4 - i) / 4;
        final y = chartH * i / 4;
        labelPaint.text = TextSpan(
          text: price.toStringAsFixed(2),
          style: const TextStyle(color: _textColor, fontSize: 9),
        );
        labelPaint.layout();
        labelPaint.paint(canvas, Offset(2, y + 2));
      }
    }
  }

  void _drawMA(Canvas canvas, Size size, double chartH, double minL,
      double priceRange, List<double?> values, Color color, double barWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    Offset? prev;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) {
        prev = null;
        continue;
      }
      final x = (i + 0.5) * barWidth;
      final y = chartH * (1 - (v - minL) / priceRange);
      final cur = Offset(x, y);
      if (prev != null) {
        canvas.drawLine(prev, cur, paint);
      }
      prev = cur;
    }
  }

  @override
  bool shouldRepaint(_KlinePainter old) =>
      old.klines != klines || old.showVolume != showVolume;
}
