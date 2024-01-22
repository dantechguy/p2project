import 'dart:async';

import 'package:blitz/core.dart';

typedef Entry = (
  bool Function(Event) test,
  Completer<dynamic> completer,
  dynamic Function(Event)? mapper,
  Timer timeoutTimer
);

class EventResponder {
  final Set<Entry> _entries = {};

  Future<T> waitUntil<T>(bool Function(Event) test,
      {T Function(Event)? mapper, required Duration timeout}) async {
    final completer = Completer<T>();
    late Entry Function() getEntry;
    final timer = Timer(timeout, () {
      completer.completeError(TimeoutException(
          'Timed out waiting for event that matches test condition.'));
      _removeEntry(getEntry());
    });
    final entry = (test, completer, mapper, timer);
    getEntry = () => entry;
    _entries.add(entry);
    return completer.future;
  }

  Stream<Event> interceptTimeSyncEvents(Stream<Event> eventStream) async* {
    await for (final Event event in eventStream) {
      final successes = _entries.where((tc) => tc.$1(event));
      for (var entry in successes) {
        final (_, completer, mapper, _) = entry;
        completer.complete(mapper?.call(event) ?? event);
        _removeEntry(entry);
      }
      if (successes.isEmpty) {
        yield event;
      }
    }
  }

  void _removeEntry(Entry entry) {
    entry.$4.cancel();
    _entries.remove(entry);
  }
}
