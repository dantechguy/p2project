sealed class EventClientIn implements Comparable<EventClientIn> {
  int get eventID;
  int get senderID;
  String get data;
  Duration get generatedTimestamp;


  @override
  int compareTo(EventClientIn other) {
    // Sort by timestamp, then by senderID, then by eventID.
    if (generatedTimestamp != other.generatedTimestamp) {
      return generatedTimestamp.compareTo(other.generatedTimestamp);
    }
    if (senderID != other.senderID) {
      return senderID.compareTo(other.senderID);
    }
    return eventID.compareTo(other.eventID);
  }
}

class EventClientInFromServer extends EventClientIn {
  EventClientInFromServer({
    required this.serverReceiptTimestamp,
    required this.generatedTimestamp,
    required this.senderID,
    required this.data,
    required this.eventID,
  });

  final Duration serverReceiptTimestamp;
  @override
  final Duration generatedTimestamp;
  @override
  final String data;
  @override
  final int senderID;
  @override
  final int eventID;
}

class EventClientInFromLocal extends EventClientIn {
  EventClientInFromLocal({
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  @override
  final Duration generatedTimestamp;
  @override
  final String data;
  @override
  final int senderID;
  @override
  final int eventID;
}

class EventClientInFromLocalButShared extends EventClientIn {
  EventClientInFromLocalButShared({
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  @override
  final Duration generatedTimestamp;
  @override
  final String data;
  @override
  final int senderID;
  @override
  final int eventID;
}