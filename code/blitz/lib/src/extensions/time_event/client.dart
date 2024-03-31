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
class EventBasedTimeClient {
  EventBasedTimeClient({
    required Duration syncTimeout,
  }) : _syncTimeout = syncTimeout;

  /// At any given time, Client_time = Server_time + offset
  /// More positive -> client more ahead
  /// More negative -> client more behind
  late Duration _offsetLocalClockToServerClock;
  late DateTime _gameStartServerTime;

  final Duration _syncTimeout;

  final StreamInserter<EventClientOut> _toServerInserter = StreamInserter();

  final StreamInterceptor<EventClientIn> _toClientInterceptor =
      StreamInterceptor();

  Future<void> initialise({bool silentTimeout = false}) async {
    // TODO: Make this throw just one exception is sync fails.
    try {
      await Future.wait([
        _syncGameStartTime(),
        _syncOffsetBetweenLocalAndServerClock(),
      ]);
    } on TimeoutException {
      if (!silentTimeout) rethrow;
    } on FormatException {
      if (!silentTimeout) rethrow;
    }
  }

  Future<void> _syncGameStartTime() async {
    // TODO: Restrict to only one sync at a time
    // TODO: If called multiple times, have change be updated smoothly so clock remains monotonic and doesn't affect gameplay.

    _toServerInserter.add(
      EventClientOut(
        // Filler value
        generatedTimestamp: Duration.zero,
        data: 'time sync start time',
        // Filler value
        eventID: -1,
      ),
    );

    // Throws TimeoutException or FormatException.
    _gameStartServerTime = await _toClientInterceptor.waitUntil(
      (event) =>
          event.data.startsWith('time sync start time:') && event.senderID == 0,
      timeout: _syncTimeout,
      passThrough: false,
      successMap: (event) => DateTime.parse(event.data.splitFirst(':')[1]),
    );
  }

  // TODO: Change from event to pure string
  Future<void> _syncOffsetBetweenLocalAndServerClock() async {
    // TODO: Restrict to only one sync at a time
    // TODO: If called multiple times, have change be updated smoothly so clock remains monotonic and doesn't affect gameplay.

    _toServerInserter.add(EventClientOut(
      // Filler value
      generatedTimestamp: Duration.zero,
      data: 'time sync clock offset',
      // Filler value
      eventID: -1,
    ));

    final rttStopwatch = Stopwatch()..start();
    final DateTime startTime = DateTime.now().toUtc();

    // Throws TimeoutException or FormatException.
    final serverReceiptTime = await _toClientInterceptor.waitUntil(
      (event) =>
          event.data.startsWith('time sync clock offset:') &&
          event.senderID == 0,
      timeout: _syncTimeout,
      passThrough: false,
      successMap: (event) => DateTime.parse(event.data.split(':')[1]),
    );

    rttStopwatch.stop();
    final halfRTT = rttStopwatch.elapsed ~/ 2;
    final DateTime serverTimeWhenRequestSent =
        serverReceiptTime.subtract(halfRTT);
    // TODO: Check offset is correct sign.
    _offsetLocalClockToServerClock =
        serverTimeWhenRequestSent.difference(startTime);
  }

  Duration getCurrentGameTime() {
    // TODO: AIGen: check offset is correct sign.
    final localCurrentTime = DateTime.now().toUtc();
    final localGameStartTime =
        _gameStartServerTime.add(_offsetLocalClockToServerClock);
    return localCurrentTime.difference(localGameStartTime);
  }

  // Insert events into stream, to send to the server
  // Rename to something more understandable without knowing internals
  Stream<EventClientOut> toServer(Stream<EventClientOut> stream) {
    return _toServerInserter.insert(stream);
  }

  // Intercept and remove events from stream, before they reach the core
  Stream<EventClientIn> toClient(Stream<EventClientIn> stream) {
    return _toClientInterceptor.intercept(stream);
  }
}
