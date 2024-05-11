import 'package:drender/src/extensions.dart';
import 'package:vector_math/vector_math.dart';
import 'package:drender/drender.dart';
import '../../process_items.dart';
import '../scene_item.dart';

class TransformItem extends SceneItem {
  TransformItem.fromSRT({
    Vector3? scale,
    Quaternion? rotate,
    Vector3? translate,
    required SceneItem child,
  })  : _scale = scale?.clone(),
        _rotation = rotate?.clone(),
        _translation = translate?.clone(),
        _child = child;

  final SceneItem _child;
  final Vector3? _scale;
  final Quaternion? _rotation;
  final Vector3? _translation;

  @override
  List<ProcessItem> compile() {
    final pItems = _child.compile();
    // print('transform compile $pItems');
    pItems.forEach(_applyTransformRecursive);
    return pItems;
  }

  void _applyTransformRecursive(ProcessItem pItem) {
    // print('apply transform');
    switch (pItem) {
      case TriProcessItem():
        // print('transform before: ${pItem.vertices}');
        if (_scale != null)
          pItem.vertices = pItem.vertices.scaleByVector(_scale!);
        if (_rotation != null)
          pItem.vertices = pItem.vertices.rotateByQuaternion(_rotation!);
        if (_translation != null)
          pItem.vertices = pItem.vertices.translateByVector(_translation!);
        // print('transform after: ${pItem.vertices}');
      case GroupProcessItem():
        pItem.children.map(_applyTransformRecursive);
        // print('transform:');
    }
  }
}
