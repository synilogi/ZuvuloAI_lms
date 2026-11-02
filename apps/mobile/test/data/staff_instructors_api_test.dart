import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/staff_certificates/staff_certificates.dart';
import 'package:syniastrolms_mobile/features/staff_instructors/staff_instructors.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

Map<String, dynamic> _firstRowField(String path, String field) {
  final rows = (fixture(path)! as Map<String, dynamic>)['rows']! as List<dynamic>;
  return (rows.first as Map<String, dynamic>)[field]! as Map<String, dynamic>;
}

Map<String, dynamic> _instructor() => _firstRowField('staff/instructors.json', 'instructor');

Map<String, dynamic> _certificate() => _firstRowField('staff/certificates.json', 'certificate');

void main() {
  late FakeAdapter adapter;
  late StaffInstructorsApi instructors;
  late StaffCertificatesApi certificates;

  setUp(() {
    adapter = FakeAdapter();
    final client = ApiClient(
      config: testConfig(),
      tokenStore: FakeTokenStore('jwt'),
      logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
      adapter: adapter,
      logRequests: false,
    );
    instructors = StaffInstructorsApi(client);
    certificates = StaffCertificatesApi(client);
  });

  group('the instructor directory', () {
    test('nothing narrowed sends no query at all', () async {
      adapter.enqueueJson(fixture('staff/instructors.json'));

      await instructors.directory();

      expect(adapter.lastRequest.method, 'GET');
      expect(adapter.lastRequest.path, '/instructors');
      expect(adapter.lastRequest.queryParameters, isEmpty);
    });

    test('every filter the route understands travels by its own name', () async {
      adapter.enqueueJson(fixture('staff/instructors.json'));

      await instructors.directory(
        search: 'vinod',
        status: 'invited',
        expertise: 'Transits',
        sort: 'students',
      );

      expect(adapter.lastRequest.queryParameters, {
        'search': 'vinod',
        'status': 'invited',
        'expertise': 'Transits',
        'sort': 'students',
      });
    });

    test('an id is escaped into the path', () async {
      adapter.enqueueJson(fixture('staff/instructor.json'));

      await instructors.instructor('abc def');

      expect(adapter.lastRequest.path, '/instructors/abc%20def');
    });
  });

  group('writing an instructor', () {
    test('adding sends the whole record, unwrapped', () async {
      adapter.enqueueJson(_instructor());

      await instructors.create(
        const InstructorForm(
          name: 'Vinod Shastri',
          title: 'Astrologer',
          email: 'vinod@example.test',
          bio: 'A bio.',
          expertise: ['Transits'],
          city: 'Varanasi',
          languages: ['Hindi'],
        ),
      );

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/instructors');
      final body = adapter.lastRequest.data! as Map<String, Object?>;
      expect(body.containsKey('input'), isFalse, reason: 'this route takes the record bare');
      expect(body['name'], 'Vinod Shastri');
      expect(body['status'], 'invited', reason: 'a new instructor is invited by default');
    });

    test('saving patches the record, whole, to its own path', () async {
      adapter.enqueueJson(_instructor());

      await instructors.save(
        'i1',
        const InstructorForm(
          name: 'Vinod Shastri',
          title: 'Astrologer',
          email: 'vinod@example.test',
          bio: 'A bio.',
          expertise: ['Transits'],
          status: InstructorStatus.active,
          city: 'Varanasi',
          languages: ['Hindi'],
          courseIds: ['c1', 'c2'],
        ),
      );

      expect(adapter.lastRequest.method, 'PATCH');
      expect(adapter.lastRequest.path, '/instructors/i1');
      final body = adapter.lastRequest.data! as Map<String, Object?>;
      expect(body['status'], 'active');
      expect(body['courseIds'], ['c1', 'c2']);
    });

    test('a status change sends only the status the academy names', () async {
      adapter.enqueueJson({..._instructor(), 'status': 'inactive'});

      final saved = await instructors.setStatus('i1', InstructorStatus.inactive);

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/instructors/i1/status');
      expect(adapter.lastRequest.data, {'status': 'inactive'});
      expect(saved.status, InstructorStatus.inactive);
    });

    test('an invitation answers with the address the academy sent it to', () async {
      adapter.enqueueJson({'sentTo': 'vinod@example.test'});

      final sentTo = await instructors.resendInvite('i1');

      expect(adapter.lastRequest.path, '/instructors/i1/resend-invite');
      expect(sentTo, 'vinod@example.test');
    });

    test('an answer without that address is a contract failure, not an empty string', () async {
      adapter.enqueueJson(const {'ok': true});

      await expectLater(
        instructors.resendInvite('i1'),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ContractFailure>())),
      );
    });
  });

  group('the credential register', () {
    test('the page and its size travel with every read', () async {
      adapter.enqueueJson(fixture('staff/certificates.json'));

      await certificates.register();

      expect(adapter.lastRequest.path, '/certificates');
      expect(adapter.lastRequest.queryParameters, {'page': 1, 'pageSize': registerPageSize});
    });

    test('a search, a course and a status narrow it', () async {
      adapter.enqueueJson(fixture('staff/certificates.json'));

      await certificates.register(search: 'ananya', courseId: 'c1', status: 'revoked', page: 2);

      expect(adapter.lastRequest.queryParameters, {
        'search': 'ananya',
        'courseId': 'c1',
        'status': 'revoked',
        'page': 2,
        'pageSize': registerPageSize,
      });
    });

    test('one certificate is read from its own path', () async {
      adapter.enqueueJson(fixture('staff/certificate.json'));

      await certificates.certificate('cert 1');

      expect(adapter.lastRequest.path, '/certificates/cert%201');
    });
  });

  group('acting on a certificate', () {
    test('issuing posts to its own action with no body', () async {
      adapter.enqueueJson({..._certificate(), 'status': 'issued'});

      final issued = await certificates.issue('c1');

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/certificates/c1/issue');
      expect(adapter.lastRequest.data, isNull);
      expect(issued.status, CertificateStatus.issued);
    });

    test('revoking carries the reason, trimmed', () async {
      adapter.enqueueJson({
        ..._certificate(),
        'status': 'revoked',
        'revokedReason': 'Issued in error.',
      });

      final revoked = await certificates.revoke('c1', reason: '  Issued in error.  ');

      expect(adapter.lastRequest.path, '/certificates/c1/revoke');
      expect(adapter.lastRequest.data, {'reason': 'Issued in error.'});
      expect(revoked.isRevoked, isTrue);
      expect(revoked.revokedReason, 'Issued in error.');
    });

    test('restoring posts to its own action', () async {
      adapter.enqueueJson({..._certificate(), 'status': 'issued'});

      await certificates.restore('c1');

      expect(adapter.lastRequest.path, '/certificates/c1/restore');
      expect(adapter.lastRequest.data, isNull);
    });
  });
}
