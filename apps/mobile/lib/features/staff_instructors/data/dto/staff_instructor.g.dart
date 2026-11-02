// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_instructor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AcademyInstructor _$AcademyInstructorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AcademyInstructor', json, ($checkedConvert) {
      final val = _AcademyInstructor(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        yearsTeaching: $checkedConvert('yearsTeaching', (v) => (v as num?)?.toInt()),
        email: $checkedConvert('email', (v) => v as String? ?? ''),
        bio: $checkedConvert('bio', (v) => v as String? ?? ''),
        expertise: $checkedConvert(
          'expertise',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$InstructorStatusEnumMap,
                v,
                unknownValue: InstructorStatus.unknown,
              ) ??
              InstructorStatus.unknown,
        ),
        joinedAt: $checkedConvert(
          'joinedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
        languages: $checkedConvert(
          'languages',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        phone: $checkedConvert('phone', (v) => v as String?),
        photo: $checkedConvert(
          'photo',
          (v) => v == null ? null : MediaFile.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AcademyInstructorToJson(_AcademyInstructor instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'title': instance.title,
  'yearsTeaching': instance.yearsTeaching,
  'email': instance.email,
  'bio': instance.bio,
  'expertise': instance.expertise,
  'status': _$InstructorStatusEnumMap[instance.status]!,
  'joinedAt': const UtcDateTimeConverter().toJson(instance.joinedAt),
  'city': instance.city,
  'languages': instance.languages,
  'phone': instance.phone,
  'photo': instance.photo?.toJson(),
};

const _$InstructorStatusEnumMap = {
  InstructorStatus.active: 'active',
  InstructorStatus.invited: 'invited',
  InstructorStatus.inactive: 'inactive',
  InstructorStatus.unknown: 'unknown',
};

_InstructorCourseBrief _$InstructorCourseBriefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorCourseBrief', json, ($checkedConvert) {
      final val = _InstructorCourseBrief(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$CourseStatusEnumMap, v, unknownValue: CourseStatus.unknown) ??
              CourseStatus.unknown,
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstructorCourseBriefToJson(_InstructorCourseBrief instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': _$CourseStatusEnumMap[instance.status]!,
    };

const _$CourseStatusEnumMap = {
  CourseStatus.draft: 'draft',
  CourseStatus.published: 'published',
  CourseStatus.archived: 'archived',
  CourseStatus.unknown: 'unknown',
};

_InstructorRow _$InstructorRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorRow', json, ($checkedConvert) {
      final val = _InstructorRow(
        instructor: $checkedConvert(
          'instructor',
          (v) => AcademyInstructor.fromJson(v as Map<String, dynamic>),
        ),
        courses: $checkedConvert(
          'courses',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => InstructorCourseBrief.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <InstructorCourseBrief>[],
        ),
        students: $checkedConvert('students', (v) => (v as num?)?.toInt() ?? 0),
        rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
        ratingCount: $checkedConvert('ratingCount', (v) => (v as num?)?.toInt() ?? 0),
        completion: $checkedConvert('completion', (v) => (v as num?)?.toInt()),
        toReview: $checkedConvert('toReview', (v) => (v as num?)?.toInt() ?? 0),
        overdue: $checkedConvert('overdue', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$InstructorRowToJson(_InstructorRow instance) => <String, dynamic>{
  'instructor': instance.instructor.toJson(),
  'courses': instance.courses.map((e) => e.toJson()).toList(),
  'students': instance.students,
  'rating': instance.rating,
  'ratingCount': instance.ratingCount,
  'completion': instance.completion,
  'toReview': instance.toReview,
  'overdue': instance.overdue,
};

_InstructorDirectory _$InstructorDirectoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorDirectory', json, ($checkedConvert) {
      final val = _InstructorDirectory(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => InstructorRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <InstructorRow>[],
        ),
        counts: $checkedConvert(
          'counts',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
              const <String, int>{},
        ),
        expertise: $checkedConvert(
          'expertise',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstructorDirectoryToJson(_InstructorDirectory instance) =>
    <String, dynamic>{
      'rows': instance.rows.map((e) => e.toJson()).toList(),
      'counts': instance.counts,
      'expertise': instance.expertise,
    };

_InstructorCourse _$InstructorCourseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorCourse', json, ($checkedConvert) {
      final val = _InstructorCourse(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$CourseStatusEnumMap, v, unknownValue: CourseStatus.unknown) ??
              CourseStatus.unknown,
        ),
        levelTitle: $checkedConvert('levelTitle', (v) => v as String? ?? ''),
        coverMotif: $checkedConvert('coverMotif', (v) => v as String?),
        coverImageUrl: $checkedConvert('coverImageUrl', (v) => v as String?),
        role: $checkedConvert('role', (v) => v as String? ?? ''),
        coInstructors: $checkedConvert(
          'coInstructors',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        enrolled: $checkedConvert('enrolled', (v) => (v as num?)?.toInt() ?? 0),
        activeLearners: $checkedConvert('activeLearners', (v) => (v as num?)?.toInt() ?? 0),
        rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
        ratingCount: $checkedConvert('ratingCount', (v) => (v as num?)?.toInt()),
        completion: $checkedConvert('completion', (v) => (v as num?)?.toInt()),
        lessons: $checkedConvert('lessons', (v) => (v as num?)?.toInt() ?? 0),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstructorCourseToJson(_InstructorCourse instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'status': _$CourseStatusEnumMap[instance.status]!,
  'levelTitle': instance.levelTitle,
  'coverMotif': instance.coverMotif,
  'coverImageUrl': instance.coverImageUrl,
  'role': instance.role,
  'coInstructors': instance.coInstructors,
  'enrolled': instance.enrolled,
  'activeLearners': instance.activeLearners,
  'rating': instance.rating,
  'ratingCount': instance.ratingCount,
  'completion': instance.completion,
  'lessons': instance.lessons,
  'updatedAt': const UtcDateTimeConverter().toJson(instance.updatedAt),
};

_CityCount _$CityCountFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CityCount', json, ($checkedConvert) {
      final val = _CityCount(
        city: $checkedConvert('city', (v) => v as String? ?? ''),
        count: $checkedConvert('count', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$CityCountToJson(_CityCount instance) => <String, dynamic>{
  'city': instance.city,
  'count': instance.count,
};

_InstructorReach _$InstructorReachFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorReach', json, ($checkedConvert) {
      final val = _InstructorReach(
        students: $checkedConvert('students', (v) => (v as num?)?.toInt() ?? 0),
        active: $checkedConvert('active', (v) => (v as num?)?.toInt() ?? 0),
        completed: $checkedConvert('completed', (v) => (v as num?)?.toInt() ?? 0),
        newThisMonth: $checkedConvert('newThisMonth', (v) => (v as num?)?.toInt() ?? 0),
        cities: $checkedConvert(
          'cities',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CityCount.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CityCount>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstructorReachToJson(_InstructorReach instance) => <String, dynamic>{
  'students': instance.students,
  'active': instance.active,
  'completed': instance.completed,
  'newThisMonth': instance.newThisMonth,
  'cities': instance.cities.map((e) => e.toJson()).toList(),
};

_MonthCount _$MonthCountFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_MonthCount', json, ($checkedConvert) {
      final val = _MonthCount(
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        detail: $checkedConvert('detail', (v) => v as String? ?? ''),
        value: $checkedConvert('value', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$MonthCountToJson(_MonthCount instance) => <String, dynamic>{
  'label': instance.label,
  'detail': instance.detail,
  'value': instance.value,
};

_InstructorPerformance _$InstructorPerformanceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorPerformance', json, ($checkedConvert) {
      final val = _InstructorPerformance(
        rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
        ratingCount: $checkedConvert('ratingCount', (v) => (v as num?)?.toInt() ?? 0),
        academyRating: $checkedConvert('academyRating', (v) => (v as num?)?.toDouble() ?? 0),
        completion: $checkedConvert('completion', (v) => (v as num?)?.toInt()),
        academyCompletion: $checkedConvert('academyCompletion', (v) => (v as num?)?.toInt() ?? 0),
        reviewHoursMedian: $checkedConvert('reviewHoursMedian', (v) => (v as num?)?.toInt()),
        reviewsOnTime: $checkedConvert('reviewsOnTime', (v) => (v as num?)?.toInt()),
        reviewed: $checkedConvert('reviewed', (v) => (v as num?)?.toInt() ?? 0),
        toReview: $checkedConvert('toReview', (v) => (v as num?)?.toInt() ?? 0),
        liveDelivered: $checkedConvert('liveDelivered', (v) => (v as num?)?.toInt() ?? 0),
        liveUpcoming: $checkedConvert('liveUpcoming', (v) => (v as num?)?.toInt() ?? 0),
        attendance: $checkedConvert('attendance', (v) => (v as num?)?.toInt()),
        enrollmentsByMonth: $checkedConvert(
          'enrollmentsByMonth',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => MonthCount.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <MonthCount>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstructorPerformanceToJson(_InstructorPerformance instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'ratingCount': instance.ratingCount,
      'academyRating': instance.academyRating,
      'completion': instance.completion,
      'academyCompletion': instance.academyCompletion,
      'reviewHoursMedian': instance.reviewHoursMedian,
      'reviewsOnTime': instance.reviewsOnTime,
      'reviewed': instance.reviewed,
      'toReview': instance.toReview,
      'liveDelivered': instance.liveDelivered,
      'liveUpcoming': instance.liveUpcoming,
      'attendance': instance.attendance,
      'enrollmentsByMonth': instance.enrollmentsByMonth.map((e) => e.toJson()).toList(),
    };

_InstructorDetail _$InstructorDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorDetail', json, ($checkedConvert) {
      final val = _InstructorDetail(
        instructor: $checkedConvert(
          'instructor',
          (v) => AcademyInstructor.fromJson(v as Map<String, dynamic>),
        ),
        courses: $checkedConvert(
          'courses',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => InstructorCourse.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <InstructorCourse>[],
        ),
        reach: $checkedConvert(
          'reach',
          (v) => v == null
              ? const InstructorReach()
              : InstructorReach.fromJson(v as Map<String, dynamic>),
        ),
        performance: $checkedConvert(
          'performance',
          (v) => v == null
              ? const InstructorPerformance()
              : InstructorPerformance.fromJson(v as Map<String, dynamic>),
        ),
        activity: $checkedConvert(
          'activity',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => AdminEvent.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <AdminEvent>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstructorDetailToJson(_InstructorDetail instance) => <String, dynamic>{
  'instructor': instance.instructor.toJson(),
  'courses': instance.courses.map((e) => e.toJson()).toList(),
  'reach': instance.reach.toJson(),
  'performance': instance.performance.toJson(),
  'activity': instance.activity.map((e) => e.toJson()).toList(),
};
