/*
TODO:
  - [x] syncStart sends 'time sync start time:'
  - [x] syncOffset sends 'time sync clock offset:'
  - [x] getTime is close when using same clock
  - [x] getTime is close when client clock ahead by 1s
  - [x] getTime is close when client clock is behind by 1s
  - [ ] getTime is close with 2s RTT but same clock
  - [x] throws format error if start time response malformed
  - [x] throws format error if clock offset response malformed
 */

import 'dart:async';

import 'package:blitz/client.dart';
import 'package:test/test.dart';

void main() {
  late TimeClient timeClient;
  late List<String> dataSentToServer;
  late List<String> dataSentToClient;
  late StreamController<String> dataToClientStreamCon;
  late StreamController<String> dataToServerStreamCon;
  late StreamInterceptor<String> dataToServerInterceptor;

  late DateTime startTime;
  late Duration serverClockOffset;
  DateTime currentServerTime() => DateTime.now().toUtc().add(serverClockOffset);
  Duration currentServerGameTime() => currentServerTime().difference(startTime);

  setUp(() async {
    timeClient = TimeClient(
      syncTimeout: Duration(seconds: 10),
    );
    dataSentToServer = [];
    dataSentToClient = [];
    dataToClientStreamCon = StreamController();
    dataToServerStreamCon = StreamController();
    dataToServerInterceptor = StreamInterceptor();

    dataToServerInterceptor
        .intercept(
          timeClient.toServer(
            dataToServerStreamCon.stream,
          ),
        )
        .forEach(dataSentToServer.add);

    timeClient
        .toClient(
          dataToClientStreamCon.stream,
        )
        .forEach(dataSentToClient.add);

    startTime = DateTime.now().subtract(Duration(seconds: 10));
    serverClockOffset = Duration.zero;
  });
  tearDown(() {
    dataToClientStreamCon.close();
    dataToServerStreamCon.close();
  });

  test('initialise sends "time sync start time" and "time sync clock offset"',
      () async {
    timeClient.init(silentTimeout: true);
    await Future.delayed(Duration.zero);
    expect(dataSentToServer.toSet(),
        {'time sync start time', 'time sync clock offset'});
  });

  test('getTime is close (within 50ms) when using same clock', () async {
    dataToServerInterceptor
        .waitUntil(
          (data) => data == 'time sync start time',
          passThrough: false,
        )
        .then((_) => dataToClientStreamCon
            .add('time sync start time:${startTime.toIso8601String()}'));
    dataToServerInterceptor
        .waitUntil(
          (data) => data == 'time sync clock offset',
          passThrough: false,
        )
        .then((_) => dataToClientStreamCon.add(
            'time sync clock offset:${currentServerTime().toIso8601String()}'));

    await timeClient.init();
    expect(
      (timeClient.getCurrentGameTime() - currentServerGameTime()).abs(),
      lessThan(Duration(milliseconds: 50)),
    );
  });

  test('getTime is close (within 50ms) when client clock is ahead by 1s',
      () async {
    serverClockOffset = Duration(seconds: -1);
    dataToServerInterceptor
        .waitUntil(
          (data) => data == 'time sync start time',
          passThrough: false,
        )
        .then((_) => dataToClientStreamCon
            .add('time sync start time:${startTime.toIso8601String()}'));
    dataToServerInterceptor
        .waitUntil(
          (data) => data == 'time sync clock offset',
          passThrough: false,
        )
        .then((_) => dataToClientStreamCon.add(
            'time sync clock offset:${currentServerTime().toIso8601String()}'));

    await timeClient.init();
    expect(
      (timeClient.getCurrentGameTime() - currentServerGameTime()).abs(),
      lessThan(Duration(milliseconds: 50)),
    );
  });

  test('getTime is close (within 50ms) when client clock is behind by 1s',
      () async {
    serverClockOffset = Duration(seconds: 1);
    dataToServerInterceptor
        .waitUntil(
          (data) => data == 'time sync start time',
          passThrough: false,
        )
        .then((_) => dataToClientStreamCon
            .add('time sync start time:${startTime.toIso8601String()}'));
    dataToServerInterceptor
        .waitUntil(
          (data) => data == 'time sync clock offset',
          passThrough: false,
        )
        .then((_) => dataToClientStreamCon.add(
            'time sync clock offset:${currentServerTime().toIso8601String()}'));

    await timeClient.init();
    expect(
      (timeClient.getCurrentGameTime() - currentServerGameTime()).abs(),
      lessThan(Duration(milliseconds: 50)),
    );
  });

  // TODO: getTime is close with 2s RTT but same clock

  test('test that async exceptions can be tested', () {
    expect(
        () async => await Future.delayed(Duration(milliseconds: 50))
            .then((_) => throw FormatException()),
        throwsFormatException);
  });

  test('Throws FormatException if start time response malformed', () async {
    dataToServerInterceptor
        .waitUntil(
          (data) => data == 'time sync start time',
          passThrough: false,
        )
        .then((_) => dataToClientStreamCon.add('time sync start time:'));

    expect(() async => await timeClient.init(), throwsFormatException);
  });

  test('Throws FormatException if clock offset response malformed', () {
    dataToServerInterceptor
        .waitUntil(
          (data) => data == 'time sync clock offset',
          passThrough: false,
        )
        .then((_) => dataToClientStreamCon.add('time sync clock offset:'));

    expect(() async => await timeClient.init(), throwsFormatException);
  });
}
