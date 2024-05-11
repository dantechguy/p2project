import 'dart:convert';

import 'package:blitz/server.dart';
import 'package:blitz/src/dart_extensions.dart';

Stream<String> serialiseEventToJsonStringForClient<Data>(
    Stream<EventServerOut<Data>> eventsToClient) {
  return eventsToClient.map(_eventToJsonString);
}

// Intercepts events received from the server. Converts them into Events for the Core.
Stream<EventServerInFromClient<Data>> deserialiseJsonStringFromClientToEvent<Data>(
    Stream<(int clientID, String)> stringStream) async* {
  await for (final (id, msg) in stringStream) {
    try {
      yield _clientIDAndJsonStringToEvent(id, msg);
    } on FormatException {
      // If invalid do nothing, 'deleting' the event.
      print('INVALID EVENT: DELETING');
      rethrow;
    }
  }
}

EventServerInFromClient<Data> _clientIDAndJsonStringToEvent<Data>(int senderID, String jsonString) {
  final Map<String, dynamic> json;

  // Throws [FormatException] if invalid.
  json = jsonDecode(jsonString);

  json.containsAllKeysOrThrow([
    'g',
    'e',
    'd',
  ]);

  // TODO: type safe way for json parsing? pass a function?
  return EventServerInFromClient(
    generatedTimestamp:
        Duration(microseconds: int.parse(json['g'])),
    data: json['d'],
    senderID: senderID,
    eventID: int.parse(json['e']),
  );
}

// TODO: type safe way to serialise json? pass a function?
String _eventToJsonString<Data>(EventServerOut<Data> event) {
  return jsonEncode({
    'g': event.generatedTimestamp.inMicroseconds.toString(),
    'sr': event.serverReceiptTimestamp.inMicroseconds.toString(),
    'd': event.data.toString(),
    's': event.senderID.toString(),
    'e': event.eventID.toString(),
  }).toString();
}
