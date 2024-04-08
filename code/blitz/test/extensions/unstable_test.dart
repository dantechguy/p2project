/*
TODO
  - runs unstable events into returned state
 */

import 'package:blitz/client.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  late String currentState;
  late List<EventClientInInCore<String>> unstableEvents;
  String getCurrentState() => currentState;
  List<EventClientInInCore<String>> getUnstableEvents() => unstableEvents;

  setUp(() {
    currentState = '';
    unstableEvents = [];
  });
  tearDown(() {});

  test('Runs unstable events into returned state', () {
    final getUnstableState = runUnstableEvents<String, String>(
      driver: (String state, List<EventClientInInCore<String>> event) => '$state,${event.map((e) => e.data).join(',')}',
      getStableState: getCurrentState,
      getUnstableEvents: getUnstableEvents,
    );
    currentState = 'start';
    // TODO: how to test timing
    unstableEvents = [
      makeEventCI('t0-s0-e0-d1-local'),
      makeEventCI('t0-s0-e0-d20-local'),
    ];
    expect(getUnstableState(), 'start,1,20');
    unstableEvents = [
      makeEventCI('t0-s0-e0-d1-local'),
      makeEventCI('t0-s0-e0-d20-local'),
      makeEventCI('t0-s0-e0-d300-local'),
      makeEventCI('t0-s0-e0-d4000-local'),
    ];
    expect(getUnstableState(), 'start,1,20,300,4000');
  });
}
