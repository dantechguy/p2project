
extension StreamExtension<T> on Stream<T> {
  Stream<T> printAll([String Function(T)? map]) async* {
    await for (final element in this) {
      print(map?.call(element) ?? element);
      yield element;
    }
  }
}