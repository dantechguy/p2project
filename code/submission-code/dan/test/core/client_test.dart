@Timeout(Duration(hours: 1))
import 'dart:async';
import 'package:blitz/client.dart';
import 'package:blitz/src/core/client.dart';
import 'package:blitz/src/dart_extensions.dart';
import 'package:test/test.dart';
import '../helpers.dart';

/*
TODO: tests
  - initialisation
    - [ ] client doesn't receive events before calling [.start()]
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
  late StreamController<EventClientInPreCore<String>> inStreamCon;
  late Duration currentTime;
  late List<EventClientOut> eventsSentToServer;
  late UniqueIntIDGenerator eventIDGenerator;
  setUp(() {
    eventIDGenerator = UniqueIntIDGenerator();
    inStreamCon = StreamController();
    currentTime = Duration.zero;
    eventsSentToServer = [];
    client = ClientCore<int, String>(
      inEvents: inStreamCon.stream,
      initialState: 0,
      driver: (v, e) => v + 1,
      unstablePeriod: Duration(seconds: 1),
      getCurrentEstimatedTime: () => currentTime,
      clientID: 1,
      generateUniqueEventID: eventIDGenerator.generateUniqueID,
    );
    client.eventsToServer.forEach(eventsSentToServer.add);
  });

  // TODO: client doesn't receive events before calling .start()

  test(
      'Late events are sorted correctly: timestamp, then senderID, then eventID',
      () async {
    inStreamCon.onListen = () async {
      currentTime = Duration(seconds: 4);
      // TODO: how to test timings for local events
      final events = [
        't1000-s1-e1-d2-localshared',
        't1000-s2-e3-d4-localshared',
        't0-s0-e0-d0-localshared',
        't500-s10-e10-d1-localshared',
        't1000-s2-e2-d3-localshared'
      ].map(makeEventCIPre).toList();
      inStreamCon.addAll(events);
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().map((e) => e.data), ['0', '1', '2', '3', '4']);
      inStreamCon.close();
    };
    client.init();
    await inStreamCon.done;
  });

  test('Events replace event with same ID (and, incorrectly, timestamp)',
      () async {
    inStreamCon.onListen = () async {
      currentTime = Duration(seconds: 3);
      final evtStrings = [
        't0-r0-s0-e0-d0-server',
        't1000-r0-s2-e3-d1-server',
        't1000-r0-s2-e3-d2-server'
      ];
      final events = evtStrings.map(makeEventCIPre).toList();
      inStreamCon.add(events[0]);
      inStreamCon.add(events[1]);
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().map((e) => e.data), ['0', '1']);
      inStreamCon.add(events[2]);
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().map((e) => e.data), ['0', '2']);
      inStreamCon.close();
    };
    client.init();
    await inStreamCon.done;
  });

  // TODO: Check this is what we want. Doesn't work because error is thrown from different async call stack.
  // test('Too old events throw error', () async {
  //   inStreamCon.onListen = () async {
  //     currentTime = Duration(seconds: 5);
  //
  //     expectLater(() async {
  //       inStreamCon.add(makeEventCI('t500-r2000-s0-e0-server'));
  //       await client.receivedEvents(n: 1);
  //     }, throwsA(isA<CoreException>()));
  //
  //     inStreamCon.add(makeEventCI('t2000-r2000-s1-e3-server'));
  //     expectLater(() async {
  //       inStreamCon.add(makeEventCI('t0-s0-e0-local'));
  //       await client.receivedEvents(n: 1);
  //     }, throwsA(isA<CoreException>()));
  //
  //     expectLater(() async {
  //       inStreamCon.add(makeEventCI('t0-s3-e0-localshared'));
  //       await client.receivedEvents(n: 1);
  //     }, throwsA(isA<CoreException>()));
  //
  //     inStreamCon.close();
  //   };
  //
  //   client.start();
  //   await inStreamCon.done;
  // });

  test('Future events are ignored', () async {
    inStreamCon.onListen = () async {
      inStreamCon.add(makeEventCIPre('t0-r0-s0-e0-server'));
      inStreamCon.add(makeEventCIPre('t100-r100-s0-e1-server'));
      inStreamCon.add(makeEventCIPre('t200-r200-s0-e2-server'));
      await Future.delayed(Duration.zero);
      expect(0, client.getUnstableEvents().length);
      currentTime = Duration(milliseconds: 50);
      expect(1, client.getUnstableEvents().length);
      currentTime = Duration(milliseconds: 150);
      expect(2, client.getUnstableEvents().length);
      currentTime = Duration(milliseconds: 250);
      expect(3, client.getUnstableEvents().length);
      inStreamCon.close();
    };
    client.init();
    await inStreamCon.done;
  });

  // TODO: add local-shared events
  // TODO: might fail because Core should have >= for baking cutoff
  test(
      'Server and local-shared events are unstable, then baked when server event with timestamp is received',
      () async {
    inStreamCon.onListen = () async {
      currentTime = Duration(seconds: 5);
      inStreamCon.add(makeEventCIPre('t0-s3-e0-localshared'));
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().length, 1);
      expect(client.getCurrentState(), 0);
      inStreamCon.add(makeEventCIPre('t750-r750-s1-e0-server'));
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().length, 2);
      expect(client.getCurrentState(), 0);
      inStreamCon.add(makeEventCIPre('t1500-s3-e1-localshared'));
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().length, 3);
      expect(client.getCurrentState(), 0);
      inStreamCon.add(makeEventCIPre('t2250-r2250-s1-e2-server'));
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().length, 2);
      expect(client.getCurrentState(), 2);
      inStreamCon.add(makeEventCIPre('t3000-s3-e2-localshared'));
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().length, 3);
      expect(client.getCurrentState(), 2);
      inStreamCon.add(makeEventCIPre('t3750-r3750-s1-e4-server'));
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().length, 2);
      expect(client.getCurrentState(), 4);
      inStreamCon.close();
    };
    client.init();
    await inStreamCon.done;
  });

  test(
      'Local events are only added to stable state if they receive server confirmation',
      () async {
    inStreamCon.onListen = () async {
      currentTime = Duration(milliseconds: 0);
      inStreamCon.add(makeEventCIPre('d-local'));
      currentTime = Duration(milliseconds: 3000);
      inStreamCon.add(makeEventCIPre('t2000-r2000-s1-e0-server'));
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().length, 1);
      expect(client.getCurrentState(), 0);
      currentTime = Duration(milliseconds: 5000);
      inStreamCon.add(makeEventCIPre('d-local'));
      inStreamCon.add(makeEventCIPre('t5000-r5000-s3-e0-server'));
      inStreamCon.add(makeEventCIPre('t7000-r7000-s1-e2-server'));
      currentTime = Duration(milliseconds: 10000);
      await Future.delayed(Duration.zero);
      expect(client.getUnstableEvents().length, 1);
      expect(client.getCurrentState(), 2);
      inStreamCon.close();
    };
    client.init();
    await inStreamCon.done;
  });

  test('Only local events are sent to the server', () async {
    inStreamCon.onListen = () async {
      currentTime = Duration(seconds: 5);
      inStreamCon.add(makeEventCIPre('d0-local'));
      inStreamCon.add(makeEventCIPre('t0-r0-s0-e1-d1-server'));
      inStreamCon.add(makeEventCIPre('t0-s0-e2-d2-localshared'));
      await Future.delayed(Duration.zero);
      expect(eventsSentToServer.map((e) => e.data).toList(), ['0']);
      inStreamCon.close();
    };
    client.init();
    await inStreamCon.done;
  });

  test('getStateAt returns correct state in future at correct time', () async {
    inStreamCon.onListen = () async {
      currentTime = Duration(seconds: 10);
      int returnedState = -1;
      client
          .getStateAt(Duration(milliseconds: 150))
          .then((val) => returnedState = val);
      inStreamCon.add(makeEventCIPre('t0-r0-s0-e0-server'));
      inStreamCon.add(makeEventCIPre('t100-r100-s0-e1-server'));
      inStreamCon.add(makeEventCIPre('t200-r200-s0-e2-server'));
      inStreamCon.add(makeEventCIPre('t3000-r3000-s0-e3-server'));
      await Future.delayed(Duration.zero);
      expect(returnedState, 2);
      inStreamCon.close();
    };
    client.init();
    await inStreamCon.done;
  });

  // // TODO: await future N received events
  // test('multiple receivedEvents complete after correct number of events', () async {
  //   bool completedA = false;
  //   bool completedB = false;
  //   bool completedC = false;
  //   client.receivedEvents(n: 1).then((_) => completedA = true);
  //   client.receivedEvents(n: 4).then((_) => completedB = true);
  //   client.receivedEvents(n: 10).then((_) => completedC = true);
  //   expect(completedA, false);
  //   expect(completedB, false);
  //   expect(completedC, false);
  //   inStreamCon.add(makeEventCI('t0-s0-e0-local'));
  //   await Future.delayed(Duration.zero);
  //   expect(completedA, true);
  //   inStreamCon.add(makeEventCI('t0-s0-e1-local'));
  //   inStreamCon.add(makeEventCI('t0-s0-e2-local'));
  //   await Future.delayed(Duration.zero);
  //   expect(completedB, false);
  //   inStreamCon.add(makeEventCI('t0-s0-e3-local'));
  //   await Future.delayed(Duration.zero);
  //   expect(completedB, true);
  //   inStreamCon.add(makeEventCI('t0-s0-e4-local'));
  //   await Future.delayed(Duration.zero);
  //   expect(completedC, false);
  // });
}
