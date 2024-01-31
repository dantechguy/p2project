import 'dart:async';

import 'events/client_in.dart';
import 'events/client_out.dart';

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
///
class Core<State> {
  Core({
    required Stream<EventClientIn> eventStream,
    required State initialState,
    required State Function(State, List<EventClientIn>) driver,
    required Duration unstablePeriod,
    required Duration Function() getCurrentEstimatedTime,
    required void Function(EventClientOut) sendEventToServer,
  })  : _bakedState = initialState,
        _driver = driver,
        _unstablePeriod = unstablePeriod,
        _getCurrentEstimatedTime = getCurrentEstimatedTime,
        _sendEventToServer = sendEventToServer {
    _listenToEventStream(eventStream);
  }

  void _listenToEventStream(Stream<EventClientIn> eventStream) {
    eventStream.forEach(_addEvent);
    // TODO: Add handling when finished and errors.
    // TODO: On finish presumably means the game is over? Depends on what scope the Core should have within the wider game logic. Obviously the developer can write whatever logic they want within the driver, but is there an obvious choice?
    // TODO: On error means that a network error may have occurred? Depends on what we define, and what's pre-defined within the Stream spec. If a network error occurred we need the Re-Connection extension to kick in.
  }

  final void Function(EventClientOut) _sendEventToServer;

  /// The latency cutoff.
  final Duration _unstablePeriod;

  // TODO: Initialise with starting state.
  State _bakedState;

  // Can contain future events (timestamp past the present).
  // Ordered by timestamp.
  // Contains both local and server events.
  // May contain events which can be baked in.
  List<EventClientIn> _unstableEvents = [];

  // TODO: consider changing datatype
  /// Each event received from the server includes the server timestamp when it was received.
  /// We store this latest server timestamp to know when we can safely bake events.
  /// TODO: is this a sensible initial value?
  Duration _lastConfirmedServerTimestamp = Duration.zero;

  // TODO: Keep allowing to change? Or make immutable? I think immutable is best. Any dynamic change of behaviour can be built-in (?).
  // TODO: Make a driver typedef
  final State Function(State, List<EventClientIn>) _driver;

  // This is our local clients best estimate of what the current time is.
  final Duration Function() _getCurrentEstimatedTime;

  // Ordered by timestamp.
  List<(Duration, Completer<State>)> _futureStateRequests = [];

  // TODO: Turn private, and have the parameter stream be the only input.
  // Adds a LOCAL event to the system. This means it will be sent to the server, and marked as local, meaning it'll be removed if no server confirmation is received.
  void _addEvent(EventClientIn event) {
    // Insert event into [_unstableEvents], by [generatedTimestamp], then [senderID], then [eventID].
    // Replace existing event if same IDs (used when server confirming local event).
    // Update [_lastConfirmedServerTimestamp] if [event] is the latest event.
    // Run [_bakeEventsPastLatencyCutoff].

    final (index, shouldReplaceEvent) =
        _indexToInsertEventInUnstableList(event);
    if (shouldReplaceEvent) {
      _unstableEvents[index] = event;
    } else {
      _unstableEvents.insert(index, event);
    }

    if (event is EventClientInFromServer &&
        event.serverReceiptTimestamp > _lastConfirmedServerTimestamp) {
      _lastConfirmedServerTimestamp = event.serverReceiptTimestamp;
    }

    _bakeEventsPastLatencyCutoff();
  }

  void _bakeEventsPastLatencyCutoff() {
    // Separate events which have passed the latency cutoff.
    // Remove local events (they shouldn't be baked, but replaced with a server-confirmed version).
    // Complete future state requests when we bake state for their timestamps.

    final stableTimestampCutoff =
        _lastConfirmedServerTimestamp - _unstablePeriod;
    for (final event in _unstableEvents) {
      if (event.generatedTimestamp > stableTimestampCutoff) {
        break;
      }
      if (event is EventClientInFromLocal) {
        continue;
      }
      _completeFutureStateRequestsBefore(event.generatedTimestamp);
      // Make more efficient by using internal non-copy driver (somehow).
      _bakedState = _driver(_bakedState, [event]);
    }
  }

  (int, bool) _indexToInsertEventInUnstableList(EventClientIn event) {
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
    final shouldReplaceEvent = _unstableEvents.isNotEmpty &&
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

  void _completeFutureStateRequestsBefore(Duration timestamp) {
    while (_futureStateRequests.isNotEmpty &&
        timestamp >= _futureStateRequests.first.$1) {
      final (_, completer) = _futureStateRequests.removeAt(0);
      completer.complete(_bakedState);
    }
  }

  // TODO: make a getter?
  State getCurrentState() {
    _bakeEventsPastLatencyCutoff();
    return _bakedState;
  }

  // TODO: make a getter?
  List<EventClientIn> getUnstableEvents() {
    // Remove stable events by baking.
    _bakeEventsPastLatencyCutoff();
    final futureCutoffIndex =
        _indexOfFirstEventAfterTimestamp(_getCurrentEstimatedTime());
    final unstablePastEvents = _unstableEvents.sublist(0, futureCutoffIndex);
    return unstablePastEvents;
  }

  // Returns when state of a certain timestamp is baked.
  Future<State> getStateAt(Duration futureTimestamp) async {
    if (futureTimestamp < _lastConfirmedServerTimestamp) {
      throw ArgumentError('Cannot get future state from past timestamp');
    }

    final completer = Completer<State>();
    _futureStateRequests.add((futureTimestamp, completer));
    return completer.future;
  }
}
