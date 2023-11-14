import 'dart:math';
import '../shared/env.dart';
import 'package:vector_math/vector_math.dart';

const tickPeriodSecs = 0.05;

/// Takes in an [Env] (including user inputs) and returns the next tick.
Env drive(Env env) {
  final envCopy = env.copy();
  driveInplace(envCopy);
  return envCopy;
}

/// Drives [Env] in place.
/// TODO: At some point, we could do an OCaml style update which is more efficient.
/// TODO: When/if physics becomes better (moments, forces, etc), generalise it.
/// TODO: add an acceleration curve?
void driveInplace(Env env) {
  for (Car car in env.cars) {
    final userInputs = env.inputs.firstWhere((inputObj) => inputObj.userId == car.userId);

    final Vector2 driveAcceleration = Vector2(-sin(car.direction), cos(car.direction)) * car.maxAcceleration * userInputs.accelerating;
    // f = ma
    // drag is proportional to velocity squared
    final Vector2 dragAcceleration = -car.velocity * car.velocity.length * car.dragCoefficient / car.mass;
    final Vector2 netAcceleration = driveAcceleration + dragAcceleration;


    final Vector2 velocityDelta = netAcceleration * tickPeriodSecs;
    car.velocity += velocityDelta;

    car.position += car.velocity;

    car.direction += - userInputs.steering * car.maxSteer * car.velocity.length;

    print('vel: ${car.velocity}');
    print('drive acc: $driveAcceleration');
    print('drag acc: $dragAcceleration');
    print('net acc: $netAcceleration');
  }
}