import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// `NotificationCategory` (`packages/domain/src/notification.ts`).
enum NotificationCategory {
  course,
  assignment,
  quiz,
  live,
  certificate,
  enrollment,
  system,
  unknown,
}

/// The categories the academy sends, in the order the preferences screen lists them.
const notificationCategories = [
  NotificationCategory.course,
  NotificationCategory.assignment,
  NotificationCategory.quiz,
  NotificationCategory.live,
  NotificationCategory.certificate,
  NotificationCategory.enrollment,
  NotificationCategory.system,
];

/// `NotificationChannel` — the bell, e-mail, and text messages.
enum NotificationChannel { app, email, sms }

/// `EmailDigest`. The route also stores `off`, which the domain's own type leaves out.
enum EmailDigest { instant, daily, weekly, off, unknown }

/// `LOCKED_CHANNELS` — account and security notices cannot be switched off in the app or by
/// e-mail. The server refuses it, and the app does not offer it.
bool isLockedChannel(NotificationCategory category, NotificationChannel channel) =>
    category == NotificationCategory.system &&
    (channel == NotificationChannel.app || channel == NotificationChannel.email);

/// A label and value shown under a notification.
@freezed
abstract class NotificationFact with _$NotificationFact {
  const factory NotificationFact({@Default('') String label, @Default('') String value}) =
      _NotificationFact;

  factory NotificationFact.fromJson(Map<String, dynamic> json) => _$NotificationFactFromJson(json);
}

/// Where a notification points. `to` is a **web** path, which the app maps to one of its own
/// routes (§5.4) and never opens as a URL (§18).
@freezed
abstract class NotificationAction with _$NotificationAction {
  const factory NotificationAction({@Default('') String label, @Default('') String to}) =
      _NotificationAction;

  factory NotificationAction.fromJson(Map<String, dynamic> json) =>
      _$NotificationActionFromJson(json);
}

/// `AppNotification`. `recipientId` is deliberately not modelled: the route answers for whoever is
/// signed in, and the app holds no one else's id (§8, §18).
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    @JsonKey(unknownEnumValue: NotificationCategory.unknown)
    @Default(NotificationCategory.unknown)
    NotificationCategory category,
    @Default('') String title,

    /// One or two sentences for the list and the bell.
    @Default('') String summary,

    /// Paragraphs for the detail page.
    @Default(<String>[]) List<String> body,
    @UtcDateTimeConverter() required DateTime createdAt,
    @NullableUtcDateTimeConverter() DateTime? readAt,

    /// Sent even while notifications are paused, and marked in the list.
    @Default(false) bool important,

    /// Who caused it, when a person did.
    String? actor,
    @Default(<NotificationFact>[]) List<NotificationFact> facts,
    NotificationAction? action,
    NotificationAction? secondaryAction,
  }) = _AppNotification;

  const AppNotification._();

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

  bool get unread => readAt == null;
}

/// `GET /notifications` — a page of notifications with the counts the bell and the filters read.
@freezed
abstract class NotificationPage with _$NotificationPage {
  const factory NotificationPage({
    @Default(<AppNotification>[]) List<AppNotification> rows,

    /// How many match the current filter, which may be more than [rows] holds.
    @Default(0) int total,

    /// Unread across **every** category, whatever the filter — this is the bell's number.
    @Default(0) int unread,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _NotificationPage;

  const NotificationPage._();

  factory NotificationPage.fromJson(Map<String, dynamic> json) => _$NotificationPageFromJson(json);

  /// Unread in one category, as the server counted them.
  int unreadIn(NotificationCategory category) => counts[category.name] ?? 0;

  bool get isEmpty => rows.isEmpty;

  /// Whether the server is holding more than this page carries.
  bool get hasMore => rows.length < total;
}

/// `GET /notifications/:id` — the notification (now read), what else is in its category, and the
/// channels the academy would send it on.
@freezed
abstract class NotificationDetail with _$NotificationDetail {
  const factory NotificationDetail({
    required AppNotification notification,
    @Default(<AppNotification>[]) List<AppNotification> related,
    @Default(<String, bool>{}) Map<String, bool> channels,
  }) = _NotificationDetail;

  const NotificationDetail._();

  factory NotificationDetail.fromJson(Map<String, dynamic> json) =>
      _$NotificationDetailFromJson(json);

  bool sendsOn(NotificationChannel channel) => channels[channel.name] ?? false;
}

/// One category's channels.
@freezed
abstract class CategoryPreference with _$CategoryPreference {
  const factory CategoryPreference({
    @JsonKey(unknownEnumValue: NotificationCategory.unknown)
    @Default(NotificationCategory.unknown)
    NotificationCategory category,
    @Default(<String, bool>{}) Map<String, bool> channels,
  }) = _CategoryPreference;

  const CategoryPreference._();

  factory CategoryPreference.fromJson(Map<String, dynamic> json) =>
      _$CategoryPreferenceFromJson(json);

  bool on(NotificationChannel channel) => channels[channel.name] ?? false;

  CategoryPreference withChannel(NotificationChannel channel, {required bool on}) =>
      copyWith(channels: {...channels, channel.name: on});
}

/// When the academy keeps quiet, in IST — `HH:MM`.
@freezed
abstract class QuietHours with _$QuietHours {
  const factory QuietHours({
    @Default(false) bool enabled,
    @Default('22:00') String from,
    @Default('07:00') String to,
  }) = _QuietHours;

  factory QuietHours.fromJson(Map<String, dynamic> json) => _$QuietHoursFromJson(json);
}

/// `GET|PUT /notifications/settings/me`.
@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    @Default(<CategoryPreference>[]) List<CategoryPreference> categories,
    @JsonKey(unknownEnumValue: EmailDigest.unknown)
    @Default(EmailDigest.instant)
    EmailDigest emailDigest,
    @Default(QuietHours()) QuietHours quietHours,

    /// Until then only important notifications arrive.
    @NullableUtcDateTimeConverter() DateTime? pausedUntil,

    /// Only the read sends this; the write answers without it.
    String? smsNumber,
  }) = _NotificationSettings;

  const NotificationSettings._();

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);

  CategoryPreference forCategory(NotificationCategory category) => categories.firstWhere(
    (c) => c.category == category,
    orElse: () => CategoryPreference(category: category),
  );

  NotificationSettings withCategory(CategoryPreference preference) => copyWith(
    categories: [
      for (final row in categories)
        if (row.category == preference.category) preference else row,
    ],
  );
}

/// Why the academy would refuse these settings, mirroring `validateNotificationSettings`. UX only:
/// the server checks again and its refusal is the one that counts (§16, §18).
@immutable
class SettingsIssue {
  const SettingsIssue(this.field, this.message);

  /// `quietHours` or `categories`.
  final String field;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is SettingsIssue && other.field == field && other.message == message;

  @override
  int get hashCode => Object.hash(field, message);
}

final _timeOfDay = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// The same checks the server makes before it stores these settings.
List<SettingsIssue> settingsIssues(NotificationSettings settings) {
  final issues = <SettingsIssue>[];
  final quiet = settings.quietHours;
  if (quiet.enabled && (!_timeOfDay.hasMatch(quiet.from) || !_timeOfDay.hasMatch(quiet.to))) {
    issues.add(const SettingsIssue('quietHours', 'Choose when quiet hours start and end.'));
  } else if (quiet.enabled && quiet.from == quiet.to) {
    issues.add(
      const SettingsIssue('quietHours', 'Quiet hours need different start and end times.'),
    );
  }
  final locked = settings.categories.any(
    (row) => NotificationChannel.values.any(
      (channel) => isLockedChannel(row.category, channel) && !row.on(channel),
    ),
  );
  if (locked) {
    issues.add(
      const SettingsIssue(
        'categories',
        'Account and security notices stay on in the app and by email.',
      ),
    );
  }
  return issues;
}
