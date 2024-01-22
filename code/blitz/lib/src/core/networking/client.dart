import 'package:blitz/src/core/events/event.dart';

// Exposes stream of events received from the server which are inputted into the Core, and a method to send events to the server which the Core calls.
import 'dart:html';
import 'package:web_socket_channel/html.dart';

void main() {
  /* var channel = HtmlWebSocketChannel.connect('ws://192.168.50.171:4040'); */
}

class NetworkingClient {
  NetworkingClient(String address, int port) : _addr = address, _port = port;
  final String _addr;
  final int _port;
  late final HtmlWebSocketChannel _channel;
  late final Stream<String> _stringStream;

  Future<void> initialise() async {
    _channel = HtmlWebSocketChannel.connect('ws://$_addr:$_port');
    print('WebSocket client connected to ws://$_addr:$_port');

    // Converts valid JSON strings into Events, and discards invalid ones.
    _stringStream = _channel.stream
        .map<String>((message) {
          print('Received: $message');
          return message.toString();
        });
  }

  // Forwards received events from its connection to the server to the Core.
  Stream<String> get serverStringStream => _stringStream;

  // Forwards events received from the Core to the server.
  // This shouldn't be a streamcontroller, as it would give too much power. They could close it for example. You'd also just be wrapping the inner stream with an outer stream. Useless, considering you're just calling a function either way.
  void sendStringToServer(String message) {
    _channel.sink.add(message);
  }
}
