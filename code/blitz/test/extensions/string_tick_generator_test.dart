@Timeout(Duration(hours: 1))
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
      triggerTick();
      triggerTick();
      triggerTick();
      await Future.delayed(Duration.zero);
      print(eventsSentToClient);
      expect(eventsSentToClient.map((e) => (e as EventClientInFromLocalButShared).generatedTimestamp).toList(),
          [tickPeriod, tickPeriod * 2, tickPeriod * 3]);
      expect(eventsSentToClient.map((e) => e.data).toList(),
          ['tick', 'tick', 'tick']);
      streamCon.close();
    };
    setUpPost();
    await streamCon.done;
  });

  test('Non-tick events pass through correctly', () async {
    streamCon.onListen = () async {
      triggerTick();
      streamCon.add(makeEventCI('t0-s0-e0-d100-local'));
      triggerTick();
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.length, 3);
      expect(eventsSentToClient[1].data, '100');
      streamCon.close();
    };
    setUpPost();
    await streamCon.done;
  });

  test(
      'A tick will be inserted if a *server* event arrives before it should have been inserted',
      () async {
    streamCon.onListen = () async {
      streamCon.add(makeEventCI('t75-s0-e0-d0-local'));
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.toShortString()).toList(),
          ['t75-s0-e0-d0-local']);
      streamCon.add(makeEventCI('t125-s0-e1-d1-localshared'));
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.toShortString()).toList(),
          ['t75-s0-e0-d0-local', 't125-s0-e1-d1-localshared']);
      streamCon.add(makeEventCI('t175-r175-s0-e2-d2-server'));
      await Future.delayed(Duration.zero);
      expect(eventsSentToClient.map((e) => e.toShortString()).toList(), [
        't75-s0-e0-d0-local',
        't125-s0-e1-d1-localshared',
        't50-s-1-e50000-dtick-localshared',
        't100-s-1-e100000-dtick-localshared',
        't150-s-1-e150000-dtick-localshared',
        't175-r175-s0-e2-d2-server',
      ]);
      streamCon.close();
    };
    setUpPost();
    await streamCon.done;
  });
}
