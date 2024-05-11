import 'dart:ui';
import 'package:drender/drender.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';

class CuboidItem extends SceneItem {
  CuboidItem.fromLengths({
    required double x,
    required double y,
    required double z,
    required Color colour,
    super.label,
  })  : _lengthX = x,
        _lengthY = y,
        _lengthZ = z,
        _colour = colour;

  final Color _colour;
  final double _lengthX;
  final double _lengthY;
  final double _lengthZ;

  @override
  List<ProcessItem> compile() {
    return ScaleItem.vector(
      scale: Vector3(_lengthX, _lengthY, _lengthZ),
      child: CubeItem.fromSize(
        size: 1,
        colour: _colour,
      ),
    ).compile();
  }
}
