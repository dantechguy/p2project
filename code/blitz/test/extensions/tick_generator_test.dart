/*
TODO
  - [-] ticks are generated regularly, close to tick period
    - not going to do, as this is just testing Timer by proxy
  - [x] ticks have exact correct generated timestamp and correct data
  - [x] a tick will be inserted if a server event arrives before it should have been generated
  - [ ] non-tick events pass through correctly
 */

import 'dart:async';

import 'package:blitz/client.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  late StreamController<EventClientIn> streamCon;
  late List<EventClientIn> eventsSentToClient;
  late StreamController<int> triggerTickStream;
  late int tickStreamEventCount;
  late Duration currentTime;
  final tickPeriod = Duration(milliseconds: 50);
  Stream<T> streamPeriodicReplacement<T>(Duration period,
      [T Function(int)? comp]) {
    return triggerTickStream.stream.map((i) => comp?.call(i) ?? null as T);
  }

  void triggerTick() {
    triggerTickStream.add(tickStreamEventCount++);
  }

  setUp(() {
    eventsSentToClient = [];
    streamCon = StreamController();
    triggerTickStream = StreamController();
    addTicks(
      streamCon.stream,
      tickPeriod: tickPeriod,
      streamPeriodicMock: streamPeriodicReplacement,
    ).forEach(eventsSentToClient.add);
    currentTime = Duration.zero;
    tickStreamEventCount = 0;
  });
  tearDown(() {
    streamCon.close();
    triggerTickStream.close();
  });

  test('Ticks have exact correct generated timestamp and correct data', () {
    streamCon.onListen = () {
      triggerTick();
      triggerTick();
      triggerTick();
      expect(eventsSentToClient.map((e) => e.generatedTimestamp).toList(),
          [tickPeriod, tickPeriod * 2, tickPeriod * 3]);
      expect(eventsSentToClient.map((e) => e.data).toList(),
          [(isTick: true, data: null)] * 3);
    };
  });

  test('Non-tick events pass through correctly', () {
    streamCon.onListen = () {
      triggerTick();
      streamCon.add(makeEventCI('t0-s0-e0-d100-local'));
      triggerTick();
      expect(eventsSentToClient.length, 3);
      expect(eventsSentToClient[1].data, (isTick: false, data: '100'));
    };
  });

  test(
      'A tick will be inserted if a server event arrives before it should have been inserted',
      () {
    streamCon.onListen = () {
      streamCon.add(makeEventCI('t750-s0-e0-d1-local'));
      expect(
          eventsSentToClient.map((e) => e.data.$1 ? 'tick' : e.data.$2), ['1']);
      streamCon.add(makeEventCI('t125-s0-e1-d2-localshared'));
      expect(eventsSentToClient.map((e) => e.data.$1 ? 'tick' : e.data.$2),
          ['1', '2']);
      streamCon.add(makeEventCI('t175-r175-s0-e2-d3-server'));
      expect(eventsSentToClient.map((e) => e.data.$1 ? 'tick' : e.data.$2),
          ['tick', '1', 'tick', '2', 'tick', '3']);
    };
  });
}
