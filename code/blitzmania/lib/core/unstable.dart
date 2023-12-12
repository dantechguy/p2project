import 'package:blitzmania/shared/env.dart';

import 'event.dart';

/// Unstable Runner
///
/// Parameters / inputs are:
/// - The core module, which contains:
///   - Current stable state, and
///   - List of unstable events.
/// - A state step function.
///
/// It exposes as output:
/// - The current unstable environment state.
///
class UnstableRunner {
  UnstableRunner(
      {required Env Function(Env, List<Event>) driver,
      required Env Function() getStableState,
      required List<Event> Function() getUnstableEvents})
      : _driver = driver,
        _getCurrentStableState = getStableState,
        _getCurrentUnstableEvents = getUnstableEvents;

  final Env Function() _getCurrentStableState;

  final List<Event> Function() _getCurrentUnstableEvents;

  final Env Function(Env, List<Event>) _driver;

  Env getCurrentState() {
    // TODO: make more efficient by only recalculating from the last changed event.
    return _driver(_getCurrentStableState(), _getCurrentUnstableEvents());
  }
}
