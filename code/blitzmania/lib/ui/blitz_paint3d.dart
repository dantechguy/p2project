import 'dart:math';

import 'package:drender/drender.dart';
import 'package:drender/src/process_items.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../state/state.dart';

class BlitzPaint3DWidget extends StatelessWidget {
  const BlitzPaint3DWidget({super.key, required this.state});

  final RacingState state;

  @override
  Widget build(BuildContext context) {
    return ViewDAR(
      camera: CameraD.lookingAt(
        position: Vector3(-10, 0, 2),
        lookPoint: Vector3(0, 0, 0),
        fov: 1000,
      ),
      items: [
        ShadeItem(
          ambientLight: Colors.white.withOpacity(.3),
          directionalLights: [
            (Vector3(1, .5, -3), Colors.white.withOpacity(.9)),
            // (Vector3(1, -2, -2), Colors.red.withOpacity(0.01)),
          ],
          child: DRenderGroup(
            children: [
              SquareItem(colour: Colors.blue.shade900, sideLength: 100),
              for (final car in state.cars)
                CarItem(
                  position: Vector3(car.position.x, car.position.y, 0),
                  rotation: car.direction,
                  steering: state.inputs
                      .firstWhere((e) => e.userId == car.userId)
                      .steering,
                  size: Vector3(car.size.width, car.size.height, 1),
                  colour: car.col,
                )
            ],
          ),
        ),
      ],
    );
  }
}

class CarItem extends SceneItem {
  CarItem({
    required this.position,
    required this.rotation,
    required this.steering,
    required this.size,
    required this.colour,
  });

  final Vector3 position;
  final double rotation;
  final double steering;
  final Vector3 size;
  final Color colour;

  @override
  List<ProcessItem> compile() {
    const carBodyHeight = 1.0;
    const wheelThickness = 0.5;
    const wheelRadius = 0.5;
    final wheelPositions = [
      (
        true,
        Vector3(-size.x * 0.6 - wheelThickness / 2, size.y * 0.5, wheelRadius)
      ),
      (
        true,
        Vector3(size.x * 0.6 + wheelThickness / 2, size.y * 0.5, wheelRadius)
      ),
      (
        false,
        Vector3(-size.x * 0.6 - wheelThickness / 2, -size.y * 0.4, wheelRadius)
      ),
      (false, Vector3(size.x * 0.6 + wheelThickness / 2, -size.y * 0.4, wheelRadius)),
    ];
    return DrenderLayer(children: [
      TransformItem.fromSRT(
        translate: position,
        rotate: Quaternion.axisAngle(
          CartesianAxis.positiveZ.unitVector,
          rotation,
        ),
        child: DRenderGroup(
            children: <SceneItem>[
          TranslateItem.fromVector(
            translate: Vector3(0, 0, wheelRadius + carBodyHeight / 2),
            child: CuboidItem.fromLengths(
                x: size.x, y: size.y, z: carBodyHeight, colour: colour),
          ),
          for (final (steer, wheelPos) in wheelPositions)
            TranslateItem.fromVector(
              translate: wheelPos,
              child: RotateItem.aroundAxis(
                axis: CartesianAxis.positiveZ,
                rotation: steer ? -steering * pi / 6 : 0,
                child: RotateItem.aroundAxis(
                  axis: CartesianAxis.positiveY,
                  rotation: pi / 2,
                  child: InvertItem(child:RegularPrismItem.fromRadiusHeight(
                    height: wheelThickness,
                    radius: wheelRadius,
                    colour: Colors.grey,
                    n: 16,
                  )),
                ),
              ),
            ),
        ].map((i) => DRenderGroup(children: [i])).toList()),
      )
    ]).compile();
  }
}
