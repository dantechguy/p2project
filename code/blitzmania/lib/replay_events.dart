import 'package:blitz/client.dart';

const s = '''50585;dis:-1.0-localpre
50587;dia:1.0-localpre
51677;dis:0.0-localpre
52211;dis:1.0-localpre
56010;dis:0.0-localpre
56833;dis:1.0-localpre
57073;dis:0.0-localpre
57097;dis:-1.0-localpre
57205;dia:0.0-localpre
57490;dia:-1.0-localpre
57650;dis:0.0-localpre
57701;dis:1.0-localpre
58033;dia:0.0-localpre
58079;dis:0.0-localpre
58122;dia:1.0-localpre
58604;dis:-1.0-localpre
59331;dia:0.0-localpre
59412;dia:-1.0-localpre
59415;dis:0.0-localpre
59423;dis:1.0-localpre
60556;dia:0.0-localpre
60601;dis:0.0-localpre
60605;dis:-1.0-localpre
60651;dia:1.0-localpre
61499;dis:0.0-localpre
61864;dis:-1.0-localpre
61971;dis:0.0-localpre
62483;dis:1.0-localpre
62776;dia:0.0-localpre
62879;dia:-1.0-localpre
62948;dis:0.0-localpre
62956;dis:-1.0-localpre
63240;dia:0.0-localpre
63264;dis:0.0-localpre
63323;dia:1.0-localpre
63352;dis:1.0-localpre
64492;dia:0.0-localpre
64572;dia:-1.0-localpre
64623;dis:0.0-localpre
64652;dis:-1.0-localpre
65383;dis:0.0-localpre
65413;dia:0.0-localpre
65505;dia:1.0-localpre
65568;dis:1.0-localpre
66052;dis:0.0-localpre
66058;dia:0.0-localpre''';

List<EventClientInFromLocalPreCoreDebug<String>> getReplayEvents(int clientID, int Function() genEventID) {
  final evts = s.split('\n').map((String line) {
    return EventClientInFromLocalPreCoreDebug<String>(
      generatedTimestamp: Duration(milliseconds: int.parse(line.split(';')[0]) - 45000),
      data: line.split(';')[1].split('-l')[0].substring(1),
      senderID: clientID,
      eventID: genEventID(),
    );
  }).toList();
  print(evts.map((e) => e.toShortString()));
  return evts;
}
