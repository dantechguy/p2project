
import 'package:blitzmania/dart_extensions.dart';
import 'package:blitzmania/state/state.dart';

/// Lightweight tickless approximator
///
/// Given a state and duration, this will return an approximate state after simulating for that duration.
///
/// Parameters / inputs are:
/// - Signal to compute and return the current tickless, approximate, envstate.
/// - Current environment state.
/// - Time of envstate and current time / how far to simulate.
///
/// It exposes as output:
/// - A current envstate which is continuous.
///
///
/// How to generalise?
///
/// You can specialise a bit by assuming standard euler physics. Write Env specific first,
///     then generalise afterwards?
/// TODO: Either take in current game time, or amount of time to simulate.
RacingState Function() ticklessExtrapolation({
  required RacingState Function() getLastState,
  required Duration Function() getCurrentGameTime,
}) {
  return () {
    final lastState = getLastState();
    final state = lastState.copy();
    Duration timeToSimulate = getCurrentGameTime() - lastState.gameTime;
    double dt = timeToSimulate.inSecondsFractional;

    for (final car in state.cars) {
      // TODO: Include angular velocity.
      // TODO: Don't assume acceleration is zero.
      // We have acceleration and velocity, and want to get displacement.
      // s = ut + 1/2 at^2

      // ATM because we assume a=0, it's just s = ut

      car.position += car.velocity * dt;
    }

    return state;
  };
}
