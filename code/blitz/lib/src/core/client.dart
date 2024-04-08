import 'dart:async';

import 'package:blitz/client.dart';
import 'package:blitz/src/dart_extensions.dart';

class CoreException implements Exception {
  final String cause;

  const CoreException(this.cause);

  String toString() {
    return "CoreException('$cause')";
  }
}


/// The inner-most core module of anticheat.
///
/// Parameters / inputs are:
/// - An initial environment state.
/// - The latency cutoff. What is the maximum latency between the server and client the game supports, and after how long an event is baked.
/// - Real-time sequence of events. It stores these internally.
/// - A state step function. Given a current environment, step forward a certain amount of time.
///
/// It exposes as output:
/// - The current stable environment state.
/// - Sequence of current, unstable, events. These may be deleted or re-ordered. It will only show unstable events up to the present: not any scheduled future events.
///
/// TODO: Make core generic of the event data type too. ATM its forced to String.
class ClientCore<State, Data> {
  ClientCore({
    required int clientID,
    required Stream<EventClientInPreCore<Data>> inEvents,
    required State initialState,
    required State Function(State, List<EventClientInInCore<Data>>) driver,
    required Duration unstablePeriod,
    required Duration Function() getCurrentEstimatedTime,
    required int Function() generateUniqueEventID,
  })
      : _clientID = clientID,
        _inEvents = inEvents,
        _bakedState = initialState,
        _driver = driver,
        _unstablePeriod = unstablePeriod,
        _getCurrentEstimatedTime = getCurrentEstimatedTime,
        _generateUniqueEventID = generateUniqueEventID;

  final Stream<EventClientInPreCore<Data>> _inEvents;

  final int _clientID;

  /// The latency cutoff.
  final Duration _unstablePeriod;

  State _bakedState;

  // Can contain future events (timestamp past the present).
  // Ordered by timestamp.
  // Contains both local and server events.
  // May contain events which can be baked in.
  List<EventClientInInCore<Data>> _unstableEvents = [];

  /// TODO: is this a sensible initial value?
  Duration _lastConfirmedServerTimestamp = Duration.zero;

  final State Function(State, List<EventClientInInCore<Data>>) _driver;

  // This is our local clients best estimate of what the current time is.
  final Duration Function() _getCurrentEstimatedTime;

  final int Function() _generateUniqueEventID;

  // Ordered by timestamp.
  List<(Duration, Completer<State>)> _futureStateRequests = [];

  Future<void> init() async {
    // await _inEvents.forEach(_addEvent);
    await for (final event in _inEvents) {
      _addEvent(event);
    }
    // TODO: Add handling when finished and errors.
    // TODO: On finish presumably means the game is over? Depends on what scope the Core should have within the wider game logic. Obviously the developer can write whatever logic they want within the driver, but is there an obvious choice?
    // TODO: On error means that a network error may have occurred? Depends on what we define, and what's pre-defined within the Stream spec. If a network error occurred we need the Re-Connection extension to kick in.
  }

  final StreamController<EventClientOut<Data>> _eventsToServerStreamController =
  StreamController();

  // TODO: fix
  // final StreamController<({State state, List<EventClientIn<Data>> unstableEvents})>
  //     _outStreamController = StreamController.broadcast();

  // TODO: prevent too old events from being added. throw error
  void _addEvent(EventClientInPreCore<Data> preCoreEvent) {
    // If the event is too old, throw an error.
    // Insert event into [_unstableEvents], by [generatedTimestamp], then [senderID], then [eventID].
    // Replace existing event if same IDs (used when server confirming local event).
    // Update [_lastConfirmedServerTimestamp] if [event] is the latest event and from server.
    // Send event to server if local.
    // Run [_bakeEventsPastLatencyCutoff].

    // TODO: refactor two below into a separate 'check event' function
    // TODO: should this update [_lastConfirmedServerTimestamp] ?
    // TODO: Check if one or both of these should just ignore error. Doing server-side checks to be safe.
    if ((preCoreEvent is EventClientInFromServer<Data> &&
        preCoreEvent.generatedTimestamp <
            preCoreEvent.serverReceiptTimestamp - _unstablePeriod)) {
      print('ERROR: Event added is too old (past latency cutoff): ${preCoreEvent
          .toShortString()}');
      return;
      // TODO: Add back error throwing. It doesn't propagate and I don't know why
      // throw CoreException(
      //     'Event added is too old (past latency cutoff): $preCoreEvent');
    }


    if (preCoreEvent is EventClientInFromLocalButShared<Data> &&
        preCoreEvent.generatedTimestamp <
            _lastConfirmedServerTimestamp - _unstablePeriod) {
      print('ERROR: Event added is too old (past latency cutoff): ${preCoreEvent
          .toShortString()}');
      return;
      // TODO: Add back error throwing. It doesn't propagate and I don't know why
      // throw CoreException(
      //     'Event added is too old (past latency cutoff): ${preCoreEvent
      //         .toShortString()}');
    }


    // TODO: Could be that event is not being added here? Maybe there's some unstableList configuration which leads to all events being lost?

    final EventClientInInCore<Data> inCoreEvent = switch (preCoreEvent) {
      EventClientInFromServer<Data>() => preCoreEvent,
      EventClientInFromLocalButShared<Data>() => preCoreEvent,
      EventClientInFromLocalPreCore<Data>() =>
          EventClientInFromLocalInCore<Data>(
            generatedTimestamp: _getCurrentEstimatedTime(),
            data: preCoreEvent.data,
            senderID: _clientID,
            eventID: _generateUniqueEventID(),
          ),
    };

    // TODO: Make it replace just on ID, without Timestamp
    final (index, shouldReplaceEvent) =
    _indexToInsertEventInUnstableList(inCoreEvent);
    if (shouldReplaceEvent) {
      _unstableEvents[index] = inCoreEvent;
    } else {
      _unstableEvents.insert(index, inCoreEvent);
    }

    if (inCoreEvent is EventClientInFromServer<Data> &&
        inCoreEvent.serverReceiptTimestamp > _lastConfirmedServerTimestamp) {
      _lastConfirmedServerTimestamp = inCoreEvent.serverReceiptTimestamp;
    }

    if (inCoreEvent is EventClientInFromLocalInCore<Data>) {
      _eventsToServerStreamController.add(EventClientOut<Data>(
        generatedTimestamp: inCoreEvent.generatedTimestamp,
        data: inCoreEvent.data,
        eventID: inCoreEvent.eventID,
      ));
    }

    _bakeEventsPastLatencyCutoff();

    // _receivedEvents++;
    // _completeReceivedEventsRequests();

    // TODO: fix
    // TODO: Be exact about when to bake, and when state will change. We want to minimise these unnecessary updates.
    // pushStateToOutStream();
  }

  void _bakeEventsPastLatencyCutoff() {
    // Separate events which have passed the latency cutoff.
    // Remove local events (they shouldn't be baked, but replaced with a server-confirmed version).
    // Complete future state requests when we bake state for their timestamps.

    final stableTimestampCutoff =
        _lastConfirmedServerTimestamp - _unstablePeriod;
    for (final event in _unstableEvents.copy()) {
      // TODO: check if should be >=
      if (event.generatedTimestamp > stableTimestampCutoff) {
        break;
      }
      _unstableEvents.removeAt(0);
      if (event is EventClientInFromLocalInCore<Data>) {
        continue;
      }
      _completeFutureStateRequestsUpTo(event.generatedTimestamp);
      // Make more efficient by using internal non-copy driver (somehow).
      _bakedState = _driver(_bakedState, [event]);
    }
  }

  (int, bool) _indexToInsertEventInUnstableList(
      EventClientInInCore<Data> event) {
    int min = 0;
    int max = _unstableEvents.length;
    while (min < max) {
      final mid = min + ((max - min) >> 1);
      if (_unstableEvents[mid].compareTo(event) < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    final shouldReplaceEvent = _unstableEvents.hasIndex(min) &&
        _unstableEvents[min].compareTo(event) == 0;
    return (min, shouldReplaceEvent);
  }

  int _indexOfFirstEventAfterTimestamp(Duration timestamp) {
    // Binary search _unstableEvents for the first event which is after [timestamp] (i.e. is stable).
    // Returns 0 or length of list if none or all are stable.
    int min = 0;
    int max = _unstableEvents.length;
    while (min < max) {
      final mid = min + ((max - min) >> 1);
      if (_unstableEvents[mid].generatedTimestamp < timestamp) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return min;
  }

  void _completeFutureStateRequestsUpTo(Duration timestamp) {
    while (_futureStateRequests.isNotEmpty &&
        timestamp >= _futureStateRequests.first.$1) {
      final (_, completer) = _futureStateRequests.removeAt(0);
      completer.complete(_bakedState);
    }
  }

  // TODO: fix with below.
  // void pushStateToOutStream() {
  //   _outStreamController.add((
  //     state: getCurrentState(),
  //     unstableEvents: getUnstableEvents().copy(),
  //   ));
  // }

  // TODO: rename.
  // TODO: fix
  // Stream<({State state, List<EventClientIn> unstableEvents})> get out =>
  //     _outStreamController.stream;

  Stream<EventClientOut<Data>> get eventsToServer =>
      _eventsToServerStreamController.stream;

  // TODO: Turn into a Stream?
  State getCurrentState() {
    _bakeEventsPastLatencyCutoff();
    return _bakedState;
  }

  // TODO: Should be >= ?
  List<EventClientInInCore<Data>> getUnstableEvents() {
    // Remove stable events by baking.
    _bakeEventsPastLatencyCutoff();
    final futureCutoffIndex =
    _indexOfFirstEventAfterTimestamp(_getCurrentEstimatedTime());
    final unstablePastEvents = _unstableEvents.sublist(0, futureCutoffIndex);
    return unstablePastEvents;
  }

  // Returns when state of a certain timestamp is baked.
  Future<State> getStateAt(Duration futureTimestamp) async {
    // TODO: Change this comparison to 'last-baked-timestamp'
    if (futureTimestamp < _lastConfirmedServerTimestamp) {
      throw ArgumentError('Cannot get future state from past timestamp');
    }

    final completer = Completer<State>();
    _futureStateRequests.add((futureTimestamp, completer));
    return completer.future;
  }

}
