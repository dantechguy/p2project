import 'package:drender/src/camera.dart';
import 'package:drender/src/extensions.dart';
import 'package:vector_math/vector_math.dart';
import 'package:drender/drender.dart';

import '../process_items.dart';
import 'sort.dart';

SortResult sortTriTriParallel(
    TriProcessItem a, TriProcessItem b, CameraD camera) {
  // final aDist = camera.plane.distanceToVector3(a.vertices.$1);
  // final bDist = camera.plane.distanceToVector3(b.vertices.$1);
  //
  // if (aDist > 0 != bDist > 0) return SortResult.None;
  // return (aDist > 0) == (aDist < bDist)
  //     ? SortResult.AInfrontofB
  //     : SortResult.ABehindB;

  // print('sortres: parallel: coplanar');
  // If coplanar then no ordering
  // TODO: extract constant
  if ((a.vertices.plane.constant - b.vertices.plane.constant).abs() < 0.01) {
    return SortResult.None;
  }

  // TODO: This bug could be caused by trying to sort with a total order algorithm on a partial order.

  final otherSideOfA = a.vertices.plane.allOnSameSideOfPlane([camera.position, b.vertices.$1]);
  final otherSideOfB = b.vertices.plane.allOnSameSideOfPlane([camera.position, a.vertices.$1]);

  // print('sortres: parallel: $otherSideOfA, $otherSideOfB');

  if (otherSideOfA && !otherSideOfB) return SortResult.ABehindB;
  if (!otherSideOfA && otherSideOfB) return SortResult.AInfrontofB;
  return SortResult.None;
}

SortResult sortTriTriNeitherOnIntersectionLine(
    TriProcessItem a, TriProcessItem b, CameraD camera) {
  final bPlane = b.vertices.plane;
  final aInFrontOfB = a.vertices.$1.inFrontOf(bPlane);
  final cameraInFrontOfB = camera.position.inFrontOf(bPlane);
  final aSameSideAsCamera = aInFrontOfB == cameraInFrontOfB;

  final aPlane = a.vertices.plane;
  final bInFrontOfA = b.vertices.$1.inFrontOf(aPlane);
  final cameraInFrontOfA = camera.position.inFrontOf(aPlane);
  final bSameSideAsCamera = bInFrontOfA == cameraInFrontOfA;

  if (aSameSideAsCamera == bSameSideAsCamera) return SortResult.None;
  return aSameSideAsCamera ? SortResult.AInfrontofB : SortResult.ABehindB;
}

SortResult sortTriTriFirstOnIntersectionLine(
    TriProcessItem a, TriProcessItem b, CameraD camera) {
  return a.vertices.plane.allOnSameSideOfPlane([camera.position, b.vertices.$1])
      ? SortResult.ABehindB
      : SortResult.AInfrontofB;
}

SortResult sortTriTriSecondOnIntersectionLine(
    TriProcessItem a, TriProcessItem b, CameraD camera) {
  return sortTriTriFirstOnIntersectionLine(b, a, camera).opposite();
}

// TODO: needs big testing.
SortResult sortTriTriBothOnIntersectionLine(
    TriProcessItem a, TriProcessItem b, CameraD camera) {
  final line = a.vertices.normal.cross(b.vertices.normal).normalized();

  final aPlane = a.vertices.plane;
  final bPlane = b.vertices.plane;

  // TODO: Handle the case where one edge is parallel to the line


  // TODO: make this a constant, or change how this works to be more robust?
  const planeThicknessEpsilon = 0.001;

  final aIntersectingEdges =
      a.vertices.edgeList.where((edge) => edge.intersectsOrMeetsPlane(bPlane, eps: planeThicknessEpsilon)).take(2);
  final bIntersectingEdges =
      b.vertices.edgeList.where((edge) => edge.intersectsOrMeetsPlane(aPlane, eps: planeThicknessEpsilon)).take(2);

  assert(aIntersectingEdges.length == 2);
  assert(bIntersectingEdges.length == 2);

  // Collection of records of an intersecting edge, its point of intersection
  // with the i-line, and that point's dot-product distance.
  final List<
      ({
        bool isTriA,
        (Vector3, Vector3) edge,
        Vector3 point,
        double distance
      })> edgePointDistance = aIntersectingEdges
          .map((edge) => (edge: edge, point: edge.intersectPlane(bPlane)))
          .map((rec) => (
                isTriA: true,
                edge: rec.edge,
                point: rec.point,
                distance: rec.point.dot(line)
              ))
          .toList() +
      bIntersectingEdges
          .map((edge) => (edge: edge, point: edge.intersectPlane(aPlane)))
          .map((rec) => (
                isTriA: false,
                edge: rec.edge,
                point: rec.point,
                distance: rec.point.dot(line)
              ))
          .toList();
  edgePointDistance.sort((a, b) => a.distance.compareTo(b.distance));

  // An invalid configuration, which can occur when the tris overlap.
  if (edgePointDistance[0].isTriA == edgePointDistance[3].isTriA) {
    // return edgePointDistance[0].isTriA
    //     ? SortResult.AInfrontofB
    //     : SortResult.ABehindB;
    return SortResult.None;
  }

  final aIntersectionPoint = edgePointDistance[0].isTriA
      ? edgePointDistance[0].point
      : edgePointDistance[3].point;
  final aMiddleEdge =
      edgePointDistance[1].isTriA ? edgePointDistance[1] : edgePointDistance[2];
  final bMiddleEdge = !edgePointDistance[1].isTriA
      ? edgePointDistance[1]
      : edgePointDistance[2];

  final separationPlane = Plane_fromNormalAndPoint(
    aMiddleEdge.edge.direction.cross(bMiddleEdge.edge.direction),
    aMiddleEdge.edge.$1,
  );

  return separationPlane
          .allOnSameSideOfPlane([camera.position, aIntersectionPoint])
      ? SortResult.AInfrontofB
      : SortResult.ABehindB;
}
