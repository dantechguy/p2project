import 'dart:async';
import '../events/client_in.dart';
import '../events/client_out.dart';
import '../extensions/event_interceptor.dart';

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

  late final void Function(EventClientOut) _sendEventToServer;

  final EventInterceptor<EventClientIn> _interceptor = EventInterceptor();

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
    // TODO: Restrict to only one sync at a time

    _sendEventToServer(EventClientOut(
      generatedTimestamp: ,
      data: 'time sync start time',
      eventID: _generateUniqueEventID(),
    ));

    // Throws TimeoutException or FormatException.
    _gameStartServerTime = await _interceptor.waitUntil(
      (event) => event.data.startsWith('time sync start time;'),
      timeout: _syncTimeout,
      mapper: (event) => DateTime.parse(event.data.split(';')[1]),
    );
  }

  Future<void> _syncOffsetBetweenLocalAndServerClock() async {
    // TODO: Restrict to only one sync at a time

    _sendEventToServer(EventClientOut(
      generatedTimestamp: ,
      data: 'time sync clock offset',
      eventID: _generateUniqueEventID(),
    ));

    final rttStopwatch = Stopwatch()..start();
    final DateTime startTime = DateTime.now().toUtc();

    // Throws TimeoutException or FormatException.
    final serverReceiptTime = await _interceptor.waitUntil(
          (event) => event.data.startsWith('time sync clock offset;'),
      timeout: _syncTimeout,
      mapper: (event) => DateTime.parse(event.data.split(';')[1]),
    );

    rttStopwatch.stop();
    final halfRTT = rttStopwatch.elapsed ~/ 2;
    final DateTime serverTimeWhenRequestSent = serverReceiptTime.subtract(halfRTT);
    _offsetLocalClockToServerClock = serverTimeWhenRequestSent.difference(startTime);
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
  void Function(EventClientOut) insertEvents(void Function(EventClientOut) addEvent) {
    _sendEventToServer = addEvent;
    return addEvent;
  }

  // Intercept and remove events from stream, before they reach the core
  Stream<EventClientIn> interceptEvents(Stream<EventClientIn> eventStream) {
    return _interceptor.interceptEvents(eventStream);
  }
}
