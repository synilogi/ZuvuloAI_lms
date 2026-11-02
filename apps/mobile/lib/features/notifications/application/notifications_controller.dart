import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/domain/notification.dart';
import '../data/notifications_api.dart';

/// The notification models the screens read (§12, §26).
export '../../../shared/domain/notification.dart';

/// What the list is showing: everything, only what is unread, and optionally one category.
@immutable
class NotificationFilter {
  const NotificationFilter({
    this.unreadOnly = false,
    this.category,
    this.limit = NotificationsApi.pageLimit,
  });

  final bool unreadOnly;
  final NotificationCategory? category;

  /// The route has no page parameter: a longer list is asked for by raising this (§12).
  final int limit;

  NotificationFilter copyWith({
    bool? unreadOnly,
    NotificationCategory? category,
    bool clearCategory = false,
    int? limit,
  }) => NotificationFilter(
    unreadOnly: unreadOnly ?? this.unreadOnly,
    category: clearCategory ? null : (category ?? this.category),
    limit: limit ?? this.limit,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationFilter &&
      other.unreadOnly == unreadOnly &&
      other.category == category &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(unreadOnly, category, limit);
}

/// What the list is filtered by right now.
final notificationFilterProvider =
    NotifierProvider<NotificationFilterController, NotificationFilter>(
      NotificationFilterController.new,
      isAutoDispose: true,
    );

class NotificationFilterController extends Notifier<NotificationFilter> {
  @override
  NotificationFilter build() => const NotificationFilter();

  void showAll() => state = state.copyWith(unreadOnly: false);

  void showUnreadOnly() => state = state.copyWith(unreadOnly: true);

  void inCategory(NotificationCategory? category) => state = category == null
      ? state.copyWith(clearCategory: true, limit: NotificationsApi.pageLimit)
      : state.copyWith(category: category, limit: NotificationsApi.pageLimit);

  /// Asks for more of the same list, up to what the route will answer with.
  void showMore() => state = state.copyWith(
    limit: (state.limit + NotificationsApi.pageLimit).clamp(1, NotificationsApi.maxLimit),
  );
}

/// The list as the academy holds it, for the current filter.
final notificationsProvider = FutureProvider<NotificationPage>((ref) {
  final filter = ref.watch(notificationFilterProvider);
  return ref
      .watch(notificationsApiProvider)
      .list(unreadOnly: filter.unreadOnly, category: filter.category, limit: filter.limit);
}, isAutoDispose: true);

/// One notification. Reading it **marks it read**, which is the route's own behaviour, so the list
/// and the bell are read again after it.
final notificationDetailProvider = FutureProvider.family<NotificationDetail, String>((
  ref,
  notificationId,
) async {
  final detail = await ref.watch(notificationsApiProvider).detail(notificationId);
  ref.invalidate(notificationsProvider);
  unawaited(ref.read(unreadCountProvider.notifier).refresh());
  return detail;
}, isAutoDispose: true);

/// How often the bell asks again while the app is in front (§12).
const unreadPollInterval = Duration(seconds: 60);

/// The bell's number. There is no push and no socket, so it is polled: on start, on resume, after
/// every mutation, and once a minute while the app is in front — never while it is in the
/// background (§12).
class UnreadCountController extends Notifier<int?> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  @override
  int? build() {
    _lifecycle = AppLifecycleListener(onResume: refresh, onHide: _stop, onShow: _start);
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
    _start();
    unawaited(refresh());
    return null;
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(unreadPollInterval, (_) => refresh());
  }

  void _stop() => _timer?.cancel();

  /// Asks the academy how many are unread. A failed poll leaves the last number alone: the bell is
  /// not the place to report a network problem (§17). A poll still in flight when the app closes
  /// is dropped rather than written to a provider that has gone.
  Future<void> refresh() async {
    try {
      final page = await ref.read(notificationsApiProvider).list(limit: 1);
      if (ref.mounted) state = page.unread;
    } on ApiException {
      // Keep whatever was last known.
    }
  }
}

final unreadCountProvider = NotifierProvider<UnreadCountController, int?>(
  UnreadCountController.new,
);

/// What a list mutation left behind: what is in flight, what can still be undone, and the
/// academy's refusal if it made one.
@immutable
class NotificationActionState {
  const NotificationActionState({
    this.busy = false,
    this.removed = const [],
    this.removing,
    this.failure,
  });

  final bool busy;

  /// The notification whose removal is in flight. It leaves the list the moment the swipe ends,
  /// and comes back if the academy refuses.
  final String? removing;

  /// Kept whole so the undo can put them back exactly as they were — which is what the route's
  /// restore takes.
  final List<AppNotification> removed;

  final AppFailure? failure;

  bool get canUndo => removed.isNotEmpty;

  /// What the list on screen should no longer show: what the academy has removed and what is on
  /// its way out. The list is read again after every removal; until it arrives, these are gone.
  Set<String> get removedIds => {?removing, for (final n in removed) n.id};
}

/// Marking read, removing with an undo, and clearing. Every count shown after one of these is the
/// academy's own answer, never a number the app worked out.
class NotificationActionController extends Notifier<NotificationActionState> {
  @override
  NotificationActionState build() => const NotificationActionState();

  Future<bool> setRead(List<String> ids, {required bool read}) =>
      _run(() => ref.read(notificationsApiProvider).setRead(ids: ids, read: read));

  /// Marks everything read, or one category, and answers how many the academy changed.
  Future<int?> readAll({NotificationCategory? category}) async {
    if (state.busy) return null;
    state = NotificationActionState(removed: state.removed, busy: true);
    try {
      final changed = await ref.read(notificationsApiProvider).readAll(category: category);
      state = NotificationActionState(removed: state.removed);
      _refresh();
      return changed;
    } on ApiException catch (e) {
      state = NotificationActionState(removed: state.removed, failure: e.failure);
      return null;
    }
  }

  /// Removes one, keeping it whole so it can be put back.
  Future<bool> remove(AppNotification notification) async {
    if (state.busy) return false;
    state = NotificationActionState(removed: state.removed, busy: true, removing: notification.id);
    try {
      await ref.read(notificationsApiProvider).remove([notification.id]);
      state = NotificationActionState(removed: [...state.removed, notification]);
      _refresh();
      return true;
    } on ApiException catch (e) {
      state = NotificationActionState(removed: state.removed, failure: e.failure);
      return false;
    }
  }

  /// Puts back what was just removed — the academy restores it exactly as it was.
  Future<bool> undo() async {
    final removed = state.removed;
    if (removed.isEmpty || state.busy) return false;
    state = NotificationActionState(removed: removed, busy: true);
    try {
      await ref.read(notificationsApiProvider).restore(removed);
      state = const NotificationActionState();
      _refresh();
      return true;
    } on ApiException catch (e) {
      state = NotificationActionState(removed: removed, failure: e.failure);
      return false;
    }
  }

  /// Forgets the undo once its moment has passed.
  void forgetUndo() => state = NotificationActionState(failure: state.failure);

  Future<int?> clear({NotificationCategory? category, bool unreadOnly = false}) async {
    if (state.busy) return null;
    state = const NotificationActionState(busy: true);
    try {
      final cleared = await ref
          .read(notificationsApiProvider)
          .clear(category: category, unreadOnly: unreadOnly);
      state = const NotificationActionState();
      _refresh();
      return cleared;
    } on ApiException catch (e) {
      state = NotificationActionState(failure: e.failure);
      return null;
    }
  }

  void clearFailure() => state = NotificationActionState(busy: state.busy, removed: state.removed);

  Future<bool> _run(Future<void> Function() action) async {
    if (state.busy) return false;
    state = NotificationActionState(removed: state.removed, busy: true);
    try {
      await action();
      state = NotificationActionState(removed: state.removed);
      _refresh();
      return true;
    } on ApiException catch (e) {
      state = NotificationActionState(removed: state.removed, failure: e.failure);
      return false;
    }
  }

  void _refresh() {
    ref.invalidate(notificationsProvider);
    unawaited(ref.read(unreadCountProvider.notifier).refresh());
  }
}

final notificationActionProvider =
    NotifierProvider<NotificationActionController, NotificationActionState>(
      NotificationActionController.new,
      isAutoDispose: true,
    );

/// The academy's settings for this account.
final notificationSettingsProvider = FutureProvider<NotificationSettings>(
  (ref) => ref.watch(notificationsApiProvider).settings(),
  isAutoDispose: true,
);

/// The preferences screen's working copy: what is on screen, whether it differs from what the
/// academy holds, and what it said if it refused.
@immutable
class SettingsDraft {
  const SettingsDraft({
    this.saved,
    this.draft,
    this.saving = false,
    this.issues = const [],
    this.failure,
  });

  /// What the academy holds.
  final NotificationSettings? saved;

  /// What is on screen.
  final NotificationSettings? draft;

  final bool saving;

  /// The academy's own issues, when it refused.
  final List<SettingsIssue> issues;
  final AppFailure? failure;

  bool get dirty => draft != null && saved != null && draft != saved;

  NotificationSettings? get current => draft ?? saved;
}

class NotificationSettingsController extends Notifier<SettingsDraft> {
  /// What is on screen, kept across a rebuild so a background read never wipes an edit.
  NotificationSettings? _draft;

  @override
  SettingsDraft build() {
    final saved = ref.watch(notificationSettingsProvider).value;
    return SettingsDraft(saved: saved, draft: _draft);
  }

  void edit(NotificationSettings settings) {
    _draft = settings;
    state = SettingsDraft(saved: state.saved, draft: settings);
  }

  /// Saves what is on screen. The app checks the academy's own rules first so a refusal is rare,
  /// but the server's answer is what counts.
  Future<bool> save() async {
    final draft = state.current;
    if (draft == null || state.saving) return false;
    final issues = settingsIssues(draft);
    if (issues.isNotEmpty) {
      state = SettingsDraft(saved: state.saved, draft: draft, issues: issues);
      return false;
    }
    state = SettingsDraft(saved: state.saved, draft: draft, saving: true);
    try {
      // What the academy answers with **is** what it now holds, so nothing is read again.
      final saved = await ref.read(notificationsApiProvider).saveSettings(draft);
      _draft = null;
      state = SettingsDraft(saved: saved);
      return true;
    } on ApiException catch (e) {
      final failure = e.failure;
      state = SettingsDraft(
        saved: state.saved,
        draft: draft,
        issues: failure is ConflictFailure
            ? [for (final issue in failure.issues) SettingsIssue(issue.key ?? '', issue.message)]
            : const [],
        failure: failure is ConflictFailure ? null : failure,
      );
      return false;
    }
  }

  void clearFailure() =>
      state = SettingsDraft(saved: state.saved, draft: state.draft, issues: state.issues);
}

final notificationSettingsDraftProvider =
    NotifierProvider<NotificationSettingsController, SettingsDraft>(
      NotificationSettingsController.new,
      isAutoDispose: true,
    );
