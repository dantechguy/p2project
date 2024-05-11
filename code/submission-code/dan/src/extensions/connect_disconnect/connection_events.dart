import 'package:blitz/server.dart';

class ConnectDisconnectEvents {
  ConnectDisconnectEvents(StreamSplitAndBuffer<String> splitAndBuffer) : _splitAndBuffer = splitAndBuffer;

  final StreamSplitAndBuffer<String> _splitAndBuffer;
  final _inserter = StreamInserter<EventServerIn<String>>();

  Stream<EventServerIn<String>> toServer(Stream<EventServerIn<String>> stream) {
    return _inserter.insert(stream);
  }

  void sendClientConnectedEvent(int clientID) {
    // New split must be added before event is sent, as otherwise new client won't get the event.
    _splitAndBuffer.addSplit(clientID);
    _inserter.add(EventServerInFromServer(data: 'connected:$clientID'));
  }

  void sendClientDisconnectedEvent(int clientID) {
    _splitAndBuffer.removeSplit(clientID);
    _inserter.add(EventServerInFromServer(data: 'disconnected:$clientID'));
  }
}
