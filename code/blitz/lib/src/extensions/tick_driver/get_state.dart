import 'package:blitz/client.dart';

State getTickedState<State, Data>((List<EventClientInPreCore<Data>>, State) wrappedState) {
  return wrappedState.$2;
}