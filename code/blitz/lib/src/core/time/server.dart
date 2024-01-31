// How to implement this in the server? Do we also have a pair of streams and write a pair of functions to intercept and insert events? This makes it easier as you can separate this from the rest of the server.

import 'package:blitz/src/core/extensions/event_interceptor.dart';

import '../events/server_in.dart';
import '../events/server_out.dart';

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

  late final void Function(int clientID, EventServerOut event) _sendEventToClient;

  final EventInterceptor<EventServerIn> _interceptor = EventInterceptor();

  // Insert events into stream, to send to the server
  // Rename to something more understandable without knowing internals
  void Function(int, EventServerOut) insertEvents(
      void Function(int, EventServerOut) sendEventToClient) {
    _sendEventToClient = sendEventToClient;
    return sendEventToClient;
  }

  // Intercept and remove events from stream, before they reach the core
  Stream<EventServerIn> interceptEvents(Stream<EventServerIn> eventStream) {
    final interceptedEventStream = _interceptor.interceptEvents(eventStream);

    _interceptor.whenever(
      (event) => event.data == 'time sync start time',
      (event) {
        _sendEventToClient(
            event.senderID,
            EventServerOut(
              serverReceiptTimestamp: _getServerTime(),
              generatedTimestamp: _getServerTime(),
              senderID: _serverID,
              data:
                  'time sync start time;${_getServerStartTime().toIso8601String()}',
              eventID: _generateUniqueEventID(),
            ));
      },
    );

    _interceptor.whenever(
      (event) => event.data == 'time sync clock offset',
      (event) {
        _sendEventToClient(
            event.senderID,
            EventServerOut(
              serverReceiptTimestamp: _getServerTime(),
              generatedTimestamp: _getServerTime(),
              senderID: _serverID,
              data:
                  'time sync clock offset;${DateTime.now().toUtc().toIso8601String()}',
              eventID: _generateUniqueEventID(),
            ));
      },
    );

    return interceptedEventStream;
  }
}
