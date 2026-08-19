import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<bool>? _connectivitySubscription;

  // ---------------------------------------------------------------------------
  // CHECK CURRENT CONNECTIVITY
  // ---------------------------------------------------------------------------

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();

    return _hasConnection(results);
  }

  // ---------------------------------------------------------------------------
  // CONNECTIVITY STREAM
  // ---------------------------------------------------------------------------

  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged
        .map(_hasConnection)
        .distinct();
  }

  // ---------------------------------------------------------------------------
  // START LISTENING
  // ---------------------------------------------------------------------------

  void listen({
    required void Function(bool isOnline) onChanged,
  }) {
    _connectivitySubscription =
        connectionStream.listen(onChanged);
  }

  // ---------------------------------------------------------------------------
  // STOP LISTENING
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();

    _connectivitySubscription = null;
  }

  // ---------------------------------------------------------------------------
  // CHECK CONNECTION TYPE
  // ---------------------------------------------------------------------------

  bool _hasConnection(
      List<ConnectivityResult> results,
      ) {
    return results.any(
          (result) =>
      result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }
}