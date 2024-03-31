import 'dart:async';

extension MapExtension<K, V> on Map<K, V> {
  List<V?> getAllNullable(List<K> keys) {
    return keys.map((key) => this[key]).toList();
  }

  List<V> getAll(List<K> keys) {
    containsAllKeysOrThrow(keys);
    return keys.map((key) => this[key]!).toList();
  }

  bool containsAllKeys(List<K> keys) {
    return keys.every((key) => containsKey(key));
  }

  void containsAllKeysOrThrow(List<K> keys) {
    if (!containsAllKeys(keys)) {
      throw FormatException(
          'JSON string does not contain all required keys: $keys');
    }
  }
}

extension IterableExtension<E> on Iterable<E> {
  (Iterable<E>, Iterable<E>) partition(bool Function(E) test) {
    final passed = <E>[];
    final failed = <E>[];
    for (final element in this) {
      if (test(element)) {
        passed.add(element);
      } else {
        failed.add(element);
      }
    }
    return (passed, failed);
  }

  List<E> sorted([int Function(E a, E b)? compare]) {
    return toList()..sort(compare);
  }
}

extension ListExtension<T> on List<T> {
  List<T> copy() => toList();

  List<T> operator*(int n) {
    List<T> res = [];
    for (int i = 0; i < n; i++) {
      res.addAll(this);
    }
    return res;
  }
}

extension StringExtension on String {
  List<String> splitFirst(Pattern pattern) {
    final pieces = split(pattern);
    if (pieces.length <= 1) return pieces;
    return [pieces[0]] + [pieces.skip(1).join('')];
  }
}

extension StreamExtension<T> on Stream<T> {
  Stream<T> handleOnDone(void Function() onDone) async* {
    await for (final T obj in this) {
      yield obj;
    }
    onDone();
  }

}

extension StreamControllerExtension<T> on StreamController<T> {
  void addAll(Iterable<T> elements) {
    for (final element in elements) {
      add(element);
    }
  }
}
