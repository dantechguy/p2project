class EventServerOut {
  EventServerOut({
    required this.serverReceiptTimestamp,
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  final Duration serverReceiptTimestamp;
  final Duration generatedTimestamp;
  final String data;
  final int senderID;
  final int eventID;
}