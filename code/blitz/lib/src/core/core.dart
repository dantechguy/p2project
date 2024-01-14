
import 'package:blitz/src/core/event.dart';

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
///
class Core<State> {
  Core({
    required Stream<Event> eventStream,
    required State initialState,
    required State Function(State, List<Event>) driver,
    required Duration unstablePeriod,
    required Duration Function() getCurrentEstimatedTime,
    required void Function(Event) sendEventToServer,
  })  : _bakedState = initialState,
        _driver = driver,
        _unstablePeriod = unstablePeriod,
        _getCurrentEstimatedTime = getCurrentEstimatedTime,
        _sendEventToServer = sendEventToServer {
    _listenToEventStream(eventStream);
  }

  void _listenToEventStream(Stream<Event> eventStream) {
    eventStream.forEach(addEvent);
    // TODO: Add handling when finished and errors.
    // TODO: On finish presumably means the game is over? Depends on what scope the Core should have within the wider game logic. Obviously the developer can write whatever logic they want within the driver, but is there an obvious choice?
    // TODO: On error means that a network error may have occurred? Depends on what we define, and what's pre-defined within the Stream spec. If a network error occurred we need the Re-Connection extension to kick in.
  }

  final void Function(Event) _sendEventToServer;

  /// The latency cutoff.
  final Duration _unstablePeriod;

  // TODO: Initialise with starting state.
  State _bakedState;

  // Can contain events with a timestamp past the current timetamp: schedule future events.
  List<Event> _unstableEvents = [];

  // TODO: consider changing datatype
  /// Each event received from the server includes the server timestamp when it was received.
  /// We store this latest server timestamp to know when we can safely bake events.
  /// TODO: is this a sensible initial value?
  Duration _lastConfirmedServerTimestamp = Duration.zero;

  // TODO: Keep allowing to change? Or make immutable? I think immutable is best. Any dynamic change of behaviour can be built-in (?).
  // TODO: Make a driver typedef
  final State Function(State, List<Event>) _driver;

  // This is our local clients best estimate of what the current time is.
  final Duration Function() _getCurrentEstimatedTime;

  // TODO: Turn into a stream? This would make it a parameter, and more explicitly an input to the system. But a function is less language (dart) specific.
  // Adds a LOCAL event to the system. This means it will be sent to the server, and marked as local, meaning it'll be removed if no server confirmation is received.
  void addEvent(Event event) {
    // Current implementation bakes new state as soon as possible (an event exceeds the latency cutoff).
    // When should you check for this? When adding a new event?

    // TODO: Add [event] in the correct position in [_unstableEvents], based on its timestamp.
    // TODO: update [_lastConfirmedServerTimestamp] if [event] is the latest event.
    // TODO: run [_bakeEventsPastLatencyCutoff].
    final insertionIndex =
        _indexOfFirstEventPastTimestamp(event.generatedTimestamp);
    _unstableEvents.insert(insertionIndex, event);
    if (event.serverReceiptTimestamp > _lastConfirmedServerTimestamp) {
      _lastConfirmedServerTimestamp = event.serverReceiptTimestamp;
    }
    _bakeEventsPastLatencyCutoff();
  }

  void _bakeEventsPastLatencyCutoff() {
    // Needs to be fast.
    // How do we efficiently find the first event which is past the latency cutoff?
    // If this is called really often, how can we re-use computation to make this efficient?
    // We know that the last time this was called, all events before the border are now gone.
    //   We could also find out the time since this last happened. So we would have the amount of time
    //   passed for all of the current events to added to the list.
    // We could approximate the index of the border element if we had an estimated rate of events arriving.
    //   I guess the best thing we can do is a binary search here if we want to keep it simple and performant
    //   over a large variety of event arrival rates.

    // TODO: In a peer-to-peer system, there is no last confirmed server timestamp. How do you know when to bake, and when you've received all events past a certain timestamp? If using TCP, you can keep a lastConfirmedClientTimestamp for each client, and use that to know when you can bake events from them past a certain timestamp. This doesn't work if using UDP. Also, what if a client misbehaves or stops sending events, then no events can be baked. You need some way to enforce the latency cutoff.
    final cutoffTimestamp = _lastConfirmedServerTimestamp - _unstablePeriod;
    final cutoffIndex = _indexOfFirstEventPastTimestamp(cutoffTimestamp);
    final eventsToBake = _unstableEvents.sublist(0, cutoffIndex);
    _unstableEvents.removeRange(0, cutoffIndex);
    _bakedState = _driver(_bakedState, eventsToBake);
  }

  int _indexOfFirstEventPastTimestamp(Duration timestamp) {
    // Binary search _unstableEvents for the first event which is past [timestamp] (i.e. is stable).
    // Returns 0 or length of list if none or all are stable.

    // AI generated code. Looks good.
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

  // TODO: make a getter?
  State getCurrentState() {
    _bakeEventsPastLatencyCutoff();
    return _bakedState;
  }

  // TODO: make a getter?
  // TODO: return a copy to prevent external modification?
  // Must remove events past the present. What is its source for the present timestamp?
  List<Event> getUnstableEvents() {
    // Removing events before doing a second binary search will make the second search faster.
    _bakeEventsPastLatencyCutoff();

    // TODO: What is the source for the current time?
    final currentTimestamp = _getCurrentEstimatedTime();
    final cutoffIndex = _indexOfFirstEventPastTimestamp(currentTimestamp);
    final unstablePastEvents = _unstableEvents.sublist(0, cutoffIndex);
    return unstablePastEvents;
  }
}
