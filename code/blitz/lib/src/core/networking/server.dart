import 'dart:async';
import 'dart:io';

import 'package:blitz/core.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkingServer {
  NetworkingServer({
    required String endpoint,
    required int port,
  })  : _port = port,
        _endpoint = endpoint;

  final String _endpoint;
  final int _port;
  late final HttpServer _server;

  late final Stopwatch _clock;
  // Starts at 1, as the server is 0.
  int _currentMaxID = 1;
  // Do we need this?
  final Map<int, WebSocketChannel> _channels = {};

  // TODO: Change type to [Stream<(int clientID, String message)>].
  late final Stream<(int clientID, String)> _outputStream;

  Future<void> initialise() async {
    // It doesn't matter when this is started, as long as it's before any events are sent.
    // TODO: Change this to use core/time/server.dart
    _clock = Stopwatch()..start();

    await _initialiseServer();
  }

  Future<void> _initialiseServer() async {
    // TODO: Make secure using WSS.
    _server = await HttpServer.bind(_endpoint, _port);
    print('Listening on $_endpoint:$_port');

    _server.transform(WebSocketTransformer()).listen(_onClientConnected);
  }

  void _onClientConnected(WebSocket webSocket) {
    int clientID = _currentMaxID++;
    print('New client $clientID connected.');

    final channel = IOWebSocketChannel(webSocket);
    _channels[clientID] = channel;

    // TODO: Add error handling with [stream.handleError].
    // TODO: Add/remove (un)trusted data from Event: replace [serverReceiptTimestamp], [senderID], remove [isServerConfirmed].
    _outputStream = channel.stream.handleOnDone(() {
      print('Client $clientID disconnected.');
      _channels.remove(channel);
    }).map((event) => (clientID, event.toString()));
  }

  Stream<(int, String)> get serverStringStream => _outputStream;

  // Review these exposed interfaces.
  void sendStringToAllClients(String message) {
    for (var c in _channels.values) {
      c.sink.add(message);
    }
  }

  void sendStringToClient(int clientID, String message) {
    _channels[clientID]?.sink.add(message);
  }
}

extension StreamHandleDone<T> on Stream<T> {
  Stream<T> handleOnDone(void Function() onDone) async* {
    await for (final T obj in this) {
      yield obj;
    }
    onDone();
  }
}
