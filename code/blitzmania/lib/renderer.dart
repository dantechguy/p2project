import 'package:flutter/material.dart';

import 'env.dart';

final Paint grassPaint = Paint()..color = Colors.green;

/// Renders an [env] to a [canvas], with a viewport of size [size].
void render(Env env, Canvas canvas, Size size) {
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);

  canvas.translate(size.width/2, size.height/2);
  canvas.scale(1, -1);
  canvas.scale(5, 5);

  for (Car car in env.cars) {
    canvas.save();
    canvas.translate(car.position.x, car.position.y);
    canvas.rotate(car.direction);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset.zero, width: car.size.width, height: car.size.height),
      Paint()..color = car.col,
    );
    canvas.restore();
  }
}
