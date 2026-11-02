import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/logging/redactor.dart';

class _RecordingReporter implements CrashReporter {
  final reports = <CrashReport>[];

  @override
  Future<void> record(CrashReport report) async => reports.add(report);
}

void main() {
  group('Redactor.redactText masks', () {
    final cases = {
      'a JWT': (
        'token eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.abcdefghij here',
        '[redacted-token]',
      ),
      'a bearer header': ('Authorization: Bearer abc123def456ghi', 'Bearer [redacted]'),
      'a Razorpay key': ('key rzp_live_AbCdEf12345678', '[redacted-key]'),
      'a Stripe-style key': ('sk_test_abcdefgh1234', '[redacted-key]'),
      'a webhook secret': ('whsec_abcdefgh1234', '[redacted-key]'),
      'a token query parameter': ('GET /x?token=supersecret&page=2', '?token=[redacted]&page=2'),
      'a reset link': (
        'https://a.in/reset-password/0123456789abcdef0123',
        '/reset-password/[redacted]',
      ),
      'a password assignment': ('password=hunter2hunter2', 'password=[redacted]'),
      'a card-like number': ('card 4111 1111 1111 1111 declined', '[redacted-card]'),
    };
    for (final entry in cases.entries) {
      test(entry.key, () {
        final (input, expected) = entry.value;
        final out = Redactor.redactText(input);
        expect(out, contains(expected));
      });
    }
  });

  test('leaves ordinary text untouched', () {
    const text = 'Loaded 12 courses for page 2 in 340 ms (lesson 3.2, 2026-09-22)';
    expect(Redactor.redactText(text), text);
  });

  test('drops values under sensitive keys, deeply', () {
    final out =
        Redactor.redact({
              'email': 'a@b.in',
              'password': 'p',
              'nested': {
                'Authorization': 'Bearer x',
                'list': [
                  {'signature': 's', 'orderId': 'order_1'},
                ],
              },
              'cvv': '123',
              'otp': '0000',
            })!
            as Map<String, Object?>;
    expect(out['password'], Redactor.redacted);
    expect(out['cvv'], Redactor.redacted);
    expect(out['otp'], Redactor.redacted);
    final nested = out['nested']! as Map<String, Object?>;
    expect(nested['Authorization'], Redactor.redacted);
    final row = (nested['list']! as List<Object?>).single! as Map<String, Object?>;
    expect(row['signature'], Redactor.redacted);
    expect(row['orderId'], 'order_1');
  });

  test('caps depth and collection size', () {
    Object? deep = 'x';
    for (var i = 0; i < 10; i++) {
      deep = {'k': deep};
    }
    expect(Redactor.redact(deep).toString(), contains('[truncated]'));
    expect((Redactor.redact(List.filled(80, 1))! as List).length, 50);
  });

  group('AppLogger', () {
    test('redacts messages and fields', () {
      final lines = <String>[];
      final logger = AppLogger(
        reporter: const NoopCrashReporter(),
        sink: (line, _) => lines.add(line),
      );
      logger.info('signed in with Bearer abcdefghijklmnop', {'token': 't', 'userId': 'u1'});
      expect(lines.single, contains('Bearer [redacted]'));
      expect(lines.single, contains('token: [redacted]'));
      expect(lines.single, contains('userId: u1'));
    });

    test('drops levels below its minimum (release keeps warnings and errors)', () {
      final lines = <String>[];
      final logger = AppLogger(
        reporter: const NoopCrashReporter(),
        minLevel: LogLevel.warn,
        sink: (line, _) => lines.add(line),
      );
      logger
        ..debug('d')
        ..info('i')
        ..warn('w');
      expect(lines, ['[warn] w']);
    });

    test('forwards errors to the crash reporter, redacted', () {
      final reporter = _RecordingReporter();
      AppLogger(reporter: reporter, sink: (_, _) {}).error(
        'checkout failed',
        error: StateError('rzp_test_abcdefgh1234 rejected'),
        fields: {'signature': 'sig'},
      );
      final report = reporter.reports.single;
      expect(report.message, contains('[redacted-key]'));
      expect(report.message, isNot(contains('rzp_test')));
      expect(report.fields['signature'], Redactor.redacted);
    });
  });
}
