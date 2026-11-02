// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationFact _$NotificationFactFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NotificationFact', json, ($checkedConvert) {
      final val = _NotificationFact(
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        value: $checkedConvert('value', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$NotificationFactToJson(_NotificationFact instance) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
};

_NotificationAction _$NotificationActionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NotificationAction', json, ($checkedConvert) {
      final val = _NotificationAction(
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        to: $checkedConvert('to', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$NotificationActionToJson(_NotificationAction instance) => <String, dynamic>{
  'label': instance.label,
  'to': instance.to,
};

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AppNotification', json, ($checkedConvert) {
      final val = _AppNotification(
        id: $checkedConvert('id', (v) => v as String),
        category: $checkedConvert(
          'category',
          (v) =>
              $enumDecodeNullable(
                _$NotificationCategoryEnumMap,
                v,
                unknownValue: NotificationCategory.unknown,
              ) ??
              NotificationCategory.unknown,
        ),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        summary: $checkedConvert('summary', (v) => v as String? ?? ''),
        body: $checkedConvert(
          'body',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        readAt: $checkedConvert(
          'readAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        important: $checkedConvert('important', (v) => v as bool? ?? false),
        actor: $checkedConvert('actor', (v) => v as String?),
        facts: $checkedConvert(
          'facts',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => NotificationFact.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <NotificationFact>[],
        ),
        action: $checkedConvert(
          'action',
          (v) => v == null ? null : NotificationAction.fromJson(v as Map<String, dynamic>),
        ),
        secondaryAction: $checkedConvert(
          'secondaryAction',
          (v) => v == null ? null : NotificationAction.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) => <String, dynamic>{
  'id': instance.id,
  'category': _$NotificationCategoryEnumMap[instance.category]!,
  'title': instance.title,
  'summary': instance.summary,
  'body': instance.body,
  'createdAt': const UtcDateTimeConverter().toJson(instance.createdAt),
  'readAt': const NullableUtcDateTimeConverter().toJson(instance.readAt),
  'important': instance.important,
  'actor': instance.actor,
  'facts': instance.facts.map((e) => e.toJson()).toList(),
  'action': instance.action?.toJson(),
  'secondaryAction': instance.secondaryAction?.toJson(),
};

const _$NotificationCategoryEnumMap = {
  NotificationCategory.course: 'course',
  NotificationCategory.assignment: 'assignment',
  NotificationCategory.quiz: 'quiz',
  NotificationCategory.live: 'live',
  NotificationCategory.certificate: 'certificate',
  NotificationCategory.enrollment: 'enrollment',
  NotificationCategory.system: 'system',
  NotificationCategory.unknown: 'unknown',
};

_NotificationPage _$NotificationPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NotificationPage', json, ($checkedConvert) {
      final val = _NotificationPage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <AppNotification>[],
        ),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
        unread: $checkedConvert('unread', (v) => (v as num?)?.toInt() ?? 0),
        counts: $checkedConvert(
          'counts',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
              const <String, int>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$NotificationPageToJson(_NotificationPage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'unread': instance.unread,
  'counts': instance.counts,
};

_NotificationDetail _$NotificationDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NotificationDetail', json, ($checkedConvert) {
      final val = _NotificationDetail(
        notification: $checkedConvert(
          'notification',
          (v) => AppNotification.fromJson(v as Map<String, dynamic>),
        ),
        related: $checkedConvert(
          'related',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <AppNotification>[],
        ),
        channels: $checkedConvert(
          'channels',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as bool)) ??
              const <String, bool>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$NotificationDetailToJson(_NotificationDetail instance) => <String, dynamic>{
  'notification': instance.notification.toJson(),
  'related': instance.related.map((e) => e.toJson()).toList(),
  'channels': instance.channels,
};

_CategoryPreference _$CategoryPreferenceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CategoryPreference', json, ($checkedConvert) {
      final val = _CategoryPreference(
        category: $checkedConvert(
          'category',
          (v) =>
              $enumDecodeNullable(
                _$NotificationCategoryEnumMap,
                v,
                unknownValue: NotificationCategory.unknown,
              ) ??
              NotificationCategory.unknown,
        ),
        channels: $checkedConvert(
          'channels',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as bool)) ??
              const <String, bool>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$CategoryPreferenceToJson(_CategoryPreference instance) => <String, dynamic>{
  'category': _$NotificationCategoryEnumMap[instance.category]!,
  'channels': instance.channels,
};

_QuietHours _$QuietHoursFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuietHours', json, ($checkedConvert) {
      final val = _QuietHours(
        enabled: $checkedConvert('enabled', (v) => v as bool? ?? false),
        from: $checkedConvert('from', (v) => v as String? ?? '22:00'),
        to: $checkedConvert('to', (v) => v as String? ?? '07:00'),
      );
      return val;
    });

Map<String, dynamic> _$QuietHoursToJson(_QuietHours instance) => <String, dynamic>{
  'enabled': instance.enabled,
  'from': instance.from,
  'to': instance.to,
};

_NotificationSettings _$NotificationSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NotificationSettings', json, ($checkedConvert) {
      final val = _NotificationSettings(
        categories: $checkedConvert(
          'categories',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CategoryPreference.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CategoryPreference>[],
        ),
        emailDigest: $checkedConvert(
          'emailDigest',
          (v) =>
              $enumDecodeNullable(_$EmailDigestEnumMap, v, unknownValue: EmailDigest.unknown) ??
              EmailDigest.instant,
        ),
        quietHours: $checkedConvert(
          'quietHours',
          (v) => v == null ? const QuietHours() : QuietHours.fromJson(v as Map<String, dynamic>),
        ),
        pausedUntil: $checkedConvert(
          'pausedUntil',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        smsNumber: $checkedConvert('smsNumber', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$NotificationSettingsToJson(_NotificationSettings instance) =>
    <String, dynamic>{
      'categories': instance.categories.map((e) => e.toJson()).toList(),
      'emailDigest': _$EmailDigestEnumMap[instance.emailDigest]!,
      'quietHours': instance.quietHours.toJson(),
      'pausedUntil': const NullableUtcDateTimeConverter().toJson(instance.pausedUntil),
      'smsNumber': instance.smsNumber,
    };

const _$EmailDigestEnumMap = {
  EmailDigest.instant: 'instant',
  EmailDigest.daily: 'daily',
  EmailDigest.weekly: 'weekly',
  EmailDigest.off: 'off',
  EmailDigest.unknown: 'unknown',
};
