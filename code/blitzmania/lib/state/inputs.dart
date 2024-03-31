import 'dart:async';

import 'package:async/async.dart';
import 'package:blitz/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputHandler {
  InputHandler({
    required int clientID,
    required Duration Function() getCurrentTimeEstimate,
  })  : _getCurrentTimeEstimate = getCurrentTimeEstimate,
        _clientID = clientID;

  final int _clientID;
  final Duration Function() _getCurrentTimeEstimate;

  late final FocusNode _focusNode;
  late final StreamController<EventClientIn> _inputStreamController;
  bool _sendEvents = false;

  double acceleration = 0;
  double steering = 0;
  bool keyWPressed = false;
  bool keySPressed = false;
  bool keyAPressed = false;
  bool keyDPressed = false;

  void initState() {
    _focusNode = FocusNode(debugLabel: 'Game inputs');
    _inputStreamController = StreamController(
      onListen: () => _sendEvents = true,
      onCancel: () => _sendEvents = false,
      onResume: () => _sendEvents = true,
      onPause: () => _sendEvents = false,
    );
  }

  void dispose() {
    _focusNode.dispose();
  }

  void onKeyPressed(KeyEvent event) {
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
      trySendDataToClient('acceleration:$acceleration');
    }
    if (newSteer != steering) {
      steering = newSteer;
      trySendDataToClient('steering:$steering');
    }
  }

  void trySendDataToClient(String data) {
    if (_sendEvents) {
      _inputStreamController.add(
        EventClientInFromLocal(
          eventID: UniqueIntIDGenerator().generateUniqueID(),
          data: '',
          generatedTimestamp: _getCurrentTimeEstimate(),
          senderID: _clientID,
        ),
      );
    }
  }

  Widget InputInterceptorWidget({required Widget child}) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: onKeyPressed,
      child: child,
    );
  }

  Stream<EventClientIn> insertEvents(Stream<EventClientIn> eventStream) {
    return StreamGroup.merge([
      _inputStreamController.stream,
      eventStream,
    ]);
  }
}
