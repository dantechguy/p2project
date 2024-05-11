import 'package:blitz/server.dart';
import 'package:blitz/src/dart_extensions.dart';

class StreamSplitAndBuffer<T> {
  StreamSplitAndBuffer();

  // TODO: thought about connecting to reconnection module. have this module expose it's 'buffer'

  // TODO: Or, the reconnection module tells this module which events to buffer. then whenever the reconnection module updates its saved state, it can increase the minimum timestamp for events to be sent. this way buffered events are handled with this module, and initial state is handled with reconnection module. This would all be done synchronously, so both modules would be aligned.

  set bufferFilter(bool Function(T)? value) {
    _bufferFilter = value;
    applyBufferFilter();
  }

  void applyBufferFilter() {
    if (_bufferFilter == null) return;
    _allData.retainWhere(_bufferFilter!);
  }

  bool Function(T)? _bufferFilter;

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
