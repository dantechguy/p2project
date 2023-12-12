import 'dart:async';

import 'package:blitzmania/core/event.dart';

/// Generates tick [Event]s from a clock and feeds them into the core. The core would likely use them to signal a computation unit.
///
/// If the input to the [Core] was a stream, this would modify the input stream by adding in additional events.
///
Stream<Event> addTickEvents(Stream<Event> eventStream, Duration tickPeriod) {
  // We need a method of generating tick events ensuring none are missed. Worst case would be having events baked in without the tick event, which is irreversible.
  // The timestamp used for baking comes from the events inputted into Core, so we can use two triggers for generating tick events:
  // - A timer, which generates a tick event every tickPeriod.
  // - An event, where we check if one or more tick events should have been generated between the last and this event. We do this in case the timer wasn't called in this time.

  // Technically the tick events don't need to go in the exact correct order with events, as they'll be re-arranged as long as they're within the latency cutoff. But only this way is guaranteed.

  // We should generate a tick event at all multiples of tickPeriod, excluding zero.

  Duration lastTickEventTimestamp = Duration.zero;
  final streamController = StreamController<Event>();

  void _generateTickEvents(Duration lastTickEventTimestamp,
      Duration currentTimestamp, Duration tickPeriod) {
    final newTickEvents = _generateNeededTickEvents(
        lastTickEventTimestamp, currentTimestamp, tickPeriod);

    if (newTickEvents.isNotEmpty) {
      lastTickEventTimestamp = newTickEvents.last.generatedTimestamp;
    }

    newTickEvents.forEach(streamController.add);
  }

  // What if this timer gets out of sync with the server?
  // AI: We could have a timer which is reset every time we receive a server event.
  // It will only be slightly out of sync, so if it's slightly too quick then it will just produce tick events in the future which we can handle. If it's too slow, then a missing tick will be handled by an event trigger.
  // TODO: Consider making this sync up properly.
  Timer.periodic(tickPeriod, (timer) {
    final currentTimestamp = tickPeriod * timer.tick;
    _generateTickEvents(lastTickEventTimestamp, currentTimestamp, tickPeriod);
  });

  // TODO: Consider writing this as a generator function, using `yield`, or using [eventStream.expand].
  eventStream.forEach((Event event) {
    _generateTickEvents(
        lastTickEventTimestamp, event.generatedTimestamp, tickPeriod);
    streamController.add(event);
  });

  return streamController.stream;
}

// TODO: Consider making this accept any time range.
List<Event> _generateNeededTickEvents(Duration lastTickEventTimestamp,
    Duration currentTimestamp, Duration tickPeriod) {
  final tickEvents = <Event>[];
  Duration tickTimestamp = currentTimestamp + tickPeriod;
  while (tickTimestamp < lastTickEventTimestamp) {
    // TODO: Fill in complete [Event] constructor when ready.
    tickEvents.add(Event(generatedTimestamp: tickTimestamp));
    tickTimestamp += tickPeriod;
  }
  return tickEvents;
}
