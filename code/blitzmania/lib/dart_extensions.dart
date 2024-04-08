import 'dart:async';

extension StreamExtension<T> on Stream<T> {
  Stream<T> printAll([String Function(T)? map]) async* {
    await for (final element in this) {
      print(map?.call(element) ?? element);
      yield element;
    }
  }

  Stream<T> listenAndBuffer() {
    var controller = StreamController<T>(sync: true);
    var subscription = listen(controller.add,
        onError: controller.addError, onDone: controller.close);
    controller
      ..onPause = subscription.pause
      ..onResume = subscription.resume
      ..onCancel = subscription.cancel;
    return controller.stream;
  }
}

extension StringExtension on String {
  String splitAfterFirst(String pattern) {
    return splitAfterN(pattern, 1);
  }

  String splitAfterN(String pattern, int n) {
    final pieces = split(pattern);
    return pieces.skip(n).join(pattern);
  }

  String indent(int n) =>
      split('\n').map((line) => ('  ' * n) + line).join('\n');
}

extension ListExtension<T> on List<T> {
  String toPrettyString({String indent = ''}) {
    if (isEmpty) return '[]';
    final middle =
        map((e) => ((e is List) ? e.toPrettyString() : e.toString()).indent(1))
            .join(',\n');
    return '[\n$middle\n]';
  }
}
