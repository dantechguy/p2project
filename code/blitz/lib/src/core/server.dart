import 'dart:async';

import 'package:blitz/server.dart';

// Consider renaming to something more descriptive
class ServerCore<Data> {
  ServerCore({
    required int serverID,
    required Stream<EventServerIn<Data>> inEvents,
    required Duration Function() getGameTime,
    required int Function() generateUniqueEventID,
    required Duration unstablePeriod,
  })  : _serverID = serverID,
        _inEvents = inEvents,
        _getGameTime = getGameTime,
        _generateUniqueEventID = generateUniqueEventID,
        _unstablePeriod = unstablePeriod;

  final int _serverID;

  final Stream<EventServerIn<Data>> _inEvents;

  final StreamController<EventServerOut<Data>>
      _eventsToClientsStreamController = StreamController();
  final Duration Function() _getGameTime;
  final Duration _unstablePeriod;
  final int Function() _generateUniqueEventID;

  Stream<EventServerOut<Data>> get eventsToClient =>
      _eventsToClientsStreamController.stream;

  void init() {
    _inEvents.forEach(_onEvent);
  }

  void _onEvent(EventServerIn<Data> event) {
    final serverReceiptTime = _getGameTime();

    if (event is EventServerInFromClient<Data>) {

      // Remove events beyond the unstable period.
      // TODO: send NACK instead
      if (serverReceiptTime - event.generatedTimestamp > _unstablePeriod) {
        return;
      }

      _eventsToClientsStreamController.add(
        EventServerOut(
          serverReceiptTimestamp: serverReceiptTime,
          generatedTimestamp: event.generatedTimestamp,
          data: event.data,
          senderID: event.senderID,
          eventID: event.eventID,
        ),
      );
    } else if (event is EventServerInFromServer<Data>) {
      _eventsToClientsStreamController.add(
        EventServerOut(
          serverReceiptTimestamp: serverReceiptTime,
          generatedTimestamp: serverReceiptTime,
          data: event.data,
          senderID: _serverID,
          eventID: _generateUniqueEventID(),
        ),
      );
    }
  }
}
