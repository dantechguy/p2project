import 'dart:async';

import 'package:async/async.dart';

// TODO: merge into StreamInterceptor?
class StreamInserter<T> {
  final List<StreamController<T>> _controllers = [];

  void add(T element) {
    for (final controller in _controllers) {
      controller.add(element);
    }
  }

  void close() {
    for (final controller in _controllers) {
      controller.close();
    }
  }

  Stream<T> insert(Stream<T> stream) {
    final controller = StreamController<T>();
    _controllers.add(controller);
    return StreamGroup.merge([stream, controller.stream]);
  }
}
