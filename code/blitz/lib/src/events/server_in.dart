class EventServerIn<Data> {
  EventServerIn({
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  final Duration generatedTimestamp;
  final Data data;
  final int senderID;
  final int eventID;
}