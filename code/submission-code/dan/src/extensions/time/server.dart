import 'package:blitz/server.dart';

class TimeServer {
  TimeServer({
    required DateTime Function() getServerClockTime,
    required DateTime Function() getServerStartTime,
  })  : _getServerClockTime = getServerClockTime,
        _getServerStartTime = getServerStartTime;

  final DateTime Function() _getServerClockTime;
  final DateTime Function() _getServerStartTime;

  final StreamInserter<(int, String)> _toClientInserter = StreamInserter();

  final StreamInterceptor<(int, String)> _toServerInterceptor =
      StreamInterceptor();

  // Insert events into stream, to send to the server
  // Rename to something more understandable without knowing internals
  Stream<(int, String)> toClient(Stream<(int, String)> stream) {
    return _toClientInserter.insert(stream);
  }

  // Intercept and remove events from stream, before they reach the core
  Stream<(int, String)> toServer(Stream<(int, String)> stream) {
    final interceptedDataStream = _toServerInterceptor.intercept(stream);

    _toServerInterceptor.whenever(
      (data) => data.$2 == 'time sync start time',
      (data) {
        _toClientInserter.add((
          data.$1,
          'time sync start time:${_getServerStartTime().toIso8601String()}',
        ));
      },
      passThrough: false,
    );

    _toServerInterceptor.whenever(
      (data) => data.$2 == 'time sync clock offset',
      (data) {
        _toClientInserter.add((
          data.$1,
          'time sync clock offset:${_getServerClockTime().toUtc().toIso8601String()}',
        ));
      },
      passThrough: false,
    );

    return interceptedDataStream;
  }
}
