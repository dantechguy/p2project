import 'dart:ui';

/// Representation of the environment at an instant in time.
class Env {
  const Env({required this.cars});

  final List<Car> cars;
}

class Car {
  const Car({
    required this.pos,
    required this.rot,
    required this.size,
    required this.col,
  });

  final Offset pos;
  final double rot;
  final Size size;
  final Color col;
}
