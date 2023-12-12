import 'package:blitzmania/core/event.dart';

import '../shared/env.dart';

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
class Core {
  Core({
    required Stream<Event> eventStream,
    required Env initialEnv,
    required Env Function(Env, List<Event>) driver,
    required Duration unstablePeriod,
  })  : _bakedEnv = initialEnv,
        _driver = driver,
        _unstablePeriod = unstablePeriod {
    _listenToEventStream(eventStream);
  }

  void _listenToEventStream(Stream<Event> eventStream) {
    eventStream.forEach(addEvent);
    // TODO: Add handling when finished and errors.
    // TODO: On finish presumably means the game is over? Depends on what scope the Core should have within the wider game logic. Obviously the developer can write whatever logic they want within the driver, but is there an obvious choice?
    // TODO: On error means that a network error may have occurred? Depends on what we define, and what's pre-defined within the Stream spec. If a network error occurred we need the Re-Connection extension to kick in.
  }

  /// The latency cutoff.
  final Duration _unstablePeriod;

  // TODO: Initialise with starting state.
  Env _bakedEnv;

  // Can contain events with a timestamp past the current timetamp: schedule future events.
  List<Event> _unstableEvents = [];

  // TODO: consider changing datatype
  /// Each event received from the server includes the server timestamp when it was received.
  /// We store this latest server timestamp to know when we can safely bake events.
  /// TODO: is this a sensible initial value?
  Duration _lastConfirmedServerTimestamp = Duration.zero;

  // TODO: Keep allowing to change? Or make immutable? I think immutable is best. Any dynamic change of behaviour can be built-in (?).
  // TODO: Make a driver typedef
  final Env Function(Env, List<Event>) _driver;

  // TODO: Turn into a stream? This would make it a parameter, and more explicitly an input to the system. But a function is less language (dart) specific.
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

    final cutoffTimestamp = _lastConfirmedServerTimestamp - _unstablePeriod;
    final cutoffIndex = _indexOfFirstEventPastTimestamp(cutoffTimestamp);
    final eventsToBake = _unstableEvents.sublist(0, cutoffIndex);
    _unstableEvents.removeRange(0, cutoffIndex);
    _bakedEnv = _driver(_bakedEnv, eventsToBake);
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
  Env getCurrentState() {
    _bakeEventsPastLatencyCutoff();
    return _bakedEnv;
  }

  // TODO: make a getter?
  // TODO: return a copy to prevent external modification?
  // Must remove events past the present. What is its source for the present timestamp?
  List<Event> getUnstableEvents() {
    // Removing events before doing a second binary search will make the second search faster.
    _bakeEventsPastLatencyCutoff();

    // TODO: What is the source for the current time?
    final currentTimestamp;
    final cutoffIndex = _indexOfFirstEventPastTimestamp(currentTimestamp);
    final unstablePastEvents = _unstableEvents.sublist(0, cutoffIndex);
    return unstablePastEvents;
  }
}
