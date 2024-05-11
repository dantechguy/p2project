import 'dart:math';
import 'dart:ui';
import 'package:drender/drender.dart';
import 'package:drender/src/extensions.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';

class RegularTubeItem extends SceneItem {
  RegularTubeItem.fromRadiusHeight({
    required double height,
    required double radius,
    required Color colour,
    required int n,
    super.label,
}) : _height = height,
  _radius = radius,
  _colour = colour,
  _numSides = n;

  final double _height;
  final double _radius;
  final Color _colour;
  final int _numSides;

  @override
  List<ProcessItem> compile() {
    final n = _numSides;
    final h = _height / 2;
    final r = _radius;

    final angleDelta = 2 * pi / n;
    // vertices
    List<Vector3> v = [
      for (double i = pi / n; i < 2 * pi; i += angleDelta)
        Vector3(sin(i), cos(i), 0) * r
    ];

    return [
      for (int i = 0; i < n; i++)
        QuadItem(
          colour: _colour,
          vertices: (
            Vector3(v[i].x, v[i].y, h),
            Vector3(v[(i + 1) % n].x, v[(i + 1) % n].y, h),
            Vector3(v[(i + 1) % n].x, v[(i + 1) % n].y, -h),
            Vector3(v[i].x, v[i].y, -h),
          ),
        ).compile()
    ].flatten().toList();
  }
}
