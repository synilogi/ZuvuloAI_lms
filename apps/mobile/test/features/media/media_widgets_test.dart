import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/features/media/media.dart';
import 'package:syniastrolms_mobile/l10n/generated/app_localizations_en.dart';
import 'package:syniastrolms_mobile/shared/domain/user_profile.dart';
import 'package:syniastrolms_mobile/shared/session/current_user.dart';

import '../../helpers/pump.dart';
import '../../helpers/test_config.dart';

const _learner = UserProfile(
  id: 'u1',
  name: 'Asha Verma',
  email: 'a@b.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

void main() {
  final l10n = AppLocalizationsEn();

  Future<void> pumpWithSession(WidgetTester tester, Widget child, {UserProfile? profile}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig()),
          currentUserProvider.overrideWithValue(profile),
        ],
        child: themedHarness(child, scroll: false),
      ),
    );
    await tester.pump();
  }

  group('refusal copy matches the server word for word', () {
    test('type', () {
      expect(
        uploadRejectionMessage(l10n, MediaRejection.type, 'notes.txt', 'text/plain'),
        'Only MP4/WebM/MOV video, PDF documents and PNG/JPG/WebP images can be uploaded.',
      );
    });

    test('video from a learner', () {
      expect(
        uploadRejectionMessage(l10n, MediaRejection.videoNeedsStaff, 'a.mp4', 'video/mp4'),
        'Only instructors and admins can upload video.',
      );
    });

    test('size, per kind', () {
      expect(
        uploadRejectionMessage(l10n, MediaRejection.size, 'a.mp4', 'video/mp4'),
        'Videos can be at most 500 MB.',
      );
      expect(
        uploadRejectionMessage(l10n, MediaRejection.size, 'a.pdf', 'application/pdf'),
        'Documents can be at most 25 MB.',
      );
      expect(
        uploadRejectionMessage(l10n, MediaRejection.size, 'a.png', 'image/png'),
        'Images can be at most 5 MB.',
      );
    });
  });

  group('MediaUploadTile', () {
    testWidgets('offers a file picker before anything is chosen', (tester) async {
      await pumpWithSession(tester, const MediaUploadTile(), profile: _learner);

      expect(find.text('Choose a file'), findsOneWidget);
    });
  });

  group('AuthImage', () {
    testWidgets('draws initials when there is no image', (tester) async {
      await pumpWithSession(
        tester,
        const AuthImage(url: null, fallbackName: 'Asha Verma', width: 40, height: 40),
        profile: _learner,
      );

      expect(find.text('AV'), findsOneWidget);
    });

    testWidgets('refuses a URL on another host and falls back', (tester) async {
      await pumpWithSession(
        tester,
        const AuthImage(
          url: 'https://evil.example/media/m1',
          fallbackName: 'Asha Verma',
          width: 40,
          height: 40,
        ),
        profile: _learner,
      );

      // Nothing is requested; the bearer never leaves the API host.
      expect(find.text('AV'), findsOneWidget);
    });

    testWidgets('shows a placeholder while signed out', (tester) async {
      await pumpWithSession(tester, const AuthImage(url: '/media/m1', width: 40, height: 40));

      expect(tester.takeException(), isNull);
    });
  });
}
