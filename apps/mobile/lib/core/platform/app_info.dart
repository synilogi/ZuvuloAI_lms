import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// What this build is: the version and build number the store and a crash report name it by.
/// Behind a provider so a test can state it instead of asking the platform.
final appInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());
