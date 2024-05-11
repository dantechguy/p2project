
import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


void main()async  {
	final server = await HttpServer.bind('127.0.0.1', 4041);

	server.transform(WebSocketTransformer()).listen((WebSocket ws) {
		print('connected');
		final channel = IOWebSocketChannel(ws);
		
		channel.stream.forEach((el) {});

		final v = '[{u: 1, p: [-37.554779052734375, -77.20777130126953], v: [-8.547920632381384e-44, -1.555441295400547e-43], d: -2.656373516482946, c: 4278313536}]';

		Timer.periodic(Duration(milliseconds: 60), (timer) {
			channel.sink.add(v);
		});
	});
}
