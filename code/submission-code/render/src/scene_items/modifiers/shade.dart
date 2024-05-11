import 'dart:math';
import 'dart:ui';
import 'package:drender/drender.dart';
import 'package:drender/src/extensions.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';
import '../scene_item.dart';

class ShadeItem extends SceneItem {
  ShadeItem({
    Color? ambientLight,
    List<(Vector3, Color)>? directionalLights,
    List<(Vector3, double, Color)>? pointLights,
    required SceneItem child,
  })  : _child = child,
        _ambientLight = ambientLight,
        _directionalLights = directionalLights,
        _pointLights = pointLights;

  final Color? _ambientLight;
  final List<(Vector3, Color)>? _directionalLights;
  final List<(Vector3, double, Color)>? _pointLights;
  final SceneItem _child;

  @override
  List<ProcessItem> compile() {
    final pItems = _child.compile();
    pItems.forEach(_applyShadingRecursive);
    return pItems;
  }

// TODO: needs testing
  void _applyShadingRecursive(ProcessItem pItem) {
    // TODO: make switch case exhaustive (as in, wont compile w/out)
    switch (pItem) {
      case TriProcessItem():
        // TODO: finish implementing
        // https://learnopengl.com/Lighting/Basic-Lighting
        final components = [Vector4.zero()];
        if (_ambientLight != null) {
          final ambient = _calculateAmbientComponent(pItem);
          components.add(ambient);
        }
        if (_directionalLights != null && _directionalLights!.isNotEmpty) {
          final directional = [
            for (final (dir, col) in _directionalLights!)
              _calculateDiffuseComponent(pItem, (dir, col))
          ].reduce((c, e) => c + e);
          components.add(directional);
        }
        if (_pointLights != null && _pointLights!.isNotEmpty) {
          final point = [
            for (final (pos, col) in _directionalLights!)
              _calculateDiffuseComponent(pItem, (pItem.midpoint - pos, col))
          ].reduce((c, e) => c + e);
          components.add(point);
        }
        final render =
            pItem.colour.toVector().mult(components.reduce((c, e) => c + e));
        render.a = 1;
        pItem.colour = render.toColor();

      case GroupProcessItem():
        pItem.children.forEach(_applyShadingRecursive);

    }
  }

  Vector4 _calculateAmbientComponent(TriProcessItem pItem) {
    // render colour = ambient light strength * ambient light colour * object colour
    final ambientStrength = _ambientLight!.toVector().a;
    final ambientColour = _ambientLight!.toVector();
    final ambientComponent = ambientColour * ambientStrength;
    ambientComponent.a = 1;
    return ambientComponent;
  }

  Vector4 _calculateDiffuseComponent(
      TriProcessItem pItem, (Vector3, Color) lightRay) {
    // render colour = normal multiplier * light colour * object colour
    final (lightDirection, lightColour) = lightRay;
    double diffuseStrength =
        max(0, -lightDirection.normalized().dot(pItem.vertices.normal));
    diffuseStrength *= lightColour.toVector().a;
    final diffuseColour = lightColour.toVector();
    final diffuseComponent = diffuseColour * diffuseStrength;
    diffuseComponent.a = 1;
    return diffuseComponent;
  }
}
