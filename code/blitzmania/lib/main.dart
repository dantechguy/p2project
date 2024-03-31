import 'package:blitz/client.dart';
import 'package:blitzmania/state/driver.dart';
import 'package:blitzmania/state/inputs.dart';
import 'package:blitzmania/state/state.dart';
import 'package:blitzmania/state/tickless_approx.dart';
import 'package:blitzmania/ui/blitz_painter.dart';
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
  late final RacingState Function() _getCurrentState;
  late final InputHandler _inputHandler;

  @override
  void initState() async {
    super.initState();
    final eventIDGenerator = UniqueIntIDGenerator();
    final networkingClient = NetworkingClient('::1', 4040);
    final timeClient = EventBasedTimeClient(
      generateUniqueEventID: eventIDGenerator.generateUniqueID,
      syncTimeout: const Duration(seconds: 10),
    );
    final unstableSync = UnstablePeriodSyncClient(
      generateUniqueEventID: eventIDGenerator.generateUniqueID,
    );
    final clientIDSync = ClientIDSyncClient(
      generateUniqueEventID: eventIDGenerator.generateUniqueID,
    );
    _inputHandler = InputHandler(
      clientID: clientIDSync.clientID,
      getCurrentTimeEstimate: timeClient.getCurrentGameTime,
    )..initState();

    final inputEventStream = _inputHandler.insertEvents(
      addTicks(
        clientIDSync.interceptEvents(
          unstableSync.interceptEvents(
            timeClient.interceptEvents(
              convertJsonStringFromServerToEvent(
                networkingClient.serverStringStream,
              ),
            ),
          ),
        ),
        tickPeriod: const Duration(milliseconds: 50),
        generateEventID: eventIDGenerator.generateUniqueID,
      ),
    );

    final sendEventToServer = clientIDSync.insertEvents(
      unstableSync.insertEvents(
        timeClient.insertEvents(
          convertEventToJsonStringForServer(
            networkingClient.sendStringToServer,
          ),
        ),
      ),
    );

    await networkingClient.initialise();
    // TODO: Do this and others all at same time with merged future, as they don't depend on each other.
    await Future.wait([
      timeClient.initialise(),
      unstableSync.initialise(),
      clientIDSync.initialise(),
    ]);

    final core = ClientCore<RacingState>(
      eventStream: inputEventStream,
      sendEventToServer: sendEventToServer,
      initialState: RacingState(),
      driver: drive,
      unstablePeriod: const Duration(seconds: 1),
      getCurrentEstimatedTime: timeClient.getCurrentGameTime,
    );

    _getCurrentState = addTicklessApproximation(
      getPrevState: runUnstableEvents(
        driver: drive,
        getStableState: core.getCurrentState,
        getUnstableEvents: core.getUnstableEvents,
      ),
      getCurrentGameTime: timeClient.getCurrentGameTime,
    );
  }

  @override
  void dispose() {
    _inputHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blitz Mania',
      home: Scaffold(
        body: _inputHandler.InputInterceptorWidget(
          child: BlitzPaintWidget(env: _getCurrentState()),
        ),
      ),
    );
  }
}
