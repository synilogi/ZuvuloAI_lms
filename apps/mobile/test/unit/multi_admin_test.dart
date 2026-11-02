import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/links/deep_link.dart';
import 'package:syniastrolms_mobile/core/network/error_decoder.dart';
import 'package:syniastrolms_mobile/features/auth/presentation/auth_messages.dart';
import 'package:syniastrolms_mobile/l10n/generated/app_localizations_en.dart';

/// The app's side of Super Admin → Admins → each Admin's own LMS: joining the right LMS, and an LMS
/// the platform suspended or closed.
void main() {
  final l10n = AppLocalizationsEn();

  group('a suspended or closed LMS', () {
    test('decodes to its own refusal, still a 403 Forbidden for every existing switch', () {
      final suspended = ErrorDecoder.fromResponse(403, {
        'message': 'This account is suspended. Contact ZuviloAI support to restore access.',
        'code': 'ACADEMY_SUSPENDED',
      });
      expect(suspended, isA<AccountClosedFailure>().having((f) => f.archived, 'archived', false));
      expect(suspended, isA<ForbiddenFailure>());
      final archived = ErrorDecoder.fromResponse(403, {
        'message': 'Closed.',
        'code': 'ACADEMY_ARCHIVED',
      });
      expect(archived, isA<AccountClosedFailure>().having((f) => f.archived, 'archived', true));
      // Other 403s are untouched.
      expect(
        ErrorDecoder.fromResponse(403, {'message': 'No.'}),
        isNot(isA<AccountClosedFailure>()),
      );
    });

    test('is titled plainly on the sign-in screen, with the server’s detail', () {
      final text = authFailureText(
        l10n,
        const AccountClosedFailure(archived: false, message: 'Contact support.'),
      );
      expect(text.title, 'This account is suspended');
      expect(text.detail, 'Contact support.');
      expect(
        authFailureText(l10n, const AccountClosedFailure(archived: true)).title,
        'This account has been closed',
      );
    });
  });

  group('joining an Admin’s LMS', () {
    test('a join link opens Create account with the LMS address filled in', () {
      expect(
        resolveDeepLink('https://zuviloai.com/join/jyotish-vidya'),
        DeepLink.to(AppRoutes.registerFor('jyotish-vidya')),
      );
      expect(AppRoutes.registerFor('jyotish-vidya'), '/register?workspace=jyotish-vidya');
      expect(deepLinkReplacement('/join/jyotish-vidya'), '/register?workspace=jyotish-vidya');
    });

    test('a join link with an address the server could never issue is refused', () {
      for (final bad in ['ab', 'Upper', 'two--hyphens', '-lead', 'x' * 41, 'a.b']) {
        expect(resolveDeepLink('https://zuviloai.com/join/$bad').isFollowed, isFalse, reason: bad);
      }
      expect(resolveDeepLink('https://evil.example/join/jyotish-vidya').isFollowed, isFalse);
    });

    test('the LMS address is taken from a pasted link, and checked as the server checks it', () {
      expect(
        AuthValidators.workspaceFrom(' https://zuviloai.com/join/Jyotish-Vidya/ '),
        'jyotish-vidya',
      );
      expect(AuthValidators.workspaceFrom('kp-school'), 'kp-school');
      expect(AuthValidators.workspace(l10n, 'kp-school'), isNull);
      expect(AuthValidators.workspace(l10n, ''), l10n.validationWorkspace);
      expect(AuthValidators.workspace(l10n, 'no spaces allowed'), l10n.validationWorkspace);
    });

    test('an address no LMS has is said in the app’s words', () {
      expect(
        authFailureText(l10n, const NotFoundFailure(message: 'No LMS has this address.')).title,
        'No LMS has this address',
      );
    });
  });
}
