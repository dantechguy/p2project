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
 */


void main() {
  late ServerCore server;
  late StreamController<EventServerIn> streamCon;
  late List eventsToClients;
  late Duration serverTime;
  setUp(() {
    serverTime = Duration.zero;
    streamCon = StreamController();
    server = ServerCore(
      inEvents: streamCon.stream,
      getServerTime: () => serverTime,
      unstablePeriod: Duration(seconds: 1),
    );
    eventsToClients = [];
    server.eventsToClient.forEach(eventsToClients.add);
  });
  tearDown(() {
    streamCon.close();
  });

  test('Server removes events past unstable period', () {
    streamCon.onListen = () {
      serverTime = Duration(milliseconds: 2000);
      streamCon.add(makeEventSI('t500-s0-e0'));
      streamCon.add(makeEventSI('t999-s0-e1'));
      expect(eventsToClients.length, 0);
    };
  });

  test('Server relays events to all clients correctly', () {
    streamCon.onListen = () {
      serverTime = Duration(milliseconds: 1500);
      final evt1 = makeEventSI('t1300-s0-e0-d0');
      final evt1Exp = makeEventSO('t1300-r1500-s0-e0-d0');
      streamCon.add(evt1);
      serverTime = Duration(milliseconds: 2000);
      final evt2 = makeEventSI('t1800-s0-e1-d1');
      final evt2Exp = makeEventSO('t1800-r2000-s0-e1-d1');
      streamCon.add(evt2);
      expect(eventsToClients, [evt1Exp, evt2Exp]);
    };
  });
}
