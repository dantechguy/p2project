import 'package:drender/drender.dart';
import 'dart:math';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';

enum CartesianAxis {
  positiveX(),
  negativeX(),
  positiveY(),
  negativeY(),
  positiveZ(),
  negativeZ();

  factory CartesianAxis.up() => CartesianAxis.positiveZ;
  factory CartesianAxis.down() => CartesianAxis.negativeZ;
  factory CartesianAxis.north() => CartesianAxis.positiveX;
  factory CartesianAxis.south() => CartesianAxis.negativeX;
  factory CartesianAxis.east() => CartesianAxis.positiveY;
  factory CartesianAxis.west() => CartesianAxis.negativeY;

  factory CartesianAxis.posZ() => CartesianAxis.positiveZ;
  factory CartesianAxis.negZ() => CartesianAxis.negativeZ;
  factory CartesianAxis.posX() => CartesianAxis.positiveX;
  factory CartesianAxis.negX() => CartesianAxis.negativeX;
  factory CartesianAxis.posY() => CartesianAxis.positiveY;
  factory CartesianAxis.negY() => CartesianAxis.negativeY;

  String get cardinalName => switch (this) {
    CAxis.positiveZ => 'up',
    CAxis.negativeZ => 'down',
    CAxis.positiveX => 'north',
    CAxis.negativeX => 'south',
    CAxis.positiveY => 'east',
    CAxis.negativeY => 'west',
  };


  Vector3 get unitVector => switch (this) {
        CAxis.positiveX => Vector3(1, 0, 0),
        CAxis.negativeX => Vector3(-1, 0, 0),
        CAxis.positiveY => Vector3(0, 1, 0),
        CAxis.negativeY => Vector3(0, -1, 0),
        CAxis.positiveZ => Vector3(0, 0, 1),
        CAxis.negativeZ => Vector3(0, 0, -1),
      };
}

typedef CAxis = CartesianAxis;

// Allow Quaternion rotationFromPosZ, pointAndRotate, and CartesianAxis

class RotateItem extends SceneItem {
  RotateItem.byQuaternion({
    required Quaternion rotate,
    required SceneItem child,
  })  : _rotation = rotate.clone(),
        _child = child;

  RotateItem.aroundAxis({
    required CAxis axis,
    required double rotation,
    required SceneItem child,
  })  : _rotation = Quaternion.axisAngle(axis.unitVector, rotation),
        _child = child;

  RotateItem.flip({
    required Vector3 axis,
    required SceneItem child,
}) : _rotation = Quaternion.axisAngle(axis, pi),
  _child = child;

  final SceneItem _child;
  final Quaternion _rotation;

  @override
  List<ProcessItem> compile() {
    return TransformItem.fromSRT(
      rotate: _rotation,
      child: _child,
    ).compile();
  }
}
