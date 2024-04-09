import 'dart:async';

import 'package:vector_math/vector_math.dart';

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

  List<T> copy() => toList();
}

extension DurationExtension on Duration {
  double get inSecondsReal => inMicroseconds / 1e6;
}

extension Vector2Extension on Vector2 {
  // TODO: test
  void changeAxis({Matrix2? from, required Matrix2 to}) {
    if (from != null) {
      final fromInverted = Matrix2.copy(from)..invert();
      fromInverted.transform(this);
    }
    to.transform(this);
  }

  Vector2 copy() => Vector2.copy(this);

  (double, double) toRecord() => (x, y);

  Vector2 rotatedCW(double radians) => Matrix2.rotation(-radians).transform(copy());

  List<double> toList() => [x, y];
}

Matrix2 Matrix2_rows(Vector2 arg0, Vector2 arg1) {
  return Matrix2.zero()..setRow(0, arg0)..setRow(1, arg1);
}