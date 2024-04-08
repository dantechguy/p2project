// server.dart

import 'package:blitz/server.dart';
import 'package:blitzmania_server/dart_extensions.dart';

void main() async {
  final unstablePeriod = Duration(seconds: 1);

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

//
// void main() async {
//   // TODO: Make secure. Use WSS (websocket secure).
//   var server = await HttpServer.bind('127.0.0.1', 4040);
//   print('WebSocket server listening on 127.0.0.1:4040');
//
//   // List to store all active WebSocket channels
//   int currentMaxID = 0;
//   Map<int, WebSocketChannel> channels = {};
//   // TODO: When is this started?
//   final gameTime = Stopwatch();
//
//   server.transform(WebSocketTransformer()).listen((WebSocket webSocket) {
//     int clientID = currentMaxID++;
//     print('Client $clientID connected.');
//     final channel = IOWebSocketChannel(webSocket);
//     channels[clientID] = channel;
//
//     channel.sink.add('Set ID:$clientID');
//
//     channel.stream.listen((message) {
//       Event event;
//       try {
//         event = Event.fromJsonString(message);
//       } on FormatException {
//         print('Client $clientID sent malformed JSON: $message');
//         return;
//       }
//
//       event.serverReceiptTimestamp = gameTime.elapsed;
//       event.senderID = clientID;
//       // TODO: Should you throw away early packets? Tiny latencies such as on a LAN, with tiny offsets of timer syncs, could cause race conditions, causing this.
//       // if (event.generatedTimestamp > event.serverReceiptTimestamp) return;
//       final eventString = event.toJsonString();
//
//       print('Client $clientID: $eventString');
//       for (var c in channels.values) {
//         c.sink.add(eventString);
//       }
//     }, onDone: () {
//       print('Client $clientID disconnected.');
//       channels.remove(channel);
//     }, onError: (error) {
//       // TODO: See when and what errors can be thrown.
//       print('Client $clientID error: $error');
//       // channels.remove(channel);
//     });
//   });
// }
