import 'dart:convert';

import 'package:blitz/server.dart';

Stream<String> serialiseEventToJsonStringForClient<Data>(
    Stream<EventServerOut<Data>> eventsToClient) {
  return eventsToClient.map(_eventToJsonString);
}

// Intercepts events received from the server. Converts them into Events for the Core.
Stream<EventServerIn<Data>> deserialiseJsonStringFromClientToEvent<Data>(
    Stream<(int clientID, String)> stringStream) async* {
  await for (final (id, msg) in stringStream) {
    try {
      yield _clientIDAndJsonStringToEvent(id, msg);
    } on FormatException {
      // If invalid do nothing, 'deleting' the event.
    }
  }
}

EventServerIn<Data> _clientIDAndJsonStringToEvent<Data>(int senderID, String jsonString) {
  final Map<String, dynamic> json;

  // Throws [FormatException] if invalid.
  json = jsonDecode(jsonString);

  json.containsAllKeysOrThrow([
    'generatedTimestamp',
    'eventID',
    'data',
  ]);

  // TODO: type safe way for json parsing? pass a function?
  return EventServerIn(
    generatedTimestamp:
        Duration(microseconds: int.parse(json['generatedTimestamp'])),
    data: json['data'],
    senderID: senderID,
    eventID: int.parse(json['eventID']),
  );
}

// TODO: type safe way to serialise json? pass a function?
String _eventToJsonString<Data>(EventServerOut<Data> event) {
  return jsonEncode({
    'generatedTimestamp': event.generatedTimestamp.inMicroseconds.toString(),
    'data': event.data.toString(),
    'senderID': event.senderID.toString(),
    'eventID': event.eventID.toString(),
  }).toString();
}
