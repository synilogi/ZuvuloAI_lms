import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_certificates/staff_certificates.dart';
import 'package:syniastrolms_mobile/features/staff_instructors/staff_instructors.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

Map<String, dynamic> _firstRowField(String path, String field) {
  final rows = (fixture(path)! as Map<String, dynamic>)['rows']! as List<dynamic>;
  return (rows.first as Map<String, dynamic>)[field]! as Map<String, dynamic>;
}

Map<String, dynamic> _instructor() => _firstRowField('staff/instructors.json', 'instructor');

Map<String, dynamic> _certificate() => _firstRowField('staff/certificates.json', 'certificate');

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({Object? write, int writeStatus = 200}) {
    adapter.handler = (options) async {
      if (options.method != 'GET') {
        return FakeAdapter.jsonResponse(write ?? _instructor(), status: writeStatus);
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path.startsWith('/instructors/')) {
        return FakeAdapter.jsonResponse(fixture('staff/instructor.json'));
      }
      if (options.path == '/instructors') {
        return FakeAdapter.jsonResponse(fixture('staff/instructors.json'));
      }
      if (options.path.startsWith('/certificates/')) {
        return FakeAdapter.jsonResponse(fixture('staff/certificate.json'));
      }
      return FakeAdapter.jsonResponse(fixture('staff/certificates.json'));
    };
  }

  ProviderContainer container() {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: _admin(),
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    container.listen(instructorActionProvider, (_, _) {});
    container.listen(certificateActionProvider, (_, _) {});
    return container;
  }

  group('the directory', () {
    test('opens on everyone, in the academy\'s own name order', () async {
      answering();
      final c = container();
      c.listen(instructorDirectoryProvider, (_, _) {});

      final directory = await c.read(instructorDirectoryProvider.future);

      expect(directory.rows, isNotEmpty);
      // Name order is the route's own default, so nothing is sent for it.
      expect(adapter.lastRequest.queryParameters, isEmpty);
    });

    test('a status narrows the read, and "all" clears it', () async {
      answering();
      final c = container();
      c.listen(instructorDirectoryProvider, (_, _) {});
      c.read(directoryFilterProvider.notifier).showStatus('invited');
      await c.read(instructorDirectoryProvider.future);
      expect(adapter.lastRequest.queryParameters['status'], 'invited');

      c.read(directoryFilterProvider.notifier).showStatus('all');
      await c.read(instructorDirectoryProvider.future);

      expect(adapter.lastRequest.queryParameters.containsKey('status'), isFalse);
    });

    test('a search, an expertise tag and a sort all travel together', () async {
      answering();
      final c = container();
      c.listen(instructorDirectoryProvider, (_, _) {});
      c.read(directoryFilterProvider.notifier)
        ..searchFor('  vinod  ')
        ..withExpertise('Transits')
        ..sortBy('rating');

      await c.read(instructorDirectoryProvider.future);

      expect(adapter.lastRequest.queryParameters['search'], 'vinod');
      expect(adapter.lastRequest.queryParameters['expertise'], 'Transits');
      expect(adapter.lastRequest.queryParameters['sort'], 'rating');
    });

    test('an empty search is cleared rather than sent blank', () async {
      answering();
      final c = container();
      c.listen(instructorDirectoryProvider, (_, _) {});
      c.read(directoryFilterProvider.notifier)
        ..searchFor('vinod')
        ..searchFor('   ');

      await c.read(instructorDirectoryProvider.future);

      expect(adapter.lastRequest.queryParameters.containsKey('search'), isFalse);
    });
  });

  group('the form', () {
    test('a new instructor opens as invited, with nothing typed', () async {
      answering();
      final c = container();
      c.listen(instructorFormProvider(null), (_, _) {});

      final form = c.read(instructorFormProvider(null));

      expect(form.status, InstructorStatus.invited);
      expect(form.name, isEmpty);
      expect(c.read(instructorFormProvider(null).notifier).dirty, isFalse);
      // The app's own reading already knows this is not ready to send.
      expect(instructorFormProblems(form), isNotEmpty);
    });

    test('an edit starts from the record as the academy has it', () async {
      answering();
      final c = container();
      c.listen(instructorFormProvider('i1'), (_, _) {});
      final detail = await c.read(instructorProvider('i1').future);

      final form = c.read(instructorFormProvider('i1'));

      expect(form.name, detail.instructor.name);
      expect(form.email, detail.instructor.email);
      expect(form.expertise, detail.instructor.expertise);
      expect(form.courseIds, [for (final course in detail.courses) course.id]);
      expect(c.read(instructorFormProvider('i1').notifier).dirty, isFalse);
    });

    test('typing marks it unsaved, and saving clears the mark', () async {
      answering();
      final c = container();
      c.listen(instructorFormProvider(null), (_, _) {});
      final controller = c.read(instructorFormProvider(null).notifier);

      controller.named('Vinod Shastri');
      expect(controller.dirty, isTrue);

      controller.saved();
      expect(controller.dirty, isFalse);
    });

    test('a tag goes on and comes off again', () async {
      answering();
      final c = container();
      c.listen(instructorFormProvider(null), (_, _) {});
      final controller = c.read(instructorFormProvider(null).notifier)
        ..toggleExpertise('Transits')
        ..toggleLanguage('Hindi')
        ..toggleCourse('c1');

      expect(c.read(instructorFormProvider(null)).expertise, ['Transits']);
      expect(c.read(instructorFormProvider(null)).languages, ['Hindi']);
      expect(c.read(instructorFormProvider(null)).courseIds, ['c1']);

      controller
        ..toggleExpertise('Transits')
        ..toggleCourse('c1');

      expect(c.read(instructorFormProvider(null)).expertise, isEmpty);
      expect(c.read(instructorFormProvider(null)).courseIds, isEmpty);
      expect(c.read(instructorFormProvider(null)).languages, ['Hindi']);
    });
  });

  group('instructor actions', () {
    InstructorForm ready() => const InstructorForm(
      name: 'Vinod Shastri',
      title: 'Predictive Astrologer',
      email: 'vinod@example.test',
      bio: 'A bio.',
      expertise: ['Transits'],
      city: 'Varanasi',
      languages: ['Hindi'],
    );

    test('adding one answers with its id and re-reads the directory', () async {
      answering();
      final c = container();
      var reads = 0;
      c.listen(instructorDirectoryProvider, (_, _) {
        reads++;
      });
      await c.read(instructorDirectoryProvider.future);

      final id = await c.read(instructorActionProvider.notifier).create(ready());
      await c.read(instructorDirectoryProvider.future);

      expect(id, isNotNull);
      expect(c.read(instructorActionProvider).savedId, id);
      expect(reads, greaterThan(1));
    });

    test('a refused write keeps the academy\'s words on each field', () async {
      answering(
        write: const {
          'message': 'Check the instructor details.',
          'issues': [
            {'field': 'email', 'message': 'Another instructor already uses this email.'},
            {'field': 'bio', 'message': 'Write a bio of at least 60 characters.'},
          ],
        },
        writeStatus: 409,
      );
      final c = container();

      final id = await c.read(instructorActionProvider.notifier).create(ready());
      final state = c.read(instructorActionProvider);

      expect(id, isNull);
      expect(state.issues, hasLength(2));
      expect(state.messageFor('email'), contains('already uses'));
      expect(state.messageFor('bio'), contains('60 characters'));
      expect(state.messageFor('name'), isNull);
    });

    test('a plan limit is kept as the academy sent it, with no field', () async {
      answering(
        write: const {'message': 'Your plan includes 3 instructors.', 'code': 'LIMIT_REACHED'},
        writeStatus: 403,
      );
      final c = container();

      expect(await c.read(instructorActionProvider.notifier).create(ready()), isNull);
      expect(c.read(instructorActionProvider).issues, isEmpty);
      expect(c.read(instructorActionProvider).failure, isNotNull);
    });

    test('a status change re-reads the record and the directory', () async {
      answering(write: {..._instructor(), 'status': 'inactive'});
      final c = container();
      var reads = 0;
      c.listen(instructorProvider('i1'), (_, _) {
        reads++;
      });
      await c.read(instructorProvider('i1').future);

      final ok = await c
          .read(instructorActionProvider.notifier)
          .setStatus('i1', InstructorStatus.inactive);
      await c.read(instructorProvider('i1').future);

      expect(ok, isTrue);
      expect(reads, greaterThan(1));
    });

    test('an invitation keeps the address the academy says it used', () async {
      answering(write: const {'sentTo': 'vinod@example.test'});
      final c = container();

      final ok = await c.read(instructorActionProvider.notifier).resendInvite('i1');

      expect(ok, isTrue);
      expect(c.read(instructorActionProvider).invitedTo, 'vinod@example.test');
    });

    test('a second action is ignored while the first is in flight', () async {
      answering();
      final c = container();
      final controller = c.read(instructorActionProvider.notifier);

      final first = controller.create(ready());
      final second = controller.setStatus('i1', InstructorStatus.active);

      expect(await second, isFalse);
      expect(await first, isNotNull);
      expect(adapter.requests.where((r) => r.method != 'GET'), hasLength(1));
    });
  });

  group('the register', () {
    test('opens on the first page of everything', () async {
      answering();
      final c = container();
      c.listen(certificateRegisterProvider, (_, _) {});

      final register = await c.read(certificateRegisterProvider.future);

      expect(register.rows, isNotEmpty);
      expect(adapter.lastRequest.queryParameters['page'], 1);
      expect(adapter.lastRequest.queryParameters.containsKey('status'), isFalse);
    });

    test('a status and a course narrow it, and changing one starts again at page 1', () async {
      answering();
      final c = container();
      c.listen(certificateRegisterProvider, (_, _) {});
      c.read(registerFilterProvider.notifier)
        ..showPage(3)
        ..showStatus('revoked');

      await c.read(certificateRegisterProvider.future);

      expect(adapter.lastRequest.queryParameters['status'], 'revoked');
      expect(
        adapter.lastRequest.queryParameters['page'],
        1,
        reason: 'a different question deserves the first page of its own answer',
      );
    });
  });

  group('certificate actions', () {
    test('issuing re-reads the certificate and the register', () async {
      answering(write: {..._certificate(), 'status': 'issued'});
      final c = container();
      var reads = 0;
      c.listen(staffCertificateProvider('cert1'), (_, _) {
        reads++;
      });
      await c.read(staffCertificateProvider('cert1').future);

      final ok = await c.read(certificateActionProvider.notifier).issue('cert1');
      await c.read(staffCertificateProvider('cert1').future);

      expect(ok, isTrue);
      expect(c.read(certificateActionProvider).done, isTrue);
      expect(reads, greaterThan(1));
    });

    test('a reason the route would refuse is never sent', () async {
      answering(write: {..._certificate(), 'status': 'revoked'});
      final c = container();

      final ok = await c.read(certificateActionProvider.notifier).revoke('cert1', reason: 'no');

      expect(ok, isFalse);
      expect(
        adapter.requests.where((r) => r.method != 'GET'),
        isEmpty,
        reason: 'the route answers 400 with no field, so the app checks the length itself',
      );
    });

    test('a refusal is kept as the academy sent it', () async {
      answering(
        write: const {'message': 'Only a pending certificate can be issued.'},
        writeStatus: 409,
      );
      final c = container();

      expect(await c.read(certificateActionProvider.notifier).issue('cert1'), isFalse);
      expect(c.read(certificateActionProvider).failure, isA<ConflictFailure>());
      expect(c.read(certificateActionProvider).done, isFalse);
    });
  });
}
