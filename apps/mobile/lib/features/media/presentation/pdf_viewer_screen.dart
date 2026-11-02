import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/pdf_document_controller.dart';

/// Reads a stored PDF inside the app (§13). Nothing is handed to another app, and the downloaded
/// copy is deleted when this screen goes away.
class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({required this.mediaId, required this.title, super.key});

  final String mediaId;
  final String title;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  int _page = 1;
  int _pages = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(pdfDocumentProvider(widget.mediaId)).value ?? const PdfDocumentState();

    return Scaffold(
      appBar: CommonAppBar(
        title: widget.title,
        bottom: _pages > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Space.s2),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.mediaPageOf(_page, _pages),
                      style: context.type.caption.copyWith(color: context.colors.muted),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: switch (state) {
        PdfDocumentState(:final failure?) => ErrorState(
          title: l10n.mediaDocumentFailed,
          detail: failure.message,
          onRetry: () => ref.invalidate(pdfDocumentProvider(widget.mediaId)),
        ),
        PdfDocumentState(:final file?) => PdfViewer.file(
          file.path,
          params: PdfViewerParams(
            onViewerReady: (document, _) {
              if (mounted) setState(() => _pages = document.pages.length);
            },
            onPageChanged: (page) {
              if (mounted && page != null) setState(() => _page = page);
            },
          ),
        ),
        _ => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 180, child: ProgressBar(value: state.progress)),
              const SizedBox(height: Space.s3),
              Text(
                l10n.mediaDocumentLoading,
                style: context.type.bodyS.copyWith(color: context.colors.muted),
              ),
            ],
          ),
        ),
      },
    );
  }
}
