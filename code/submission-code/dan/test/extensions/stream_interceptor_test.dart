/*
TODO:
  - [x] wait until triggers exactly once
  - [x] whenever triggers several times
  - [x] correct trigger order with multiple accepting tests
  - [x] waitUntil timeout triggers error
  - [x] waitUntil timeout cancels trigger
  - [x] waitUntil and whenever passThrough false prevents later added triggers
  - [x] waitUntil and whenever passThrough false prevents propagation out of stream
  - [x] waitUntil and whenever passThrough true allows later added triggers
  - [x] waitUntil and whenever passThrough true allows propagation out of stream
 */

import 'dart:async';

import 'package:blitz/client.dart';
import 'package:test/test.dart';

void main() {
  late StreamController<int> streamCon;
  late StreamInterceptor<int> interceptor;
  late List<int> receivedElements;
  setUp(() {
    streamCon = StreamController();
    interceptor = StreamInterceptor();
    receivedElements = [];
    interceptor.intercept(streamCon.stream).forEach(receivedElements.add);
  });
  tearDown(() {
    streamCon.close();
  });

  test('waitUntil triggers exactly once', () async {
    int triggers = 0;
    interceptor
        .waitUntil(
          (i) => i % 2 == 0,
          passThrough: true,
        )
        .then((_) => triggers++);
    await Future.delayed(Duration.zero);
    streamCon.add(0);
    streamCon.add(1);
    streamCon.add(2);
    streamCon.add(3);
    streamCon.add(4);
    streamCon.add(5);
    await Future.delayed(Duration.zero);
    expect(triggers, 1);
  });

  test('whenever triggers multiple times', () async {
    int triggers = 0;
    interceptor.whenever(
      (i) => i % 2 == 0,
      (_) => triggers++,
      passThrough: true,
    );
    await Future.delayed(Duration.zero);
    streamCon.add(0);
    streamCon.add(1);
    streamCon.add(2);
    streamCon.add(3);
    streamCon.add(4);
    streamCon.add(5);
    await Future.delayed(Duration.zero);
    expect(3, triggers);
  });

  test('Correct trigger order with multiple accepting tests', () async {
    final triggerResults = [];
    interceptor.whenever(
      (i) => true,
      (_) => triggerResults.add(0),
      passThrough: true,
    );
    interceptor
        .waitUntil(
          (i) => i % 2 == 0,
          passThrough: true,
        )
        .then((_) => triggerResults.add(1));
    await Future.delayed(Duration.zero);
    streamCon.add(1);
    streamCon.add(2);
    await Future.delayed(Duration.zero);
    expect([0, 0, 1], triggerResults);
  });

  test('waitUntil timeout throws error', () {
    expect(() async {
      await interceptor.waitUntil(
        (_) => false,
        passThrough: true,
        timeout: Duration.zero,
      );
    }, throwsA(TypeMatcher<TimeoutException>()));
  });

  test('waitUntil timeout cancels trigger', () async {
    bool triggered = false;
    try {
      await interceptor
          .waitUntil(
            (_) => true,
            passThrough: true,
            timeout: Duration.zero,
          )
          .then((_) => triggered = true);
    } on TimeoutException {}
    await Future.delayed(Duration.zero);
    streamCon.add(0);
    await Future.delayed(Duration.zero);
    expect(triggered, false);
  });

  test('waitUntil and whenever passThrough false prevents later added triggers',
      () async {
    int triggers = 0;
    interceptor
        .waitUntil(
          (i) => i == 0,
          passThrough: false,
        )
        .then((_) => triggers++);
    interceptor
        .waitUntil(
          (i) => i == 0,
          passThrough: false,
        )
        .then((_) => triggers++);
    interceptor.whenever(
      (i) => i == 1,
      (_) => triggers++,
      passThrough: false,
    );
    interceptor.whenever(
      (i) => i == 1,
      (_) => triggers++,
      passThrough: false,
    );

    await Future.delayed(Duration.zero);
    streamCon.add(0);
    await Future.delayed(Duration.zero);
    expect(triggers, 1);

    streamCon.add(1);
    await Future.delayed(Duration.zero);
    expect(triggers, 2);
  });

  test(
      'waitUntil and whenever passThrough false prevents propagation out of stream',
      () async {
    interceptor.waitUntil(
      (i) => i == 0,
      passThrough: false,
    );
    interceptor.whenever(
      (i) => i == 1,
      (_) => null,
      passThrough: false,
    );

    await Future.delayed(Duration.zero);
    streamCon.add(0);
    await Future.delayed(Duration.zero);
    expect(receivedElements, []);

    streamCon.add(1);
    await Future.delayed(Duration.zero);
    expect(receivedElements, []);
  });

  test('waitUntil and whenever passThrough true allows later added triggers',
      () async {
    int triggers = 0;
    interceptor
        .waitUntil(
          (i) => i == 0,
          passThrough: true,
        )
        .then((_) => triggers++);
    interceptor
        .waitUntil(
          (i) => i == 0,
          passThrough: true,
        )
        .then((_) => triggers++);
    interceptor.whenever(
      (i) => i == 1,
      (_) => triggers++,
      passThrough: true,
    );
    interceptor.whenever(
      (i) => i == 1,
      (_) => triggers++,
      passThrough: true,
    );

    await Future.delayed(Duration.zero);
    streamCon.add(0);
    await Future.delayed(Duration.zero);
    expect(triggers, 2);

    streamCon.add(1);
    await Future.delayed(Duration.zero);
    expect(triggers, 4);
  });

  test(
      'waitUntil and whenever passThrough true allows propagation out of stream',
      () async {
    interceptor.waitUntil(
      (i) => i == 0,
      passThrough: true,
    );
    interceptor.whenever(
      (i) => i == 1,
      (_) => null,
      passThrough: true,
    );

    await Future.delayed(Duration.zero);
    streamCon.add(0);
    await Future.delayed(Duration.zero);
    expect(receivedElements, [0]);

    streamCon.add(1);
    await Future.delayed(Duration.zero);
    expect(receivedElements, [0, 1]);
  });

}
