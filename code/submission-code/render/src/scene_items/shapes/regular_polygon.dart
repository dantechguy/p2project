import 'dart:math';
import 'package:drender/drender.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../../process_items.dart';

class RegularPolygonItem extends SceneItem {
  // TODO: shouldnt the "from" format *not* have named parameters?
  RegularPolygonItem.fromSideLength({
    required double sideLength,
    required Color colour,
    required int n,
    String label = '',
  }) : this.fromRadius(
            radius: sideLength / (2 * sin(2 * pi / n / 2)),
            colour: colour,
            n: n,
            label: label);

  RegularPolygonItem.fromRadius({
    required double radius,
    required Color colour,
    required int n,
    super.label,
  })  : assert(n >= 3, 'Polygon must have ≥ 3 sides ($n given)'),
        assert(radius > 0, 'Radius must be positive ($radius given)'),
        _radius = radius,
        _colour = colour,
        _numSides = n;

  final Color _colour;
  final double _radius;
  final int _numSides;

  @override
  List<ProcessItem> compile() {
    final angleDelta = 2 * pi / _numSides;

    List<Vector3> vertices = [
      for (double i = pi / _numSides; i < 2 * pi; i += angleDelta)
        Vector3(-sin(i), cos(i), 0) * _radius
    ].reversed.toList();

    List<TriProcessItem> tris = [
      for (int i = 0; i < _numSides - 2; i++)
        TriProcessItem(
          vertices: (vertices[0], vertices[i + 1], vertices[i + 2]),
          colour: _colour,
          // colour: Color.lerp(_colour, Colors.black, i / _numSides)!,
          label: '$label$i',
        )
    ];
    return tris;
  }
}
