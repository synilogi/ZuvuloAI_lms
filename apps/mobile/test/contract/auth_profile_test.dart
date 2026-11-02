import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/error_decoder.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/auth/data/dto/auth_response.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

UserProfile _profile(String fixture) =>
    UserProfile.fromJson(_fixture(fixture)['user']! as Map<String, dynamic>);

/// Contract tests against responses captured from the real API (`tool/capture_fixture.sh`).
void main() {
  test('an academy admin carries all 24 permission keys', () {
    final admin = _profile('auth/me-admin.json');

    expect(admin.role, UserRole.admin);
    expect(admin.permissions, hasLength(24));
    expect(admin.permissions, isNot(contains(PermissionKey.unknown)));
    expect(admin.has(PermissionKey.catalogPublish), isTrue);
    expect(admin.has(PermissionKey.settingsEdit), isTrue);
  });

  test('every key the backend sends is known to this build', () {
    final sent =
        (_fixture('auth/me-admin.json')['user']! as Map<String, dynamic>)['permissions']!
            as List<dynamic>;
    expect(
      sent.map((k) => PermissionKey.parse('$k')),
      isNot(contains(PermissionKey.unknown)),
      reason: 'a new permission key was added to the backend',
    );
  });

  test('a learner and an instructor hold no permissions', () {
    final student = _profile('auth/me-student.json');
    expect(student.role, UserRole.student);
    expect(student.permissions, isEmpty);
    expect(student.has(PermissionKey.catalogView), isFalse);
    expect(student.instructorId, isNull);
    expect(student.descriptor, isNotEmpty);

    final instructor = _profile('auth/me-instructor.json');
    expect(instructor.role, UserRole.instructor);
    expect(instructor.permissions, isEmpty);
    expect(instructor.instructorId, isNotNull);
  });

  test('a login response carries a token and the profile', () {
    final response = AuthResponse.fromJson(_fixture('auth/login.json'));

    expect(response.token, isNotEmpty);
    expect(response.user.role, UserRole.student);
  });

  test('forgot-password always answers ok', () {
    expect(_fixture('auth/forgot-password.json'), {'ok': true});
  });

  test('registering with an existing e-mail is a 409 the app can explain', () {
    final failure = ErrorDecoder.fromResponse(409, _fixture('errors/register-duplicate.json'));

    expect(
      failure,
      isA<ConflictFailure>().having(
        (f) => f.message,
        'message',
        'An account with this email already exists.',
      ),
    );
  });

  group('unknown values do not crash the app', () {
    test('an unknown role falls back', () {
      final profile = UserProfile.fromJson(const {
        'id': 'u1',
        'name': 'A',
        'email': 'a@b.test',
        'role': 'auditor',
        'descriptor': 'x',
      });
      expect(profile.role, UserRole.unknown);
    });

    test('an unknown permission key is kept out of the model', () {
      final profile = UserProfile.fromJson(const {
        'id': 'u1',
        'name': 'A',
        'email': 'a@b.test',
        'role': 'admin',
        'descriptor': 'x',
        'permissions': ['catalog.view', 'brand.new.key'],
      });
      expect(profile.permissions, [PermissionKey.catalogView, PermissionKey.unknown]);
      expect(profile.has(PermissionKey.unknown), isFalse);
      expect(profile.toJson()['permissions'], ['catalog.view']);
    });

    test('a missing permissions field means none, never all (register)', () {
      final profile = UserProfile.fromJson(const {
        'id': 'u1',
        'name': 'A',
        'email': 'a@b.test',
        'role': 'student',
        'descriptor': 'Learner',
      });
      expect(profile.permissions, isEmpty);
    });
  });
}
