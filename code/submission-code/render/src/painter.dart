import 'package:drender/drender.dart';
import 'package:drender/src/extensions.dart';
import 'package:drender/src/process_items.dart';

import 'package:drender/src/render_items.dart';
import 'package:drender/src/scene.dart';
import 'package:flutter/material.dart';

class DrenPainter extends CustomPainter {
  const DrenPainter({
    this.counter,
    required this.camera,
    required this.items,
  });

  final CameraD camera;
  final List<SceneItem> items;
  final int? counter;

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.drawCircle(
    //   Offset(size.width / 2, size.height / 2),
    //   50,
    //   Paint()
    //     ..color = Colors.red,
    // );
    canvas.drawColor(Colors.grey, BlendMode.src);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.clipRect(Rect.fromCenter(
        center: Offset.zero, width: size.width, height: size.height));

    // final path = Path();
    // canvas.drawLine(Offset(-size.width/2, 0), Offset(size.width/2, 0), Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // print('render');
    final List<RenderItem> renderItems = GroupProcessItem(
            children: items
                .map((item) => item.compile())
                .flatten()
                .map((pItem) => pItem.process(camera))
                .flatten()
                .toList())
        .sort(null, camera)
        .compile(camera)
        .toList();
    // print('rendered ${renderItems.length} items');
    final count = counter == null ? renderItems.length : counter! % (renderItems.length*1.4).toInt();
    // print(count);
    for (final r in renderItems.take(count)) {
      canvas.save();
      r.render(canvas, size);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
    throw UnimplementedError();
  }
}
