class EventClientOut {
  EventClientOut({
    required this.generatedTimestamp,
    required this.data,
    required this.eventID,
  });

  final Duration generatedTimestamp;
  final String data;
  final int eventID;
}