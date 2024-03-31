import 'dart:async';

import 'package:async/async.dart' show StreamGroup;
import 'package:blitz/client.dart';

typedef StreamPeriodicMock = Stream<T> Function<T>(Duration,
    [T Function(int)?]);

typedef TickRecord<Data> = ({bool isTick, Data? data});

Stream<EventClientIn<TickRecord<Data>>> addTicks<Data>(
  Stream<EventClientIn<Data>> eventStream, {
  required Duration tickPeriod,
  StreamPeriodicMock? streamPeriodicMock,
}) {
  var lastTickEventTimestamp = Duration.zero;
  final streamPeriodic = streamPeriodicMock ?? Stream.periodic;

  final timerStream = streamPeriodic<EventClientIn<TickRecord<Data>>>(tickPeriod, (tickNum) {
    lastTickEventTimestamp += tickPeriod;
    return _generateTickEvent(lastTickEventTimestamp);
  });

  final eventBackupStream =
      eventStream.expand<EventClientIn<TickRecord<Data>>>((event) {
    if (event is EventClientInFromServer<Data>) {
      return [
        ..._generateTickEventsUpTo(
          timestamp: event.serverReceiptTimestamp,
          lastTickEventTimestamp: lastTickEventTimestamp,
          tickPeriod: tickPeriod,
        ),
        _generateNonTickEvent(event),
      ];
    } else {
      return [_generateNonTickEvent(event)];
    }
  });

  // Merge together and return
  return StreamGroup.merge([timerStream, eventBackupStream]);
}

List<EventClientInFromLocalButShared<TickRecord<Data>>>
    _generateTickEventsUpTo<Data>({
  required Duration timestamp,
  required Duration lastTickEventTimestamp,
  required Duration tickPeriod,
}) {
  final tickEvents =
      <EventClientInFromLocalButShared<TickRecord<Data>>>[];
  Duration tickTimestamp = timestamp + tickPeriod;
  while (tickTimestamp <= lastTickEventTimestamp) {
    tickEvents.add(_generateTickEvent(tickTimestamp));
    tickTimestamp += tickPeriod;
  }
  return tickEvents;
}

// TODO: what should sender and eventID be?
EventClientInFromLocalButShared<TickRecord<Data>>
    _generateTickEvent<Data>(Duration tickTimestamp) {
  return EventClientInFromLocalButShared(
    generatedTimestamp: tickTimestamp,
    data: (isTick: true, data: null),
    senderID: -1,
    eventID: tickTimestamp.inMicroseconds,
  );
}

EventClientIn<TickRecord<Data>> _generateNonTickEvent<Data>(
    EventClientIn<Data> event) {
  if (event is EventClientInFromLocal<Data>) {
    return EventClientInFromLocal(
      generatedTimestamp: event.generatedTimestamp,
      data: (isTick: false, data: event.data),
      senderID: event.senderID,
      eventID: event.eventID,
    );
  } else if (event is EventClientInFromLocalButShared<Data>) {
    return EventClientInFromLocalButShared(
      generatedTimestamp: event.generatedTimestamp,
      data: (isTick: false, data: event.data),
      senderID: event.senderID,
      eventID: event.eventID,
    );
  } else if (event is EventClientInFromServer<Data>) {
    return EventClientInFromServer(
      serverReceiptTimestamp: event.serverReceiptTimestamp,
      generatedTimestamp: event.generatedTimestamp,
      data: (isTick: false, data: event.data),
      senderID: event.senderID,
      eventID: event.eventID,
    );
  } else {
    throw UnimplementedError();
  }
}
