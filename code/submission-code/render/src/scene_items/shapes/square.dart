import 'dart:math';
import 'dart:ui';
import 'package:drender/drender.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';


class SquareItem extends SceneItem {
  SquareItem({
    required Color colour,
    required double sideLength,
    super.label = 'sq',
  }) : _colour = colour,
        _sideLength = sideLength;

  final Color _colour;
  final double _sideLength;

  @override
  List<ProcessItem> compile() {
    return RegularPolygonItem.fromSideLength(
      sideLength: _sideLength,
      colour: _colour,
      n: 4,
      label: label,
    ).compile();
  }
}
