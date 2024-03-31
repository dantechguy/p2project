import 'dart:convert';

import 'package:blitz/client.dart';

Stream<String> serialiseEventToJsonStringForServer<Data>(
    Stream<EventClientOut<Data>> eventsToServer) {
  return eventsToServer.map(_eventToJsonString);
}

// Intercepts events received from the server. Converts them into Events for the Core.
Stream<EventClientInFromServer<Data>> deserialiseJsonStringFromServerToEvent<Data>(
    Stream<String> stringStream) async* {
  await for (final String msg in stringStream) {
    try {
      yield _jsonStringToEvent(msg);
    } on FormatException {
      // If invalid do nothing, 'deleting' the event.
    }
  }
}

EventClientInFromServer<Data> _jsonStringToEvent<Data>(String jsonString) {
  final Map<String, dynamic> json;

  // Throws [FormatException] if invalid.
  json = jsonDecode(jsonString);

  json.containsAllKeysOrThrow([
    'serverReceiptTimestamp',
    'generatedTimestamp',
    'senderID',
    'eventID',
    'data',
  ]);

  // TODO: Find some way to have type-safe JSON parsing. Maybe you need to pass in a function
  return EventClientInFromServer(
    serverReceiptTimestamp:
        Duration(microseconds: int.parse(json['serverReceiptTimestamp'])),
    generatedTimestamp:
        Duration(microseconds: int.parse(json['generatedTimestamp'])),
    senderID: int.parse(json['senderID']),
    eventID: int.parse(json['eventID']),
    data: json['data'],
  );
}

// TODO: type safe json serialisation. pass a function?
String _eventToJsonString<Data>(EventClientOut<Data> event) {
  return jsonEncode({
    'generatedTimestamp': event.generatedTimestamp.inMicroseconds.toString(),
    'eventID': event.eventID.toString(),
    'data': event.data.toString(),
  }).toString();
}
