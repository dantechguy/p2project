// server.dart
import 'dart:io';
import 'package:blitzmania_server/event.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // TODO: Make secure. Use WSS (websocket secure).
  var server = await HttpServer.bind('127.0.0.1', 4040);
  print('WebSocket server listening on 127.0.0.1:4040');

  // List to store all active WebSocket channels
  int currentMaxID = 0;
  Map<int, WebSocketChannel> channels = {};
  // TODO: When is this started?
  final gameTime = Stopwatch();

  server.transform(WebSocketTransformer()).listen((WebSocket webSocket) {
    int clientID = currentMaxID++;
    print('Client $clientID connected.');
    final channel = IOWebSocketChannel(webSocket);
    channels[clientID] = channel;

    channel.sink.add('Set ID:$clientID');

    channel.stream.listen((message) {
      Event event;
      try {
        event = Event.fromJsonString(message);
      } on FormatException {
        print('Client $clientID sent malformed JSON: $message');
        return;
      }

      event.serverReceiptTimestamp = gameTime.elapsed;
      event.senderID = clientID;
      // TODO: Should you throw away early packets? Tiny latencies such as on a LAN, with tiny offsets of timer syncs, could cause race conditions, causing this.
      // if (event.generatedTimestamp > event.serverReceiptTimestamp) return;
      final eventString = event.toJsonString();

      print('Client $clientID: $eventString');
      for (var c in channels.values) {
        c.sink.add(eventString);
      }
    }, onDone: () {
      print('Client $clientID disconnected.');
      channels.remove(channel);
    }, onError: (error) {
      // TODO: See when and what errors can be thrown.
      print('Client $clientID error: $error');
      // channels.remove(channel);
    });
  });
}
