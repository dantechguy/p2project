import 'dart:async';

import 'package:blitz/client.dart';
import 'package:blitz/src/core/client.dart';
import 'package:test/test.dart';

import '../helpers.dart';

/*
TODO: tests
  - add events
    - [x] late events are sorted (timestamp, then senderID, then eventID)
    - [x] events replace with same ID
    - [x] future events aren't considered
    - [x] server and local-shared events are unstable when added, and stable when a server event with timestamp past unstable period is added
    - [x] local events are only added to stable state with server confirmation after unstable period
    - [x] only local events are sent to server
  - server checks
    - [x] too old events throw error
  - get state
    - [ ] can get getStateAt at future time correctly. This is used for uploading state to the server, for re-connection.
 */

void main() {
  late ClientCore<int, String> client;
  late StreamController<EventClientIn<String>> inStreamCon;
  late Duration currentTime;
  late List<EventClientOut> eventsSentToServer;
  setUp(() {
    inStreamCon = StreamController();
    currentTime = Duration.zero;
    client = ClientCore<int, String>(
      inEvents: inStreamCon.stream,
      initialState: 0,
      driver: (v, e) => v,
      unstablePeriod: Duration(seconds: 1),
      getCurrentEstimatedTime: () => currentTime,
    );
    eventsSentToServer = [];
    client.eventsToServer.forEach(eventsSentToServer.add);
  });
  tearDown(() {
    inStreamCon.close();
  });

  test(
      'Late events are sorted correctly: timestamp, then senderID, then eventID',
      () {
    inStreamCon.onListen = () {
      currentTime = Duration(seconds: 4);
      final evtStrings = [
        't1000-s1-e1-local',
        't1000-s2-e3-local',
        't0-s0-e0-local',
        't1000-s2-e2-local'
      ];
      final evtStringsActual = [
        't0-s0-e0-local',
        't1000-s1-e1-local',
        't1000-s2-e2-local',
        't1000-s2-e3-local'
      ];
      final events = evtStrings.map(makeEventCI);
      inStreamCon.addAll(events);
      expect(client.getUnstableEvents(), evtStringsActual);
    };
  });

  test('Events replace event with same ID (and, incorrectly, timestamp)', () {
    inStreamCon.onListen = () {
      currentTime = Duration(seconds: 3);
      final evtStrings = [
        't0-s0-e0-d0-local',
        't1000-s2-s3-d1-local',
        't1000-s2-e3-d2-local'
      ];
      final events = evtStrings.map(makeEventCI).toList();
      inStreamCon.add(events[0]);
      inStreamCon.add(events[1]);
      expect(client.getUnstableEvents()[1].data, '1');
      inStreamCon.add(events[2]);
      expect(client.getUnstableEvents()[1].data, '2');
      expect(client.getUnstableEvents().length, 2);
    };
  });

  // TODO: Check this is what we want
  test('Too old events throw error', () {
    inStreamCon.onListen = () {
      currentTime = Duration(seconds: 5);
      expect(() {
        inStreamCon.add(makeEventCI('t500-r2000-s0-e0-server'));
      }, throwsA(TypeMatcher<CoreException>()));
      inStreamCon.add(makeEventCI('t2000-r2000-s1-e3-server'));
      expect(() {
        inStreamCon.add(makeEventCI('t0-s0-e0-local'));
      }, throwsA(TypeMatcher<CoreException>()));
      expect(() {
        inStreamCon.add(makeEventCI('t0-s3-e0-localshared'));
      }, throwsA(TypeMatcher<CoreException>()));
    };
  });

  test('Future events are ignored', () {
    inStreamCon.onListen = () {
      inStreamCon.add(makeEventCI('t0-s0-e0-local'));
      inStreamCon.add(makeEventCI('t100-s0-e1-local'));
      inStreamCon.add(makeEventCI('t200-s0-e2-local'));
      expect(0, client.getUnstableEvents().length);
      currentTime = Duration(milliseconds: 50);
      expect(1, client.getUnstableEvents().length);
      currentTime = Duration(milliseconds: 150);
      expect(2, client.getUnstableEvents().length);
      currentTime = Duration(milliseconds: 250);
      expect(3, client.getUnstableEvents().length);
    };
  });

  // TODO: add local-shared events
  // TODO: might fail because Core should have >= for baking cutoff
  test(
      'Server and local-shared events are unstable, then baked when server event with timestamp is received',
      () {
    inStreamCon.onListen = () {
      currentTime = Duration(seconds: 5);
      inStreamCon.add(makeEventCI('t0-s3-e0-localshared'));
      expect(client.getUnstableEvents().length, 1);
      expect(client.getCurrentState(), 0);
      inStreamCon.add(makeEventCI('t750-s1-e0-server'));
      expect(client.getUnstableEvents().length, 2);
      expect(client.getCurrentState(), 0);
      inStreamCon.add(makeEventCI('t1500-s3-e1-localshared'));
      expect(client.getUnstableEvents().length, 3);
      expect(client.getCurrentState(), 0);
      inStreamCon.add(makeEventCI('t2250-s1-e2-server'));
      expect(client.getUnstableEvents().length, 2);
      expect(client.getCurrentState(), 2);
      inStreamCon.add(makeEventCI('t3000-s3-e2-localshared'));
      expect(client.getUnstableEvents().length, 3);
      expect(client.getCurrentState(), 2);
      inStreamCon.add(makeEventCI('t2750-s1-e4-server'));
      expect(client.getUnstableEvents().length, 2);
      expect(client.getCurrentState(), 4);
    };
  });

  test(
      'Local events are only added to stable state if they receive server confirmation',
      () {
    inStreamCon.onListen = () {
      currentTime = Duration(seconds: 10);
      inStreamCon.add(makeEventCI('t0-s0-e0-local'));
      inStreamCon.add(makeEventCI('t2000-s1-e0-server'));
      expect(1, client.getUnstableEvents().length);
      expect(0, client.getCurrentState());
      inStreamCon.add(makeEventCI('t5000-s3-e0-localshared'));
      inStreamCon.add(makeEventCI('t5000-s3-e0-server'));
      inStreamCon.add(makeEventCI('t7000-s1-e2-server'));
      expect(1, client.getUnstableEvents().length);
      expect(2, client.getCurrentState());
    };
  });

  test('Only local events are sent to the server', () {
    inStreamCon.onListen = () {
      currentTime = Duration(seconds: 5);
      inStreamCon.add(makeEventCI('t0-s0-e0-d0-local'));
      inStreamCon.add(makeEventCI('t0-s0-e1-d1-server'));
      inStreamCon.add(makeEventCI('t0-s0-e2-d2-localshared'));
      expect(eventsSentToServer, ['0']);
    };
  });

  // TODO: test returns state from future time.
  test('getStateAt returns correct state in future at correct time', () {
    inStreamCon.onListen = () {
      currentTime = Duration(seconds: 10);
      int returnedState = -1;
      client
          .getStateAt(Duration(milliseconds: 150))
          .then((val) => returnedState = val);
      inStreamCon.add(makeEventCI('t0-s0-e0-server'));
      inStreamCon.add(makeEventCI('t100-s0-e1-server'));
      inStreamCon.add(makeEventCI('t200-s0-e2-server'));
      inStreamCon.add(makeEventCI('t3000-s0-e3-server'));
      expect(returnedState, 2);
    };
  });
}
