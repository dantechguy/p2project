import 'dart:ui';
import 'package:drender/src/camera.dart';
import 'package:vector_math/vector_math.dart';

Offset project3DTo2D(Vector3 point3D, CameraD camera) {
  var point = Vector3.copy(point3D);
  point -= camera.position;
  // camera.rotation.rotate(point);
  camera.rotation.inverted().rotate(point);

  // A quaternion is just a rotation, so the zero-direction is defined
  // by where you look after the transformation. We assume at position
  // (0, 0, 0), facing +X, with +Y to our left, and +Z above us.
  //
  // This is a +Z up, right-handed coordinate system.
  //
  // We can map arbitrary directions to each axis:
  // +X and -X = North and South
  // +Y and -Y = East and West
  // +Z and -Z = Up and Down


  /* TODO:
      - incorporate FOV
      - the quaternion representing the camera isn't being used properly.
        it should represent the direction the camera is facing, and a rotation.
        but atm it represents a rotation from the +X facing direction.
  */

  // Top-down othographic projection
  // return Offset(point.y * 10, -point.x * 10);

  return Offset(point.y/point.x*camera.fov, -point.z/point.x*camera.fov);
}