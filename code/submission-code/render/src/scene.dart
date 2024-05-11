import 'package:flutter/material.dart';
import 'package:drender/drender.dart';


typedef DrenderPaintCallback = void Function(
    Canvas canvas,
    Size size,
    CameraD camera,
    );

class SceneDAR {
  SceneDAR({
    required this.items,
  });

  final List<SceneItem> items;

  /* TODO
    - background and foreground paint callback (incl camera)
    - custom render objects with callback which you can insert yourself
    without these two helper funcs, this class is useless.
   */
}

/* TODO
    - Purpose is to be a general, *nice*, extensible interface for
      adding geometry to a scene. Supports flipping, stretching geometry,
      loading from files, etc.
    - Have pre-built shapes like cube, pyramid, etc.
    - Have all support transform/translate, and add convenience methods
      to the group
    - OR! it can simply apply them directly to the DrenderTree results it
      gets back from its children when running `computeTree`
 */



