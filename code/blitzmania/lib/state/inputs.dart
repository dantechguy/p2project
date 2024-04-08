import 'dart:async';

import 'package:blitz/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputGenerator {
  late final StreamInserter<EventClientInPreCore<String>> _streamInserter;

  double acceleration = 0;
  double steering = 0;
  bool keyWPressed = false;
  bool keySPressed = false;
  bool keyAPressed = false;
  bool keyDPressed = false;

  void initState() {
    _streamInserter = StreamInserter();
  }

  void dispose() {
  }

  KeyEventResult onKeyPressed(FocusNode node, KeyEvent event) {
    double newAcc;
    double newSteer;

    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyW:
          keyWPressed = true;
        case LogicalKeyboardKey.keyS:
          keySPressed = true;
        case LogicalKeyboardKey.keyA:
          keyAPressed = true;
        case LogicalKeyboardKey.keyD:
          keyDPressed = true;
      }
    } else if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyW:
          keyWPressed = false;
        case LogicalKeyboardKey.keyS:
          keySPressed = false;
        case LogicalKeyboardKey.keyA:
          keyAPressed = false;
        case LogicalKeyboardKey.keyD:
          keyDPressed = false;
      }
    }

    newAcc = keyWPressed ? 1 : (keySPressed ? -1 : 0);
    newSteer = keyDPressed ? 1 : (keyAPressed ? -1 : 0);

    if (newAcc != acceleration) {
      acceleration = newAcc;
      sendDataToClient('input:acceleration:$acceleration');
    }
    if (newSteer != steering) {
      steering = newSteer;
      sendDataToClient('input:steering:$steering');
    }
    return KeyEventResult.handled;
  }

  void sendDataToClient(String data) {
    _streamInserter.add(
      EventClientInFromLocalPreCore<String>(
        data: data,
      ),
    );
  }

  Widget InputInterceptorWidget({required Widget child}) {
    return Focus(
      autofocus: true,
      onKeyEvent: onKeyPressed,
      child: child,
    );
  }

  Stream<EventClientInPreCore<String>> toClient(
      Stream<EventClientInPreCore<String>> stream) {
    return _streamInserter.insert(stream);
  }
}
