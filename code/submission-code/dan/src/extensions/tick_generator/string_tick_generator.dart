import 'package:blitz/client.dart';
import 'package:blitz/src/extensions/tick_generator/tick_generator.dart';

Stream<EventClientInPreCore<String>> addStringTicks(
  Stream<EventClientInPreCore<String>> eventStream, {
  required Duration tickPeriod,
      required Duration Function() getCurrentTime,
StreamPeriodicMock? streamPeriodicMock,
}) {
  return addTicks<String, String>(
    eventStream,
    tickPeriod: tickPeriod,
    generateTickEvent: _generateStringTickEvent,
    generateNonTickEvent: (event) => event,
    getCurrentTime: getCurrentTime,
    streamPeriodicMock: streamPeriodicMock,
  );
}

// TODO: what should sender and eventID be?
EventClientInFromLocalButShared<String> _generateStringTickEvent(
    Duration tickTimestamp) {
  return EventClientInFromLocalButShared(
    generatedTimestamp: tickTimestamp,
    data: 'tick',
    senderID: -1,
    eventID: tickTimestamp.inMilliseconds,
  );
}