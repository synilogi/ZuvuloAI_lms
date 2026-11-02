import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/domain/user_profile.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

/// `{token, user}` from login and register.
@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({required String token, required UserProfile user}) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
}
