import 'dart:async';

import 'package:blitz/server.dart';
import 'package:blitz/src/dart_extensions.dart';

/*
TODO:
  - Supply init_data with current [_lastSavedState].
  - Supply stream_split_buffer with filter to buffer events since [_lastSavedState].
  -
 */

/// Can issue multiple state save requests simultaneously.
class ReConnectionServer<Data> {
  ReConnectionServer({
    required String initialState,
    required void Function(bool Function(String)?) updateBufferFilter,
    required List<int> Function() getAllClientIDs,
    required Duration stateSavePeriod,
    required Duration clientResponseTimeout,
    required void Function(int) removeClientForIgnoring,
    required String hashState(String),
  })  : _lastSavedState = initialState,
        _updateBufferFilter = updateBufferFilter,
        _getAllClientIDs = getAllClientIDs,
        _stateSavePeriod = stateSavePeriod,
        _clientResponseTimeout = clientResponseTimeout,
        _removeClientForIgnoring = removeClientForIgnoring,
        _hashState = hashState;

  String _lastSavedState;

// Supplies stream_split_buffer with filter to buffer events only since [_lastSavedState].
  final void Function(bool Function(String)?) _updateBufferFilter;

  final List<int> Function() _getAllClientIDs;

  final Duration _stateSavePeriod;

// Any client who takes longer than this will be kicked.
  final Duration _clientResponseTimeout;

  final void Function(int) _removeClientForIgnoring;

  final String Function(String) _hashState;

// Passed to init_data module to send to client.
  String getLastSavedState() => _lastSavedState;

  int nextClientToRequestStateFrom = 0;

  Duration _lastSavedStateTimestamp = Duration.zero;

// ======== Network =========

  final StreamInserter<(int clientID, String data)> _toClientInserter =
      StreamInserter();
  final StreamInterceptor<(int, String)> _toServerInterceptor =
      StreamInterceptor();

  Stream<(int, String)> toClient(Stream<(int, String)> stream) =>
      _toClientInserter.insert(stream);

  Stream<(int, String)> toServer(Stream<(int, String)> stream) =>
      _toServerInterceptor.intercept(stream);

// =============== Issue request ===============

  Future<void> _issueStateSaveRequest(Duration saveTimestamp) async {
    final clientsInRequest = _getAllClientIDs();
    if (clientsInRequest.isEmpty) return;

    // Send hash request to all clients
    for (final clientID in clientsInRequest) {
      _toClientInserter
          .add((clientID, 'get state hash:${saveTimestamp.inMicroseconds}'));
    }

    // Wait for hash response from all clients
    final List<Future<(int, String)>> responseFutures = [];
    for (final clientID in clientsInRequest) {
      final future = _toServerInterceptor
          .waitUntil(
            (r) => r.$1 == clientID && r.$2.startsWith('get state hash:'),
            passThrough: false,
            timeout: _clientResponseTimeout,
            name:
                'Client $clientID responds with save state hash for time: $saveTimestamp',
          )
          .catchError(
            (error) => (clientID, 'timeout'),
            test: (error) => error is TimeoutException,
          );
      responseFutures.add(future);
    }
    final responses = await Future.wait(responseFutures);

    // Remove clients with invalid or timeout hash responses
    for (final response in responses) {
      final (clientID, data) = response;
      if (data == 'timeout' || !data.startsWith('get state hash:')) {
        clientsInRequest.remove(clientID);
        _removeClientForIgnoring(clientID);
      }
    }
    if (clientsInRequest.isEmpty) return;

    // Check all responses identical
    final hashResponses =
        responses.map((r) => (r.$1, r.$2.split(':')[1])).toList();
    // TODO: Run driver on server to determine who is lying.
    if (!hashResponses.map((r) => r.$2).allEqual()) {
      print('ERROR! Not all save state hashes identical: $hashResponses');
      return;
    }

    // Send serialised state request to one client. Repeat until valid response or no clients left.
    late final serialisedSavedState;
    while (clientsInRequest.isNotEmpty) {
      final stateRequestClientID =
          clientsInRequest.wrappedElementAt(nextClientToRequestStateFrom++);
      // Send request to client.
      _toClientInserter.add((
        stateRequestClientID,
        'get saved state${saveTimestamp.inMicroseconds}'
      ));
      try {
        // Wait for response.
        final (_, response) = await _toServerInterceptor.waitUntil(
          (r) =>
              r.$1 == stateRequestClientID &&
              r.$2.startsWith('get saved state:'),
          passThrough: false,
          timeout: _clientResponseTimeout,
          name:
              'Client $stateRequestClientID responds with saved state for time: $saveTimestamp',
        );
        // Check response is formatted correctly.
        if (!response.startsWith('get saved state:')) throw FormatException();
        // Check response hash matches earlier hash.
        final responseHash = _hashState(response);
        if (responseHash != hashResponses.first.$2) throw FormatException();
        serialisedSavedState = response;
      } on TimeoutException {
        clientsInRequest.remove(stateRequestClientID);
        _removeClientForIgnoring(stateRequestClientID);
      } on FormatException {
        clientsInRequest.remove(stateRequestClientID);
        _removeClientForIgnoring(stateRequestClientID);
      }
    }
    if (clientsInRequest.isEmpty) return;

    _updateSavedState(saveTimestamp, serialisedSavedState);
  }

  void _updateSavedState(Duration stateTimestamp, String serialisedState) {
    // TODO: this synchronisation mechanism doesn't work. see next-steps.
    _lastSavedState = serialisedState;
    _lastSavedStateTimestamp = _lastSavedStateTimestamp;
    // _updateBufferFilter()
  }
}
