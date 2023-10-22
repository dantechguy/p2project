import 'dart:math';

import 'package:blitzmania/blitz_painter.dart';
import 'package:blitzmania/inputs.dart';
import 'package:flutter/material.dart';

import 'env.dart';

void main() {
  runApp(BlitzApp());
}

class BlitzApp extends StatefulWidget {
  const BlitzApp({super.key});

  @override
  State<BlitzApp> createState() => _BlitzAppState();
}

class _BlitzAppState extends State<BlitzApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blitz Mania',
      home: Scaffold(
        body: BlitzInputs(
          child: BlitzPaintWidget(
            env: Env(
              cars: [
                Car(pos: Offset(0, 0), rot: pi/4, size: Size(20, 50), col: Colors.red),
                Car(pos: Offset(100, 0), rot: 0, size: Size(20, 50), col: Colors.blue),
                Car(pos: Offset(200, 0), rot: pi/2, size: Size(20, 50), col: Colors.orange),
                Car(pos: Offset(0, 100), rot: 3*pi/4, size: Size(20, 50), col: Colors.purple),
                Car(pos: Offset(0, -100), rot: 0, size: Size(20, 50), col: Colors.tealAccent),
              ]
            ),
          ),
        ),
      ),
    );
  }
}