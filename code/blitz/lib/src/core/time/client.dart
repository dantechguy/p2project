import 'dart:async';
import 'dart:io';

import 'package:blitz/src/core/events/event.dart';

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
    required int clientID,
    required int Function() generateUniqueEventID,
    required Duration syncTimeout,
  })  : _syncTimeout = syncTimeout,
        _clientID = clientID,
        _generateUniqueEventID = generateUniqueEventID;

  /// At any given time, Client_time = Server_time + offset
  /// More positive -> client more ahead
  /// More negative -> client more behind
  late Duration _offsetLocalClockToServerClock;
  late DateTime _gameStartServerTime;

  final int _clientID;
  final int Function() _generateUniqueEventID;

  final Duration _syncTimeout;

  final Stopwatch _syncOffsetRTTStopwatch = Stopwatch();
  late DateTime _syncOffsetStartTime;
  late Completer<String> _syncOffsetResponseCompleter;
  Completer<void> _syncOffsetCompleter = Completer()..complete();

  late Completer<String> _syncGameStartTimeResponseCompleter;
  Completer<void> _syncGameStartTimeCompleter = Completer()..complete();

  late final void Function(Event) _sendEventToServer;

  Future<void> initialise() async {
    // Performs a first time sync.
    // TODO: Implement
    // Server sends game start time, and set [_gameStartServerTime].
    // Calculate [_offsetLocalClockToServerClock] from RTT sync.

    // Is it just as simple as this?
    // A difference between first time sync and following syncs is that following syncs are doing during gameplay and we must ensure that the time remains monotonic. Smoothing / interpolation may be used.
    // TODO: Make this throw just one exception is sync fails.
    try {
      await Future.wait([
        _syncGameStartTime(),
        _syncOffsetBetweenLocalAndServerClock(),
      ]);
    } on TimeoutException {
      rethrow;
    } on FormatException {
      rethrow;
    }
  }

  Future<void> _syncGameStartTime() async {
    // Only one time sync can happen at a time.
    if (!_syncGameStartTimeCompleter.isCompleted) {
      return _syncGameStartTimeCompleter.future;
    }
    _syncGameStartTimeCompleter = Completer();

    // Send event and wait for response
    _sendEventToServer(Event(
      serverReceiptTimestamp: Duration.zero,
      generatedTimestamp: Duration.zero,
      senderID: _clientID,
      data: 'time sync start time',
      eventID: _generateUniqueEventID(),
      isServerConfirmed: false,
    ));
    _syncGameStartTimeResponseCompleter = Completer();

    // Update value on response. Set a timeout.
    try {
      final timeString = await _syncGameStartTimeResponseCompleter.future
          .timeout(_syncTimeout);
      _gameStartServerTime = DateTime.parse(timeString);
    } on TimeoutException {
      _syncGameStartTimeCompleter.complete();
      rethrow;
    } on FormatException {
      _syncGameStartTimeCompleter.complete();
      rethrow;
    }

    // Another sync can now start.
    _syncGameStartTimeCompleter.complete();
  }

  Future<void> _syncOffsetBetweenLocalAndServerClock() async {
    // Only one time sync can happen at a time.
    if (!_syncOffsetCompleter.isCompleted) {
      return _syncOffsetCompleter.future;
    }
    _syncOffsetCompleter = Completer();

    // Send event and start timer.
    _sendEventToServer(Event(
      serverReceiptTimestamp: Duration.zero,
      generatedTimestamp: Duration.zero,
      senderID: _clientID,
      data: 'time sync clock offset',
      eventID: _generateUniqueEventID(),
      isServerConfirmed: false,
    ));
    _syncOffsetRTTStopwatch.reset();
    _syncOffsetRTTStopwatch.start();
    _syncOffsetResponseCompleter = Completer();
    _syncOffsetStartTime = DateTime.now().toUtc();

    // Await on future and assign to property. Set a timeout.
    final DateTime serverReceipt;
    try {
      final timeString = await _syncOffsetResponseCompleter.future.timeout(_syncTimeout);
      serverReceipt = DateTime.parse(timeString);
    } on TimeoutException {
      _syncOffsetCompleter.complete();
      rethrow;
    } on FormatException {
      _syncOffsetCompleter.complete();
      rethrow;
    }

    _syncOffsetRTTStopwatch.stop();

    // Calculate offset.
    final Duration halfRTT = _syncOffsetRTTStopwatch.elapsed ~/ 2;
    final DateTime serverTimeOnSend = serverReceipt.subtract(halfRTT);
    // TODO: Correct sign?
    _offsetLocalClockToServerClock =
        serverTimeOnSend.difference(_syncOffsetStartTime);

    // Another sync can now start.
    _syncOffsetCompleter.complete();
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
  void Function(Event) insertTimeSyncEvents(void Function(Event) addEvent) {
    _sendEventToServer = addEvent;
    return addEvent;
  }

  // Intercept and remove events from stream, before they reach the core
  Stream<Event> interceptTimeSyncEvents(Stream<Event> eventStream) async* {
    await for (final Event event in eventStream) {
      if (event.data.startsWith('time sync start time;')) {
        _syncGameStartTimeResponseCompleter.complete(event.data.split(';')[1]);
      } else if (event.data.startsWith('time sync clock offset;')) {
        _syncOffsetResponseCompleter.complete(event.data.split(';')[1]);
      } else {
        yield event;
      }
    }
  }
}
