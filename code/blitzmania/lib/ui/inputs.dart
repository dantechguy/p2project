import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlitzInputs extends StatefulWidget {
  const BlitzInputs(
      {required this.child, super.key, required this.onSteer, required this.onAccelerate,
      });

  final Widget child;
  final void Function(double steer) onSteer;
  final void Function(double steer) onAccelerate;

  @override
  State<BlitzInputs> createState() => _BlitzInputsState();
}

class _BlitzInputsState extends State<BlitzInputs> {
  late final FocusNode focusNode;
  final List<String> log = [];

  bool upArrow = false;
  bool downArrow = false;
  bool leftArrow = false;
  bool rightArrow = false;
  double steering = 0;
  double accelerating = 0;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(debugLabel: "Arrow Keys Input");
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void updateVals() {
    double newSteer = 0;
    if (leftArrow && !rightArrow) newSteer = -1;
    if (!leftArrow && rightArrow) newSteer = 1;
    if (newSteer != steering) {
      steering = newSteer;
      widget.onSteer(steering);
    }

    double newAccelerate = 0;
    if (upArrow) newAccelerate = 1;
    if (newAccelerate != accelerating) {
      accelerating = newAccelerate;
      widget.onAccelerate(accelerating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      includeSemantics: false,
      // Prevents screen-readers reading it.
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent || event is KeyUpEvent) {
          setState(() {
            final val = event is KeyDownEvent;
            switch (event.logicalKey) {
              case LogicalKeyboardKey.arrowUp:
                upArrow = val;
              case LogicalKeyboardKey.arrowDown:
                downArrow = val;
              case LogicalKeyboardKey.arrowLeft:
                leftArrow = val;
              case LogicalKeyboardKey.arrowRight:
                rightArrow = val;
            }
            updateVals();
          });
        }

        if (event is! KeyDownEvent) return;

        final key = switch (event.logicalKey) {
          LogicalKeyboardKey.arrowLeft => '! left arrow',
          LogicalKeyboardKey.arrowRight => '! right arrow',
          LogicalKeyboardKey.arrowUp => '! up arrow',
          LogicalKeyboardKey.arrowDown => '! down arrow',
          _ => event.logicalKey.debugName ?? '<none>',
        };
        setState(() {
          log.add(key);
        });
      },
      child: Stack(children: [
        widget.child,
        Align(
          alignment: Alignment.topLeft,
          child: Text('$steering\n$accelerating\n' + log.skip(max(0, log.length - 20)).join('\n')),
        ),
      ]),
    );
  }
}
