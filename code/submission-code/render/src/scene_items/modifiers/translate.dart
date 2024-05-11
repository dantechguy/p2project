
// Use transform
import 'package:drender/drender.dart';

import 'package:vector_math/vector_math.dart';

import '../../process_items.dart';

class TranslateItem extends SceneItem {
  TranslateItem.fromVector({
    required Vector3 translate,
    required SceneItem child,
  }) : _translation = translate.clone(),
        _child = child;

  final SceneItem _child;
  final Vector3 _translation;

  @override
  List<ProcessItem> compile() {
    return TransformItem.fromSRT(
      translate: _translation,
      child: _child,
    ).compile();
  }
}
