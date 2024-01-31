import 'dart:async';

import 'package:blitz/src/core/events/client_in.dart';
import 'package:blitz/src/core/extensions/event_interceptor.dart';

import '../events/client_out.dart';

class UnstablePeriodSyncClient {
  UnstablePeriodSyncClient({
    required int Function() generateUniqueEventID,
  }) : _generateUniqueEventID = generateUniqueEventID;

  final int Function() _generateUniqueEventID;
  late final void Function(EventClientOut) _sendEventToServer;
  final EventInterceptor<EventClientIn> _interceptor = EventInterceptor();

  late final int _clientID;
  int get clientID => _clientID;

  Future<void> initialise() async {
    _sendEventToServer(
      EventClientOut(
        generatedTimestamp: ,
        data: 'get unstable period',
        eventID: _generateUniqueEventID(),
      ),
    );

    try {
      _clientID = await _interceptor.waitUntil(
          (event) => event.data.startsWith('get unstable period;'),
          timeout: Duration(seconds: 5),
          mapper: (event) => int.parse(event.data.split(';')[1]));
    } on TimeoutException {
      rethrow;
    } on FormatException {
      rethrow;
    }
  }

  void Function(EventClientOut) insertEvents(
      void Function(EventClientOut) sendEventToServer) {
    _sendEventToServer = sendEventToServer;
    return sendEventToServer;
  }

  Stream<EventClientIn> interceptEvents(Stream<EventClientIn> eventStream) {
    return _interceptor.interceptEvents(eventStream);
  }
}
