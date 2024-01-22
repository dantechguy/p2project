import 'package:blitz/src/core/events/event_ids.dart' show EventIDGenerator;
import 'package:test/test.dart';

void main() {
  test('Generated event IDs should be unique.', () {
    final idGenerator = EventIDGenerator();
    final generatedIDs = <dynamic>{};

    // Generate 1000 IDs and check all unique.
    for (int i = 0; i < 1000; i++) {
      final id = idGenerator.generateUniqueID();
      expect(generatedIDs.contains(id), false);
      generatedIDs.add(id);
    }
  });
}