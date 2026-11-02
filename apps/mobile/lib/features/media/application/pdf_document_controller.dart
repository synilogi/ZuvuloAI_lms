import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/media/media_cache.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cancellation.dart';
import '../data/media_api.dart';

/// Fetching a stored document for the viewer (§13): downloaded with the bearer into the app's
/// temporary folder — there are no public URLs — and deleted when the screen goes away.
class PdfDocumentState {
  const PdfDocumentState({this.progress = 0, this.file, this.failure});

  /// 0–1 while downloading.
  final double progress;
  final File? file;
  final AppFailure? failure;

  bool get isReady => file != null;
}

/// Emits progress, then the file on disk. Watching it starts the download; leaving the screen
/// cancels it and deletes the copy. Re-reading (`ref.invalidate`) retries.
final pdfDocumentProvider = StreamProvider.family<PdfDocumentState, String>((ref, mediaId) {
  final controller = StreamController<PdfDocumentState>();
  final cancellation = RequestCancellation();
  File? downloaded;

  ref.onDispose(() {
    cancellation.cancel();
    unawaited(controller.close());
    final file = downloaded;
    // The copy on disk goes with the screen (§15).
    if (file != null && file.existsSync()) file.deleteSync();
  });

  Future<void> run() async {
    try {
      final bytes = await ref
          .read(mediaApiProvider)
          .bytes(
            mediaId,
            cancellation: cancellation,
            onProgress: (progress) {
              if (!controller.isClosed) controller.add(PdfDocumentState(progress: progress));
            },
          );
      final file = await ref.read(mediaCacheProvider).temporaryFile('$mediaId.pdf');
      await file.writeAsBytes(bytes, flush: true);
      downloaded = file;
      if (!controller.isClosed) controller.add(PdfDocumentState(progress: 1, file: file));
    } on ApiException catch (e) {
      if (!controller.isClosed) controller.add(PdfDocumentState(failure: e.failure));
    }
  }

  unawaited(run());
  return controller.stream;
}, isAutoDispose: true);
