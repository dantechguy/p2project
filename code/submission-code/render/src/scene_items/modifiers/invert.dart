import 'package:drender/drender.dart';
import '../../process_items.dart';
import '../scene_item.dart';

/// Flips the direction of all tris (reverses normal)
class InvertItem extends SceneItem {
  InvertItem({
    required SceneItem child,
  }) : _child = child;

  final SceneItem _child;

  @override
  List<ProcessItem> compile() {
    final pTree = _child.compile();
    pTree.forEach(_applyInvertRecursive);
    return pTree;
  }

  void _applyInvertRecursive(ProcessItem pTree) {
    switch (pTree) {
      case TriProcessItem():
        pTree.vertices =
            (pTree.vertices.$1, pTree.vertices.$3, pTree.vertices.$2);
      case GroupProcessItem():
        pTree.children.map(_applyInvertRecursive);
    }
  }
}
