class EventServerOut<Data> {
  EventServerOut({
    required this.serverReceiptTimestamp,
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  final Duration serverReceiptTimestamp;
  final Duration generatedTimestamp;
  final Data data;
  final int senderID;
  final int eventID;

  @override
  bool operator ==(Object other) {
    return other is EventServerOut &&
        serverReceiptTimestamp == other.serverReceiptTimestamp &&
        generatedTimestamp == other.generatedTimestamp &&
        data == other.data &&
        senderID == other.senderID &&
        eventID == other.eventID;
  }

  @override
  int get hashCode => Object.hash(
      serverReceiptTimestamp, generatedTimestamp, data, senderID, eventID);
}
