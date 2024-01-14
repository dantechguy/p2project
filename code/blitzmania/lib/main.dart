import 'package:blitz/core.dart';
import 'package:blitz/extensions.dart';
import 'package:blitz/networking.dart';
import 'package:blitz/time.dart';
import 'package:blitzmania/state/driver.dart';
import 'package:blitzmania/state/state.dart';
import 'package:blitzmania/state/tickless_approx.dart';
import 'package:blitzmania/ui/blitz_painter.dart';
import 'package:blitzmania/ui/inputs.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const BlitzApp());
}

class BlitzApp extends StatefulWidget {
  const BlitzApp({super.key});

  @override
  State<BlitzApp> createState() => _BlitzAppState();
}

class _BlitzAppState extends State<BlitzApp> {
  late final Core<RacingState> _core;
  late final NetworkingClient _networkingClient;
  late final EventBasedTimeClient _timeClient;
  late final RacingState Function() _getCurrentState;

  @override
  void initState() async {
    super.initState();
    _networkingClient = NetworkingClient();
    await _networkingClient.initialise();
    _timeClient = EventBasedTimeClient();
    await _timeClient.initialise();

    final inputEventStream = _timeClient.interceptTimeSyncEvents(
      addTickEvents(
        _networkingClient.serverEventStream,
        const Duration(milliseconds: 50), // Should be 3, and 37.24.
      ),
    );

    final outputEventFunction = _timeClient.insertTimeSyncEvents(
      _networkingClient.sendEvent,
    );

    _core = Core<RacingState>(
      eventStream: inputEventStream,
      sendEventToServer: outputEventFunction,
      initialState: RacingState(),
      driver: drive,
      unstablePeriod: const Duration(seconds: 1),
      getCurrentEstimatedTime: _timeClient.getCurrentGameTime,
    );

    _getCurrentState = addTicklessApproximation(
      getPrevState: runUnstableEvents(
        driver: drive,
        getStableState: _core.getCurrentState,
        getUnstableEvents: _core.getUnstableEvents,
      ),
      getCurrentGameTime: _timeClient.getCurrentGameTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blitz Mania',
      home: Scaffold(
        body: BlitzInputs(
          onSteer: (double steer) => input.steering = steer,
          onAccelerate: (double accelerate) => input.accelerating = accelerate,
          child: BlitzPaintWidget(
              env: _getCurrentState()
          ),
        ),
      ),
    );
  }
}
