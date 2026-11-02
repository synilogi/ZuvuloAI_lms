import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What must be forgotten when the session ends or the signed-in person changes (§8.4, §6):
/// caches, temporary files, badges. Features register their own cleanup at start-up; the session
/// controller runs them all on sign-out. A failing cleanup never blocks signing out.
class SessionCleanupRegistry {
  final List<Future<void> Function()> _tasks = [];

  void register(Future<void> Function() task) => _tasks.add(task);

  Future<void> runAll({void Function(Object error, StackTrace stack)? onError}) async {
    for (final task in List.of(_tasks)) {
      try {
        await task();
      } on Object catch (error, stack) {
        onError?.call(error, stack);
      }
    }
  }
}

final sessionCleanupProvider = Provider<SessionCleanupRegistry>((ref) => SessionCleanupRegistry());
