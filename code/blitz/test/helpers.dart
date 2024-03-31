import 'package:blitz/client.dart';
import 'package:blitz/server.dart';

EventClientIn<String> makeEventCI(String s) {
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

EventClientInFromLocal<String> makeEventCILocal(String s) {
  final pattern = RegExp(r'^t(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?-localr$');
  final [ts!, sID!, eID!, data] = pattern.firstMatch(s)!.groups([1, 2, 3, 4]);
  return EventClientInFromLocal(
    generatedTimestamp: Duration(milliseconds: int.parse(ts)),
    data: data ?? '',
    senderID: int.parse(sID),
    eventID: int.parse(eID),
  );
}

EventClientInFromLocalButShared<String> makeEventCILocalShared(String s) {
  final pattern = RegExp(r'^t(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?-localshared$');
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
  final pattern = RegExp(r'^t(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?$');
  final [ts!, sID!, eID!, data] = pattern.firstMatch(s)!.groups([1, 2, 3, 4]);
  return EventServerIn(
    generatedTimestamp: Duration(milliseconds: int.parse(ts)),
    data: data ?? '',
    senderID: int.parse(sID),
    eventID: int.parse(eID),
  );
}

EventServerOut<String> makeEventSO(String s) {
  final pattern = RegExp(r'^t(\d+)-r(\d+)-s(\d+)-e(\d+)(?:-d(\d+))?$');
  final [ts!, rts!, sID!, eID!, data] = pattern.firstMatch(s)!.groups([1, 2, 3, 4, 5]);
  return EventServerOut(
    serverReceiptTimestamp: Duration(milliseconds: int.parse(rts)),
    generatedTimestamp: Duration(milliseconds: int.parse(ts)),
    data: data ?? '',
    senderID: int.parse(sID),
    eventID: int.parse(eID),
  );
}
