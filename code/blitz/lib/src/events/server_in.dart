sealed class EventServerIn<Data> {
  Data get data;

  String toShortString();
}

class EventServerInFromServer<Data> extends EventServerIn<Data> {
  EventServerInFromServer({
    required this.data,
  });

  @override
  final Data data;

  @override
  bool operator ==(Object other) =>
      other is EventServerInFromServer && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toShortString() {
    return 'd$data-server';
  }
}

class EventServerInFromClient<Data> extends EventServerIn<Data> {
  EventServerInFromClient({
    required this.generatedTimestamp,
    required this.data,
    required this.senderID,
    required this.eventID,
  });

  final Duration generatedTimestamp;
  @override
  final Data data;
  final int senderID;
  final int eventID;

  @override
  bool operator ==(Object other) =>
      other is EventServerInFromClient &&
      generatedTimestamp == other.generatedTimestamp &&
      data == other.data &&
      senderID == other.senderID &&
      eventID == other.eventID;

  @override
  int get hashCode => Object.hash(generatedTimestamp, data, senderID, eventID);

  @override
  String toShortString() {
    return 't${generatedTimestamp.inMilliseconds}-s$senderID-e$eventID-d$data-client';
  }
}
