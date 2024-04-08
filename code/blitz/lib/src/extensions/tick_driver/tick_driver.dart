import 'package:blitz/src/dart_extensions.dart';
import 'package:blitz/client.dart';

// TODO: Make this useful. It will only be useful if we completely control the input system, which we don't.
State Function(State, List<EventClientInPreCore<Data>>)
    tickedDriver<State, Data>({
  required State Function(State) computeDriver,
  required State Function(State, List<EventClientInPreCore<Data>>) inputDriver,
  required bool Function(EventClientInPreCore<Data>) isInputEvent,
  required bool Function(EventClientInPreCore<Data>) isTickEvent,
}) {
  State batchInputDriverWrapper(
      State state, List<EventClientInPreCore<Data>> inEvents) {

    late final newState;
    for (final event in inEvents) {
      if (isTickEvent(event)) {
        newState = computeDriver(state);
      } else if (isInputEvent(event)) {
          newState = inputDriver(state, [event]);
      } else {
      }
    }
    return newState;
  }

  return batchInputDriverWrapper;
}
