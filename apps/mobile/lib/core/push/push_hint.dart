import 'package:flutter/foundation.dart';

import '../../app/routing/routes.dart';

/// A push from the academy (§12, §18). `apps/api/src/lib/push.ts` sends a **hint and nothing else** —
/// `data: {notificationId, category}` with no title, body or content — precisely so that what a reader
/// sees is always what the API served them, never what arrived on the wire.
///
/// So the payload is treated as untrusted: it is read for an id and a category, both validated, and
/// anything else in it is ignored. Nothing from a push is ever shown; the app fetches
/// `/notifications/:id` and shows that.

/// The categories the academy sends. One it has added since this build shipped is [unknown], which is
/// still routable — the notification itself is what matters, not the label on the envelope.
enum PushCategory { course, assignment, quiz, live, certificate, account, system, billing, unknown }

PushCategory pushCategoryOf(String? raw) => switch (raw) {
  'course' => PushCategory.course,
  'assignment' => PushCategory.assignment,
  'quiz' => PushCategory.quiz,
  'live' => PushCategory.live,
  'certificate' => PushCategory.certificate,
  'account' => PushCategory.account,
  'system' => PushCategory.system,
  'billing' => PushCategory.billing,
  _ => PushCategory.unknown,
};

final _notificationId = RegExp(r'^[A-Za-z0-9_-]{8,64}$');

/// A push the app will act on.
@immutable
class PushHint {
  const PushHint({required this.notificationId, required this.category});

  final String notificationId;
  final PushCategory category;

  /// Where tapping it goes. The notification's own screen reads the API and follows the academy's own
  /// action from there (§5.4) — the push never says where to go.
  String get route => AppRoutes.notification(notificationId);

  @override
  bool operator ==(Object other) =>
      other is PushHint && other.notificationId == notificationId && other.category == category;

  @override
  int get hashCode => Object.hash(notificationId, category);
}

/// Reads a push payload, or returns `null` for one the app will not act on.
///
/// Dropped without a word: a payload with no `notificationId`, one whose id is not the shape the API
/// issues, and one carrying content where the academy sends none. A push is a hint to go and ask; a
/// payload that tries to be the message itself is not one the academy sent.
PushHint? readPushHint(Map<Object?, Object?> data) {
  final id = data['notificationId'];
  if (id is! String || !_notificationId.hasMatch(id)) return null;
  final category = data['category'];
  if (category != null && category is! String) return null;
  return PushHint(notificationId: id, category: pushCategoryOf(category as String?));
}

/// Whether a payload carries anything that would be *shown* — a title, a body, a message. The academy
/// sends none of it, so a payload that has some did not come from the academy's own transport, and is
/// worth counting as malformed rather than rendering.
bool payloadCarriesContent(Map<Object?, Object?> data) =>
    const ['title', 'body', 'message', 'summary', 'image'].any(data.containsKey);
