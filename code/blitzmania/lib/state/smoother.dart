import 'dart:math';

import 'package:blitzmania/dart_extensions.dart';
import 'package:blitzmania/state/state.dart';
import 'package:collection/collection.dart';
import 'package:vector_math/vector_math.dart';

/* TODO: Generalise:
      - This could first involve using anonymous functions.
        - One function to gather an iterator of objects to interpolate over.
        - You need to know which object corresponds to which across frames, so
          either the function above returns a map from ids to objects, or you
          have another function which given an object returns its id.
        - One function to take in a current object and return it interpolated.
        - An issue with the above is that you don't have the object's source
          (where you got it from) when determining it's id, so you may have to
          resort to type lookup. Would be better if you could specify its id
          alongside the item in the iterator, such as in a record.
        - You could also have objects implement a "Smoothable" type where they
          just expose a unique id. There's the question of where the smoothing
          implementation is. I feel doing it in one smoothing object (here)
          is better than across all Smoothable objects, as it keeps the logic
          in one place.
      - Then build upon this with a physics object interpolator.
      - How does customising the smoothing technique work?
        - For example: exponential vs linear vs whatever.
        - What is the minimum interface to implement any method? You likely just
          need a persistent state object you can write and read.  Maybe for now
          I'll make the state just an object of that type, for ease?  However
          this will not be type safe, as if the same id is used for two
          objects of different types in consecutive frames, it'll break.  I can
          see this being quite a difficult bug to identify and fix too.
   */


/// Interpolator / smoother
///
/// Parameters / inputs are:
/// - An interpolation function.
/// - A signal to compute and return the current envstate.
/// - Sequence of envstates over time.
///
/// It exposes as output:
/// - A current envstate which changes smoothly (has no sudden jumps).
///

RacingState Function() racingSmoother({
  required double Function(double) curve,
  required Duration smoothLength,
  required RacingState Function() getState,
  required Duration Function() getTime,
}) {
  final List<(Duration, RacingState)> pastStates = [];

  void removeOldStates(Duration cutoffTime) {
    while (pastStates.isNotEmpty && pastStates.first.$1 < cutoffTime) {
      pastStates.removeAt(0);
    }
  }

  List<(double, RacingState)> getWeightedPastStates(Duration currentTime) {
    final cutoffTime = currentTime = smoothLength;
    return pastStates.map((rec) {
      final (time, state) = rec;
      final weighting = (time - cutoffTime).inSecondsReal /
          smoothLength.inSecondsReal;
      return (weighting, state);
    }).where((rec) => rec.$1 != 0).toList();
  }

  return () {
    final time = getTime();
    final state = getState().copy();
    pastStates.add((time, state.copy()));
    if (pastStates.length == 1) {
      return pastStates.first.$2;
    }
    removeOldStates(time - smoothLength);
    state.gameTime = time;
    final weightedStates = getWeightedPastStates(time);
    for (final car in state.cars) {
      final weightedCars = weightedStates.expand<(double, Car)>((r) {
        final olderCar = r.$2.cars.firstWhereOrNull((otherCar) =>
        otherCar.userId == car.userId);
        return olderCar == null ? [] : [(r.$1, olderCar)];
      });
      car.position = weightedMeanLinearVector2(
          weightedCars.map((r) => (r.$1, r.$2.position)));
      car.direction = weightedMeanCircularDouble(
          weightedCars.map((r) => (r.$1, r.$2.direction))) ?? car.direction;
    }
    return state;
  };
}

double? weightedMeanCircularDouble(Iterable<(double, double)> weightAndValue) {
  // convert to unit vectors in that direction
  final weightedUnitVectors = weightAndValue.map((r) =>
  (r.$1, Vector2(sin(r.$2), cos(r.$2))));
  // take mean using below vector2
  final meanVector = weightedMeanLinearVector2(weightedUnitVectors);
  // return angle of mean unit vector
  if (meanVector.length == 0) {
    return null;
  } else {
    return -Vector2(0, 1).angleToSigned(meanVector);
  }
}

Vector2 weightedMeanLinearVector2(Iterable<(double, Vector2)> weightAndValue) {
  return Vector2(
    weightedMeanLinearDouble(weightAndValue.map((r) => (r.$1, r.$2.x))),
    weightedMeanLinearDouble(weightAndValue.map((r) => (r.$1, r.$2.y))),
  );
}

double weightedMeanLinearDouble(Iterable<(double, double)> weightAndValue) {
  final totalWeight = weightAndValue
      .map((rec) => rec.$1)
      .sum;
  return weightAndValue
      .map((r) => r.$2 * (r.$1 / totalWeight))
      .sum;
}
