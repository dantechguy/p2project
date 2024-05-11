import 'dart:convert';
import 'package:blitz/client.dart';
import 'package:blitz/src/dart_extensions.dart';

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
    } on FormatException catch (e) {
      // If invalid do nothing, 'deleting' the event.
      print('REMOVED EVENT: $msg for reason: $e');
      rethrow;
    }
  }
}

EventClientInFromServer<Data> _jsonStringToEvent<Data>(String jsonString) {
  final Map<String, dynamic> json;

  // Throws [FormatException] if invalid.
  json = jsonDecode(jsonString);

  json.containsAllKeysOrThrow([
    'sr', //serverReceiptTimestamp
    'g', //generatedTimestamp
    's', //senderID
    'e', //eventID
    'd', //data
  ]);

  // TODO: Find some way to have type-safe JSON parsing. Maybe you need to pass in a function
  return EventClientInFromServer(
    serverReceiptTimestamp:
        Duration(microseconds: int.parse(json['sr'])),
    generatedTimestamp:
        Duration(microseconds: int.parse(json['g'])),
    senderID: int.parse(json['s']),
    eventID: int.parse(json['e']),
    data: json['d'],
  );
}

// TODO: type safe json serialisation. pass a function?
String _eventToJsonString<Data>(EventClientOut<Data> event) {
  return jsonEncode({
    'g': event.generatedTimestamp.inMicroseconds.toString(),
    'e': event.eventID.toString(),
    'd': event.data.toString(),
  }).toString();
}
