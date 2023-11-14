


import 'package:blitzmania/core/event.dart';

import '../shared/env.dart';

/// The inner-most core module of anticheat.
///
/// Parameters / inputs are:
/// - The latency cutoff. What is the maximum latency between the server and client the game supports, and after how long an event is baked.
/// - Real-time sequence of events. It stores these internally.
/// - A state step function. Given a current environment, step forward a certain amount of time.
///
/// It exposes as output:
/// - The current stable environment state.
/// - Sequence of current, unstable, events. These may be deleted or re-ordered.
///
///
///
class Core {

  Duration _latencyCutoff;

  Env Function(Env) driver;

  void addEvent(Event event) {
    throw UnimplementedError();
  }

  Env getCurrentState() {
    throw UnimplementedError();
  }

  List<Event> getUnstableEvents() {
    throw UnimplementedError();
  }
}