import 'dart:convert';
import 'package:blitz/client.dart';

class InitialisationDataServer {
  InitialisationDataServer({
    required Map<String, dynamic> Function(int) getData,
  }) : _getData = getData;

  final StreamInserter<(int clientID, String data)> _toClientInserter =
      StreamInserter();
  final StreamInterceptor<(int, String)> _toServerInterceptor = StreamInterceptor();

  final Map<String, dynamic> Function(int) _getData;

  Stream<(int, String)> toClient(Stream<(int, String)> stream) {
    return _toClientInserter.insert(stream);
  }

  Stream<(int, String)> toServer(Stream<(int, String)> stream) {
    final interceptedStream = _toServerInterceptor.intercept(stream);

    _toServerInterceptor.whenever(
      (data) => data.$2 == 'get initialisation data',
      (data) => _toClientInserter.add((
        data.$1,
        'get initialisation data:${jsonEncode(_getData(data.$1))}'
      )),
      passThrough: false,
    );

    return interceptedStream;
  }
}
