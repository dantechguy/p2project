import 'package:blitz/src/core/events/server_in.dart';
import 'package:blitz/src/core/events/server_out.dart';
import 'package:blitz/src/core/extensions/event_interceptor.dart';

class UnstablePeriodSyncServer {
  UnstablePeriodSyncServer({
    required Duration unstablePeriod,
    required int Function() generateUniqueEventID,
  })  : _unstablePeriod = unstablePeriod,
        _generateUniqueEventID = generateUniqueEventID;

  final Duration _unstablePeriod;
  final int Function() _generateUniqueEventID;
  late final void Function(int, EventServerOut) _sendEventToClient;
  final EventInterceptor<EventServerIn> _interceptor = EventInterceptor();

  void Function(int, EventServerOut) insertEvents(
      void Function(int, EventServerOut) sendEventToClient) {
    _sendEventToClient = sendEventToClient;
    return sendEventToClient;
  }

  Stream<EventServerIn> interceptEvents(Stream<EventServerIn> eventStream) {
    final interceptedEventStream = _interceptor.interceptEvents(eventStream);

    // We know that Event's senderID is set by the server, so can be trusted and sent back directly.
    _interceptor.whenever(
      (event) => event.data == 'get unstable period',
      (event) {
        _sendEventToClient(
            event.senderID,
            EventServerOut(
              serverReceiptTimestamp: ,
              generatedTimestamp: ,
              senderID: 0,
              data: 'get unstable period;$_unstablePeriod',
              eventID: _generateUniqueEventID(),
            ));
      },
    );

    return interceptedEventStream;
  }
}
