import 'package:blitz/client.dart';

// (List<EventClientInPreCore<String>>, State) Function(
//         (List<EventClientInPreCore<String>>, State), List<EventClientInPreCore<String>>)
//     stringTickedDriver<State>({
//   required State Function(State, List<EventClientInPreCore<String>>) driver,
// }) {
//   return ((List<EventClientInPreCore<String>>, State) wrappedState,
//           List<EventClientInPreCore<String>> inEvents) =>
//       tickedDriver<State, String>(
//         driver: driver,
//         isInputEvent: (event) => event.data.startsWith('input:'),
//         isTickEvent: (event) => event.data == 'tick',
//       )(wrappedState, inEvents);
// }
