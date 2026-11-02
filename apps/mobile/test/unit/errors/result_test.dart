import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/errors/result.dart';

void main() {
  test('Ok and Err fold, map and expose their values', () {
    const AppResult<int> ok = Ok(2);
    const AppResult<int> err = Err(NotFoundFailure());
    expect(ok.isOk, isTrue);
    expect(ok.map((v) => v * 10).valueOrNull, 20);
    expect(err.map((v) => v * 10).failureOrNull, isA<NotFoundFailure>());
    expect(ok.fold((v) => 'value $v', (f) => 'failure'), 'value 2');
    expect(err.fold((v) => 'value', (f) => f.runtimeType.toString()), 'NotFoundFailure');
  });

  test('field issues expose whichever key the server sent', () {
    expect(const FieldIssue(path: 'title', message: 'm').key, 'title');
    expect(const FieldIssue(field: 'lesson-media', message: 'm').key, 'lesson-media');
    expect(const FieldIssue(path: 'a', message: 'm'), const FieldIssue(path: 'a', message: 'm'));
  });

  test('failures can be handled exhaustively', () {
    String describe(AppFailure f) => switch (f) {
      NetworkFailure(:final problem) => 'network ${problem.name}',
      ValidationFailure(:final issues) => 'validation ${issues.length}',
      UnauthenticatedFailure() => 'unauthenticated',
      EntitlementFailure(:final problem) => 'entitlement ${problem.name}',
      PermissionFailure() => 'permission',
      ForbiddenFailure() => 'forbidden',
      NotFoundFailure() => 'not found',
      ConflictFailure(:final code) => 'conflict $code',
      PayloadTooLargeFailure() => 'too large',
      RateLimitedFailure() => 'rate limited',
      PaymentFailure() => 'payment',
      ServerFailure(:final status) => 'server $status',
      ContractFailure(:final endpoint) => 'contract $endpoint',
    };
    expect(describe(const NetworkFailure(NetworkProblem.timeout)), 'network timeout');
    expect(
      describe(const EntitlementFailure(EntitlementProblem.limitReached, message: 'm')),
      'entitlement limitReached',
    );
    expect(describe(const ServerFailure(status: 503)), 'server 503');
  });
}
