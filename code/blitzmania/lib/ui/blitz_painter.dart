import 'package:blitzmania/state/state.dart';
import 'package:blitzmania/ui/renderer.dart';
import 'package:flutter/cupertino.dart';

class BlitzPaintWidget extends StatelessWidget {
  const BlitzPaintWidget({super.key, required this.env});

  final RacingState env;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: BlitzPainter(state: env),
      ),
    );
  }

}


class BlitzPainter extends CustomPainter {
  const BlitzPainter({required this.state});

  final RacingState state;

  @override
  void paint(Canvas canvas, Size size) {
    render(state, canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is BlitzPainter && oldDelegate.state != state;
  }

}