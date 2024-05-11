

import 'dart:ui';
import 'package:drender/drender.dart';

import '../../process_items.dart';

class TriangleItem extends SceneItem {
  // TODO: Add convenience SRT constructor args to all SceneItem shapes
  // TODO: for flat items, maybe add a .facing named constructor?
  TriangleItem({
    required Color colour,
    required double sideLength,
    super.label,
}) : _colour = colour,
  _sideLength = sideLength;

  final Color _colour;
  final double _sideLength;

  @override
  List<ProcessItem> compile() {
    return RegularPolygonItem.fromSideLength(
      sideLength: _sideLength,
      colour: _colour,
      n: 3,
    ).compile();
  }
}