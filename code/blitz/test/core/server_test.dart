import 'dart:async';

import 'package:blitz/server.dart';
import 'package:test/test.dart';

import '../helpers.dart';

/*
TODO
  - server checks
    - [x] removes events past unstable period
  - relaying
    - [x] copies over information
    - [x] puts in correct current server time
    - [x] sends to all clients
  - sending events
    - [ ] server-generated events are send to all clients correctly
 */

void main() {
  late ServerCore<String> server;
  late StreamController<EventServerIn<String>> streamCon;
  late List<EventServerOut<String>> eventsToClients;
  late Duration serverTime;
  late int uniqueID;
  setUp(() {
    uniqueID = 0;
    streamCon = StreamController();
    serverTime = Duration.zero;
    server = ServerCore(
      inEvents: streamCon.stream,
      getGameTime: () => serverTime,
      unstablePeriod: Duration(seconds: 1),
      serverID: 0,
      generateUniqueEventID: () => uniqueID++,
    );
    eventsToClients = [];
    server.eventsToClient.forEach(eventsToClients.add);
  });

  test('Server removes client events past unstable period', () async {
    streamCon.onListen = () async {
      serverTime = Duration(milliseconds: 2000);
      streamCon.add(makeEventSI('t500-s0-e0-client'));
      streamCon.add(makeEventSI('t999-s0-e1-client'));
      streamCon.add(makeEventSI('t1500-s0-e1-client'));
      await Future.delayed(Duration.zero);
      expect(eventsToClients.length, 1);
      streamCon.close();
    };
    server.init();
    await streamCon.done;
  });

  test('Server relays client events to all clients correctly', () async {
    streamCon.onListen = () async {
      serverTime = Duration(milliseconds: 1500);
      final evt1 = makeEventSI('t1300-s0-e0-d0-client');
      final evt1Exp = makeEventSO('t1300-r1500-s0-e0-d0');
      streamCon.add(evt1);
      await Future.delayed(Duration.zero);
      serverTime = Duration(milliseconds: 2000);
      final evt2 = makeEventSI('t1800-s0-e1-d1-client');
      final evt2Exp = makeEventSO('t1800-r2000-s0-e1-d1');
      streamCon.add(evt2);
      await Future.delayed(Duration.zero);
      expect(eventsToClients, [evt1Exp, evt2Exp]);
      streamCon.close();
    };
    server.init();
    await streamCon.done;
  });

  test('Server relays server events to all clients correctly', () async {
    streamCon.onListen = () async {
      serverTime = Duration(milliseconds: 100);
      streamCon.add(makeEventSI('d1-server'));
      await Future.delayed(Duration.zero);
      serverTime = Duration(milliseconds: 200);
      streamCon.add(makeEventSI('d2-server'));
      await Future.delayed(Duration.zero);
      expect(eventsToClients, [
        makeEventSO('t100-r100-s0-e0-d1'),
        makeEventSO('t200-r200-s0-e1-d2'),
      ]);
      streamCon.close();
    };
    server.init();
    await streamCon.done;
  });
}
