class EventClientOut<Data> {
  EventClientOut({
    required this.generatedTimestamp,
    required this.data,
    required this.eventID,
  });

  final Duration generatedTimestamp;
  final Data data;
  final int eventID;

  @override
  bool operator==(Object other) =>
      other is EventClientOut &&
      generatedTimestamp == other.generatedTimestamp &&
      data == other.data &&
      eventID == other.eventID;

  @override
  int get hashCode => Object.hash(generatedTimestamp, data, eventID);

  String toShortString() {
    return 't${generatedTimestamp.inMilliseconds}-e$eventID-d$data';
  }
}