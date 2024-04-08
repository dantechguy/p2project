import 'package:blitz/src/dart_extensions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkingClient {
  NetworkingClient({
    required String address,
    required int port,
  })  : _addr = address,
        _port = port;
  final String _addr;
  final int _port;
  late final WebSocketChannel _channel;
  late final Stream<String> _dataFromServer;
  late final Stream<String> _dataToServer;

  Future<void> init() async {
    _channel = WebSocketChannel.connect(Uri.parse('ws://$_addr:$_port'));
    print('WebSocket client connected to ws://$_addr:$_port');

    _dataFromServer = _channel.stream.map<String>((data) => data.toString());
  }

  void listenToDataToServer(Stream<String> stream) {
    _dataToServer = stream;
    _channel.sink.addStream(_dataToServer);
  }

  // Forwards received events from its connection to the server to the Core.
  Stream<String> get dataFromServer => _dataFromServer;
}
