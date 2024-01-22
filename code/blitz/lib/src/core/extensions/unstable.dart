
import 'package:blitz/src/core/events/event.dart';

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

State Function() runUnstableEvents<State>({
  required State Function(State, List<Event>) driver,
  required State Function() getStableState,
  required List<Event> Function() getUnstableEvents,
}) {
  return () => driver(
    getStableState(),
    getUnstableEvents(),
  );
}
