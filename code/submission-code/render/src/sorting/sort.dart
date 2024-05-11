import 'package:drender/drender.dart';
import 'package:drender/src/extensions.dart';
import 'package:drender/src/sorting/sort_tri_tri.dart';

import '../process_items.dart';

enum SortResult {
  AInfrontofB(),
  ABehindB(),
  None();

  const SortResult();

  SortResult opposite() {
    if (this == SortResult.AInfrontofB) return SortResult.ABehindB;
    if (this == SortResult.ABehindB) return SortResult.AInfrontofB;
    return this;
  }

  int get sortInt {
    if (this == SortResult.ABehindB) return -1;
    if (this == SortResult.AInfrontofB) return 1;
    return 0;
  }
}

SortResult compareProcessItem(
  ProcessItem a,
  ProcessItem b,
  CameraD camera,
) {
  final res = switch (a) {
    TriProcessItem() => switch (b) {
        TriProcessItem() => _sortTriTri(a, b, camera),
        GroupProcessItem() => _sortTriGroup(a, b, camera),
      },
    GroupProcessItem() => switch (b) {
        TriProcessItem() => _sortGroupTri(a, b, camera),
        GroupProcessItem() => _sortGroupGroup(a, b, camera),
      }
  };
  // print('sortresult: $res');
  return res;
}

SortResult _sortTriTri(
  TriProcessItem a,
  TriProcessItem b,
  CameraD camera,
) {
  // print('sort: ${a.label}, ${b.label}');
  // 1. First do crude 2D overlap check. If they do overlap, then do
  //    complex checking.
  final [aTri2D] = a.compile(camera);
  final [bTri2D] = b.compile(camera);
  // print('sortres: none bound');
  if (!aTri2D.vertices
      .computeBoundingBox()
      .overlaps(bTri2D.vertices.computeBoundingBox())) return SortResult.None;

  // print('sortres: parallel');
  // TODO: add epsilon to parallel check. leads to better results than if it falls back to one of the later tests.
  // TODO: Not sure if needed? check graphs.
  const parallelEpsilon = 0.001;
  // 2. Do one of five complete checks.
  if (a.vertices.isParallelWith(b.vertices, eps: parallelEpsilon)) {
    return sortTriTriParallel(a, b, camera);
  }

  // TODO: Preventing false overlaps by making these two conditions harder to be true. Now require slight overlap "epsilon" to be considered intersecting
  const overlapEpsilon = 0.001;
  final aOnLine =
      a.vertices.intersectsPlane(b.vertices.plane, eps: overlapEpsilon);
  final bOnLine =
      b.vertices.intersectsPlane(a.vertices.plane, eps: overlapEpsilon);

  // print('sortres: neither online');
  if (!aOnLine && !bOnLine) {
    return sortTriTriNeitherOnIntersectionLine(a, b, camera);
  }
  // print('sortres: online 1');
  if (aOnLine && !bOnLine) {
    return sortTriTriFirstOnIntersectionLine(a, b, camera);
  }
  // print('sortres: online 2');
  if (!aOnLine && bOnLine) {
    return sortTriTriSecondOnIntersectionLine(a, b, camera);
  }

  // print('sortres: both on line');
  return sortTriTriBothOnIntersectionLine(a, b, camera);
}

SortResult _sortTriGroup(
    TriProcessItem a, GroupProcessItem b, CameraD camera) {
  // print('sort: tri group');
  // Just check if group midpoint is infront / behind tri plane.
  if (b.midpoint.behind(a.vertices.plane)) return SortResult.AInfrontofB;
  if (b.midpoint.inFrontOf(a.vertices.plane)) return SortResult.ABehindB;
  return SortResult.None;
}

SortResult _sortGroupTri(
    GroupProcessItem a, TriProcessItem b, CameraD camera) {
  // print('sort: group tri');
  return _sortTriGroup(b, a, camera).opposite();
}

SortResult _sortGroupGroup(
    GroupProcessItem a, GroupProcessItem b, CameraD camera) {
  // print('sort: group group');
  // Midpoint to midpoint check? 😬
  return a.midpoint.distanceTo(camera.position) <
          b.midpoint.distanceTo(camera.position)
      ? SortResult.AInfrontofB
      : SortResult.ABehindB;
}
