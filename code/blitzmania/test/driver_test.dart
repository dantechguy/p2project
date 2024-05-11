// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:blitz/client.dart';
import 'package:blitzmania/dart_extensions.dart';
import 'package:blitzmania/state/driver.dart';
import 'package:blitzmania/state/state.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

RacingState generateRandomState() {
  final Random r = Random();
  final numIds = 1 + r.nextInt(20);
  final ids = {for (int i = 0; i < numIds; i++) r.nextInt(20)}.toList();
  return RacingState(
    gameTime: Duration(milliseconds: r.nextInt(10000000)),
    users: [
      for (int id in ids) User(displayName: 'user $id', id: id, connected: true)
    ],
    cars: [
      for (int id in ids)
        Car(
          userId: id,
          position: (Vector2.random() - Vector2(0.5, 0.5)) * 1000,
          velocity: (Vector2.random() - Vector2(0.5, 0.5)) * 50,
          direction: r.nextDouble() * pi * 2,
          mass: r.nextDouble() * 50,
          forwardDragCoefficient: r.nextDouble(),
          sideDragCoefficient: r.nextDouble(),
          maxAcceleration: r.nextDouble() * 500,
          maxSteer: r.nextDouble() * 0.4,
          size: Size(r.nextDouble() * 30, r.nextDouble() * 50),
          col: Color((r.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
        )
    ],
    inputs: [
      for (int id in ids)
        UserInput(
          userId: id,
          accelerating: r.nextDouble() * 2 - 1,
          steering: r.nextDouble() * 2 - 1,
        )
    ],
  );
}

List<EventClientInInCore<String>> generateRandomEvents(RacingState state) {
  final Random r = Random();
  final testEventData = [
    'tick',
    'ia:1.0',
    'ia:-1.0',
    'ia:0.0',
    'is:1.0',
    'is:-1.0',
    'is:0.0',
    'disconnected:${state.users.randomItem().id}',
    'connected:${r.nextInt(1000) + 21}'
  ];
  return [
    for (String data in testEventData)
      EventClientInFromServer(
        serverReceiptTimestamp:
            state.gameTime - Duration(milliseconds: r.nextInt(1000)),
        generatedTimestamp:
            state.gameTime + Duration(milliseconds: r.nextInt(1000)),
        senderID: state.users.randomItem().id,
        data: data,
        eventID: r.nextInt(1000),
      ),
  ];
}

void main() {
  late List<EventClientInInCore<String>> testEvents;
  setUp(() {});
  test('Fuzzy test that driver is deterministic', () {
    for (int i = 0; i < 1000; i++) {
      final state = generateRandomState();
      final testEvents = generateRandomEvents(state);
      for (final event in testEvents) {
        final res1 = jsonEncode(drive(state, [event]).toJson());
        final res2 = jsonEncode(drive(state, [event]).toJson());
        expect(res1, res2);
      }
    }
  });

  test('Fuzzy test that state is driver doesn\'t modify state', () {
    for (int i = 0; i<1000; i++) {
      final state = generateRandomState();
      final serialised = jsonEncode(state.toJson());
      final testEvents = generateRandomEvents(state);
      for (final event in testEvents) {
        drive(state, [event]);
        expect(serialised, jsonEncode(state.toJson()));
      }
    }
  });
}
