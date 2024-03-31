import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:blitz/server.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkingServer {
  NetworkingServer({
    required String address,
    required int port,
    required int Function() generateUserID,
  })  : _port = port,
        _address = address,
        _generateUserID = generateUserID;

  final String _address;
  final int _port;
  late final HttpServer _server;

  final int Function() _generateUserID;

  final Map<int, WebSocketChannel> _channels = {};

  late final Stream<String> _dataToAllClients;
  late final StreamGroup<(int clientID, String data)> _dataToServerGroup =
      StreamGroup();

  Future<void> initialise() async {
    // TODO: Make secure using WSS.
    _server = await HttpServer.bind(_address, _port);
    print('Listening on $_address:$_port');

    _server.transform(WebSocketTransformer()).listen(_onClientConnected);

    _dataToAllClients.forEach((String data) {
      for (var c in _channels.values) {
        c.sink.add(data);
      }
    });
  }

  void listenToDataToAllClients(Stream<String> stream) =>
      _dataToAllClients = stream;

  void _onClientConnected(WebSocket webSocket) {
    int clientID = _generateUserID();
    print('New client $clientID connected.');

    final channel = IOWebSocketChannel(webSocket);
    _channels[clientID] = channel;

    final stream = channel.stream.handleOnDone(() {
      print('Client $clientID disconnected.');
      // TODO: Do i need to remove the stream from StreamGroup here?
      _channels.remove(channel);
    }).handleError((error) {
      print('Client $clientID errored, so disconnected.');
      _channels.remove(channel);
      // Not sure if needed.
      webSocket.close();
    }).map((event) => (clientID, event.toString()));

    _dataToServerGroup.add(stream);
  }

  Stream<(int, String)> get dataToServer => _dataToServerGroup.stream;

  // TODO: Old. Remove. Kept as reference for how to send single-client messages
  void sendStringToClient(int clientID, String message) {
    _channels[clientID]?.sink.add(message);
  }
}
