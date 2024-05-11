// server.dart

import 'dart:async';

import 'package:blitz/server.dart';
import 'package:blitzmania_server/dart_extensions.dart';

void main() async {
  final unstablePeriod = Duration(seconds: 2);

  final gameStartTime = DateTime.now().toUtc();
  final eventIDGen = UniqueIntIDGenerator();
  final playerIDGen = UniqueIntIDGenerator();
  final serverID = playerIDGen.generateUniqueID();
  final streamSplitAndBuffer = StreamSplitAndBuffer<String>();
  final connectDisconnectEvents = ConnectDisconnectEvents(streamSplitAndBuffer);
  final networkingServer = NetworkingServer(
    address: '127.0.0.1',
    port: 4040,
    generateUserID: playerIDGen.generateUniqueID,
    onClientConnect: connectDisconnectEvents.sendClientConnectedEvent,
    onClientDisconnect: connectDisconnectEvents.sendClientDisconnectedEvent,
    // artificialLatency: Duration(milliseconds: 200),
  );
  final initDataServer = InitialisationDataServer(
      getData: (clientID) => {
            'unstablePeriod': unstablePeriod.inMilliseconds,
            'clientID': clientID,
            'serverID': serverID,
          });
  final timeServer = TimeServer(
    getServerClockTime: () => DateTime.now().toUtc(),
    getServerStartTime: () => gameStartTime,
  );
  Duration getGameTime() => DateTime.now().toUtc().difference(gameStartTime);

  final inEvents = connectDisconnectEvents.toServer(
    deserialiseJsonStringFromClientToEvent<String>(
      timeServer.toServer(
        initDataServer.toServer(
          networkingServer.dataToServer,
        ),
      ),
    ),
  );

  await networkingServer.init();

  final serverCore = ServerCore<String>(
    serverID: serverID,
    inEvents: inEvents,
    getGameTime: getGameTime,
    generateUniqueEventID: eventIDGen.generateUniqueID,
    unstablePeriod: unstablePeriod,
  );

  final outData = initDataServer.toClient(
    timeServer.toClient(
      streamSplitAndBuffer.split(
        serialiseEventToJsonStringForClient(
          serverCore.eventsToClient,
        ).printAll(),
      ),
    ),
  );
  networkingServer.listenToDataForClients(outData);

  serverCore.init();

}
