class EventServerIn {
  EventServerIn({
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  final Duration generatedTimestamp;
  final String data;
  final int senderID;
  final int eventID;
}