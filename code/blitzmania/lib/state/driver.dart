import 'dart:math';

import 'package:blitz/client.dart';
import 'package:blitzmania/state/state.dart';
import 'package:vector_math/vector_math.dart';

const tickPeriodSecs = 0.05;

/// Takes in an [RacingState] (including user inputs) and returns the next tick.
RacingState drive(RacingState env, List<EventClientIn> events) {
  final envCopy = env.copy();
  driveInplace(envCopy, events);
  return envCopy;
}

/// Drives [RacingState] in place.
/// TODO: At some point, we could do an OCaml style update which is more efficient.
/// TODO: When/if physics becomes better (moments, forces, etc), generalise it.
/// TODO: add an acceleration curve?
void driveInplace(RacingState state, List<EventClientIn> events) {
  for (EventClientIn event in events) {
    if (event.data == 'tick') {
      driverCompute(state);
    } else if (event.data.startsWith('steering:') ||
        event.data.startsWith('acceleration:')) {
      driverInputs(state, event);
    }
  }
}

void driverInputs(RacingState state, EventClientIn event) {
  try {
    if (event.data.startsWith('steering:')) {
      final steering = double.parse(event.data.split(':')[1]);
      state.inputs
          .firstWhere((inputObj) => inputObj.userId == event.senderID)
          .steering = steering;
    } else if (event.data.startsWith('acceleration:')) {
      final acceleration = double.parse(event.data.split(':')[1]);
      state.inputs
          .firstWhere((inputObj) => inputObj.userId == event.senderID)
          .accelerating = acceleration;
    }
  } on FormatException {
    print('Invalid input event: ${event.data}');
  }
}

void driverCompute(RacingState state) {
  for (Car car in state.cars) {
    final userInputs =
    state.inputs.firstWhere((inputObj) => inputObj.userId == car.userId);

    final Vector2 driveAcceleration =
        Vector2(-sin(car.direction), cos(car.direction)) *
            car.maxAcceleration *
            userInputs.accelerating;
    // f = ma
    // drag is proportional to velocity squared
    final Vector2 dragAcceleration =
        -car.velocity * car.velocity.length * car.dragCoefficient / car.mass;
    final Vector2 netAcceleration = driveAcceleration + dragAcceleration;

    final Vector2 velocityDelta = netAcceleration * tickPeriodSecs;
    car.velocity += velocityDelta;

    car.position += car.velocity;

    car.direction += -userInputs.steering * car.maxSteer * car.velocity.length;
  }
}
