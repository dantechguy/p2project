import 'dart:math';
import 'dart:ui';

import 'package:blitz/client.dart';
import 'package:blitzmania/dart_extensions.dart';
import 'package:blitzmania/state/state.dart';
import 'package:vector_math/vector_math.dart';

const tickPeriodSecs = 0.05;

/// Takes in an [RacingState] (including user inputs) and returns the next tick.
RacingState drive(RacingState env, List<EventClientInInCore<String>> events) {
  final envCopy = env.copy();
  driveInplace(envCopy, events);
  return envCopy;
}

/// Drives [RacingState] in place.
/// TODO: At some point, we could do an OCaml style update which is more efficient.
/// TODO: When/if physics becomes better (moments, forces, etc), generalise it.
/// TODO: add an acceleration curve?
void driveInplace(RacingState state, List<EventClientInInCore<String>> events) {
  for (final event in events) {
    if (event.data == 'tick') {
      driverCompute(state, event);
    } else if (event.data.startsWith('input:')) {
      driverInputs(state, event);
    } else if (event.data.startsWith('connected:') ||
        event.data.startsWith('disconnected:')) {
      clientConnectDisconnect(state, event);
    } else {
      print('ERROR: invalid event. Not handled!');
      throw 'Invalid event. Not handled!!';
    }
  }
}

void clientConnectDisconnect(
    RacingState state, EventClientInInCore<String> event) {
  final clientID = int.parse(event.data.splitAfterFirst(':'));
  if (event.data.startsWith('connected:')) {
    state.users.add(
        User(displayName: 'Player $clientID', id: clientID, connected: true));
    state.cars.add(Car(
        userId: clientID,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        direction: 0,
        mass: 10,
        dragCoefficient: 10,
        maxAcceleration: 30,
        maxSteer: 0.05,
        size: const Size(3, 6),
        col: Color(((clientID * 123456) & 0xFFFFFF).toInt()).withOpacity(1.0)));
    state.inputs.add(UserInput(userId: clientID, accelerating: 0, steering: 0));
  } else if (event.data.startsWith('disconnected:')) {
    state.users.removeWhere((user) => user.id == clientID);
    state.cars.removeWhere((car) => car.userId == clientID);
    state.inputs.removeWhere((input) => input.userId == clientID);
  }
}

void driverInputs(RacingState state, EventClientInInCore<String> event) {
  try {
    if (event.data.startsWith('input:steering:')) {
      final steering = double.parse(event.data.split(':')[2]);
      state.inputs
          .firstWhere((inputObj) => inputObj.userId == event.senderID)
          .steering = steering;
    } else if (event.data.startsWith('input:acceleration:')) {
      final acceleration = double.parse(event.data.split(':')[2]);
      state.inputs
          .firstWhere((inputObj) => inputObj.userId == event.senderID)
          .accelerating = acceleration;
    }
  } on FormatException {
    print('Invalid input event: ${event.data}');
    rethrow;
  }
}

void driverCompute(RacingState state, EventClientInInCore<String> event) {
  state.gameTime = event.generatedTimestamp;

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
