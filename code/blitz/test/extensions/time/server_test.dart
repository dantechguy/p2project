/*
TODO:
  - returns correct start time string several times
  - returns correct current server clock several times
 */

import 'dart:async';

import 'package:blitz/server.dart';
import 'package:test/test.dart';

void main() {
  late TimeServer timeServer;
  late StreamController<(int, String)> dataToServerStreamCon;
  late StreamController<(int, String)> dataToClientStreamCon;
  late StreamInterceptor<(int, String)> dataToClientInterceptor;
  late List<(int, String)> dataSentToClient;
  late List<(int, String)> dataSentToServer;

  late DateTime currentServerClockTime;
  late DateTime serverStartTime;

  setUp(() {
    dataToServerStreamCon = StreamController();
    dataToClientStreamCon = StreamController();
    dataToClientInterceptor = StreamInterceptor();
    dataSentToClient = [];
    dataSentToServer = [];

    currentServerClockTime = DateTime.now().toUtc();
    serverStartTime = DateTime.now().toUtc().subtract(Duration(seconds: 60));

    timeServer = TimeServer(
      getServerClockTime: () => currentServerClockTime,
      getServerStartTime: () => serverStartTime,
    );

    timeServer
        .toServer(
          dataToServerStreamCon.stream,
        )
        .forEach(dataSentToServer.add);

    dataToClientInterceptor
        .intercept(
          timeServer.toClient(
            dataToClientStreamCon.stream,
          ),
        )
        .forEach(dataSentToClient.add);
  });

  tearDown(() {
    dataToServerStreamCon.close();
  });

  test('Returns correct start time string serveral times', () async {
    dataToServerStreamCon.add((0, 'time sync start time'));
    await Future.delayed(Duration.zero);
    expect(
      dataSentToClient,
      [(0, 'time sync start time:${serverStartTime.toIso8601String()}')],
    );

    dataToServerStreamCon.add((0, 'time sync start time'));
    await Future.delayed(Duration.zero);
    expect(
      dataSentToClient,
      [(0, 'time sync start time:${serverStartTime.toIso8601String()}')] * 2,
    );
  });

  test('Returns correct current server clock several times', () async {
    dataToServerStreamCon.add((0, 'time sync clock offset'));
    await Future.delayed(Duration.zero);
    expect(dataSentToClient, [
      (0, 'time sync clock offset:${currentServerClockTime.toIso8601String()}')
    ]);

    dataToServerStreamCon.add((0, 'time sync clock offset'));
    await Future.delayed(Duration.zero);
    expect(
        dataSentToClient,
        [
              (
                0,
                'time sync clock offset:${currentServerClockTime.toIso8601String()}'
              )
            ] *
            2);
  });
}
