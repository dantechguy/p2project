import 'dart:convert';
import 'package:blitz/core.dart';

// Intercepts events sent to the server. Converts them into strings.
void Function(Event) convertEventToJsonString(
    void Function(String) sendStringToServer) {
  return (Event event) {
    sendStringToServer(_eventToJsonString(event));
  };
}

// Intercepts events received from the server. Converts them into Events for the Core.
Stream<Event> convertJsonStringToEvent(Stream<String> stringStream) async* {
  await for (final String msg in stringStream) {
    try {
      yield _jsonStringToEvent(msg);
    } on FormatException {
      // If invalid do nothing, 'deleting' the event.
    }
  }
}

Event _jsonStringToEvent(String jsonString) {
  final Map<String, dynamic> json;

  // Throws [FormatException] if invalid.
  json = jsonDecode(jsonString);

  json.containsAllKeysOrThrow([
    'serverReceiptTimestamp',
    'generatedTimestamp',
    'senderID',
    'eventID',
    'data',
    'isLocal',
  ]);

  return Event(
    serverReceiptTimestamp:
        microsecondsStringToDuration(json['serverReceiptTimestamp']),
    generatedTimestamp:
        microsecondsStringToDuration(json['generatedTimestamp']),
    senderID: int.parse(json['senderID']),
    eventID: int.parse(json['eventID']),
    data: json['data'],
    isServerConfirmed: json['isLocal'] == 'true' ? true : false,
  );
}

String _eventToJsonString(Event event) {
  return jsonEncode({
    'serverReceiptTimestamp':
        event.serverReceiptTimestamp.inMicroseconds.toString(),
    'generatedTimestamp': event.generatedTimestamp.inMicroseconds.toString(),
    'senderID': event.senderID.toString(),
    'eventID': event.eventID.toString(),
    'data': event.data.toString(),
    'isLocal': event.isServerConfirmed.toString(),
  }).toString();
}

Duration microsecondsStringToDuration(String microsecondsString) {
  return Duration(microseconds: int.parse(microsecondsString));
}

extension MapExtension on Map<String, dynamic> {
  bool containsAllKeys(List<String> keys) {
    return keys.every((key) => containsKey(key));
  }

  void containsAllKeysOrThrow(List<String> keys) {
    if (!containsAllKeys(keys)) {
      throw FormatException(
          'JSON string does not contain all required keys: $keys');
    }
  }
}
