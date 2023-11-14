import 'dart:ui';

import 'package:vector_math/vector_math.dart';

/// Representation of the environment at an instant in time.
///
/// Stores:
class Env {
  Env({
    required this.gameTime,
    required this.users,
    required this.cars,
    required this.inputs,
  });

  Duration gameTime;
  List<User> users;
  List<UserInput> inputs;
  List<Car> cars;

  Env copy() => Env(
        users: users.map((user) => user.copy()).toList(),
        inputs: inputs.map((input) => input.copy()).toList(),
        cars: cars.map((car) => car.copy()).toList(),
      );
}

// TODO: Consider merging [User] and [UserInput].
class User {
  User({
    required this.displayName,
    required this.id,
    required this.connected,
  });

  String displayName;

  // TODO: can be abstracted later, but for the sake of efficiency, an int will do.
  int id;

  /// If the user is actively connected or disconnected.
  bool connected;

  User copy() => User(displayName: displayName, id: id, connected: connected);
}

// TODO: Just because this is the current model, doesn't mean the physics can't later change.
class UserInput {
  UserInput({
    required this.userId,
    required this.accelerating,
    required this.steering,
  });

  int userId;

  /// Value from 0 to 1 representing how much they are accelerating.
  /// Analogous to how far the acceleration pedal is pressed down.
  double accelerating;

  /// Value from -1 to 1 representing how much they are steering.
  /// Negative is left steering, positive is right.
  double steering;

  UserInput copy() => UserInput(
        userId: userId,
        accelerating: accelerating,
        steering: steering,
      );
}

class Car {
  Car({
    required this.userId,
    required this.position,
    required this.velocity,
    required this.direction,
    required this.mass,
    required this.dragCoefficient,
    required this.maxAcceleration,
    required this.maxSteer,
    required this.size,
    required this.col,
  });

  int userId;

  Vector2 position;

  // TODO: maybe change to momentum
  Vector2 velocity;
  double direction;
  double mass;

  /// Not real drag-coefficient. Multiplied by velocity to get drag force.
  double dragCoefficient;
  double maxAcceleration;
  double maxSteer;
  Size size;
  Color col;

  Car copy() => Car(
    userId: userId,
    position: position,
    velocity: velocity,
    direction: direction,
    mass: mass,
    dragCoefficient: dragCoefficient,
    maxAcceleration: maxAcceleration,
    maxSteer: maxSteer,
    size: size,
    col: col,
  );
}
