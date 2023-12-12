


import 'package:blitzmania/shared/env.dart';
import 'package:flutter/animation.dart';

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
class Smoother {
  Smoother();

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



  // Internal store of previous Env's. This is interpolation approach specific.
  // Here we have a 'cum' env, for an exponential smoothing.
  late Env prevEnv;

  Env getCurrentState(Env unstableEnv) {
    // For all values, take 0.5 of [prevEnv] and 0.5 of [unstableEnv].
    // Then update [prevEnv] to the result.

    final env = unstableEnv.copy();

    for (final car in env.cars) {
      car.position = prevEnv.
    }

  }
}