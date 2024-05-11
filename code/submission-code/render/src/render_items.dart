import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

sealed class RenderItem {
  RenderItem({this.label = ''});
  final String label;

  void renderLabel(Canvas canvas, Size size, Offset position) {
    if (label.isEmpty) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, position);
  }
  
  void render(Canvas canvas, Size size);
}

class RenderTri extends RenderItem {
  RenderTri({
    required this.vertices,
    required this.colour,
    super.label,
  });

  // TODO: Allow passing Paint() instead for more control.
  final Color colour;
  final (Offset, Offset, Offset) vertices;

  @override
  void render(Canvas canvas, Size size) {

    // TODO: fix until https://github.com/flutter/flutter/issues/145229 fixed
    // Rect bound = Rect.fromCenter(center: Offset.zero, width: 1000, height: 1000);
    // final tris = [vertices.$1, vertices.$2, vertices.$3].map((tri) => tri.clamp(bound)).toList();
    final tris = [vertices.$1, vertices.$2, vertices.$3];

    canvas.drawVertices(
      Vertices(
        VertexMode.triangles,
        tris,
      ),
      BlendMode.src,
      Paint()..color = colour,
    );
    // renderLabel(canvas, size, vertices.midpoint);

    // print('trirender $tris');
    // var col = Colors.black;
    // col = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

    // canvas.save();
    // final random = math.Random();
    // final dx = random.nextDouble() * 4 - 2;
    // final dy = random.nextDouble() * 4 - 2;
    // canvas.translate(dx, dy);

    // final path = Path();
    // path.moveTo(vertices.$1.dx, vertices.$1.dy);
    // path.lineTo(vertices.$2.dx, vertices.$2.dy);
    // path.lineTo(vertices.$3.dx, vertices.$3.dy);
    // path.close();
    // final paint = Paint()..color = col
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 1.0;
    // canvas.drawPath(path, paint);
    //
    // canvas.restore();
  }
}

// TODO: See readme if this is a good idea.
class RenderLine extends RenderItem {
  RenderLine({
    required this.vertices,
    required this.colour,
    required this.strokeWidth,
    super.label,
  });

  final Color colour;
  final (Offset, Offset) vertices;
  final double strokeWidth;

  @override
  void render(Canvas canvas, Size size) {
    canvas.drawLine(
      vertices.$1,
      vertices.$2,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }
}

// TODO: See readme if this is a good idea.
class RenderPoint extends RenderItem {
  RenderPoint({
    required this.position,
    required this.colour,
    required this.radius,
    super.label,
  });

  final Color colour;
  final Offset position;
  final double radius;

  @override
  void render(Canvas canvas, Size size) {
    canvas.drawCircle(
      position,
      radius,
      Paint()
        ..color = colour
        ..style = PaintingStyle.fill,
    );
  }
}

// TODO: See readme if this is a good idea.
// Useful base for shaders which don't operate on existing RenderItems. Not meant to be rendered, and likely meant to be ignored in shaders?
class RenderMarker extends RenderItem {
  RenderMarker({
    required this.position,
    super.label,
  });

  final Offset position;

  @override
  void render(Canvas canvas, Size size) {}
}

// TODO: See readme if this is a good idea.
class RenderEffect extends RenderItem {
  RenderEffect({
    required this.children,
    required this.effect,
  });

  final List<RenderItem> children;
  final Function(Canvas, Size, List<RenderItem>) effect;

  @override
  void render(Canvas canvas, Size size) {
    effect(canvas, size, children);
  }
}