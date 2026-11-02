import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syniastrolms_mobile/core/connectivity/connectivity_service.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  test('online when any interface is up; changes are de-duplicated', () async {
    final connectivity = _MockConnectivity();
    final changes = StreamController<List<ConnectivityResult>>();
    addTearDown(changes.close);
    when(connectivity.checkConnectivity).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => connectivity.onConnectivityChanged).thenAnswer((_) => changes.stream);

    final service = ConnectivityService(connectivity);
    expect(await service.isOnline(), isTrue);

    final seen = <bool>[];
    final sub = service.onlineChanges.listen(seen.add);
    changes
      ..add([ConnectivityResult.none])
      ..add([ConnectivityResult.none])
      ..add([ConnectivityResult.mobile, ConnectivityResult.vpn]);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(seen, [false, true]);
  });
}
