import 'dart:io';
import 'package:blitz/src/core/events/server_in.dart';
import 'package:blitz/src/core/events/server_out.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Consider renaming to something more descriptive
class Server {
  Server({
    required Stream<EventServerIn> eventStream,
    required void Function(EventServerOut event) sendEventToAllClients,
    required Duration Function() getServerTime,
    required Duration unstablePeriod,
  })  : _getServerTime = getServerTime,
        _unstablePeriod = unstablePeriod,
        _sendEventToAllClients = sendEventToAllClients {
    eventStream.forEach(_onEvent);
  }

  final void Function(EventServerOut event) _sendEventToAllClients;
  final Duration Function() _getServerTime;
  final Duration _unstablePeriod;

  void _onEvent(EventServerIn event) {
    // Remove events beyond the unstable period.
    if (_getServerTime() - event.generatedTimestamp > _unstablePeriod) return;

    _sendEventToAllClients(
      EventServerOut(
        serverReceiptTimestamp: _getServerTime(),
        generatedTimestamp: event.generatedTimestamp,
        data: event.data,
        senderID: event.senderID,
        eventID: event.eventID,
      ),
    );
  }
}
