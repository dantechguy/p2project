import 'dart:async';
import 'package:async/async.dart' show StreamGroup;
import 'package:blitz/src/core/events/client_in.dart';

Stream<EventClientIn> addTicks(Stream<EventClientIn> eventStream,
    Duration tickPeriod, int Function() generateEventID, {}) {
  var lastTickEventTimestamp = Duration.zero;

  final timerStream = Stream.periodic(tickPeriod, (timer) {
    lastTickEventTimestamp += tickPeriod;
    return _generateTickEvent(lastTickEventTimestamp);
  });

  final eventBackupStream = eventStream.expand((event) {
    if (event is EventClientInFromServer) {
      return [
        ..._generateTickEventsUpTo(
          timestamp: event.serverReceiptTimestamp,
          lastTickEventTimestamp: lastTickEventTimestamp,
          tickPeriod: tickPeriod,
          generateEventID: generateEventID,
        ),
        event,
      ];
    } else {
      return [event];
    }
  });

  // Merge together and return
  return StreamGroup.merge([timerStream, eventBackupStream]);
}

List<EventClientInFromLocalButShared> _generateTickEventsUpTo({
  required Duration timestamp,
  required Duration lastTickEventTimestamp,
  required Duration tickPeriod,
  required int Function() generateEventID,
}) {
  final tickEvents = <EventClientInFromLocalButShared>[];
  Duration tickTimestamp = timestamp + tickPeriod;
  while (tickTimestamp <= lastTickEventTimestamp) {
    tickEvents.add(_generateTickEvent(tickTimestamp));
    tickTimestamp += tickPeriod;
  }
  return tickEvents;
}

EventClientInFromLocalButShared _generateTickEvent(Duration tickTimestamp) {
  return EventClientInFromLocalButShared(
    generatedTimestamp: tickTimestamp,
    data: 'tick',
    senderID: -1,
    eventID: tickTimestamp.inMicroseconds,
  );
}

final a = Stream.periodic;