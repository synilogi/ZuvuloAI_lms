import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// Import boundaries (modules.md §10.1, §26):
/// - Dio is used only by the network core and features' data layers.
/// - Presentation code never imports a data layer, an API service or the network core.
/// - `core` and `shared` never import a feature.
/// - A feature imports another feature only through that feature's public barrel.
const _package = 'syniastrolms_mobile';

final _import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Resolves an import URI to a `lib/`-relative path, or returns it unchanged for other packages.
String resolveImport(String fromPath, String uri) {
  if (uri.startsWith('package:$_package/')) {
    return 'lib/${uri.substring('package:$_package/'.length)}';
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return uri;
  final segments = fromPath.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '..') {
      segments.removeLast();
    } else if (part != '.') {
      segments.add(part);
    }
  }
  return segments.join('/');
}

String? _featureOf(String path) {
  final match = RegExp(r'^lib/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

/// Every boundary broken by [path] importing [uris]; empty when the file is clean.
List<String> boundaryViolations(String path, Iterable<String> uris) {
  final problems = <String>[];
  final feature = _featureOf(path);
  final inPresentation = RegExp(r'^lib/features/[^/]+/presentation/').hasMatch(path);
  final dioAllowed =
      path.startsWith('lib/core/network/') || RegExp(r'^lib/features/[^/]+/data/').hasMatch(path);

  for (final uri in uris) {
    final target = resolveImport(path, uri);
    if ((target == 'package:dio/dio.dart' || target.startsWith('package:dio/')) && !dioAllowed) {
      problems.add('$path imports Dio ($uri)');
    }
    if (inPresentation &&
        (target.startsWith('lib/core/network/') ||
            RegExp(r'^lib/features/[^/]+/data/').hasMatch(target))) {
      problems.add('$path (presentation) imports a data/network layer ($uri)');
    }
    if ((path.startsWith('lib/core/') || path.startsWith('lib/shared/')) &&
        target.startsWith('lib/features/')) {
      problems.add('$path (core/shared) imports a feature ($uri)');
    }
    final targetFeature = _featureOf(target);
    if (feature != null && targetFeature != null && targetFeature != feature) {
      final barrel = 'lib/features/$targetFeature/$targetFeature.dart';
      if (target != barrel) {
        problems.add('$path imports $targetFeature internals ($uri); use $barrel');
      }
    }
  }
  return problems;
}

void main() {
  test('lib/ respects the layering and feature boundaries', () {
    final problems = <String>[];
    for (final file in dartSources()) {
      final path = relativePath(file);
      final uris = _import.allMatches(file.readAsStringSync()).map((m) => m.group(1)!);
      problems.addAll(boundaryViolations(path, uris));
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  group('boundary detector', () {
    test('flags Dio in a widget', () {
      expect(
        boundaryViolations('lib/features/auth/presentation/screens/login_screen.dart', [
          'package:dio/dio.dart',
        ]),
        hasLength(1),
      );
    });

    test('flags presentation importing its own data layer', () {
      expect(
        boundaryViolations('lib/features/auth/presentation/screens/login_screen.dart', [
          '../../data/auth_api.dart',
        ]),
        isNotEmpty,
      );
    });

    test('flags core importing a feature', () {
      expect(
        boundaryViolations('lib/core/auth/session_controller.dart', [
          'package:syniastrolms_mobile/features/auth/auth.dart',
        ]),
        isNotEmpty,
      );
    });

    test("flags another feature's internals but allows its barrel", () {
      const from = 'lib/features/learner_home/application/home_controller.dart';
      expect(boundaryViolations(from, ['../../explore/data/explore_repository.dart']), isNotEmpty);
      expect(boundaryViolations(from, ['../../explore/explore.dart']), isEmpty);
    });

    test('allows Dio in the network core and data layers', () {
      expect(
        boundaryViolations('lib/core/network/api_client.dart', ['package:dio/dio.dart']),
        isEmpty,
      );
      expect(
        boundaryViolations('lib/features/auth/data/auth_api.dart', ['package:dio/dio.dart']),
        isEmpty,
      );
    });
  });
}
