class EventClientOut<Data> {
  EventClientOut({
    required this.generatedTimestamp,
    required this.data,
    required this.eventID,
  });

  final Duration generatedTimestamp;
  final Data data;
  final int eventID;
}