import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Hands text to the platform's share sheet. A platform capability like connectivity: behind a
/// provider, so a test can see exactly what would leave the app without a plugin.
typedef ShareText = Future<void> Function({required String text, String? subject});

final shareTextProvider = Provider<ShareText>((ref) => shareThroughPlatform);

/// The platform's own share sheet.
Future<void> shareThroughPlatform({required String text, String? subject}) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
}
