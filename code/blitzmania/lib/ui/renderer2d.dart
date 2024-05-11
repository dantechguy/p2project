import 'package:blitzmania/state/state.dart';
import 'package:flutter/material.dart';

final Paint grassPaint = Paint()..color = Colors.green;

/// Renders an [env] to a [canvas], with a viewport of size [size].
void render2D(RacingState env, Canvas canvas, Size size) {
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);

  canvas.translate(size.width / 2, size.height / 2);
  canvas.scale(1, -1);
  canvas.scale(5, 5);

  final Paint roadPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 30
    ..strokeJoin = StrokeJoin.round
  ..style = PaintingStyle.stroke;
  // canvas.drawCircle(Offset.zero, size.shortestSide * 0.09, roadPaint);
  // canvas.drawCircle(Offset.zero, size.shortestSide * 0.06, grassPaint);
  canvas.drawPath(
    Path()
      ..moveTo(100, 100)
      ..lineTo(100, 33)
      ..lineTo(0, 33)
      ..lineTo(0, -33)
      ..lineTo(100, -33)
      ..lineTo(100, -100)
      ..lineTo(-100, -100)
      ..lineTo(-100, 100)
      ..close(),
    roadPaint,
  );

  for (Car car in env.cars) {
    canvas.save();
    canvas.translate(car.position.x, car.position.y);
    // Matrix rotation is counterclockwise
    canvas.rotate(-car.direction);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset.zero, width: car.size.width, height: car.size.height),
      Paint()..color = car.col,
    );
    canvas.restore();
  }
}
