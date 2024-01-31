import 'dart:convert';
import 'package:blitz/src/core/event_serialiser/client.dart';

import '../events/server_in.dart';
import '../events/server_out.dart';

void Function(EventServerOut) convertEventToJsonStringForClient(
    void Function(String) sendStringToClient) {
  return (EventServerOut event) {
    sendStringToClient(_eventToJsonString(event));
  };
}

// Intercepts events received from the server. Converts them into Events for the Core.
Stream<EventServerIn> convertJsonStringFromClientToEvent(
    Stream<(int clientID, String)> stringStream) async* {
  await for (final (id, msg) in stringStream) {
    try {
      yield _clientIDAndJsonStringToEvent(id, msg);
    } on FormatException {
      // If invalid do nothing, 'deleting' the event.
    }
  }
}

EventServerIn _clientIDAndJsonStringToEvent(int senderID, String jsonString) {
  final Map<String, dynamic> json;

  // Throws [FormatException] if invalid.
  json = jsonDecode(jsonString);

  json.containsAllKeysOrThrow([
    'generatedTimestamp',
    'eventID',
    'data',
  ]);

  return EventServerIn(
    generatedTimestamp:
        Duration(microseconds: int.parse(json['generatedTimestamp'])),
    data: json['data'].toString(),
    senderID: senderID,
    eventID: int.parse(json['eventID']),
  );
}

String _eventToJsonString(EventServerOut event) {
  return jsonEncode({
    'generatedTimestamp': event.generatedTimestamp.inMicroseconds.toString(),
    'data': event.data.toString(),
    'senderID': event.senderID.toString(),
    'eventID': event.eventID.toString(),
  }).toString();
}
