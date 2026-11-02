import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// The headers an image or video request carries. Read from secure storage each time the session
/// changes; the token never leaves this layer and is never written to a log (§18).
final mediaAuthHeadersProvider = FutureProvider<Map<String, String>>((ref) async {
  final token = await ref.watch(tokenStoreProvider).read();
  return token == null ? const {} : {'Authorization': 'Bearer $token'};
});
