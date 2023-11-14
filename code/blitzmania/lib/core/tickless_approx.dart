import 'package:blitzmania/core/interpolator.dart';
import 'package:blitzmania/shared/env.dart';

/// Lightweight tickless approximator
///
/// Parameters / inputs are:
/// - Signal to compute and return the current tickless, approximate, envstate.
/// - Current environment state.
/// - Time of envstate and current time / how far to simulate.
///
/// It exposes as output:
/// - A current envstate which is continuous.
///
class TicklessExtrapolator {
  int a = 0;
  Env getCurrentState(Duration currentGameTime) {
    throw UnimplementedError();
  }
}



