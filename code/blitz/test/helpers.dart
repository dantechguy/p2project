import 'package:blitz/client.dart';
import 'package:blitz/server.dart';
import 'package:blitz/src/events/client_in.dart';

EventClientInPreCore<String> makeEventCIPre(String s) {
  if (s.endsWith('-local')) {
    return makeEventCILocal(s);
  } else if (s.endsWith('-localshared')) {
    return makeEventCILocalShared(s);
  } else if (s.endsWith('-server')) {
    return makeEventCIServer(s);
  } else {
    throw FormatException('invalid makeEvent string: $s');
  }
}

EventClientInFromLocalPreCore<String> makeEventCILocal(String s) {
  final pattern = RegExp(r'^t(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?-local$');
  if (!pattern.hasMatch(s)) throw FormatException('invalid makeEvent string: $s');
  final [ts!, sID!, eID!, data] = pattern.firstMatch(s)!.groups([1, 2, 3, 4]);
  return EventClientInFromLocalPreCore(
    data: data ?? '',
  );
}

EventClientInFromLocalButShared<String> makeEventCILocalShared(String s) {
  final pattern = RegExp(r'^t(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?-localshared$');
  if (!pattern.hasMatch(s)) throw FormatException('invalid makeEvent string: $s');
  final [ts!, sID!, eID!, data] = pattern.firstMatch(s)!.groups([1, 2, 3, 4]);
  return EventClientInFromLocalButShared(
    generatedTimestamp: Duration(milliseconds: int.parse(ts)),
    data: data ?? '',
    senderID: int.parse(sID),
    eventID: int.parse(eID),
  );
}

EventClientInFromServer<String> makeEventCIServer(String s) {
  final pattern = RegExp(r'^t(\d+)-r(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?-server$');
  if (!pattern.hasMatch(s)) throw FormatException('invalid makeEvent string: $s');
  final [ts!, rts!, sID!, eID!, data] = pattern.firstMatch(s)!.groups([1, 2, 3, 4, 5]);
  return EventClientInFromServer(
    serverReceiptTimestamp: Duration(milliseconds: int.parse(rts)),
    generatedTimestamp: Duration(milliseconds: int.parse(ts)),
    data: data ?? '',
    senderID: int.parse(sID),
    eventID: int.parse(eID),
  );
}



EventServerIn<String> makeEventSI(String s) {
  if (s.endsWith('-client')) {
    return makeEventSIClient(s);
  } else if (s.endsWith('-server')) {
    return makeEventSIServer(s);
  } else {
    throw FormatException('invalid makeEvent string: $s');
  }
}

EventServerInFromClient<String> makeEventSIClient(String s) {
  final pattern = RegExp(r'^t(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?-client$');
  if (!pattern.hasMatch(s)) throw FormatException('invalid makeEvent string: $s');
  final [ts!, sID!, eID!, data] = pattern.firstMatch(s)!.groups([1, 2, 3, 4]);
  return EventServerInFromClient(
    generatedTimestamp: Duration(milliseconds: int.parse(ts)),
    data: data ?? '',
    senderID: int.parse(sID),
    eventID: int.parse(eID),
  );
}

EventServerInFromServer<String> makeEventSIServer(String s) {
  final pattern = RegExp(r'^d(\d+)-server$');
  if (!pattern.hasMatch(s)) throw FormatException('invalid makeEvent string: $s');
  final [data!] = pattern.firstMatch(s)!.groups([1]);
  return EventServerInFromServer(
    data: data,
  );
}

EventServerOut<String> makeEventSO(String s) {
  final pattern = RegExp(r'^t(\d+)-r(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?$');
  if (!pattern.hasMatch(s)) throw FormatException('invalid makeEvent string: $s');
  final [ts!, rts!, sID!, eID!, data] = pattern.firstMatch(s)!.groups([1, 2, 3, 4, 5]);
  return EventServerOut(
    serverReceiptTimestamp: Duration(milliseconds: int.parse(rts)),
    generatedTimestamp: Duration(milliseconds: int.parse(ts)),
    data: data ?? '',
    senderID: int.parse(sID),
    eventID: int.parse(eID),
  );
}
