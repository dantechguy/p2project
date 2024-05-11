@Timeout(Duration(hours: 1))
/*
TODO
  - [-] ticks are generated regularly, close to tick period
    - not going to do, as this is just testing Timer by proxy
  - [x] ticks have exact correct generated timestamp and correct data
  - [x] a tick will be inserted if a server event arrives before it should have been generated
  - [ ] non-tick events pass through correctly
  UPDATE SINCE NOW BASED ON CURRENT_TIME RATHER THAN A CALLBACK
 */

import 'dart:async';

import 'package:blitz/client.dart';
import 'package:blitz/src/extensions/tick_generator/string_tick_generator.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  late StreamController<EventClientInPreCore<String>> streamCon;
  late List<EventClientInPreCore<String>> eventsSentToClient;
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

  void setUpPost() {
    addStringTicks(
      streamCon.stream,
      tickPeriod: tickPeriod,
      getCurrentTime: () => currentTime,
      streamPeriodicMock: streamPeriodicReplacement,
    ).forEach(eventsSentToClient.add);
  }

  setUp(() {
    eventsSentToClient = [];
    streamCon = StreamController();
    triggerTickStream = StreamController();
    currentTime = Duration.zero;
    tickStreamEventCount = 0;
  });
  tearDown(() {
    triggerTickStream.close();
  });

  test('Ticks have exact correct generated timestamp and correct data',
      () async {
    streamCon.onListen = () async {
      currentTime = Duration(milliseconds: 51);
      triggerTick();
      currentTime = Duration(milliseconds: 101);
      triggerTick();
      currentTime = Duration(milliseconds: 151);
      triggerTick();
      await Future.delayed(Duration.zero);
      expect(
          eventsSentToClient
              .map((e) =>
                  (e as EventClientInFromLocalButShared).generatedTimestamp)
              .toList(),
          [tickPeriod, tickPeriod * 2, tickPeriod * 3]);
      expect(eventsSentToClient.map((e) => e.data).toList(),
          ['tick', 'tick', 'tick']);
      streamCon.close();
    };
    setUpPost();
    await streamCon.done;
  });

  test('Tick inserted if timer callback drifts from game time', () async {
    streamCon.onListen = () async {
      currentTime = Duration.zero;
      triggerTick();
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.toShortString()).toList(), []);
      currentTime = Duration(milliseconds: 150);
      triggerTick();
      await Future.delayed(Duration.zero);
      expect(
        eventsSentToClient.map((e) => e.toShortString()).toList(),
        [
          't50-s-1-e50-dtick-localshared',
          't100-s-1-e100-dtick-localshared',
          't150-s-1-e150-dtick-localshared',
        ],
      );
      streamCon.close();
    };
    setUpPost();
    await streamCon.done;
  });

  test('Non-tick events pass through correctly', () async {
    streamCon.onListen = () async {
      currentTime = Duration(milliseconds: 50);
      triggerTick();
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.data).toList(), ['tick']);
      streamCon.add(makeEventCIPre('d100-local'));
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.data).toList(), ['tick', '100']);
      currentTime = Duration(milliseconds: 100);
      triggerTick();
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.data).toList(), ['tick', '100', 'tick']);
      streamCon.close();
    };
    setUpPost();
    await streamCon.done;
  });

  test(
      'A tick will be inserted if a *server* event arrives before it should have been inserted',
      () async {
    streamCon.onListen = () async {
      currentTime = Duration(milliseconds: 75);
      streamCon.add(makeEventCIPre('d0-local'));
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.toShortString()).toList(),
          ['d0-localpre']);
      streamCon.add(makeEventCIPre('t125-s0-e1-d1-localshared'));
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.toShortString()).toList(),
          ['d0-localpre', 't125-s0-e1-d1-localshared']);
      streamCon.add(makeEventCIPre('t175-r175-s0-e2-d2-server'));
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.toShortString()).toList(), [
        'd0-localpre',
        't125-s0-e1-d1-localshared',
        't50-s-1-e50-dtick-localshared',
        't100-s-1-e100-dtick-localshared',
        't150-s-1-e150-dtick-localshared',
        't175-r175-s0-e2-d2-server',
      ]);
      streamCon.close();
    };
    setUpPost();
    await streamCon.done;
  });
}
