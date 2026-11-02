/// The upload allow-list, mirrored from the server (`apps/api/src/lib/media.ts`). This is a UX
/// pre-check so a person is not made to wait for an upload the server will refuse; the server
/// checks again and its answer is the one that counts (§13, §18).
enum MediaKind {
  video,
  document,
  image,

  /// A kind this build does not know (a newer server).
  unknown;

  static MediaKind parse(Object? value) =>
      MediaKind.values.firstWhere((k) => k.name == value, orElse: () => MediaKind.unknown);
}

/// What one kind accepts. Both the MIME type **and** the extension must match, exactly as
/// `classifyUpload` requires.
class MediaRule {
  const MediaRule({
    required this.kind,
    required this.mimes,
    required this.extensions,
    required this.maxBytes,
  });

  final MediaKind kind;
  final List<String> mimes;
  final List<String> extensions;
  final int maxBytes;

  int get maxMb => (maxBytes / (1024 * 1024)).round();
}

/// Why a file cannot be uploaded, in the server's own words so the two never disagree.
enum MediaRejection {
  /// Neither the extension nor the MIME type is on the allow-list.
  type,

  /// Larger than the kind's limit.
  size,

  /// Video is course material; only staff may upload it.
  videoNeedsStaff,

  /// The first bytes are not what the extension says (a renamed file). The server checks this
  /// too and refuses with its own message (SAAS-023, `matchesSignature`).
  contents,
}

abstract final class MediaRules {
  static const _mb = 1024 * 1024;

  static const video = MediaRule(
    kind: MediaKind.video,
    mimes: ['video/mp4', 'video/webm', 'video/quicktime'],
    extensions: ['.mp4', '.webm', '.mov'],
    maxBytes: 500 * _mb,
  );
  static const document = MediaRule(
    kind: MediaKind.document,
    mimes: ['application/pdf'],
    extensions: ['.pdf'],
    maxBytes: 25 * _mb,
  );
  static const image = MediaRule(
    kind: MediaKind.image,
    mimes: ['image/png', 'image/jpeg', 'image/webp'],
    extensions: ['.png', '.jpg', '.jpeg', '.webp'],
    maxBytes: 5 * _mb,
  );

  static const all = [video, document, image];

  /// The rule for [kind], or null for a kind with no rule.
  static MediaRule? forKind(MediaKind kind) => all.where((rule) => rule.kind == kind).firstOrNull;

  /// The kind a file belongs to — both its MIME type and its extension must agree, as the server
  /// requires. Null when it is not something the academy accepts.
  static MediaRule? classify({required String fileName, required String? mimeType}) {
    final extension = _extensionOf(fileName);
    final mime = (mimeType ?? '').toLowerCase();
    for (final rule in all) {
      if (rule.extensions.contains(extension) && rule.mimes.contains(mime)) return rule;
    }
    return null;
  }

  /// Whether this file may be sent, or why not. [head] is the file's first bytes when the caller
  /// has read them; without it the contents are simply not checked here and the server decides.
  static MediaRejection? rejectionFor({
    required String fileName,
    required String? mimeType,
    required int sizeBytes,
    required bool uploaderIsStaff,
    List<int>? head,
  }) {
    final rule = classify(fileName: fileName, mimeType: mimeType);
    if (rule == null) return MediaRejection.type;
    if (rule.kind == MediaKind.video && !uploaderIsStaff) return MediaRejection.videoNeedsStaff;
    if (sizeBytes > rule.maxBytes) return MediaRejection.size;
    if (head != null && !matchesSignature(fileName, head)) return MediaRejection.contents;
    return null;
  }

  /// How many bytes [matchesSignature] needs.
  static const headBytes = 16;

  /// Whether a file's first bytes are what its extension claims, mirroring the server's
  /// `matchesSignature` (`apps/api/src/lib/media.ts`): PDF `%PDF-`, PNG's eight-byte signature,
  /// JPEG `FF D8 FF`, WebP a RIFF container of type `WEBP`, MP4 and MOV an ISO `ftyp` box at
  /// offset 4, WebM the EBML header. The bytes are the one thing a client cannot rename.
  static bool matchesSignature(String fileName, List<int> head) {
    bool at(int offset, List<int> want) {
      if (head.length < offset + want.length) return false;
      for (var i = 0; i < want.length; i++) {
        if (head[offset + i] != want[i]) return false;
      }
      return true;
    }

    List<int> ascii(String text) => text.codeUnits;

    return switch (_extensionOf(fileName)) {
      '.pdf' => at(0, ascii('%PDF-')),
      '.png' => at(0, const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      '.jpg' || '.jpeg' => at(0, const [0xff, 0xd8, 0xff]),
      '.webp' => at(0, ascii('RIFF')) && at(8, ascii('WEBP')),
      '.mp4' || '.mov' => at(4, ascii('ftyp')),
      '.webm' => at(0, const [0x1a, 0x45, 0xdf, 0xa3]),
      _ => false,
    };
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot).toLowerCase();
  }
}
