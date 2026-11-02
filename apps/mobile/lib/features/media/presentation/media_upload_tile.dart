import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/capabilities.dart';
import '../../../core/media/media_rules.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/session/current_user.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/media_upload_controller.dart';

/// Picking and sending one file, with the design system's tile showing progress, a refusal that
/// keeps the file for a retry, and the stored result (§13).
class MediaUploadTile extends ConsumerWidget {
  const MediaUploadTile({
    super.key,
    this.accept = const [MediaKind.document, MediaKind.image],
    this.onUploaded,
  });

  /// What this field takes. A learner's hand-in is documents and images; staff add video.
  final List<MediaKind> accept;

  /// The stored media the server returned — its id, name, size, URL and type — so a caller can
  /// send it straight back where the API expects a file (an assignment's work, for instance).
  final void Function(UploadedMedia uploaded)? onUploaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(mediaUploadControllerProvider);
    final controller = ref.read(mediaUploadControllerProvider.notifier);
    // Only staff may upload video — the same rule the server applies.
    final isStaff = can(ref.watch(currentUserProvider), Capability.viewCourses);

    final picked = state.picked;
    if (picked == null) {
      return AppButton(
        label: l10n.uploadChooseFile,
        icon: AppIcons.upload,
        variant: AppButtonVariant.secondary,
        onPressed: () async {
          final uploaded = await controller.pickAndUpload(uploaderIsStaff: isStaff, accept: accept);
          if (uploaded != null) onUploaded?.call(uploaded);
        },
      );
    }

    final rule = MediaRules.classify(fileName: picked.name, mimeType: picked.mimeType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFilePickerTile(
          name: picked.name,
          sizeLabel: _sizeLabel(picked.sizeBytes),
          kind: switch (rule?.kind) {
            MediaKind.document => PickedFileKind.pdf,
            MediaKind.image => PickedFileKind.image,
            MediaKind.video => PickedFileKind.video,
            _ => PickedFileKind.other,
          },
          progress: state.progress,
          failed: state.hasFailed,
          onCancel: state.isUploading ? controller.cancel : null,
          onRemove: state.isUploading ? null : controller.clear,
          onRetry: state.failure != null
              ? () async {
                  final uploaded = await controller.retry(uploaderIsStaff: isStaff);
                  if (uploaded != null) onUploaded?.call(uploaded);
                }
              : null,
        ),
        if (state.rejection != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.s2),
            child: Semantics(
              liveRegion: true,
              child: Text(
                uploadRejectionMessage(l10n, state.rejection!, picked.name, picked.mimeType),
                style: context.type.bodyS.copyWith(color: context.colors.dangerInk),
              ),
            ),
          ),
        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.s2),
            child: Text(
              state.failure!.message ?? l10n.stateErrorBody,
              style: context.type.bodyS.copyWith(color: context.colors.dangerInk),
            ),
          ),
      ],
    );
  }

  static String _sizeLabel(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// The app's wording for a pre-check refusal — the server's own sentences, so a person never sees
/// two different explanations for the same rule (`apps/api/src/routes/media.ts`).
String uploadRejectionMessage(
  AppLocalizations l10n,
  MediaRejection rejection,
  String fileName,
  String? mimeType,
) {
  switch (rejection) {
    case MediaRejection.type:
      return l10n.uploadRejectedType;
    case MediaRejection.videoNeedsStaff:
      return l10n.uploadRejectedVideoStaff;
    case MediaRejection.contents:
      return l10n.uploadRejectedContents;
    case MediaRejection.size:
      final rule = MediaRules.classify(fileName: fileName, mimeType: mimeType);
      return switch (rule?.kind) {
        MediaKind.video => l10n.uploadRejectedSizeVideo(rule!.maxMb),
        MediaKind.image => l10n.uploadRejectedSizeImage(rule!.maxMb),
        _ => l10n.uploadRejectedSizeDocument(rule?.maxMb ?? MediaRules.document.maxMb),
      };
  }
}
