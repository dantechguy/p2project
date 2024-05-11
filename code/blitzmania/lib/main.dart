import 'dart:async';

import 'package:blitz/client.dart';
import 'package:blitzmania/dart_extensions.dart';
import 'package:blitzmania/replay_events.dart';
import 'package:blitzmania/state/driver.dart';
import 'package:blitzmania/state/extrapolation.dart';
import 'package:blitzmania/state/inputs.dart';
import 'package:blitzmania/state/smoother.dart';
import 'package:blitzmania/state/state.dart';
import 'package:blitzmania/ui/blitz_paint2d.dart';
import 'package:blitzmania/ui/blitz_paint3d.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

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
  late final RacingState Function() _getCurrentState0;
  late final RacingState Function() _getCurrentState1;
  late final RacingState Function() _getCurrentState2;
  late final RacingState Function() _getCurrentState;
  late final List<EventClientInInCore<String>> Function() _getUnstableEvents;
  late final Duration Function() _getTime;
  late final void Function(EventClientInPreCore<String> event) _addEvent;
  late final List<EventClientInFromLocalPreCoreDebug<String>> _replayEvents;
  late final InputGenerator _inputGenerator;

  @override
  void initState() {
    super.initState();
    _inputGenerator = InputGenerator()..initState();
    setupEngine();
    Timer.periodic(const Duration(milliseconds: 1), (timer) => setState(() {}));
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
      getCurrentTime: () =>
          engineSetup ? timeClient.getCurrentGameTime() : Duration.zero,
    )
        // .printAll(
        //   map: (e) =>
        //       '${timeClient.getCurrentGameTime().inMilliseconds.toString()};${e.toShortString()}',
        //   filter: (e) => e is EventClientInFromLocalPreCore,
        // )
        .listenAndBuffer();

    final outCoreStreamCon = StreamController<EventClientOut<String>>();
    final outData = initDataClient.toServer(
      timeClient.toServer(
        serialiseEventToJsonStringForServer(
          outCoreStreamCon.stream,
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

    _replayEvents = clientID == -1 ? getReplayEvents(clientID, eventIDGen.generateUniqueID) : [];
    final replayInserter = StreamInserter<EventClientInPreCore<String>>();

    final coreClient = ClientCore<RacingState, String>(
      inEvents: replayInserter.insert(inEvents),
      initialState: getInitialState(),
      driver: drive,
      unstablePeriod: Duration(milliseconds: unstablePeriodMillis),
      getCurrentEstimatedTime: timeClient.getCurrentGameTime,
      clientID: clientID,
      generateUniqueEventID: eventIDGen.generateUniqueID,
    );
    outCoreStreamCon.addStream(coreClient.eventsToServer);

    _getCurrentState = racingSmoother(
      getState: racingTicklessExtrapolation(
        getLastState: runUnstableEvents(
          driver: drive,
          getStableState: coreClient.getCurrentState,
          getUnstableEvents: coreClient.getUnstableEvents,
        ),
        getCurrentGameTime: timeClient.getCurrentGameTime,
      ),
      getTime: timeClient.getCurrentGameTime,
      curve: (x) => x * x * x,
      smoothLength: const Duration(milliseconds: 100),
    );

    _getCurrentState2 = racingSmoother(
      getState: runUnstableEvents(
        driver: drive,
        getStableState: coreClient.getCurrentState,
        getUnstableEvents: coreClient.getUnstableEvents,
      ),
      getTime: timeClient.getCurrentGameTime,
      curve: (x) => x*x,
      smoothLength: const Duration(milliseconds: 100),
    );

    _getCurrentState1 = racingTicklessExtrapolation(
      getLastState: runUnstableEvents(
        driver: drive,
        getStableState: coreClient.getCurrentState,
        getUnstableEvents: coreClient.getUnstableEvents,
      ),
      getCurrentGameTime: timeClient.getCurrentGameTime,
    );

    _getCurrentState0 = runUnstableEvents(
      driver: drive,
      getStableState: coreClient.getCurrentState,
      getUnstableEvents: coreClient.getUnstableEvents,
    );
    _getUnstableEvents = coreClient.getUnstableEvents;

    _getTime = timeClient.getCurrentGameTime;
    _addEvent = replayInserter.add;

    setState(() {
      engineSetup = true;
    });
    print('ENGINE START!');
    coreClient.init();
    // Timer.periodic(
    //     Duration(milliseconds: 50),
    //     (timer) =>
    //         print(timeClient.getCurrentGameTime().inMilliseconds.toString()));

    // TODO: EVAL REMOVE
    // Timer.periodic(Duration(milliseconds: 60), (timer) {
    //   networkingClient.passiveReplicationServerChannel.sink.add(
    //       _getCurrentState()
    //           .cars
    //           .map((car) => car.toJson())
    //           .toList()
    //           .toString());
    // });
  }

  @override
  void dispose() {
    _inputGenerator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // while (_replayEvents.isNotEmpty && _replayEvents.first.generatedTimestamp < _getTime()) {
    //   _addEvent(_replayEvents.first);
    //   _replayEvents.removeAt(0);
    // }
    // if (engineSetup) {
    //   final double y0 =_getCurrentState0().cars.firstWhereOrNull((car) => car.position.y != 0.0)?.position.y ?? 0;
    //   final double y1 =_getCurrentState1().cars.firstWhereOrNull((car) => car.position.y != 0.0)?.position.y ?? 0;
    //   final double y2 =_getCurrentState2().cars.firstWhereOrNull((car) => car.position.y != 0.0)?.position.y ?? 0;
    //   final double y3 =_getCurrentState().cars.firstWhereOrNull((car) => car.position.y != 0.0)?.position.y ?? 0;
    //   if ([y0, y1, y2, y3].any((y) => y != 0)) {
    //     print(
    //       '${_getTime().inMilliseconds.toString()} $y0 $y1 $y2 $y3');
    //   }
    // }
    return MaterialApp(
      title: 'DAN: demo',
      home: Scaffold(
        body: _inputGenerator.InputInterceptorWidget(
          child: Stack(
            children: [
              BlitzPaint3DWidget(
              // BlitzPaint2DWidget(
                  state: engineSetup ? _getCurrentState() : getInitialState()),
              // Align(
              //   alignment: Alignment.topLeft,
              //   child: Text((engineSetup ? _getUnstableEvents() : [])
              //       .where((e) => e is! EventClientInFromLocalButShared<String>)
              //       .map((e) => e.toShortString())
              //       .join('\n')),
              // ),
              // Align(
              //   alignment: Alignment.topCenter,
              //   child: Text(engineSetup ? _getTime().inMilliseconds.toString() : 'nothing'),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
