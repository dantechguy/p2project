import 'dart:ui';

import 'package:blitzmania/dart_extensions.dart';
import 'package:vector_math/vector_math.dart';

RacingState getInitialState() {
  return RacingState(
    gameTime: Duration.zero,
    users: [],
    cars: [],
    inputs: [],
  );
}

/// Representation of the environment at an instant in time.
///
/// Stores:
class RacingState {
  RacingState({
    required this.gameTime,
    required this.users,
    required this.cars,
    required this.inputs,
  });

  Duration gameTime;
  List<User> users;
  List<UserInput> inputs;
  List<Car> cars;

  RacingState copy() => RacingState(
        gameTime: gameTime,
        users: users.map((user) => user.copy()).toList(),
        inputs: inputs.map((input) => input.copy()).toList(),
        cars: cars.map((car) => car.copy()).toList(),
      );

  @override
  String toString() {
    return 'state ' + [users, cars, inputs].toPrettyString(indent: '  ');
  }

  RacingState.fromJson(Map<String, dynamic> json)
      : gameTime = Duration(microseconds: json['gameTime']),
        users = (json['users'] as List).map((e) => User.fromJson(e)).toList(),
        cars = (json['cars'] as List).map((e) => Car.fromJson(e)).toList(),
        inputs = (json['inputs'] as List).map((e) => UserInput.fromJson(e)).toList();

  Map<String, dynamic> toJson() => {
    'gameTime': gameTime.inMicroseconds,
    'users': users.map((e) => e.toJson()).toList(),
    'cars': cars.map((e) => e.toJson()).toList(),
    'inputs': inputs.map((e) => e.toJson()).toList(),
  };
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

  @override
  String toString() {
    return 'user\n' +
        'id: $id\ndisplayName: $displayName\nconnected: $connected'.indent(1);
  }

  User.fromJson(Map<String, dynamic> json)
      : displayName = json['displayName'],
        id = json['id'],
        connected = json['connected'];

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'id': id,
    'connected': connected,
  };
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

  // TODO: Somehow do OCaml-esque efficient copying.
  UserInput copy() => UserInput(
        userId: userId,
        accelerating: accelerating,
        steering: steering,
      );

  @override
  String toString() {
    return 'input\n' +
        'id: $userId\naccelerating: $accelerating\nsteering: $steering'
            .indent(1);
  }

  UserInput.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        accelerating = json['accelerating'],
        steering = json['steering'];

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'accelerating': accelerating,
    'steering': steering,
  };
}

class Car {
  Car({
    required this.userId,
    required this.position,
    required this.velocity,
    required this.direction,
    required this.mass,
    required this.forwardDragCoefficient,
    required this.sideDragCoefficient,
    required this.maxAcceleration,
    required this.maxSteer,
    required this.size,
    required this.col,
  });

  int userId;

  Vector2 position;

  // TODO: consider adding acceleration here, even thought it is generated from user inputs.
  // TODO: maybe change to momentum
  Vector2 velocity;
  double direction;
  double mass;

  /// Not real drag-coefficient. Multiplied by velocity to get drag force.
  double forwardDragCoefficient;
  double sideDragCoefficient;
  double maxAcceleration;
  double maxSteer;
  Size size;
  Color col;

  Car copy() => Car(
        userId: userId,
        position: position.copy(),
        velocity: velocity.copy(),
        direction: direction,
        mass: mass,
        forwardDragCoefficient: forwardDragCoefficient,
        sideDragCoefficient: sideDragCoefficient,
        maxAcceleration: maxAcceleration,
        maxSteer: maxSteer,
        size: size,
        col: col,
      );

  @override
  String toString() {
    return 'car\n' +
        'userId: $userId\nposition: $position\nvelocity: $velocity\ndirection: $direction\nmass: $mass\ndragCoefficient: $forwardDragCoefficient\nmaxAcceleration: $maxAcceleration\nmaxSteer: $maxSteer\nsize: $size\ncol: $col'
            .indent(1);
  }

  Car.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        position = Vector2(json['position'][0], json['position'][1]),
        velocity = Vector2(json['velocity'][0], json['velocity'][1]),
        direction = json['direction'],
        mass = json['mass'],
        forwardDragCoefficient = json['forwardDragCoefficient'],
        sideDragCoefficient = json['sideDragCoefficient'],
        maxAcceleration = json['maxAcceleration'],
        maxSteer = json['maxSteer'],
        size = Size(json['size'][0], json['size'][1]),
        col = Color(json['col']);

  Map<String, dynamic> toJson() => {
    // TODO: EVAL REMOVE
    'u': userId,
    'p': position.toList(),
    'v': velocity.toList(),
    'd': direction,
    'c': col.value,
    // 'userId': userId,
    // 'position': position.toList(),
    // 'velocity': velocity.toList(),
    // 'direction': direction,
    // 'mass': mass,
    // 'forwardDragCoefficient': forwardDragCoefficient,
    // 'sideDragCoefficient': sideDragCoefficient,
    // 'maxAcceleration': maxAcceleration,
    // 'maxSteer': maxSteer,
    // 'size': [size.width, size.height],
    // 'col': col.value,
  };
}
