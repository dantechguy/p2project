sealed class EventClientIn<Data> implements Comparable<EventClientIn<Data>> {
  int get eventID;
  int get senderID;
  Data get data;
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

class EventClientInFromServer<Data> extends EventClientIn<Data> {
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
  final Data data;
  @override
  final int senderID;
  @override
  final int eventID;
}

// TODO: Remove sender ID, as only local client makes these and so sender ID should be set automatically.
class EventClientInFromLocal<Data> extends EventClientIn<Data> {
  EventClientInFromLocal({
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  @override
  final Duration generatedTimestamp;
  @override
  final Data data;
  @override
  final int senderID;
  @override
  final int eventID;
}

class EventClientInFromLocalButShared<Data> extends EventClientIn<Data> {
  EventClientInFromLocalButShared({
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  @override
  final Duration generatedTimestamp;
  @override
  final Data data;
  @override
  final int senderID;
  @override
  final int eventID;
}