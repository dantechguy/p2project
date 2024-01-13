

import 'package:blitzmania/core/event.dart';

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

  /// At any given time, Client_time = Server_time + offset
  /// More positive -> client more ahead
  /// More negative -> client more behind
  late Duration _offsetLocalClockToServerClock;
  late DateTime _gameStartServerTime;

  late final void Function(Event) _sendEventToServer;

  Future<void> initialise() async {
    // Performs a first time sync.
    // TODO: Implement
    // Server sends game start time, and set [_gameStartServerTime].
    // Calculate [_offsetLocalClockToServerClock] from RTT sync.

    // Is it just as simple as this?
    // A difference between first time sync and following syncs is that following syncs are doing during gameplay and we must ensure that the time remains monotonic. Smoothing / interpolation may be used.
    await _syncOffsetBetweenLocalAndServerClock();
  }

  Future<void> _syncOffsetBetweenLocalAndServerClock() async {

  }

  Duration getCurrentGameTime() {
    // TODO: AIGen: check offset is correct sign.
    final localCurrentTime = DateTime.now().toUtc();
    final localGameStartTime = _gameStartServerTime.add(_offsetLocalClockToServerClock);
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
      // TODO: What type is event type?
      if (event.type == 'time sync') {
        // TODO: How to signal when received time sync event? (likely a response)
      } else {
        yield event;
      }
    }
  }
}