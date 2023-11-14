import 'package:blitzmania/ui/renderer.dart';
import 'package:flutter/cupertino.dart';
import '../shared/env.dart';

class BlitzPaintWidget extends StatelessWidget {
  const BlitzPaintWidget({super.key, required this.env});

  final Env env;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: BlitzPainter(env: env),
      ),
    );
  }

}


class BlitzPainter extends CustomPainter {
  const BlitzPainter({required this.env});

  final Env env;

  @override
  void paint(Canvas canvas, Size size) {
    render(env, canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is BlitzPainter && oldDelegate.env == env;
  }

}