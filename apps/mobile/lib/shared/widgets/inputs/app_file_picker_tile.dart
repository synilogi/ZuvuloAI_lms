import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';

enum PickedFileKind { pdf, image, video, other }

/// A picked or uploaded file: name, size and — while uploading — progress with cancel; after a
/// failure, the file is kept with a retry (§17). Picking itself is FLUTTER-007's.
class AppFilePickerTile extends StatelessWidget {
  const AppFilePickerTile({
    required this.name,
    required this.sizeLabel,
    super.key,
    this.kind = PickedFileKind.other,
    this.progress,
    this.failed = false,
    this.onCancel,
    this.onRemove,
    this.onRetry,
  });

  final String name;

  /// Pre-formatted size, e.g. "2.4 MB".
  final String sizeLabel;
  final PickedFileKind kind;

  /// 0–1 while uploading; null when idle or done.
  final double? progress;
  final bool failed;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final uploading = progress != null && !failed;
    final percent = ((progress ?? 0) * 100).round().clamp(0, 100);
    final icon = switch (kind) {
      PickedFileKind.pdf => AppIcons.filePdf,
      PickedFileKind.image => AppIcons.fileImage,
      PickedFileKind.video => AppIcons.lessonVideo,
      PickedFileKind.other => AppIcons.file,
    };
    final status = failed
        ? l10n.fileUploadFailed
        : uploading
        ? l10n.fileUploading(percent)
        : sizeLabel;

    return Container(
      padding: const EdgeInsets.all(Space.s3),
      decoration: BoxDecoration(
        color: failed ? c.dangerSoft : c.surface2,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: failed ? c.danger : c.border),
      ),
      child: Row(
        children: [
          AppIcon(icon, color: failed ? c.dangerInk : c.accentInk),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.type.titleS,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Space.s1),
                Semantics(
                  liveRegion: uploading || failed,
                  child: Text(
                    status,
                    style: context.type.bodyS.copyWith(color: failed ? c.dangerInk : c.muted),
                  ),
                ),
                if (uploading) ...[
                  const SizedBox(height: Space.s2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.pill),
                    child: LinearProgressIndicator(value: progress, minHeight: 4),
                  ),
                ],
              ],
            ),
          ),
          if (failed && onRetry != null)
            IconButton(
              tooltip: l10n.actionRetry,
              onPressed: onRetry,
              icon: AppIcon(AppIcons.upload, color: c.dangerInk),
            ),
          if (uploading && onCancel != null)
            IconButton(
              tooltip: l10n.actionCancelUpload,
              onPressed: onCancel,
              icon: AppIcon(AppIcons.close, color: c.muted),
            )
          else if (!uploading && onRemove != null)
            IconButton(
              tooltip: l10n.actionRemoveFile,
              onPressed: onRemove,
              icon: AppIcon(AppIcons.delete, color: c.muted),
            ),
        ],
      ),
    );
  }
}
