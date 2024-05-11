import 'dart:ui';
import 'package:drender/drender.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';

class RectangleItem extends SceneItem {
  RectangleItem.fromLengths({
    required double x,
    required double y,
    required Color colour,
    super.label
  })  : _lengthX = x,
        _lengthY = y,
        _colour = colour;

  final Color _colour;
  final double _lengthX;
  final double _lengthY;

  @override
  List<ProcessItem> compile() {
    return ScaleItem.vector(
      scale: Vector3(_lengthX, _lengthY, 1),
      child: SquareItem(colour: _colour, sideLength: 1),
    ).compile();
  }
}
