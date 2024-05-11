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

  // TODO: EVAL REMOVE
  // late final WebSocketChannel passiveReplicationServerChannel;

  Future<void> init() async {
    _channel = WebSocketChannel.connect(Uri.parse('ws://$_addr:$_port'));
    print('WebSocket client connected to ws://$_addr:$_port');

    _dataFromServer = _channel.stream.map<String>((data) => data.toString());

    // TODO: EVAL REMOVE
    // passiveReplicationServerChannel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:4041'));
    // passiveReplicationServerChannel.stream.forEach((element) { });
  }

  void listenToDataToServer(Stream<String> stream) {
    _dataToServer = stream;
    // TODO: EVAL KEEP
    _channel.sink.addStream(_dataToServer);
    // TODO: EVAL REMOVE
    // stream.forEach((element) {
    //   _channel.sink.add(element);
    //   passiveReplicationServerChannel.sink.add(element);
    // });
  }

  // Forwards received events from its connection to the server to the Core.
  Stream<String> get dataFromServer => _dataFromServer;
}
