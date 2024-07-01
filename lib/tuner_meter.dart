import 'package:flutter/material.dart';

class TunerMeter extends StatelessWidget {
  final double frequency;
  final double minFrequency;
  final double maxFrequency;
  final double correctFrequency;

  TunerMeter({
    required this.frequency,
    required this.minFrequency,
    required this.maxFrequency,
    required this.correctFrequency,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, 100), // メーターのサイズ
      painter: TunerMeterPainter(frequency, minFrequency, maxFrequency, correctFrequency),
    );
  }
}

class TunerMeterPainter extends CustomPainter {
  final double frequency;
  final double minFrequency;
  final double maxFrequency;
  final double correctFrequency;

  TunerMeterPainter(this.frequency, this.minFrequency, this.maxFrequency, this.correctFrequency);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0;

    // メーターの背景を描画
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2 - 10, size.width, 20), paint..color = Colors.grey[300]!);

    // 中央のラインを描画
    double centerX = size.width / 2;
    canvas.drawLine(
        Offset(centerX, size.height / 2 - 20), Offset(centerX, size.height / 2 + 20), paint..color = Colors.red);

    // 現在の周波数の位置を計算
    if (!minFrequency.isNaN && !maxFrequency.isNaN && minFrequency != maxFrequency) {
      double normalizedFrequency = (frequency - minFrequency) / (maxFrequency - minFrequency);
      double frequencyPosition = normalizedFrequency * size.width;

      if (!frequencyPosition.isNaN) {
        // 針を描画
        canvas.drawLine(Offset(frequencyPosition, size.height / 2 - 30),
            Offset(frequencyPosition, size.height / 2 + 30), paint..color = Colors.blue);
      }
    }
  }

  @override
  bool shouldRepaint(TunerMeterPainter oldDelegate) {
    return oldDelegate.frequency != frequency ||
        oldDelegate.minFrequency != minFrequency ||
        oldDelegate.maxFrequency != maxFrequency ||
        oldDelegate.correctFrequency != correctFrequency;
  }
}
