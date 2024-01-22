import 'dart:async';

import 'package:blitz/src/core/events/event.dart';

/// Generates tick [Event]s from a clock and feeds them into the core. The core would likely use them to signal a computation unit.
///
/// If the input to the [Core] was a stream, this would modify the input stream by adding in additional events.
///
/// Make accept a `currentTime` value, which is the upper bound for ticks to be generated. However given the core can handle future events, you could technically add infinite ticks all at the start and it would still work. But that's not particularly nice.
/// Make into named arguments?
Stream<Event> addTickEvents(Stream<Event> eventStream, Duration tickPeriod,
    int Function() generateEventID) {
  // We need a method of generating tick events ensuring none are missed. Worst case would be having events baked in without the tick event, which is irreversible.
  // The timestamp used for baking comes from the events inputted into Core, so we can use two triggers for generating tick events:
  // - A timer, which generates a tick event every tickPeriod.
  // - An event, where we check if one or more tick events should have been generated between the last and this event. We do this in case the timer wasn't called in this time.

  // Technically the tick events don't need to go in the exact correct order with events, as they'll be re-arranged as long as they're within the latency cutoff. But only this way is guaranteed.

  // We should generate a tick event at all multiples of tickPeriod, excluding zero.

  Duration lastTickEventTimestamp = Duration.zero;
  // TODO: https://dart.dev/articles/libraries/creating-streams
  // TODO: Check for no memory leaks? Use async* function?
  final streamController = StreamController<Event>();

  void generateTickEvents(
    Duration lastTickEventTimestamp,
    Duration currentTimestamp,
    Duration tickPeriod,
  ) {
    final newTickEvents = _generateNeededTickEvents(
        lastTickEventTimestamp, currentTimestamp, tickPeriod, generateEventID);

    if (newTickEvents.isNotEmpty) {
      lastTickEventTimestamp = newTickEvents.last.generatedTimestamp;
    }

    newTickEvents.forEach(streamController.add);
  }

  // What if this timer gets out of sync with the server?
  // AI: We could have a timer which is reset every time we receive a server event.
  // It will only be slightly out of sync, so if it's slightly too quick then it will just produce tick events in the future which we can handle. If it's too slow, then a missing tick will be handled by an event trigger.
  // Consider making this sync up properly.
  // TODO: When should it start generating events?
  Timer.periodic(tickPeriod, (timer) {
    final currentTimestamp = tickPeriod * timer.tick;
    generateTickEvents(lastTickEventTimestamp, currentTimestamp, tickPeriod);
  });

  // Consider writing this as a generator function, using `yield`, or using [eventStream.expand].
  eventStream.forEach((Event event) {
    generateTickEvents(
        lastTickEventTimestamp, event.generatedTimestamp, tickPeriod);
    streamController.add(event);
  });

  return streamController.stream;
}

// Consider making this accept any time range.
List<Event> _generateNeededTickEvents(
  Duration lastTickEventTimestamp,
  Duration currentTimestamp,
  Duration tickPeriod,
  int Function() generateEventID,
) {
  final tickEvents = <Event>[];
  Duration tickTimestamp = currentTimestamp + tickPeriod;
  while (tickTimestamp < lastTickEventTimestamp) {
    tickEvents.add(Event(
      // TODO: Change? Invalid value.
      serverReceiptTimestamp: Duration.zero,
      generatedTimestamp: tickTimestamp,
      // TODO: Change? This means it's technically from the server.
      senderID: 0,
      data: 'tick',
      eventID: generateEventID(),
      isServerConfirmed: false,
    ));
    tickTimestamp += tickPeriod;
  }
  return tickEvents;
}
