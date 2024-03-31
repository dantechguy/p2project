import 'dart:async';

import 'package:blitz/client.dart';
import 'package:blitz/src/extensions/stream_inserter.dart';

/// A module which exposes the current game-time to the Core (and rest of system).
///
/// It must be asynchronously initialised. This does an initial sync with the server.
///
/// Parameters / inputs are:
/// - ? The Core (used to access room reference). Not needed before Room-Extension
///
/// It exposes as output:
/// - Its best estimate of the current game-time.
class TimeClient {
  TimeClient({
    required Duration syncTimeout,
  }) : _syncTimeout = syncTimeout;

  /// At any given time, Client_time = Server_time + offset
  /// More positive -> client more ahead
  /// More negative -> client more behind
  late Duration _localToServerClockOffset;
  late DateTime _gameStartServerTime;

  final Duration _syncTimeout;

  final StreamInserter<String> _toServerInserter = StreamInserter();

  final StreamInterceptor<String> _toClientInterceptor = StreamInterceptor();

  Future<void> initialise({bool silentTimeout = false}) async {
    // TODO: Make this throw just one exception if sync fails.
    try {
      await Future.wait(
        [
          _syncGameStartTime(),
          _syncOffsetBetweenLocalAndServerClock(),
        ],
        eagerError: true,
      );
    } on FormatException {
      if (!silentTimeout) rethrow;
    } on TimeoutException {
      if (!silentTimeout) rethrow;
    }
  }

  Future<void> _syncGameStartTime() async {
    // TODO: Restrict to only one sync at a time
    // TODO: If called multiple times, have change be updated smoothly so clock remains monotonic and doesn't affect gameplay.

    _toServerInserter.add('time sync start time');

    // Throws TimeoutException
    final responseData = await _toClientInterceptor.waitUntil(
      (data) => data.startsWith('time sync start time:'),
      timeout: _syncTimeout,
      passThrough: false,
    );
    // Throws FormatException
    _gameStartServerTime = DateTime.parse(responseData.splitFirst(':')[1]);
  }

  // TODO: Change from event to pure string
  Future<void> _syncOffsetBetweenLocalAndServerClock() async {
    // TODO: Restrict to only one sync at a time
    // TODO: If called multiple times, have change be updated smoothly so clock remains monotonic and doesn't affect gameplay.

    _toServerInserter.add('time sync clock offset');

    final rttStopwatch = Stopwatch()..start();
    final DateTime startTime = DateTime.now().toUtc();

    // Throws TimeoutException
    final responseData = await _toClientInterceptor.waitUntil(
      (data) => data.startsWith('time sync clock offset:'),
      timeout: _syncTimeout,
      passThrough: false,
    );
    // Throws FormatException
    final serverReceiptTime = DateTime.parse(responseData.splitFirst(':')[1]);

    rttStopwatch.stop();
    final halfRTT = rttStopwatch.elapsed ~/ 2;
    final DateTime serverTimeWhenRequestSent =
        serverReceiptTime.subtract(halfRTT);
    // TODO: Check offset is correct sign.
    _localToServerClockOffset = startTime.difference(serverTimeWhenRequestSent);
  }

  Duration getCurrentGameTime() {
    // TODO: AIGen: check offset is correct sign.
    final localCurrentTime = DateTime.now().toUtc();
    final localGameStartTime =
        _gameStartServerTime.add(_localToServerClockOffset);
    return localCurrentTime.difference(localGameStartTime);
  }

  // Insert events into stream, to send to the server
  // Rename to something more understandable without knowing internals
  Stream<String> toServer(Stream<String> stream) {
    return _toServerInserter.insert(stream);
  }

  // Intercept and remove events from stream, before they reach the core
  Stream<String> toClient(Stream<String> stream) {
    return _toClientInterceptor.intercept(stream);
  }
}
