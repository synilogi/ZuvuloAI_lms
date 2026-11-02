import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A hint about connectivity (§17). It only says whether the device has a network interface — the
/// real signal is a failed request — so it drives the offline banner and "retry when back", never a
/// decision to skip a request.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<bool> isOnline() async => _online(await _connectivity.checkConnectivity());

  /// Emits on every change, de-duplicated.
  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged.map(_online).distinct();
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

/// Current online hint; starts optimistic (true) until the platform answers.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isOnline();
  yield* service.onlineChanges;
});
