import 'dart:async';
import 'package:async/async.dart' show StreamGroup;
import 'package:blitz/client.dart';

typedef StreamPeriodicMock = Stream<T> Function<T>(Duration,
    [T Function(int)?]);

Stream<EventClientInPreCore<OutData>> addTicks<InData, OutData>(
  Stream<EventClientInPreCore<InData>> eventStream, {
  required Duration tickPeriod,
  required EventClientInFromLocalButShared<OutData> Function(Duration)
      generateTickEvent,
  required EventClientInPreCore<OutData> Function(EventClientInPreCore<InData>)
      generateNonTickEvent,
  StreamPeriodicMock? streamPeriodicMock,
}) {
  var lastTickEventTimestamp = Duration.zero;
  final streamPeriodic = streamPeriodicMock ?? Stream.periodic;

  final timerStream =
      streamPeriodic<EventClientInPreCore<OutData>>(tickPeriod, (tickNum) {
    lastTickEventTimestamp += tickPeriod;
    return generateTickEvent(lastTickEventTimestamp);
  });

  final eventBackupStream =
      eventStream.expand<EventClientInPreCore<OutData>>((event) {
    // TODO: should we just use server events here? yes.
    if (event is EventClientInFromServer<InData>) {
      final insertedTickEvents = _generateTickEventsUpTo(
        timestamp: event.serverReceiptTimestamp,
        lastTickEventTimestamp: lastTickEventTimestamp,
        tickPeriod: tickPeriod,
        generateTickEvent: generateTickEvent,
      );
      if (insertedTickEvents.isNotEmpty) {
        lastTickEventTimestamp = insertedTickEvents.last.generatedTimestamp;
      }
      return [
        ...insertedTickEvents,
        generateNonTickEvent(event),
      ];
    } else {
      return [generateNonTickEvent(event)];
    }
  });

  // Merge together and return
  return StreamGroup.merge([timerStream, eventBackupStream]);
}

List<EventClientInFromLocalButShared<OutData>>
    _generateTickEventsUpTo<OutData>({
  required Duration timestamp,
  required Duration lastTickEventTimestamp,
  required Duration tickPeriod,
  required EventClientInFromLocalButShared<OutData> Function(Duration)
      generateTickEvent,
}) {
  final tickEvents = <EventClientInFromLocalButShared<OutData>>[];
  Duration tickTimestamp = lastTickEventTimestamp + tickPeriod;
  while (tickTimestamp <= timestamp) {
    tickEvents.add(generateTickEvent(tickTimestamp));
    tickTimestamp += tickPeriod;
  }
  return tickEvents;
}
