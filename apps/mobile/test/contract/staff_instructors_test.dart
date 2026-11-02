import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_certificates/staff_certificates.dart';
import 'package:syniastrolms_mobile/features/staff_instructors/staff_instructors.dart';

/// Contract tests (§23) for the instructor directory and the credential register, against what the
/// real API returned — `test/fixtures/staff/instructors.json`, `instructor.json`,
/// `certificates.json` and `certificate.json`, each captured with `tool/capture_fixture.sh`.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

Map<String, dynamic> _map(String path) => _fixture(path)! as Map<String, dynamic>;

void main() {
  group('the instructor directory', () {
    late InstructorDirectory directory;

    setUp(() => directory = InstructorDirectory.fromJson(_map('staff/instructors.json')));

    test('every row carries a record the app can read', () {
      expect(directory.rows, isNotEmpty);
      for (final row in directory.rows) {
        expect(row.instructor.id, isNotEmpty);
        expect(row.instructor.name, isNotEmpty);
        expect(row.instructor.title, isNotEmpty);
        expect(row.instructor.status, isNot(InstructorStatus.unknown));
        expect(row.instructor.joinedAt.isUtc, isTrue);
        expect(row.instructor.expertise, isNotEmpty);
      }
    });

    test('the counts cover every status and add up to all of them', () {
      final byStatus = [
        'active',
        'invited',
        'inactive',
      ].fold<int>(0, (n, status) => n + directory.countOf(status));
      expect(byStatus, directory.countOf('all'));
      expect(directory.countOf('all'), directory.rows.length);
    });

    test('the expertise offered is every tag the academy has in use', () {
      final used = {for (final row in directory.rows) ...row.instructor.expertise};
      expect(directory.expertise.toSet(), used);
      // Sorted, so the filter reads the same way every time.
      final sorted = [...directory.expertise]..sort();
      expect(directory.expertise, orderedEquals(sorted));
    });

    test('a rating is weighted by the academy, and absent until a course is rated', () {
      for (final row in directory.rows) {
        if (row.rating == null) {
          expect(row.ratingCount, 0);
        } else {
          expect(row.ratingCount, greaterThan(0));
          expect(row.rating, inInclusiveRange(0, 5));
        }
      }
    });

    test('a course on a row is named and has a status the app knows', () {
      final row = directory.rows.firstWhere((r) => r.courses.isNotEmpty);
      for (final course in row.courses) {
        expect(course.id, isNotEmpty);
        expect(course.title, isNotEmpty);
        expect(course.status, isNot(CourseStatus.unknown));
      }
      expect(row.publishedCourses, lessThanOrEqualTo(row.courses.length));
    });
  });

  group('one instructor in full', () {
    late InstructorDetail detail;

    setUp(() => detail = InstructorDetail.fromJson(_map('staff/instructor.json')));

    test('their courses carry the academy\'s own figures', () {
      expect(detail.courses, isNotEmpty);
      for (final course in detail.courses) {
        expect(course.title, isNotEmpty);
        expect(course.levelTitle, isNotEmpty);
        expect(course.role, anyOf('lead', 'co'));
        expect(course.updatedAt.isUtc, isTrue);
        expect(course.activeLearners, lessThanOrEqualTo(course.enrolled));
      }
    });

    test('their reach is the academy\'s arithmetic, cities ordered by size', () {
      final reach = detail.reach;
      expect(reach.students, greaterThan(0));
      expect(reach.active, lessThanOrEqualTo(reach.students));
      expect(reach.cities, isNotEmpty);
      final counts = [for (final city in reach.cities) city.count];
      final descending = [...counts]..sort((a, b) => b.compareTo(a));
      expect(counts, orderedEquals(descending));
    });

    test('performance carries the academy comparison, not one the app computed', () {
      final performance = detail.performance;
      expect(performance.academyRating, greaterThan(0));
      expect(performance.academyCompletion, greaterThanOrEqualTo(0));
      if (performance.rating case final rating?) {
        expect(performance.ratingGap, closeTo(rating - performance.academyRating, 0.001));
      }
      if (performance.completion case final completion?) {
        expect(performance.completionGap, completion - performance.academyCompletion);
      }
    });

    test('enrolments arrive as eight labelled months, the last one in progress', () {
      final months = detail.performance.enrollmentsByMonth;
      expect(months, hasLength(8));
      for (final month in months) {
        expect(month.label, isNotEmpty);
        expect(month.detail, isNotEmpty);
      }
      expect(months.last.detail, contains('so far'));
    });

    test('their activity is the academy\'s own sentences, newest first', () {
      expect(detail.activity, isNotEmpty);
      for (final event in detail.activity) {
        expect(event.id, isNotEmpty);
        expect(event.actor, isNotEmpty);
        expect(event.summary, isNotEmpty);
        expect(event.kind, isNot(AdminEventKind.unknown));
        expect(event.at.isUtc, isTrue);
      }
      final times = [for (final event in detail.activity) event.at];
      final newestFirst = [...times]..sort((a, b) => b.compareTo(a));
      expect(times, orderedEquals(newestFirst));
    });
  });

  group('the credential register', () {
    late CertificateRegister register;

    setUp(() => register = CertificateRegister.fromJson(_map('staff/certificates.json')));

    test('every row names a learner, a course and a credential', () {
      expect(register.rows, isNotEmpty);
      for (final row in register.rows) {
        expect(row.certificate.id, isNotEmpty);
        expect(row.certificate.credentialId, isNotEmpty);
        expect(row.certificate.status, isNot(CertificateStatus.unknown));
        expect(row.certificate.completedAt.isUtc, isTrue);
        expect(row.studentName, isNotEmpty);
        expect(row.studentEmail, isNotEmpty);
        expect(row.courseTitle, isNotEmpty);
      }
    });

    test('the counts cover every status and add up to the whole register', () {
      final byStatus = [
        'issued',
        'pending',
        'revoked',
      ].fold<int>(0, (n, status) => n + register.countOf(status));
      expect(byStatus, register.countOf('all'));
      expect(register.countOf('all'), register.total);
    });

    test('a pending certificate has no issue date, and an issued one has', () {
      for (final row in register.rows) {
        if (row.certificate.isPending) {
          expect(row.certificate.issuedAt, isNull);
        } else {
          expect(row.certificate.issuedAt, isNotNull);
        }
      }
      expect(register.pending.map((r) => r.certificate.isPending), everyElement(isTrue));
    });

    test('a revoked certificate carries the academy\'s reason', () {
      final revoked = register.rows.where((r) => r.certificate.isRevoked);
      for (final row in revoked) {
        expect(row.certificate.revokedAt, isNotNull);
        expect(row.certificate.revokedReason, isNotNull);
        expect(row.certificate.revokedReason, isNotEmpty);
      }
    });
  });

  group('one certificate in full', () {
    late StaffCertificateDetail detail;

    setUp(() => detail = StaffCertificateDetail.fromJson(_map('staff/certificate.json')));

    test('it carries everything the canvas prints from', () {
      expect(detail.certificate.credentialId, isNotEmpty);
      expect(detail.courseTitle, isNotEmpty);
      expect(detail.levelTitle, isNotEmpty);
      expect(detail.student.name, isNotEmpty);
      expect(detail.template, isNotNull);
      expect(detail.template!.heading, isNotEmpty);
      expect(detail.template!.statement, isNotEmpty);
      expect(detail.template!.signatories, isNotEmpty);
    });

    test('the verification path is the academy\'s own, built from the credential', () {
      expect(detail.verifyUrl, '/verify/${detail.certificate.credentialId}');
    });

    test('the learner-facing copy carries no e-mail address', () {
      // Staff are served one and need it to search; nothing about sharing a credential may carry it.
      expect(detail.student.email, isNotEmpty);
      final printed = detail.asPrinted;
      expect(printed.student.name, detail.student.name);
      expect(printed.student.city, detail.student.city);
      expect(printed.toString(), isNot(contains(detail.student.email)));
      expect(printed.certificate, detail.certificate);
      expect(printed.template, detail.template);
      expect(printed.verifyUrl, detail.verifyUrl);
    });
  });

  group('what the form checks before asking', () {
    InstructorForm complete() => const InstructorForm(
      name: 'Acharya Vinod Shastri',
      title: 'Predictive Astrologer',
      email: 'vinod@example.test',
      bio: 'A bio long enough for the academy to publish it on every course page for learners.',
      expertise: ['Transits'],
      status: InstructorStatus.active,
      city: 'Varanasi',
      languages: ['Hindi'],
    );

    test('a complete instructor has nothing to fix', () {
      expect(instructorFormProblems(complete()), isEmpty);
    });

    test('a short name, title or e-mail is named field by field', () {
      final problems = instructorFormProblems(
        complete().copyWith(name: 'No', title: 'X', email: 'not-an-address'),
      );
      expect(problems, containsAll(['name', 'title', 'email']));
    });

    test('a bio is only required once they are active', () {
      expect(instructorFormProblems(complete().copyWith(bio: 'Too short')), contains('bio'));
      expect(
        instructorFormProblems(
          complete().copyWith(bio: 'Too short', status: InstructorStatus.invited),
        ),
        isNot(contains('bio')),
      );
    });

    test('expertise and a language are both required', () {
      final problems = instructorFormProblems(
        complete().copyWith(expertise: const [], languages: const []),
      );
      expect(problems, containsAll(['expertise', 'languages']));
    });

    test('a phone number is optional, but checked when given', () {
      expect(instructorFormProblems(complete().copyWith(phone: '')), isNot(contains('phone')));
      expect(instructorFormProblems(complete().copyWith(phone: '12')), contains('phone'));
      expect(
        instructorFormProblems(complete().copyWith(phone: '+91 98765 43210')),
        isNot(contains('phone')),
      );
    });

    test('years teaching is checked against the academy\'s own range', () {
      expect(instructorFormProblems(complete().copyWith(yearsTeaching: 20)), isEmpty);
      expect(
        instructorFormProblems(complete().copyWith(yearsTeaching: 99)),
        contains('yearsTeaching'),
      );
    });
  });

  group('the body a write sends', () {
    test('an edit starts from the record exactly as the academy holds it', () {
      final detail = InstructorDetail.fromJson(_map('staff/instructor.json'));
      final form = InstructorForm.of(
        detail.instructor,
        courseIds: [for (final course in detail.courses) course.id],
      );

      expect(form.name, detail.instructor.name);
      expect(form.title, detail.instructor.title);
      expect(form.bio, detail.instructor.bio);
      expect(form.expertise, detail.instructor.expertise);
      expect(form.languages, detail.instructor.languages);
      expect(form.city, detail.instructor.city);
      expect(form.status, detail.instructor.status);
      expect(form.yearsTeaching, detail.instructor.yearsTeaching);
      expect(form.courseIds, [for (final course in detail.courses) course.id]);
      expect(instructorFormProblems(form), isEmpty);
    });

    test('every field the route requires travels, and the e-mail is normalised', () {
      final input = const InstructorForm(
        name: '  Vinod Shastri  ',
        title: 'Astrologer',
        email: '  Vinod@Example.Test ',
        bio: 'A bio.',
        expertise: ['Transits'],
        city: ' Varanasi ',
        languages: ['Hindi'],
        courseIds: ['c1'],
      ).toInput();

      expect(input['name'], 'Vinod Shastri');
      expect(input['email'], 'vinod@example.test');
      expect(input['city'], 'Varanasi');
      expect(
        input.keys,
        containsAll([
          'name',
          'title',
          'email',
          'bio',
          'expertise',
          'status',
          'city',
          'languages',
          'courseIds',
        ]),
      );
    });

    test('a photo is never sent, so the academy keeps whatever it holds', () {
      expect(const InstructorForm().toInput().containsKey('photo'), isFalse);
    });

    test('an empty phone and no years are left out rather than sent empty', () {
      final input = const InstructorForm(phone: '   ').toInput();
      expect(input.containsKey('phone'), isFalse);
      expect(input.containsKey('yearsTeaching'), isFalse);
    });

    test('an unknown status is never sent; it travels as active', () {
      expect(const InstructorForm(status: InstructorStatus.unknown).toInput()['status'], 'active');
    });
  });

  group('what a revocation needs', () {
    test('a reason of fewer than three characters is never sent', () {
      // The route answers 400 with a message and no field, so the screen checks it first (finding 31).
      expect(revokeReasonIsEnough(''), isFalse);
      expect(revokeReasonIsEnough('  a  '), isFalse);
      expect(revokeReasonIsEnough('Issued in error.'), isTrue);
    });

    test('a reason longer than the route will take is refused too', () {
      expect(revokeReasonIsEnough('x' * maxRevokeReason), isTrue);
      expect(revokeReasonIsEnough('x' * (maxRevokeReason + 1)), isFalse);
    });
  });
}
