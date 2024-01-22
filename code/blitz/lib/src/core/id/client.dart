import 'dart:async';

import 'package:blitz/core.dart';
import 'package:blitz/src/core/extensions/event_responder.dart';

class ClientIDSyncClient {
  final int _clientID;
  final int Function() _generateUniqueEventID;
  late final void Function(Event) _sendEventToServer;
  final EventResponder _responder = EventResponder();

  Future<void> initialise() async {
    _sendEventToServer(
      Event(
        serverReceiptTimestamp: Duration.zero,
        generatedTimestamp: Duration.zero,
        // Remove
        senderID: 0,
        data: 'get client id',
        eventID: _generateUniqueEventID(),
        isServerConfirmed: false,
      ),
    );

    try {
      await _responder.waitUntil(
          (event) => event.data.startsWith('get client id;'),
          timeout: Duration(seconds: 5),
          mapper: (event) => int.parse(event.data.split(';')[1]));
    } on TimeoutException {
      rethrow;
    } on FormatException {
      rethrow;
    }
  }

  void Function(Event) insertIDSyncEvents(
      void Function(Event) sendEventToServer) {
    _sendEventToServer = sendEventToServer;
    return sendEventToServer;
  }

  Stream<Event> interceptTimeSyncEvents(Stream<Event> eventStream) {
    return _responder.interceptTimeSyncEvents(eventStream);
  }
}
