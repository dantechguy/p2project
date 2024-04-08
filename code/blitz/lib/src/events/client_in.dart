sealed class EventClientInPreCore<Data> {
  Data get data;

  String toShortString();
}

sealed class EventClientInInCore<Data>
    implements Comparable<EventClientInInCore<Data>> {
  int get eventID;

  int get senderID;

  Data get data;

  Duration get generatedTimestamp;

  @override
  int compareTo(EventClientInInCore<Data> other) {
    // Sort by timestamp, then by senderID, then by eventID.
    if (generatedTimestamp != other.generatedTimestamp) {
      return generatedTimestamp.compareTo(other.generatedTimestamp);
    }
    if (senderID != other.senderID) {
      return senderID.compareTo(other.senderID);
    }
    return eventID.compareTo(other.eventID);
  }

  String toShortString();
}

class EventClientInFromServer<Data> extends EventClientInInCore<Data>
    implements EventClientInPreCore<Data> {
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

  @override
  bool operator ==(Object other) =>
      other is EventClientInFromServer<Data> &&
      serverReceiptTimestamp == other.serverReceiptTimestamp &&
      generatedTimestamp == other.generatedTimestamp &&
      senderID == other.senderID &&
      data == other.data &&
      eventID == other.eventID;

  @override
  int get hashCode => Object.hash(
      serverReceiptTimestamp, generatedTimestamp, senderID, data, eventID);

  @override
  String toShortString() {
    return 't${generatedTimestamp.inMilliseconds}-r${serverReceiptTimestamp.inMilliseconds}-s$senderID-e$eventID-d$data-server';
  }
}

class EventClientInFromLocalButShared<Data> extends EventClientInInCore<Data>
    implements EventClientInPreCore<Data> {
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

  @override
  bool operator ==(Object other) =>
      other is EventClientInFromLocalButShared<Data> &&
      generatedTimestamp == other.generatedTimestamp &&
      data == other.data &&
      senderID == other.senderID &&
      eventID == other.eventID;

  @override
  int get hashCode => Object.hash(generatedTimestamp, data, senderID, eventID);

  @override
  String toShortString() {
    return 't${generatedTimestamp.inMilliseconds}-s$senderID-e$eventID-d$data-localshared';
  }
}

class EventClientInFromLocalInCore<Data> extends EventClientInInCore<Data> {
  EventClientInFromLocalInCore({
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

  @override
  bool operator ==(Object other) =>
      other is EventClientInFromLocalInCore<Data> &&
      generatedTimestamp == other.generatedTimestamp &&
      data == other.data &&
      senderID == other.senderID &&
      eventID == other.eventID;

  @override
  int get hashCode => Object.hash(generatedTimestamp, data, senderID, eventID);

  @override
  String toShortString() {
    return 't${generatedTimestamp.inMilliseconds}-s$senderID-e$eventID-d$data-local';
  }
}

class EventClientInFromLocalPreCore<Data>
    implements EventClientInPreCore<Data> {
  EventClientInFromLocalPreCore({required this.data});

  @override
  final Data data;

  @override
  String toShortString() {
    return 'd$data-localpre';
  }


}
