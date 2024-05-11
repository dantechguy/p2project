
import 'package:blitz/client.dart';

/// Unstable Runner
///
/// Parameters / inputs are:
/// - Current stable state, and
/// - List of unstable events.
/// - A state step function.
///
/// It exposes as output:
/// - The current unstable state.
///

// Stream<State> runUnstableEvents<State>({
//   required State Function(State, List<EventClientIn>) driver,
//   required Stream<({State state, List<EventClientIn> unstableEvents})> stateAndUnstableEvents,
// }) {
//   return stateAndUnstableEvents.map((s) => driver(s.state, s.unstableEvents));
// }

State Function() runUnstableEvents<State, Data>({
  required State Function(State, List<EventClientInInCore<Data>>) driver,
  required State Function() getStableState,
  required List<EventClientInInCore<Data>> Function() getUnstableEvents,
}) {
  return () => driver(
    getStableState(),
    getUnstableEvents(),
  );
}
