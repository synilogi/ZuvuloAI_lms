import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'core/config/flavor.dart';
import 'dev/gallery/gallery_screen.dart';

/// Developer-only routes; also registered by `main.dart`, the default dev entry point.
final Map<String, WidgetBuilder> devRoutes = {
  GalleryScreen.routeName: (_) => const GalleryScreen(),
};

void main() => bootstrap(Flavor.dev, devRoutes: devRoutes);
