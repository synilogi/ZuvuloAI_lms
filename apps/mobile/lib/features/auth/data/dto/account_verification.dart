import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import 'auth_response.dart';

part 'account_verification.freezed.dart';
part 'account_verification.g.dart';

/// `202 {status: 'verify', …}` from a learner's or instructor's own registration, and
/// `GET /public/verifications/:id` / `POST /public/verifications/resend` — a registration waiting for
/// the 6-digit code emailed to [email]. Nothing that can sign in exists yet: the server holds it in
/// the LMS the link named ([lms] is its display name), and [role] is the server's, never the app's.
@freezed
abstract class VerificationPending with _$VerificationPending {
  const factory VerificationPending({
    required String verificationId,
    required String email,
    @Default('student') String role,
    @Default('') String lms,
    @UtcDateTimeConverter() required DateTime expiresAt,
    @UtcDateTimeConverter() required DateTime resendAvailableAt,
  }) = _VerificationPending;

  factory VerificationPending.fromJson(Map<String, dynamic> json) =>
      _$VerificationPendingFromJson(json);
}

/// What a registration door (`/auth/register`, a join link, an invitation, a course link, a request to
/// teach) or `POST /public/verifications/verify` answers. A deployment that skips email verification
/// still answers the old shapes, so every door reads all three.
sealed class AccountReply {
  const AccountReply();

  /// Reads [raw] as `{status: 'verify', …}`, `{status: 'pending', message}` or `{token, user, …}`; any
  /// other shape is a [ContractFailure] naming [endpoint].
  static AccountReply parse(String endpoint, Object? raw) {
    final body = asJsonObject(endpoint, raw);
    return parseResponse(endpoint, body, (_) {
      if (body['status'] == 'verify') return AccountNeedsCode(VerificationPending.fromJson(body));
      if (body['status'] == 'pending') {
        return AccountAwaitingApproval(
          body['message'] is String ? body['message'] as String : null,
        );
      }
      if (body['token'] is String) {
        return AccountCreated(
          AuthResponse.fromJson(body),
          enrolled: body['enrolled'] is bool ? body['enrolled'] as bool : null,
          enrolment: body['enrolment'] is String ? body['enrolment'] as String : null,
          enrolmentCode: body['enrolmentCode'] is String ? body['enrolmentCode'] as String : null,
        );
      }
      throw const FormatException('expected status "verify" or "pending", or a token');
    });
  }
}

/// The server emailed a code; nothing exists until it is entered.
final class AccountNeedsCode extends AccountReply {
  const AccountNeedsCode(this.pending);

  final VerificationPending pending;
}

/// A learner's account exists and [auth] signs them in. [enrolled] and [enrolment] are set only for a
/// course link: whether the LMS's policy enrolled the account, and the server's reason when not.
/// [enrolmentCode] is the reason's code — `COURSE_PURCHASE_REQUIRED` for a paid course, which is
/// bought on its page rather than joined.
final class AccountCreated extends AccountReply {
  const AccountCreated(this.auth, {this.enrolled, this.enrolment, this.enrolmentCode});

  final AuthResponse auth;
  final bool? enrolled;
  final String? enrolment;
  final String? enrolmentCode;
}

/// An instructor's request reached the LMS admin (D34): nobody is signed in. [message] is the
/// server's own words.
final class AccountAwaitingApproval extends AccountReply {
  const AccountAwaitingApproval(this.message);

  final String? message;
}
