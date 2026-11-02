import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/links/deep_link.dart';

/// A link from outside the app is untrusted input (§18). These tests are mostly about what the app
/// **refuses**: the host it does not answer for, the scheme that could be read on the way, and the id
/// that was never one the API issued.
const _host = 'zuviloai.com';

/// A real credential id, as `/verify` prints them.
const _credential = 'SA-JY-2026-00142';

/// A cuid2-shaped id, as the API issues them.
const _id = 'cmumqihbi001rmmos6cypzr5m';

/// A reset token as the API issues it: 64 hex characters.
const _realToken = '3f9a1c7e20b84d65af0e2d19c8b73540e6a92f14bc385d70a1fe6b29d4c80713';

void main() {
  group('a link the academy sent', () {
    test('a reset link opens the reset screen with its token', () {
      const token = _realToken;
      final link = resolveDeepLink('https://$_host/reset-password/$token');

      expect(link.isFollowed, isTrue);
      expect(link.route, '/reset-password/$token');
      // The reset screen is reached without signing in — that is the whole point of it.
      expect(link.needsSignIn, isFalse);
    });

    test('a verification link opens the public check', () {
      final link = resolveDeepLink('https://$_host/verify/$_credential');

      expect(link.route, '/verify/$_credential');
      expect(link.needsSignIn, isFalse);
    });

    test('a course link opens the catalogue entry', () {
      final link = resolveDeepLink('https://$_host/courses/foundations-of-vedic-astrology');

      expect(link.route, '/catalog/foundations-of-vedic-astrology');
      expect(link.needsSignIn, isFalse);
    });

    test('a learning link is the reader\'s own, so it signs in first', () {
      final link = resolveDeepLink('https://$_host/learn/$_id');

      expect(link.route, '/learn/$_id');
      expect(link.needsSignIn, isTrue);
    });

    test('a lesson link carries both ids', () {
      final link = resolveDeepLink('https://$_host/learn/$_id/lessons/${_id}x');

      expect(link.route, '/learn/$_id/lessons/${_id}x');
      expect(link.needsSignIn, isTrue);
    });

    test('a notification link opens that notification, behind a sign-in', () {
      final link = resolveDeepLink('https://$_host/notifications/$_id');

      expect(link.route, '/notifications/$_id');
      expect(link.needsSignIn, isTrue);
    });

    test('a class link opens that class, behind a sign-in', () {
      final link = resolveDeepLink('https://$_host/live/$_id');

      expect(link.route, '/live/$_id');
      expect(link.needsSignIn, isTrue);
      expect(resolveDeepLink('https://$_host/live/not%20an%20id').refusal, LinkRefusal.malformedId);
    });

    test('the notification list is a link of its own', () {
      expect(resolveDeepLink('https://$_host/notifications').route, '/notifications');
    });

    test('the bare host opens the welcome screen', () {
      expect(resolveDeepLink('https://$_host/').route, '/welcome');
      expect(resolveDeepLink('https://$_host').route, '/welcome');
    });

    test('a trailing slash and a query change nothing', () {
      expect(
        resolveDeepLink('https://$_host/verify/$_credential/?from=email').route,
        '/verify/$_credential',
      );
    });

    test('the host is matched whatever its case', () {
      expect(resolveDeepLink('https://${_host.toUpperCase()}/notifications').isFollowed, isTrue);
    });
  });

  group('a link the academy did not send', () {
    test('another host is refused, however familiar the path looks', () {
      for (final host in [
        'zuviloai.com.evil.test',
        'evil.test',
        'synilogictech.in',
        'zuviloai.co',
      ]) {
        final link = resolveDeepLink('https://$host/reset-password/$_realToken');
        expect(link.isFollowed, isFalse, reason: host);
        expect(link.refusal, LinkRefusal.foreignHost, reason: host);
      }
    });

    test('anything but https is refused: a token must not travel in the clear', () {
      for (final raw in [
        'http://$_host/reset-password/$_realToken',
        'syniastrolms://reset-password/$_realToken',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'not a url at all',
        '',
      ]) {
        expect(resolveDeepLink(raw).refusal, LinkRefusal.notAUrl, reason: raw);
      }
    });

    test('a path the app has no screen for is refused', () {
      for (final path in ['/admin', '/learn', '/verify', '/courses', '/a/b/c/d']) {
        final link = resolveDeepLink('https://$_host$path');
        expect(link.isFollowed, isFalse, reason: path);
        expect(link.refusal, LinkRefusal.unknownPath, reason: path);
      }
    });
  });

  group('an id that was never issued', () {
    test('a reset token too short to be one is refused', () {
      expect(
        resolveDeepLink('https://$_host/reset-password/short').refusal,
        LinkRefusal.malformedId,
      );
    });

    test('an id carrying anything but its own characters is refused', () {
      for (final id in [
        '../../etc/passwd',
        'abc def',
        '<script>alert(1)</script>',
        "' OR 1=1",
        'a' * 300,
        'ab',
      ]) {
        final link = resolveDeepLink('https://$_host/notifications/${Uri.encodeComponent(id)}');
        expect(link.isFollowed, isFalse, reason: 'notifications/$id should not open a screen');
      }
    });

    test('a slug with capitals or spaces is not one the catalogue built', () {
      expect(
        resolveDeepLink('https://$_host/courses/Foundations').refusal,
        LinkRefusal.malformedId,
      );
      expect(resolveDeepLink('https://$_host/courses/-leading').refusal, LinkRefusal.malformedId);
    });

    test('a lesson link with one good id and one bad opens nothing', () {
      expect(
        resolveDeepLink('https://$_host/learn/$_id/lessons/x').refusal,
        LinkRefusal.malformedId,
      );
      expect(
        resolveDeepLink('https://$_host/learn/x/lessons/$_id').refusal,
        LinkRefusal.malformedId,
      );
    });
  });

  group('a link an Admin sends a learner', () {
    test('an invitation opens the invitation, signed out or in', () {
      final link = resolveDeepLink('https://$_host/invite/$_realToken');

      expect(link.route, '/invite/$_realToken');
      // The screen itself handles someone already being signed in; it is never behind a sign-in.
      expect(link.needsSignIn, isFalse);
      expect(deepLinkReplacement('/invite/$_realToken'), isNull);
    });

    test('a course link opens the course-link screen, not the catalogue', () {
      final link = resolveDeepLink('https://$_host/courses/$_id/enroll');

      expect(link.route, '/enrol/$_id');
      expect(link.needsSignIn, isFalse);
      // Android hands the router the path itself, which is mapped the same way.
      expect(deepLinkReplacement('/courses/$_id/enroll'), '/enrol/$_id');
    });

    test('a two-part course link is still the catalogue entry', () {
      expect(resolveDeepLink('https://$_host/courses/foundations').route, '/catalog/foundations');
      expect(deepLinkReplacement('/courses/foundations'), '/catalog/foundations');
    });

    test('an invitation token that is not 64 lowercase hex is refused', () {
      for (final token in [
        'short',
        _realToken.toUpperCase(),
        '${_realToken}0',
        _realToken.substring(1),
        '${_realToken.substring(1)}g',
      ]) {
        expect(
          resolveDeepLink('https://$_host/invite/$token').refusal,
          LinkRefusal.malformedId,
          reason: token,
        );
        expect(deepLinkReplacement('/invite/$token'), unroutableLocation, reason: token);
      }
    });

    test('a course link with an id the API would never issue is refused', () {
      for (final id in ['ab', 'a' * 65, 'abc.defgh', r'abcdefgh$']) {
        final encoded = Uri.encodeComponent(id);
        expect(
          resolveDeepLink('https://$_host/courses/$encoded/enroll').refusal,
          LinkRefusal.malformedId,
          reason: id,
        );
        expect(deepLinkReplacement('/courses/$encoded/enroll'), unroutableLocation, reason: id);
      }
    });

    test('from another host, neither is followed', () {
      for (final path in ['/invite/$_realToken', '/courses/$_id/enroll']) {
        expect(
          resolveDeepLink('https://zuviloai.com.evil.test$path').refusal,
          LinkRefusal.foreignHost,
          reason: path,
        );
        expect(resolveDeepLink('http://$_host$path').refusal, LinkRefusal.notAUrl, reason: path);
      }
    });
  });

  group('a pasted link on Create account', () {
    test('an invitation, a course link and a join link are ways in', () {
      expect(joinRouteFrom(' https://$_host/invite/$_realToken '), '/invite/$_realToken');
      expect(joinRouteFrom('https://$_host/courses/$_id/enroll'), '/enrol/$_id');
      expect(
        joinRouteFrom('https://$_host/join/jyotish-vidya'),
        '/register?workspace=jyotish-vidya',
      );
    });

    test('a real link that joins nothing is not one', () {
      for (final path in [
        '/courses/foundations',
        '/verify/$_credential',
        '/learn/$_id',
        '/notifications',
        '/',
      ]) {
        expect(joinRouteFrom('https://$_host$path'), isNull, reason: path);
      }
    });

    test('the deep-link rules still apply: host, scheme and id', () {
      for (final raw in [
        'https://evil.test/invite/$_realToken',
        'http://$_host/invite/$_realToken',
        'https://$_host/invite/short',
        'https://$_host/join/No Spaces',
        'jyotish-vidya',
        '',
      ]) {
        expect(joinRouteFrom(raw), isNull, reason: raw);
      }
    });
  });

  group('the allow-list', () {
    test('holds the academy\'s own host, and one host only', () {
      expect(linkHosts, {'zuviloai.com'});
    });

    test('a test or a dev build may widen it without changing the rules', () {
      final link = resolveDeepLink(
        'https://staging.example.test/notifications',
        hosts: const {'staging.example.test'},
      );
      expect(link.route, '/notifications');
      // Widening the hosts does not soften the validation.
      expect(
        resolveDeepLink(
          'https://staging.example.test/notifications/nope',
          hosts: const {'staging.example.test'},
        ).refusal,
        LinkRefusal.malformedId,
      );
    });
  });
}
