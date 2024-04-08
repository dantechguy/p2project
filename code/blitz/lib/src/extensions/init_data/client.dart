// Combine:
// - Unstable period sync
// - Client ID sync
// Add via non-event communication

import 'dart:async';
import 'dart:convert';

import 'package:blitz/client.dart';
import 'package:blitz/src/dart_extensions.dart';

class InitialisationDataClient {
  InitialisationDataClient({
    required Duration syncTimeout,
  }) : _syncTimeout = syncTimeout;

  final StreamInserter<String> _toServerInserter = StreamInserter();
  final StreamInterceptor<String> _toClientInterceptor = StreamInterceptor();
  final Duration _syncTimeout;

  late final Map<String, dynamic> _data;

  Map<String, dynamic> get data => _data;

  Future<void> init() async {
    _toServerInserter.add('get initialisation data');

    // TODO: Add auto-prefix system to StreamInterceptor

    try {
      final stringData = await _toClientInterceptor.waitUntil(
        (stringData) => stringData.startsWith('get initialisation data:'),
        timeout: _syncTimeout,
        passThrough: false,
        name: 'Synchronise Initialisation Data',
      );
      _data = jsonDecode(stringData.splitAfterFirst(':'));
    } on TimeoutException {
      rethrow;
    } on FormatException {
      rethrow;
    }
  }

  Stream<String> toServer(Stream<String> dataToServer) {
    return _toServerInserter.insert(dataToServer);
  }

  Stream<String> toClient(Stream<String> dataToClient) {
    return _toClientInterceptor.intercept(dataToClient);
  }
}
