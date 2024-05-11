import 'dart:math';
import 'dart:ui';
import 'package:drender/src/extensions.dart';
import 'package:vector_math/vector_math.dart';

import '../../key.dart';
import 'package:drender/drender.dart';

import '../../process_items.dart';

// Use 'Square'

class CubeItem extends SceneItem {
  CubeItem.fromSize({
    required double size,
    required Color colour,
    Map<CAxis, Color> faceColours = const {},
    super.label,
  })  : _colour = colour,
        _sideLength = size,
        _faceColours = faceColours;

  final double _sideLength;
  final Color _colour;
  final Map<CAxis, Color> _faceColours;

  @override
  List<ProcessItem> compile() {
    final List<(CAxis, double, String)> rotations = [
      (CAxis.positiveX, pi / 2, 'east'),
      (CAxis.positiveX, -pi / 2, 'west'),
      (CAxis.positiveY, pi / 2, 'north'),
      (CAxis.positiveY, -pi / 2, 'south'),
      (CAxis.positiveY, pi, 'down'),
      (CAxis.positiveY, 0, 'up'),
    ];
    final List<SceneItem> faces = [
      for (final (axis, rotation, name) in rotations)
        RotateItem.aroundAxis(
          axis: axis,
          rotation: rotation,
          child: TranslateItem.fromVector(
            translate: Vector3(0, 0, _sideLength / 2),
            child: SquareItem(
              colour: _faceColours[axis] ?? _colour,
              sideLength: _sideLength,
              label: name[0],
            ),
          ),
        )
    ];
    return faces
        .map((e) => e.compile())
        .flatten()
        .toList();
  }
}
