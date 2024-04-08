import 'package:blitz/server.dart';
import 'package:blitz/src/dart_extensions.dart';

class StreamSplitAndBuffer<T> {
  final List<T> _allData = [];

  List<T> get allData => _allData.copy();

  final StreamInserter<(int, T)> _inserter = StreamInserter();

  final Set<int> _ids = {};

  // This should all run within one zone, so no other async work can happen and intercept it. The only thing we have to ensure would be that no events are added to _allData anywhere between the start of the for loop, and adding the id to _ids.
  void addSplit(int id) {
    if (_ids.contains(id)) return;

    for (final data in _allData) {
      _inserter.add((id, data));
    }
    _ids.add(id);
  }

  // There may be events still in the stream pipeline going to that split after this has been called. We need to make sure
  void removeSplit(int id) {
    _ids.remove(id);
  }

  // TODO: where does it get its list of clients from
  // TODO: where does it get its splitter format from? hard bake

  Stream<(int, T)> split(Stream<T> stream) {
    return _inserter.insert(
      stream.expand((T data) {
        _allData.add(data);
        final duplicatedData = [for (final id in _ids) (id, data)];
        return duplicatedData;
      }),
    );
  }
}
