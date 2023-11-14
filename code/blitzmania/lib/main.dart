import 'dart:async';
import 'dart:math';

import 'package:blitzmania/ui/blitz_painter.dart';
import 'package:blitzmania/physics/driver.dart';
import 'package:blitzmania/ui/inputs.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import 'shared/env.dart';

void main() {
  runApp(BlitzApp());
}

class BlitzApp extends StatefulWidget {
  const BlitzApp({super.key});

  @override
  State<BlitzApp> createState() => _BlitzAppState();
}

class _BlitzAppState extends State<BlitzApp> {
  late Env env;


  final input = UserInput(userId: 0, accelerating: 0, steering: 0);

  @override
  void initState() {
    super.initState();

    final testCar = Car(
      userId: 0,
      position: Vector2.zero(),
      velocity: Vector2.zero(),
      direction: 0,
      mass: 1000,
      dragCoefficient: 1000,
      maxAcceleration: 3,
      maxSteer: 2 * pi * 0.01,
      size: Size(1, 2),
      col: Colors.red,
    );

    env = Env(
      inputs: [],
      users: [
        User(displayName: 'dan', id: 0, connected: true),
      ],
      cars: [
        testCar,
      ],
    );

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        env.inputs = [input];
        driveInplace(env);
        print(env.cars.first.position);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blitz Mania',
      home: Scaffold(
        body: BlitzInputs(
          onSteer: (double steer) => input.steering = steer,
          onAccelerate: (double accelerate) => input.accelerating = accelerate,
          child: BlitzPaintWidget(
            env: env,
          ),
        ),
      ),
    );
  }
}
