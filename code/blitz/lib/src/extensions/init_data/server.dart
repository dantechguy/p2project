import 'dart:convert';

import 'package:blitz/client.dart';
import 'package:blitz/src/extensions/stream_inserter.dart';

class InitialisationDataServer {
  InitialisationDataServer({
    required Map<String, dynamic> data,
  }) : _initialisationData = jsonEncode(data);

  final StreamInserter<(int clientID, String data)> _toClientInserter = StreamInserter();
  final StreamInterceptor<(int, String)> _interceptor = StreamInterceptor();

  final String _initialisationData;

  Stream<(int, String)> insertData(
      Stream<(int, String)> dataToClient) {
    return _toClientInserter.insert(dataToClient);
  }

  Stream<(int, String)> interceptData(Stream<(int, String)> dataStream) {
    final interceptedStream = _interceptor.intercept(dataStream);

    _interceptor.whenever(
      (streamData) => streamData.$2 == 'get initialisation data',
      (streamData) => _toClientInserter.add((streamData.$1, 'get initialisation data:$_initialisationData')),
      passThrough: false,
    );

    return interceptedStream;
  }
}
