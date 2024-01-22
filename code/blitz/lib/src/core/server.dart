import 'dart:io';
import 'package:blitz/core.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Consider renaming to something more descriptive
class Server {
  Server({
    required Stream<Event> eventStream,
    required void Function(int clientID, Event event) sendEventToClient,
    required void Function(Event event) sendEventToAllClients,
    required Duration Function() getServerTime,
    required Duration unstablePeriod,
  })  : _sendEventToClient = sendEventToClient,
        _getServerTime = getServerTime,
        _unstablePeriod = unstablePeriod,
    _sendEventToAllClients = sendEventToAllClients {
    eventStream.forEach(_onEvent);
  }

  final void Function(int clientID, Event event) _sendEventToClient;
  final void Function(Event event) _sendEventToAllClients;
  final Duration Function() _getServerTime;
  final Duration _unstablePeriod;

  void _onEvent(Event event) {
    // Remove events beyond the unstable period.
    if (_getServerTime() - event.generatedTimestamp > _unstablePeriod) return;

    final newEvent = event.copyWith(
      serverReceiptTimestamp: _getServerTime(),
      isLocal: false, // TODO: Not sure if needed.
    );

    _sendEventToAllClients(newEvent);
  }
}
