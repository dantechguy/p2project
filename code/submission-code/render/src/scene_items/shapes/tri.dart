import 'dart:ui';
import 'package:drender/drender.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';

class TriItem extends SceneItem {
  TriItem({
    required Color colour,
    required (Vector3, Vector3, Vector3) vertices,
    super.label,
  })  : _colour = colour,
        vertices = vertices;

  final Color _colour;
  // TODO: make back private
  final (Vector3, Vector3, Vector3) vertices;

  @override
  List<ProcessItem> compile() {
    return [
      TriProcessItem(
        vertices: vertices,
        colour: _colour,
      )
    ];
  }
}
