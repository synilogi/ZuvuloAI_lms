import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';

part 'academy_signup.freezed.dart';
part 'academy_signup.g.dart';

/// `POST /signup/start` (202) and `POST /signup/resend` — a registration waiting for the 6-digit code
/// emailed to [email]. Nothing exists yet: the academy and its admin are created only by the code.
@freezed
abstract class SignupPending with _$SignupPending {
  const factory SignupPending({
    required String signupId,
    required String email,
    @UtcDateTimeConverter() required DateTime expiresAt,
    @UtcDateTimeConverter() required DateTime resendAvailableAt,
  }) = _SignupPending;

  factory SignupPending.fromJson(Map<String, dynamic> json) => _$SignupPendingFromJson(json);
}
