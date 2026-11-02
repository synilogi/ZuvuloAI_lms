import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// The roles the backend issues (`packages/domain/src/identity.ts`).
@JsonEnum(fieldRename: FieldRename.none)
enum UserRole {
  student,
  instructor,
  admin,
  superadmin,

  /// A role this build does not know; treated as no access.
  unknown,
}

/// The 24 academy permission keys (`packages/domain/src/permission.ts`). They are read from the
/// database on every session response, never from the token, so a revoked key is gone on the next
/// call. Only an academy admin holds any; every other role answers `[]`.
enum PermissionKey {
  catalogView('catalog.view'),
  catalogEdit('catalog.edit'),
  catalogPublish('catalog.publish'),
  catalogArchive('catalog.archive'),
  catalogCategoriesManage('catalog.categories.manage'),
  assessmentView('assessment.view'),
  assessmentEdit('assessment.edit'),
  assessmentGrade('assessment.grade'),
  learnersView('learners.view'),
  learnersEnroll('learners.enroll'),
  learnersSuspend('learners.suspend'),
  learnersMessage('learners.message'),
  instructorsView('instructors.view'),
  instructorsManage('instructors.manage'),
  instructorsStatus('instructors.status'),
  certificatesIssue('certificates.issue'),
  certificatesRevoke('certificates.revoke'),
  certificatesTemplatesManage('certificates.templates.manage'),
  liveManage('live.manage'),
  liveNotify('live.notify'),
  reportsView('reports.view'),
  reportsInstructorsView('reports.instructors.view'),
  settingsView('settings.view'),
  settingsEdit('settings.edit'),

  /// A key added to the backend after this build shipped; grants nothing.
  unknown('');

  const PermissionKey(this.wire);

  /// The string the API sends.
  final String wire;

  static PermissionKey parse(String value) =>
      PermissionKey.values.firstWhere((k) => k.wire == value, orElse: () => PermissionKey.unknown);
}

/// Keeps unknown keys out of the model instead of crashing on a new server value.
class PermissionKeysConverter implements JsonConverter<List<PermissionKey>, List<dynamic>?> {
  const PermissionKeysConverter();

  @override
  List<PermissionKey> fromJson(List<dynamic>? json) => [
    for (final value in json ?? const []) PermissionKey.parse('$value'),
  ];

  @override
  List<dynamic> toJson(List<PermissionKey> object) => [
    for (final key in object)
      if (key != PermissionKey.unknown) key.wire,
  ];
}

/// `UserProfile` from `POST /auth/login`, `POST /auth/register` and `GET /auth/me`
/// (`apps/api/src/routes/auth.ts` `toProfile`). `permissions` is absent on register — it defaults to
/// empty, never to "all" (§7).
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String name,
    required String email,
    @JsonKey(unknownEnumValue: UserRole.unknown) required UserRole role,

    /// The line the web shows under the name ("Academy admin", "Beginner · Ardra").
    required String descriptor,
    String? instructorId,
    @PermissionKeysConverter() @Default([]) List<PermissionKey> permissions,
  }) = _UserProfile;

  const UserProfile._();

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

  /// UX only — every call is still checked by the server (§7).
  bool has(PermissionKey key) => key != PermissionKey.unknown && permissions.contains(key);
}
