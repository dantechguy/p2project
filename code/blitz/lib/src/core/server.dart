import 'dart:async';

import 'package:blitz/server.dart';

// Consider renaming to something more descriptive
class ServerCore<Data> {
  ServerCore({
    required Stream<EventServerIn<Data>> inEvents,
    required Duration Function() getServerTime,
    required Duration unstablePeriod,
  })  : _getServerTime = getServerTime,
        _unstablePeriod = unstablePeriod
        {
    inEvents.forEach(_onEvent);
  }

  final StreamController<EventServerOut<Data>> _eventsToClientsStreamController = StreamController();
  final Duration Function() _getServerTime;
  final Duration _unstablePeriod;

  Stream<EventServerOut<Data>> get eventsToClient => _eventsToClientsStreamController.stream;

  void _onEvent(EventServerIn<Data> event) {
    // Remove events beyond the unstable period.
    final serverReceiptTime = _getServerTime();
    if (serverReceiptTime - event.generatedTimestamp > _unstablePeriod) return;

    _eventsToClientsStreamController.add(
      EventServerOut(
        serverReceiptTimestamp: serverReceiptTime,
        generatedTimestamp: event.generatedTimestamp,
        data: event.data,
        senderID: event.senderID,
        eventID: event.eventID,
      ),
    );
  }
}
