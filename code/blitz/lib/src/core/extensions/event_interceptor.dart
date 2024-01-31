import 'dart:async';


typedef WheneverEntry<Event> = (
  bool Function(Event) test,
  dynamic Function(Event) callback,
);

typedef WaitUntilEntry<Event> = (
  bool Function(Event) test,
  Completer<dynamic> completer,
  dynamic Function(Event)? mapper,
  Timer timeoutTimer
);

class EventInterceptor<Event> {
  final Set<WheneverEntry<Event>> _wheneverEntries = {};
  final Set<WaitUntilEntry<Event>> _waitUntilEntries = {};

  Future<T> waitUntil<T>(bool Function(Event) test,
      {T Function(Event)? mapper, required Duration timeout}) async {
    final completer = Completer<T>();
    late WaitUntilEntry<Event> Function() getEntry;
    final timer = Timer(timeout, () {
      completer.completeError(TimeoutException(
          'Timed out waiting for event that matches test condition.'));
      _removeEntry(getEntry());
    });
    final entry = (test, completer, mapper, timer);
    getEntry = () => entry;
    _waitUntilEntries.add(entry);
    return completer.future;
  }

  void whenever<T>(bool Function(Event) test, T Function(Event) callback) {
    _wheneverEntries.add((test, callback));
  }

  // Rename to something more accurate
  Stream<Event> interceptEvents(Stream<Event> eventStream) async* {
    await for (final Event event in eventStream) {
      final waitUntilSuccess = _waitUntilEntries.where((tc) => tc.$1(event));
      for (final entry in waitUntilSuccess) {
        final (_, completer, mapper, _) = entry;
        completer.complete(mapper?.call(event) ?? event);
        _removeEntry(entry);
      }

      final wheneverSuccesses = _wheneverEntries.where((tc) => tc.$1(event));
      for (final entry in wheneverSuccesses) {
        final (_, callback) = entry;
        callback(event);
      }

      if (waitUntilSuccess.isEmpty && wheneverSuccesses.isEmpty) {
        yield event;
      }
    }
  }

  void _removeEntry(WaitUntilEntry<Event> entry) {
    entry.$4.cancel();
    _waitUntilEntries.remove(entry);
  }
}
