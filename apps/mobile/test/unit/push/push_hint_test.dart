import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/push/push_hint.dart';

/// A push payload is untrusted (§18). `apps/api/src/lib/push.ts` sends `{notificationId, category}`
/// and nothing else, so anything more — or anything less — did not come from the academy's transport.
const _id = 'cmumqihbi001rmmos6cypzr5m';

void main() {
  group('a push the academy sent', () {
    test('is read as the hint it is', () {
      final hint = readPushHint(const {'notificationId': _id, 'category': 'live'});

      expect(hint, isNotNull);
      expect(hint!.notificationId, _id);
      expect(hint.category, PushCategory.live);
    });

    test('opens the notification, and lets the API say where that leads', () {
      final hint = readPushHint(const {'notificationId': _id, 'category': 'certificate'})!;

      // Never a route the push chose: the notification's own screen follows the academy's action.
      expect(hint.route, '/notifications/$_id');
    });

    test('every category the academy sends is understood', () {
      for (final (word, category) in [
        ('course', PushCategory.course),
        ('assignment', PushCategory.assignment),
        ('quiz', PushCategory.quiz),
        ('live', PushCategory.live),
        ('certificate', PushCategory.certificate),
        ('account', PushCategory.account),
        ('system', PushCategory.system),
        ('billing', PushCategory.billing),
      ]) {
        expect(readPushHint({'notificationId': _id, 'category': word})!.category, category);
      }
    });

    test('a category added since this build shipped is still routable', () {
      final hint = readPushHint(const {'notificationId': _id, 'category': 'something-new'});

      expect(hint, isNotNull, reason: 'the notification matters; the label on it does not');
      expect(hint!.category, PushCategory.unknown);
    });

    test('a hint with no category at all is still a hint', () {
      final hint = readPushHint(const {'notificationId': _id});

      expect(hint, isNotNull);
      expect(hint!.category, PushCategory.unknown);
    });
  });

  group('a push the app will not act on', () {
    test('one with no notification id is dropped', () {
      expect(readPushHint(const {'category': 'live'}), isNull);
      expect(readPushHint(const <String, Object?>{}), isNull);
    });

    test('an id that was never issued is dropped', () {
      for (final id in ['', 'ab', '../../etc/passwd', 'abc def', 'a' * 300, r'$(whoami)']) {
        expect(readPushHint({'notificationId': id}), isNull, reason: id);
      }
    });

    test('an id that is not even a string is dropped', () {
      expect(readPushHint(const {'notificationId': 42}), isNull);
      expect(readPushHint(const {'notificationId': null}), isNull);
      expect(
        readPushHint(const {
          'notificationId': ['a'],
        }),
        isNull,
      );
    });

    test('a category that is not a string is dropped rather than coerced', () {
      expect(readPushHint(const {'notificationId': _id, 'category': 7}), isNull);
    });
  });

  group('a payload that tries to be the message', () {
    test('is recognised for what it is', () {
      // The academy sends no title, body or image. One that does was not sent by it.
      for (final key in ['title', 'body', 'message', 'summary', 'image']) {
        expect(
          payloadCarriesContent({'notificationId': _id, key: 'Pay here now'}),
          isTrue,
          reason: key,
        );
      }
    });

    test('and the academy\'s own hint is not mistaken for one', () {
      expect(payloadCarriesContent(const {'notificationId': _id, 'category': 'live'}), isFalse);
    });
  });
}
