import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:blitz/server.dart';
import 'package:blitz/src/dart_extensions.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkingServer {
  NetworkingServer({
    required String address,
    required int port,
    required int Function() generateUserID,
    void Function(int)? onClientConnect,
    void Function(int)? onClientDisconnect,
  })  : _clientConnectCallback = onClientConnect,
        _clientDisconnectCallback = onClientDisconnect,
        _port = port,
        _address = address,
        _generateUserID = generateUserID;

  final String _address;
  final int _port;
  late final HttpServer _server;

  final int Function() _generateUserID;
  final void Function(int)? _clientConnectCallback;
  final void Function(int)? _clientDisconnectCallback;

  final Map<int, WebSocketChannel> _channels = {};

  late final Stream<(int, String)> _dataToSingleClient;
  late final StreamGroup<(int clientID, String data)> _dataToServerGroup =
      StreamGroup();

  // TODO: separate out String dependency
  final StreamInserter<EventServerIn<String>> _toServerInserter =
      StreamInserter();

  Future<void> init() async {
    // TODO: Make secure using WSS.
    _server = await HttpServer.bind(_address, _port);
    print('Listening on $_address:$_port');

    _server.transform(WebSocketTransformer()).listen(_onWebSocketConnected);
  }

  void listenToDataForClients(Stream<(int, String)> stream) async {
    _dataToSingleClient = stream;
    await for (final r in _dataToSingleClient) {
      final (int clientID, String data) = r;
      if (!_channels.containsKey(clientID)) {
        // Can't have this because client data may still be on the way to this module from the splitter, for a short period after removing the id from the splitter.
        // throw ArgumentError('Client $clientID does not exist.');
        continue;
      }
      _channels[clientID]!.sink.add(data);
    }
  }

  /// Used to insert connection/disconnection events to server, to be sent to clients
  Stream<EventServerIn<String>> toServer(Stream<EventServerIn<String>> stream) {
    return _toServerInserter.insert(stream);
  }

  void _onWebSocketConnected(WebSocket webSocket) {
    int clientID = _generateUserID();

    final channel = IOWebSocketChannel(webSocket);
    _channels[clientID] = channel;

    final stream = channel.stream.handleOnDone(() {
      _onClientDisconnect(clientID);
    }).handleError((error) {
      _onClientError(clientID, webSocket, error);
    }).map((event) => (clientID, event.toString()));

    _onClientConnect(clientID);

    _dataToServerGroup.add(stream);
  }

  // TODO: add callback parameter to separate the String specific functionality.
  /// Called before any client events have been sent to server
  void _onClientConnect(int clientID) {
    _clientConnectCallback?.call(clientID);
    // _toServerInserter.add(EventServerInFromServer(data: 'connected:$clientID'));
  }

  /// Called after client has disconnected
  void _onClientDisconnect(int clientID) {
    // TODO: Do i need to remove the stream from StreamGroup here?
    _channels.remove(clientID);
    _clientDisconnectCallback?.call(clientID);
    // _toServerInserter
    //     .add(EventServerInFromServer(data: 'disconnected:$clientID'));
  }

  /// Called after an error is thrown, but connection is not necessarily closed.
  void _onClientError(int clientID, WebSocket webSocket, dynamic error) {
    _channels.remove(clientID);
    // Not sure if needed.
    webSocket.close();
    _clientDisconnectCallback?.call(clientID);
    // _toServerInserter
    //     .add(EventServerInFromServer(data: 'disconnected:$clientID'));
  }

  Stream<(int, String)> get dataToServer => _dataToServerGroup.stream;
}
