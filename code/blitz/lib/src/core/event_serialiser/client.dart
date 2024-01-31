import 'dart:convert';

import '../events/client_in.dart';
import '../events/client_out.dart';

void Function(EventClientOut) convertEventToJsonStringForServer(
    void Function(String) sendStringToServer) {
  return (EventClientOut event) {
    sendStringToServer(_eventToJsonString(event));
  };
}

// Intercepts events received from the server. Converts them into Events for the Core.
Stream<EventClientInFromServer> convertJsonStringFromServerToEvent(
    Stream<String> stringStream) async* {
  await for (final String msg in stringStream) {
    try {
      yield _jsonStringToEvent(msg);
    } on FormatException {
      // If invalid do nothing, 'deleting' the event.
    }
  }
}

EventClientInFromServer _jsonStringToEvent(String jsonString) {
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

  return EventClientInFromServer(
    serverReceiptTimestamp:
    microsecondsStringToDuration(json['serverReceiptTimestamp']),
    generatedTimestamp:
    microsecondsStringToDuration(json['generatedTimestamp']),
    senderID: int.parse(json['senderID']),
    eventID: int.parse(json['eventID']),
    data: json['data'],
  );
}

String _eventToJsonString(EventClientOut event) {
  return jsonEncode({
    'generatedTimestamp': event.generatedTimestamp.inMicroseconds.toString(),
    'eventID': event.eventID.toString(),
    'data': event.data.toString(),
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
