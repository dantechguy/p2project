

// Exposes stream of events received from the server which are inputted into the Core, and a method to send events to the server which the Core calls.

import 'package:blitz/src/core/event.dart';

class NetworkingClient {
  Future<void> initialise() async {

  }

  // Forwards received events from its connection to the server to the Core.
  Stream<Event> get serverEventStream {
    throw UnimplementedError();
  }

  // Forwards events received from the Core to the server.
  // TODO: Should be a streamcontroller perhaps? No need really, this suffices.
  void sendEvent(Event event) {

  }
}