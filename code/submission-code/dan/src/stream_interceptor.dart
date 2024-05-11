import 'dart:async';
import 'package:blitz/src/dart_extensions.dart';

typedef WheneverEntry<T> = (
  bool Function(T) test,
  void Function(T) callback,
  bool passThrough,
);

typedef WaitUntilEntry<T> = (
  bool Function(T) test,
  Completer<T> completer,
  bool passThrough,
  Timer? timeoutTimer,
);

class StreamInterceptor<T> {
  // Insert order matters
  final List<dynamic> _entries = [];

  // TODO: Remove successMap. Just modify the result. And rename failMap to passThroughMap.
  Future<T> waitUntil(
    bool Function(T) test, {
    required bool passThrough,
    Duration? timeout,
        String? name,
  }) {
    final completer = Completer<T>();
    late WaitUntilEntry<T> Function() getEntry;
    late final Timer? timer;
    if (timeout == null) {
      timer = null;
    } else {
      // TODO: Consider using Future.timeout instead
      timer = Timer(timeout, () {
        completer.completeError(TimeoutException(
            'Timed out waiting for matching stream element: $name'));
        _removeWaitUntilEntry(getEntry());
      });
    }
    final entry = (test, completer, passThrough, timer);
    getEntry = () => entry;
    _entries.add(entry);
    return completer.future;
  }

  void whenever(
    bool Function(T) test,
    void Function(T) callback, {
    required bool passThrough,
  }) {
    _entries.add((test, callback, passThrough));
  }

  // Cycles through entries in order of addition.
  // If [passThrough] is false, stops on first match.
  // If no matches, it passes the event on.
  // If [failMap] is set, it passes that result.
  Stream<T> intercept(Stream<T> stream) async* {
    await for (T event in stream) {
      bool shouldYield = true;

      for (final entry in _entries.copy()) {
        if (entry is WaitUntilEntry<T>) {
          final (test, completer, passThrough, _) = entry;
          if (test(event)) {
            // Remove first, then complete, in case timer triggers and calls completeError inbetween completing and removing. Not sure if a valid concern.
            _removeWaitUntilEntry(entry);
            completer.complete(event);
            if (!passThrough) {
              shouldYield = false;
              break;
            }
          }
        } else if (entry is WheneverEntry<T>) {
          final (test, callback, passThrough) = entry;
          if (test(event)) {
            callback(event);
            if (!passThrough) {
              shouldYield = false;
              break;
            }
          }
        } else {
          throw ArgumentError(
              'StreamInterceptor, entry of impossible type: $entry');
        }
      }

      if (shouldYield) {
        yield event;
      }
    }
  }

  void _removeWaitUntilEntry(WaitUntilEntry<T> entry) {
    entry.$4?.cancel();
    _entries.remove(entry);
  }
}
