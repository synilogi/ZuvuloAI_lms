import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';

part 'device.freezed.dart';
part 'device.g.dart';

/// `POST|GET|DELETE /notifications/devices` — the devices an account has registered for push
/// (SAAS-021, clarification B4). The route **never echoes the token back**: it is a credential for the
/// device, and what comes back is its last eight characters, enough to tell one device from another.
@freezed
abstract class RegisteredDevice with _$RegisteredDevice {
  const factory RegisteredDevice({
    @Default('') String id,
    @Default('') String platform,

    /// The last eight characters of the token — never the token itself.
    @Default('') String tokenEnd,

    /// Whether this is the device the current session is signed in on.
    @Default(false) bool current,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime lastSeenAt,
  }) = _RegisteredDevice;

  factory RegisteredDevice.fromJson(Map<String, dynamic> json) => _$RegisteredDeviceFromJson(json);
}

/// The platforms the route's schema accepts.
enum DevicePlatform { android, ios, web }

/// The shortest and longest token the route will take.
const minDeviceToken = 20;
const maxDeviceToken = 4096;

/// Whether a token is one the route would accept. A token shorter than this is not an FCM token, and
/// sending it would only earn a 400.
bool deviceTokenIsUsable(String token) {
  final trimmed = token.trim();
  return trimmed.length >= minDeviceToken && trimmed.length <= maxDeviceToken;
}
