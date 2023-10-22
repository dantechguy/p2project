import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlitzInputs extends StatefulWidget {
  const BlitzInputs({required this.child, super.key});

  final Widget child;

  @override
  State<BlitzInputs> createState() => _BlitzInputsState();
}

class _BlitzInputsState extends State<BlitzInputs> {
  late final FocusNode focusNode;
  final List<String> log = [];

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

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      includeSemantics: false,
      // Prevents screen-readers reading it.
      onKeyEvent: (KeyEvent event) {
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
          child: Text(log.skip(max(0, log.length-20)).join('\n')),
        ),
      ]),
    );
  }
}
