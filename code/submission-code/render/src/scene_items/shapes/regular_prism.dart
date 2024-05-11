import 'dart:ui';
import 'package:drender/drender.dart';
import 'package:drender/src/extensions.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';

class RegularPrismItem extends SceneItem {
  RegularPrismItem.fromRadiusHeight({
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
  // TODO: this is inside out
  return [
    TranslateItem.fromVector(
      translate: Vector3(0, 0, -_height / 2),
      child: RegularPolygonItem.fromRadius(
        radius: _radius,
        colour: _colour,
        n: _numSides,
      ),
    ).compile(),
    RegularTubeItem.fromRadiusHeight(
      height: _height,
      radius: _radius,
      colour: _colour,
      n: _numSides,
    ).compile(),
    InvertItem(
      child: TranslateItem.fromVector(
        translate: Vector3(0, 0, _height / 2),
        child: RegularPolygonItem.fromRadius(
          radius: _radius,
          colour: _colour,
          n: _numSides,
        ),
      ),
    ).compile(),
  ].flatten().toList();
}}