import 'package:blitz/server.dart';
import 'package:blitz/src/extensions/stream_inserter.dart';

class EventBasedTimeServer {
  EventBasedTimeServer({
    required Duration Function() getServerTime,
    required DateTime Function() getServerClockTime,
    required DateTime Function() getServerStartTime,
  })  : _getServerGameTime = getServerTime,
        _getServerClockTime = getServerClockTime,
        _getServerStartTime = getServerStartTime;

  final Duration Function() _getServerGameTime;
  final DateTime Function() _getServerClockTime;
  final DateTime Function() _getServerStartTime;

  final StreamInserter<(int, EventServerOut)> _toClientInserter =
      StreamInserter();

  final StreamInterceptor<EventServerIn> _toServerInterceptor =
      StreamInterceptor();

  // Insert events into stream, to send to the server
  // Rename to something more understandable without knowing internals
  Stream<(int, EventServerOut)> toClient(Stream<(int, EventServerOut)> stream) {
    return _toClientInserter.insert(stream);
  }

  // Intercept and remove events from stream, before they reach the core
  Stream<EventServerIn> toServer(Stream<EventServerIn> stream) {
    final interceptedEventStream = _toServerInterceptor.intercept(stream);

    _toServerInterceptor.whenever(
      (event) => event.data == 'time sync start time',
      (event) {
        _toClientInserter.add((
          event.senderID,
          EventServerOut(
            // Filler value
            serverReceiptTimestamp: Duration.zero,
            // Filler value
            generatedTimestamp: Duration.zero,
            senderID: 0,
            data:
                'time sync start time:${_getServerStartTime().toIso8601String()}',
            // Filler value
            eventID: -1,
          )
        ));
      },
      passThrough: false,
    );

    _toServerInterceptor.whenever(
      (event) => event.data == 'time sync clock offset',
      (event) {
        _toClientInserter.add((
          event.senderID,
          EventServerOut(
            // Filler value
            serverReceiptTimestamp: Duration.zero,
            // Filler value
            generatedTimestamp: Duration.zero,
            senderID: 0,
            data:
                'time sync clock offset:${_getServerClockTime().toUtc().toIso8601String()}',
            // Filler value
            eventID: -1,
          )
        ));
      },
      passThrough: false,
    );

    return interceptedEventStream;
  }
}
