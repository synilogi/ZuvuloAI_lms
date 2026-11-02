import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/media/media_rules.dart';

/// The allow-list the server enforces (`apps/api/src/lib/media.ts` `MEDIA_KINDS`, `classifyUpload`).
/// The app checks first only so nobody waits for an upload that will be refused.
void main() {
  const staff = true;
  const learner = false;

  group('classify — the MIME type and the extension must agree', () {
    const accepted = {
      ('lesson.mp4', 'video/mp4'): MediaKind.video,
      ('lesson.webm', 'video/webm'): MediaKind.video,
      ('lesson.mov', 'video/quicktime'): MediaKind.video,
      ('chart.pdf', 'application/pdf'): MediaKind.document,
      ('chart.png', 'image/png'): MediaKind.image,
      ('chart.jpg', 'image/jpeg'): MediaKind.image,
      ('chart.jpeg', 'image/jpeg'): MediaKind.image,
      ('chart.webp', 'image/webp'): MediaKind.image,
    };

    accepted.forEach((file, kind) {
      test('${file.$1} as ${file.$2} is ${kind.name}', () {
        expect(MediaRules.classify(fileName: file.$1, mimeType: file.$2)?.kind, kind);
      });
    });

    test('a mismatch between the name and the type is refused', () {
      // The server requires both to match, so a renamed executable is not a PDF.
      expect(
        MediaRules.classify(fileName: 'payload.pdf', mimeType: 'application/x-msdownload'),
        isNull,
      );
      expect(MediaRules.classify(fileName: 'payload.exe', mimeType: 'application/pdf'), isNull);
      expect(MediaRules.classify(fileName: 'chart.svg', mimeType: 'image/svg+xml'), isNull);
      expect(MediaRules.classify(fileName: 'notes.txt', mimeType: 'text/plain'), isNull);
      expect(MediaRules.classify(fileName: 'chart', mimeType: 'image/png'), isNull);
      expect(MediaRules.classify(fileName: 'chart.png', mimeType: null), isNull);
    });

    test('the extension is read case-insensitively', () {
      expect(
        MediaRules.classify(fileName: 'CHART.PNG', mimeType: 'image/png')?.kind,
        MediaKind.image,
      );
      expect(
        MediaRules.classify(fileName: 'a.PDF', mimeType: 'APPLICATION/PDF')?.kind,
        MediaKind.document,
      );
    });
  });

  group('limits match the server', () {
    test('500 MB video, 25 MB documents, 5 MB images', () {
      expect(MediaRules.video.maxMb, 500);
      expect(MediaRules.document.maxMb, 25);
      expect(MediaRules.image.maxMb, 5);
    });

    test('a file at the limit passes and one byte over is refused', () {
      const mb = 1024 * 1024;
      expect(
        MediaRules.rejectionFor(
          fileName: 'chart.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 25 * mb,
          uploaderIsStaff: learner,
        ),
        isNull,
      );
      expect(
        MediaRules.rejectionFor(
          fileName: 'chart.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 25 * mb + 1,
          uploaderIsStaff: learner,
        ),
        MediaRejection.size,
      );
      expect(
        MediaRules.rejectionFor(
          fileName: 'chart.png',
          mimeType: 'image/png',
          sizeBytes: 6 * mb,
          uploaderIsStaff: staff,
        ),
        MediaRejection.size,
      );
    });
  });

  group('who may upload what', () {
    test('a learner may send documents and images', () {
      for (final file in [('chart.pdf', 'application/pdf'), ('chart.png', 'image/png')]) {
        expect(
          MediaRules.rejectionFor(
            fileName: file.$1,
            mimeType: file.$2,
            sizeBytes: 1024,
            uploaderIsStaff: learner,
          ),
          isNull,
          reason: file.$1,
        );
      }
    });

    test('video is staff only, whatever its size', () {
      expect(
        MediaRules.rejectionFor(
          fileName: 'lesson.mp4',
          mimeType: 'video/mp4',
          sizeBytes: 1024,
          uploaderIsStaff: learner,
        ),
        MediaRejection.videoNeedsStaff,
      );
      expect(
        MediaRules.rejectionFor(
          fileName: 'lesson.mp4',
          mimeType: 'video/mp4',
          sizeBytes: 1024,
          uploaderIsStaff: staff,
        ),
        isNull,
      );
    });

    test('an unacceptable type is refused before its size is considered', () {
      expect(
        MediaRules.rejectionFor(
          fileName: 'huge.txt',
          mimeType: 'text/plain',
          sizeBytes: 900 * 1024 * 1024,
          uploaderIsStaff: staff,
        ),
        MediaRejection.type,
      );
    });
  });

  test('a kind from a newer server is unknown rather than wrong', () {
    expect(MediaKind.parse('audio'), MediaKind.unknown);
    expect(MediaKind.parse('video'), MediaKind.video);
    expect(MediaRules.forKind(MediaKind.unknown), isNull);
  });

  group('the file\'s first bytes', () {
    List<int> pdf() => '%PDF-1.7'.codeUnits;
    const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    const jpeg = [0xff, 0xd8, 0xff, 0xe0];
    final webp = [...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WEBP'.codeUnits];
    final mp4 = [0, 0, 0, 0x18, ...'ftyp'.codeUnits];
    const webm = [0x1a, 0x45, 0xdf, 0xa3];

    test('each accepted type is recognised by its own signature', () {
      expect(MediaRules.matchesSignature('notes.pdf', pdf()), isTrue);
      expect(MediaRules.matchesSignature('chart.png', png), isTrue);
      expect(MediaRules.matchesSignature('chart.jpg', jpeg), isTrue);
      expect(MediaRules.matchesSignature('chart.jpeg', jpeg), isTrue);
      expect(MediaRules.matchesSignature('chart.webp', webp), isTrue);
      expect(MediaRules.matchesSignature('lesson.mp4', mp4), isTrue);
      expect(MediaRules.matchesSignature('lesson.mov', mp4), isTrue);
      expect(MediaRules.matchesSignature('lesson.webm', webm), isTrue);
    });

    test('a file renamed to another type is refused', () {
      expect(MediaRules.matchesSignature('notes.pdf', png), isFalse);
      expect(MediaRules.matchesSignature('chart.png', pdf()), isFalse);
      expect(MediaRules.matchesSignature('lesson.mp4', webm), isFalse);
      expect(MediaRules.matchesSignature('script.pdf', 'MZ'.codeUnits), isFalse);
    });

    test('too few bytes to tell is not a match', () {
      expect(MediaRules.matchesSignature('notes.pdf', const [0x25]), isFalse);
      expect(MediaRules.matchesSignature('notes.pdf', const []), isFalse);
      expect(MediaRules.matchesSignature('chart.webp', 'RIFF'.codeUnits), isFalse);
    });

    test('the pre-check refuses a renamed file, with the server\'s own reason', () {
      expect(
        MediaRules.rejectionFor(
          fileName: 'notes.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 1024,
          uploaderIsStaff: false,
          head: png,
        ),
        MediaRejection.contents,
      );
    });

    test('without the bytes nothing is claimed — the server still checks', () {
      expect(
        MediaRules.rejectionFor(
          fileName: 'notes.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 1024,
          uploaderIsStaff: false,
        ),
        isNull,
      );
    });

    test('type, staff and size are still decided before the contents', () {
      // A learner picking a video is told why, not that the bytes are wrong.
      expect(
        MediaRules.rejectionFor(
          fileName: 'lesson.mp4',
          mimeType: 'video/mp4',
          sizeBytes: 1024,
          uploaderIsStaff: false,
          head: png,
        ),
        MediaRejection.videoNeedsStaff,
      );
      expect(
        MediaRules.rejectionFor(
          fileName: 'notes.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 26 * 1024 * 1024,
          uploaderIsStaff: true,
          head: png,
        ),
        MediaRejection.size,
      );
    });
  });
}
