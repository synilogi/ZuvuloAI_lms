import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../auth/session_cleanup.dart';
import '../logging/app_logger.dart';

/// Where media lives on the device: an image cache scoped to the signed-in person, and a temp
/// folder for files opened in a viewer. Both are emptied on sign-out and when the person changes,
/// so one academy's material never shows to the next (§8.4, §15).
class MediaCache {
  MediaCache({Directory Function()? temporaryDirectory})
    : _temporaryDirectoryOverride = temporaryDirectory;

  final Directory Function()? _temporaryDirectoryOverride;
  CacheManager? _images;
  String? _userKey;

  static const _imageCachePrefix = 'syniastro_media_';
  static const _tempFolder = 'syniastro_media';

  /// The image cache for [userId]. Changing person swaps the store, so a cached image is never
  /// served to someone else.
  CacheManager imagesFor(String userId) {
    if (_userKey != userId) {
      _images = CacheManager(
        Config(
          '$_imageCachePrefix$userId',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 300,
        ),
      );
      _userKey = userId;
    }
    return _images!;
  }

  /// A place for a file a viewer needs on disk (a PDF). Deleted with [purge].
  Future<Directory> temporaryMediaDirectory() async {
    final base = _temporaryDirectoryOverride?.call() ?? await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, _tempFolder));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> temporaryFile(String name) async =>
      File(p.join((await temporaryMediaDirectory()).path, name));

  /// Empties the image cache and deletes every temporary file.
  Future<void> purge() async {
    await _images?.emptyCache();
    _images = null;
    _userKey = null;
    final dir = await temporaryMediaDirectory();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

final mediaCacheProvider = Provider<MediaCache>((ref) {
  final cache = MediaCache();
  // Signing out forgets every cached image and temporary file (§6).
  ref.read(sessionCleanupProvider).register(() async {
    try {
      await cache.purge();
    } on Object catch (error, stack) {
      ref.read(appLoggerProvider).error('media cache purge failed', error: error, stack: stack);
    }
  });
  return cache;
});
