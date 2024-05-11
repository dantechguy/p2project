import 'dart:ui';

import 'package:drender/src/sorting/dag_sorting.dart';
import 'package:drender/src/sorting/sort.dart';
import 'package:vector_math/vector_math.dart';
import 'package:drender/drender.dart';

import 'extensions.dart';
import 'projection.dart';
import 'render_items.dart';

sealed class ProcessItem {
  ProcessItem({this.label = ''});

  final String label;

  List<RenderItem> compile(
    CameraD camera,
  );

  Vector3 get midpoint;

  // TODO: swap parameter order. make sortedTree optional?
  ProcessItem sort(ProcessItem? prevSortedTree, CameraD camera);

  /// Removes and re-formats polygons for performance
  /// - Removes tris which face away from the camera
  /// - Removes tris which are behind the camera
  ///
  /// Returns a list of DrenderTree objects to replace this one.
  /// - No optimisation will return itself in a list.
  /// - A removed tri will be an empty list
  /// - A tri split into multiple will be several objects in a list.
  ///
  /// TODO: find out if optimise or sort first is faster
  List<ProcessItem> process(CameraD camera);
}

/// A SLRG. Contains a list of other
class GroupProcessItem extends ProcessItem {
  GroupProcessItem({
    super.label,
    required this.children,
  });

  List<ProcessItem> children;

  // TODO: implement this better
  @override
  Vector3 get midpoint =>
      children.map((e) => e.midpoint).reduce((c, e) => c + e) /
      children.length.toDouble();

  @override
  List<RenderItem> compile(CameraD camera) {
    return children.map((child) => child.compile(camera)).flatten().toList();
  }

  // TODO: implement
  @override
  ProcessItem sort(ProcessItem? prevSortedTree, CameraD camera) {
    for (final child in children) {
      // TODO: Pass down correct prevSortedTree
      child.sort(prevSortedTree, camera);
    }

    // TODO: Use prevSortedTree to speed up
    // children.sort((a, b) {
    //   final res = compareProcessItem(a, b, camera).sortInt;
    //   print('sortresult: $res');
    //   return res;
    // });

    children = sortPreorder(
      children,
      (a, b) => compareProcessItem(a, b, camera).sortInt,
    );

    return this;
  }

  @override
  List<ProcessItem> process(CameraD camera) {
    final List<ProcessItem> newChildren =
        children.map((e) => e.process(camera)).flatten().toList();

    if (newChildren.length <= 1) {
      return newChildren;
    } else {
      children = newChildren;
      return [this];
    }
  }
}

// TODO: add convex hull ProcessItem

class TriProcessItem extends ProcessItem {
  TriProcessItem({
    super.label,
    required this.vertices,
    required this.colour,
  });

  (Vector3, Vector3, Vector3) vertices;
  Color colour;

  @override
  Vector3 get midpoint => vertices.toList.reduce((c, x) => c + x) / 3;

  @override
  List<RenderTri> compile(CameraD camera) {
    return [
      RenderTri(
        vertices: vertices.map((v) => project3DTo2D(v, camera)),
        colour: colour,
        label: label,
      )
    ];
  }

  @override
  ProcessItem sort(ProcessItem? prevSortedTree, CameraD camera) {
    return this;
  }

  @override
  List<ProcessItem> process(CameraD camera) {
    final cameraPlane = camera.plane;

    // If tri is completely behind the camera, delete.
    // TODO: Make this culling distance a constant
    // TODO: Fix planeInfrontAlongNormal. It's broken!
    if (vertices.toList.every(
        (vertex) => vertex.behind(cameraPlane.planeInFrontAlongNormal(0.1)))) {
      return [];
    }

    // If tri faces away from the camera, delete.
    if (camera.position.behind(vertices.plane)) {
      return [];
    }

    // TODO: I think the discrepancy here and the split line is causing it to only return one tri from the split.
    // TODO: To fix, remove the prior check. Do the split immediately and if it returns non-null then continue. Or, just make sure that the prior check is the same as the proceding one.
    // TODO: although doing this causes a stackoverflow
    /* TODO:
        - actually this should be fine
        - i don't see why it would stackoverflow
     */
    if (vertices.intersectsPlane(cameraPlane)) {
      // TODO: make this forward split distance a constant
      final (tri1, tri2!, tri3!) =
          vertices.splitOnPlane(cameraPlane.planeInFrontAlongNormal(0.05));
      final tris = [tri1, tri2, tri3]
          .map((tri) => TriProcessItem(vertices: tri, colour: colour))
          .toList();
      return GroupProcessItem(children: tris).process(camera);
    }

    // Otherwise, return as normal.
    return [this];
  }
}
