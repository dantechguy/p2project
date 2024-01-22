import 'package:blitz/core.dart';
import 'package:blitz/extensions.dart';
import 'package:blitz/src/core/events/event_ids.dart' show EventIDGenerator;
import 'package:test/test.dart';

int driver(int state, List<Event> events) {
  if (events.isEmpty) return state;
  return events.map((e) {
    try {
      return int.parse(e.data);
    } on FormatException {
      return 0;
    }
  }).reduce((a, b) => a + b);
}

void main() {
  test('State runs all events', () {
    final initialState = 0;
    final expectedState = 6;
    final events = [
      for (int i in [1, 2, 3])
        Event(
            serverReceiptTimestamp: Duration.zero,
            generatedTimestamp: Duration.zero,
            senderID: 0,
            data: i.toString(),
            eventID: 0,
            isServerConfirmed: true),
    ];
    final func = runUnstableEvents(
      driver: driver,
      getStableState: () => initialState,
      getUnstableEvents: () => events,
    );
    final newState = func();
    expect(newState, 6);
  });

  test('State unchanged if no events', () {
    final initialState = 0;
    final func = runUnstableEvents(
      driver: driver,
      getStableState: () => initialState,
      getUnstableEvents: () => [],
    );
    final newState = func();
    expect(newState, initialState);
  });
}
