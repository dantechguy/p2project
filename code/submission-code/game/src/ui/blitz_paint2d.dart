import 'package:blitzmania/state/state.dart';
import 'package:blitzmania/ui/renderer2d.dart';
import 'package:flutter/cupertino.dart';

class BlitzPaint2DWidget extends StatelessWidget {
  const BlitzPaint2DWidget({super.key, required this.state});

  final RacingState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: BlitzPainter(state: state),
      ),
    );
  }

}


class BlitzPainter extends CustomPainter {
  const BlitzPainter({required this.state});

  final RacingState state;

  @override
  void paint(Canvas canvas, Size size) {
    render2D(state, canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is BlitzPainter && oldDelegate.state != state;
  }

}