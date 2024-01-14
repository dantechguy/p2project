import 'dart:math';
import 'package:blitz/core.dart';
import 'package:blitzmania/state/state.dart';
import 'package:vector_math/vector_math.dart';

const tickPeriodSecs = 0.05;

/// Takes in an [RacingState] (including user inputs) and returns the next tick.
RacingState drive(RacingState env, List<Event> events) {
  final envCopy = env.copy();
  driveInplace(envCopy, events);
  return envCopy;
}

/// Drives [RacingState] in place.
/// TODO: At some point, we could do an OCaml style update which is more efficient.
/// TODO: When/if physics becomes better (moments, forces, etc), generalise it.
/// TODO: add an acceleration curve?
void driveInplace(RacingState env, List<Event> events) {
  // TODO: There will be 'tick' events which signal a computation. We buffer events until the next tick, when they are all computed in one go. You could also convert the events into inputs (pre-computing), but there's not much difference here.

  // TODO: Update to use input OR compute events. Some events only update inputs (between ticks), and some events compute the next tick (tick events, on the tick).
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