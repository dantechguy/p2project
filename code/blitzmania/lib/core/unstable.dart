import 'package:blitzmania/shared/env.dart';

import 'core.dart';
import 'event.dart';

/// Unstable Runner
///
/// Parameters / inputs are:
/// - ? Real-time sequence of events. Unsure if this module passes events into its internal core module. Probably.
/// - The core module.
/// - A state step function.
///
/// It exposes as output:
/// - The current unstable environment state.
///
class UnstableRunner {

  Core _core;

  Env Function(Env) driver;

  // TODO: Have? See doc comments
  void addEvent(Event event) {
    throw UnimplementedError();
  }

  Env getCurrentState() {
    throw UnimplementedError();
  }
}