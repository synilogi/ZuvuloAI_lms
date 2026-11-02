import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/media/media_rules.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cancellation.dart';
import '../data/dto/uploaded_media.dart';
import '../data/media_api.dart';

/// What the server stored, for the screens that hand the result on (§13).
export '../data/dto/uploaded_media.dart';

/// A file the person picked, before it is sent.
class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.name,
    required this.sizeBytes,
    this.mimeType,
    this.head,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String? mimeType;

  /// The file's first [MediaRules.headBytes] bytes, read when it was picked, so a renamed file is
  /// caught before the upload rather than after it (SAAS-023). Null when they could not be read,
  /// which leaves the check to the server.
  final List<int>? head;
}

/// What the upload tile shows (§13, §17): a picked file, progress, a refusal that keeps the file so
/// it can be retried, or the stored media the server returned.
class MediaUploadState {
  const MediaUploadState({this.picked, this.progress, this.uploaded, this.rejection, this.failure});

  final PickedMedia? picked;

  /// 0–1 while sending; null when idle.
  final double? progress;
  final UploadedMedia? uploaded;

  /// Refused by the app's own pre-check, in the server's words.
  final MediaRejection? rejection;

  /// Refused by the server, or the network failed. The picked file is kept for a retry.
  final AppFailure? failure;

  bool get isUploading => progress != null;
  bool get hasFailed => rejection != null || failure != null;
}

/// Picks a file, checks it against the allow-list the server enforces, and uploads it with
/// progress and cancel. The server checks everything again (§13).
class MediaUploadController extends Notifier<MediaUploadState> {
  RequestCancellation? _cancellation;

  @override
  MediaUploadState build() {
    ref.onDispose(() => _cancellation?.cancel());
    return const MediaUploadState();
  }

  /// Opens the picker, then uploads. [uploaderIsStaff] mirrors the server's rule that only staff
  /// may upload video.
  Future<UploadedMedia?> pickAndUpload({
    required bool uploaderIsStaff,
    List<MediaKind> accept = const [MediaKind.document, MediaKind.image],
    Future<List<PlatformFile>> Function()? picker,
  }) async {
    final files = await (picker ?? () => _defaultPicker(accept))();
    final file = files.firstOrNull;
    final path = file?.path;
    if (file == null || path == null) return null;

    final picked = PickedMedia(
      path: path,
      name: file.name,
      sizeBytes: file.lengthSync() ?? 0,
      mimeType: lookupMimeType(file.name),
      head: await headOf(path),
    );
    return uploadPicked(picked, uploaderIsStaff: uploaderIsStaff);
  }

  /// Uploads a file that has already been picked (also used by retry). Nothing is awaited before
  /// the first state is published, so the pre-check's answer is never lost.
  Future<UploadedMedia?> uploadPicked(PickedMedia picked, {required bool uploaderIsStaff}) async {
    final rejection = MediaRules.rejectionFor(
      fileName: picked.name,
      mimeType: picked.mimeType,
      sizeBytes: picked.sizeBytes,
      uploaderIsStaff: uploaderIsStaff,
      head: picked.head,
    );
    if (rejection != null) {
      state = MediaUploadState(picked: picked, rejection: rejection);
      return null;
    }

    final cancellation = RequestCancellation();
    _cancellation = cancellation;
    state = MediaUploadState(picked: picked, progress: 0);
    try {
      final uploaded = await ref
          .read(mediaApiProvider)
          .upload(
            filePath: picked.path,
            fileName: picked.name,
            mimeType: picked.mimeType,
            cancellation: cancellation,
            onProgress: (progress) {
              if (state.isUploading) state = MediaUploadState(picked: picked, progress: progress);
            },
          );
      state = MediaUploadState(picked: picked, uploaded: uploaded);
      return uploaded;
    } on ApiException catch (e) {
      // Cancelling is not a failure to report; the tile simply goes back to the picked file.
      final cancelled =
          e.failure is NetworkFailure &&
          (e.failure as NetworkFailure).problem == NetworkProblem.cancelled;
      state = cancelled
          ? MediaUploadState(picked: picked)
          : MediaUploadState(picked: picked, failure: e.failure);
      return null;
    } finally {
      _cancellation = null;
    }
  }

  /// Sends the picked file again after a failure, keeping what the person chose (§17).
  Future<UploadedMedia?> retry({required bool uploaderIsStaff}) async {
    final picked = state.picked;
    if (picked == null) return null;
    return uploadPicked(picked, uploaderIsStaff: uploaderIsStaff);
  }

  void cancel() => _cancellation?.cancel();

  /// Forgets the picked file and anything uploaded.
  void clear() {
    _cancellation?.cancel();
    state = const MediaUploadState();
  }

  Future<List<PlatformFile>> _defaultPicker(List<MediaKind> accept) {
    final extensions = [
      for (final kind in accept)
        ...?MediaRules.forKind(kind)?.extensions.map((e) => e.substring(1)),
    ];
    return FilePicker.pickFiles(
      type: extensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: extensions.isEmpty ? null : extensions,
    );
  }
}

final mediaUploadControllerProvider = NotifierProvider<MediaUploadController, MediaUploadState>(
  MediaUploadController.new,
  isAutoDispose: true,
);

/// The file's first [MediaRules.headBytes] bytes, or null when they cannot be read — an
/// unreadable file is left for the server to refuse.
Future<List<int>?> headOf(String path) async {
  try {
    final handle = await File(path).open();
    try {
      return await handle.read(MediaRules.headBytes);
    } finally {
      await handle.close();
    }
  } on FileSystemException {
    return null;
  }
}

/// A file on disk, for tests and for code that already has one.
PickedMedia pickedFromFile(File file, {String? mimeType}) {
  final handle = file.openSync();
  try {
    return PickedMedia(
      path: file.path,
      name: file.uri.pathSegments.last,
      sizeBytes: file.lengthSync(),
      mimeType: mimeType ?? lookupMimeType(file.path),
      head: handle.readSync(MediaRules.headBytes),
    );
  } finally {
    handle.closeSync();
  }
}
