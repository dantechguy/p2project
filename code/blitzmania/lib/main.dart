import 'dart:async';

import 'package:blitz/client.dart';
import 'package:blitzmania/dart_extensions.dart';
import 'package:blitzmania/state/driver.dart';
import 'package:blitzmania/state/inputs.dart';
import 'package:blitzmania/state/state.dart';
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
  bool engineSetup = false;
  late final RacingState Function() _getCurrentState;
  late final InputGenerator _inputGenerator;

  @override
  void initState() {
    super.initState();
    _inputGenerator = InputGenerator()..initState();
    setupEngine();
    Timer.periodic(Duration(milliseconds: 1), (timer) => setState(() {}));
  }

  void setupEngine() async {
    const tickPeriod = Duration(milliseconds: 50);
    const timeout = Duration(seconds: 10);

    final networkingClient = NetworkingClient(address: '127.0.0.1', port: 4040);
    final initDataClient = InitialisationDataClient(syncTimeout: timeout);
    final timeClient = TimeClient(syncTimeout: timeout);
    final eventIDGen = UniqueIntIDGenerator();

    await networkingClient.init();

    // Note that we're using [.listenAndBuffer] here. This subscribes to the streams so events go through, and the init modules can start working.
    final inEvents = addStringTicks(
      _inputGenerator.toClient(
        deserialiseJsonStringFromServerToEvent(
          timeClient.toClient(
            initDataClient.toClient(
              networkingClient.dataFromServer,
            ),
          ),
        ),
      ),
      tickPeriod: tickPeriod,
    ).printAll((e) => 'IN:  ${e.toShortString()}').listenAndBuffer();

    final outCoreStreamCon = StreamController<EventClientOut<String>>();
    final outData = initDataClient.toServer(
      timeClient.toServer(
        serialiseEventToJsonStringForServer(
          outCoreStreamCon.stream.printAll((e) => 'OUT: ${e.toShortString()}'),
        ),
      ),
    );

    networkingClient.listenToDataToServer(outData);

    await Future.wait([
      initDataClient.init(),
      timeClient.init(),
    ]);
    final {
      'unstablePeriod': int unstablePeriodMillis,
      'clientID': int clientID,
      'serverID': int serverID,
    } = initDataClient.data;

    final coreClient = ClientCore<RacingState, String>(
      inEvents: inEvents,
      initialState: getInitialState(),
      driver: drive,
      unstablePeriod: Duration(milliseconds: unstablePeriodMillis),
      getCurrentEstimatedTime: timeClient.getCurrentGameTime,
      clientID: clientID,
      generateUniqueEventID: eventIDGen.generateUniqueID,
    );
    outCoreStreamCon.addStream(coreClient.eventsToServer);
    _getCurrentState = runUnstableEvents(
      driver: drive,
      getStableState: coreClient.getCurrentState,
      getUnstableEvents: coreClient.getUnstableEvents,
    );

    setState(() {
      engineSetup = true;
    });
    print('ENGINE START!');
    coreClient.init();
  }

  @override
  void dispose() {
    _inputGenerator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAN: demo',
      home: Scaffold(
        body: _inputGenerator.InputInterceptorWidget(
          child: BlitzPaintWidget(
              env: engineSetup ? _getCurrentState() : getInitialState()),
        ),
      ),
    );
  }
}
