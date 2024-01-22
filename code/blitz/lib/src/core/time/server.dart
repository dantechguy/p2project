// How to implement this in the server? Do we also have a pair of streams and write a pair of functions to intercept and insert events? This makes it easier as you can separate this from the rest of the server.

import 'package:blitz/core.dart';

class EventBasedTimeServer {
  EventBasedTimeServer({
    required int serverID,
    required int Function() generateUniqueEventID,
    required Duration Function() getServerTime,
    required DateTime Function() getServerStartTime,
  })  : _serverID = serverID,
        _generateUniqueEventID = generateUniqueEventID,
        _getServerTime = getServerTime,
        _getServerStartTime = getServerStartTime;

  final int _serverID;
  final int Function() _generateUniqueEventID;
  final Duration Function() _getServerTime;
  final DateTime Function() _getServerStartTime;

  late final void Function(int clientID, Event event) _sendEventToClient;

  // Insert events into stream, to send to the server
  // Rename to something more understandable without knowing internals
  void Function(int, Event) insertTimeSyncEvents(
      void Function(int, Event) sendEventToClient) {
    _sendEventToClient = sendEventToClient;
    return sendEventToClient;
  }

  // Intercept and remove events from stream, before they reach the core
  Stream<Event> interceptTimeSyncEvents(Stream<Event> eventStream) async* {
    await for (final Event event in eventStream) {
      if (event.data == 'time sync start time') {
        _sendEventToClient(
            event.senderID,
            Event(
              serverReceiptTimestamp: _getServerTime(),
              generatedTimestamp: _getServerTime(),
              senderID: _serverID,
              data:
                  'time sync start time;${_getServerStartTime().toIso8601String()}',
              eventID: _generateUniqueEventID(),
              isServerConfirmed: false,
            ));
      } else if (event.data == 'time sync clock offset') {
        _sendEventToClient(
            event.senderID,
            Event(
              serverReceiptTimestamp: _getServerTime(),
              generatedTimestamp: _getServerTime(),
              senderID: _serverID,
              data:
                  'time sync clock offset;${DateTime.now().toUtc().toIso8601String()}',
              eventID: _generateUniqueEventID(),
              isServerConfirmed: false,
            ));
      } else {
        yield event;
      }
    }
  }
}
