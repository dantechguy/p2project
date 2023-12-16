import 'dart:convert';

class Event {
  // TODO: Change timestamp type?
  late final Duration serverReceiptTimestamp;
  // TODO: Change timestamp type?
  late final Duration generatedTimestamp;
  // TODO: Change to ID type?
  late final int senderID;
  // TODO: Change type?
  late final String action;
  // TODO: Change type?
  late final int eventID;

  Event.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    serverReceiptTimestamp = microsecondsStringToDuration(json['serverReceiptTimestamp']);
    generatedTimestamp = microsecondsStringToDuration(json['generatedTimestamp']);
    senderID = int.parse(json['senderID']);
    eventID = int.parse(json['eventID']);
    action = json['action'].toString();
  }

  String toJsonString() {
    return jsonEncode({
      'serverReceiptTimestamp': serverReceiptTimestamp.inMicroseconds.toString(),
      'generatedTimestamp': generatedTimestamp.inMicroseconds.toString(),
      'senderID': senderID.toString(),
      'eventID': eventID.toString(),
      'action': action,
    }).toString();
  }
}

Duration microsecondsStringToDuration(String microsecondsString) {
  return Duration(microseconds: int.parse(microsecondsString));
}