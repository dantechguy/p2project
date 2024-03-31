/*
TODO
  - runs unstable events into returned state
 */

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:blitz/client.dart';
import 'package:test/test.dart';

import '../helpers.dart';


void main() {
  late ClientCore client;
  late StreamController<EventClientIn<String>> streamCon;
  late Duration currentTime;
  setUp(() {
    streamCon = StreamController();
    client = ClientCore<int, String>(
      inEvents: streamCon.stream,
      initialState: 0,
      driver: (v, e) => e.map((ev) => int.parse(ev.data)).sum + v,
      unstablePeriod: Duration(seconds: 1),
      getCurrentEstimatedTime: () => currentTime,
    );
    currentTime = Duration.zero;
  });
  tearDown(() {
    streamCon.close();
  });

  test('Runs unstable events into returned state', () {
    final getState = runUnstableEvents(
      driver: (v, _) => v+1,
      getStableState: client.getCurrentState,
      getUnstableEvents: client.getUnstableEvents,
    );
    streamCon.onListen = () {
      currentTime = Duration(seconds: 1);
      streamCon.add(makeEventCI('t0-s0-e0-d1-local'));
      expect(1, getState());
      streamCon.add(makeEventCI('t0-s0-e0-d2-local'));
      expect(3, getState());
    };
  });
}