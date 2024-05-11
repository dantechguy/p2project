import 'dart:ui';
import 'package:drender/drender.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';

class QuadItem extends SceneItem {
  QuadItem({
    required Color colour,
    required (Vector3, Vector3, Vector3, Vector3) vertices,
    super.label
  })  : _colour = colour,
        _v = vertices;

  final Color _colour;
  final (Vector3, Vector3, Vector3, Vector3) _v;

  @override
  List<ProcessItem> compile() {
    return [
      TriProcessItem(vertices: (_v.$1, _v.$2, _v.$3), colour: _colour),
      TriProcessItem(vertices: (_v.$3, _v.$4, _v.$1), colour: _colour),
    ];
  }
}
