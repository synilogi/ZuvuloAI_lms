import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/theme.dart';

/// The app's icon vocabulary: Phosphor (the web's family), duotone by default, named by meaning
/// rather than by glyph so a feature asks for `AppIcons.notifications`, not a bell.
abstract final class AppIcons {
  // Navigation
  static const home = PhosphorIconsDuotone.house;
  static const learning = PhosphorIconsDuotone.bookOpenText;
  static const explore = PhosphorIconsDuotone.compass;
  static const live = PhosphorIconsDuotone.videoCamera;
  static const profile = PhosphorIconsDuotone.userCircle;
  static const dashboard = PhosphorIconsDuotone.squaresFour;
  static const review = PhosphorIconsDuotone.clipboardText;
  static const courses = PhosphorIconsDuotone.books;
  static const people = PhosphorIconsDuotone.usersThree;
  static const more = PhosphorIconsDuotone.dotsThreeCircle;
  static const notifications = PhosphorIconsDuotone.bell;
  static const calendar = PhosphorIconsDuotone.calendarBlank;
  static const reports = PhosphorIconsDuotone.chartLine;
  static const billing = PhosphorIconsDuotone.creditCard;
  static const certificate = PhosphorIconsDuotone.certificate;
  static const rank = PhosphorIconsDuotone.medal;
  static const help = PhosphorIconsDuotone.question;
  static const settings = PhosphorIconsDuotone.gearSix;
  static const email = PhosphorIconsDuotone.envelopeSimple;
  static const quiz = PhosphorIconsDuotone.exam;
  static const assignment = PhosphorIconsDuotone.clipboardText;
  static const instructor = PhosphorIconsDuotone.chalkboardTeacher;
  static const rocket = PhosphorIconsDuotone.rocketLaunch;
  static const level = PhosphorIconsDuotone.chartBar;
  static const language = PhosphorIconsDuotone.translate;
  static const format = PhosphorIconsDuotone.path;
  static const duration = PhosphorIconsDuotone.clock;

  // Actions
  static const back = PhosphorIconsRegular.arrowLeft;
  static const forward = PhosphorIconsRegular.arrowRight;
  static const close = PhosphorIconsRegular.x;
  static const search = PhosphorIconsRegular.magnifyingGlass;
  static const filter = PhosphorIconsRegular.funnelSimple;
  static const sort = PhosphorIconsRegular.sortAscending;
  static const add = PhosphorIconsRegular.plus;
  static const bookmark = PhosphorIconsRegular.bookmarkSimple;
  static const bookmarked = PhosphorIconsFill.bookmarkSimple;
  static const remove = PhosphorIconsRegular.minus;
  static const edit = PhosphorIconsRegular.pencilSimple;
  static const delete = PhosphorIconsRegular.trash;
  static const share = PhosphorIconsRegular.shareNetwork;
  static const external = PhosphorIconsRegular.arrowSquareOut;
  static const chevronRight = PhosphorIconsRegular.caretRight;
  static const chevronDown = PhosphorIconsRegular.caretDown;
  static const chevronUp = PhosphorIconsRegular.caretUp;
  static const check = PhosphorIconsBold.check;
  static const eye = PhosphorIconsRegular.eye;
  static const eyeOff = PhosphorIconsRegular.eyeSlash;
  static const upload = PhosphorIconsDuotone.uploadSimple;
  static const file = PhosphorIconsDuotone.fileText;
  static const filePdf = PhosphorIconsDuotone.filePdf;
  static const fileImage = PhosphorIconsDuotone.fileImage;
  static const date = PhosphorIconsRegular.calendarBlank;
  static const time = PhosphorIconsRegular.clock;
  static const trendUp = PhosphorIconsBold.arrowUpRight;
  static const trendDown = PhosphorIconsBold.arrowDownRight;
  static const trendFlat = PhosphorIconsBold.arrowRight;
  static const list = PhosphorIconsRegular.listBullets;
  static const chart = PhosphorIconsRegular.chartBar;
  static const play = PhosphorIconsFill.play;
  static const rating = PhosphorIconsFill.star;
  static const pause = PhosphorIconsFill.pause;

  // States
  static const error = PhosphorIconsDuotone.cloudWarning;
  static const offline = PhosphorIconsDuotone.wifiSlash;
  static const lock = PhosphorIconsDuotone.lockSimple;
  static const featureOff = PhosphorIconsDuotone.sparkle;
  static const subscription = PhosphorIconsDuotone.receipt;
  static const notFound = PhosphorIconsDuotone.mapTrifold;
  static const empty = PhosphorIconsDuotone.planet;
  static const warning = PhosphorIconsDuotone.warningCircle;
  static const info = PhosphorIconsDuotone.info;
  static const success = PhosphorIconsDuotone.checkCircle;

  // Lesson types
  static const lessonVideo = PhosphorIconsDuotone.playCircle;
  static const lessonReading = PhosphorIconsDuotone.article;
  static const lessonDocument = PhosphorIconsDuotone.filePdf;
  static const lessonPractice = PhosphorIconsDuotone.pencilLine;
  static const lessonLive = PhosphorIconsDuotone.broadcast;
  static const lessonQuiz = PhosphorIconsDuotone.exam;
  static const lessonAssignment = PhosphorIconsDuotone.clipboardText;
}

/// An icon in the design system's style. Pass [semanticLabel] when the icon carries meaning
/// on its own; decorative icons are excluded from semantics.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = IconSizes.md, this.color, this.semanticLabel});

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? context.colors.text;
    final glyph = PhosphorIcon(
      icon,
      size: size,
      color: resolved,
      duotoneSecondaryColor: resolved,
      duotoneSecondaryOpacity: 0.22,
      semanticLabel: semanticLabel,
    );
    return semanticLabel == null ? ExcludeSemantics(child: glyph) : glyph;
  }
}

/// How a destination's icon is drawn in the app's navigation (bottom bar, rail, the More sheet): a
/// light line glyph while idle, the same glyph filled when selected, and the destination's own hue
/// — so each tab reads by shape and colour at a glance, the way store apps draw their bars.
@immutable
class NavGlyph {
  const NavGlyph(this.idle, this.active, this.hue);

  final IconData idle;
  final IconData active;
  final Hue hue;
}

/// The navigation look of each destination icon, keyed by its [AppIcons] glyph. One place, so the
/// learner and staff shells draw every tab the same way.
abstract final class AppNavIcons {
  static final Map<IconData, NavGlyph> _byIcon = {
    AppIcons.home: const NavGlyph(PhosphorIconsRegular.house, PhosphorIconsFill.house, Hue.violet),
    AppIcons.dashboard: const NavGlyph(
      PhosphorIconsRegular.squaresFour,
      PhosphorIconsFill.squaresFour,
      Hue.violet,
    ),
    AppIcons.learning: const NavGlyph(
      PhosphorIconsRegular.bookOpenText,
      PhosphorIconsFill.bookOpenText,
      Hue.blue,
    ),
    AppIcons.courses: const NavGlyph(PhosphorIconsRegular.books, PhosphorIconsFill.books, Hue.blue),
    AppIcons.live: const NavGlyph(
      PhosphorIconsRegular.videoCamera,
      PhosphorIconsFill.videoCamera,
      Hue.pink,
    ),
    AppIcons.quiz: const NavGlyph(PhosphorIconsRegular.exam, PhosphorIconsFill.exam, Hue.orange),
    AppIcons.review: const NavGlyph(
      PhosphorIconsRegular.clipboardText,
      PhosphorIconsFill.clipboardText,
      Hue.orange,
    ),
    AppIcons.people: const NavGlyph(
      PhosphorIconsRegular.usersThree,
      PhosphorIconsFill.usersThree,
      Hue.green,
    ),
    AppIcons.profile: const NavGlyph(
      PhosphorIconsRegular.userCircle,
      PhosphorIconsFill.userCircle,
      Hue.green,
    ),
    AppIcons.more: const NavGlyph(
      PhosphorIconsRegular.dotsThreeCircle,
      PhosphorIconsFill.dotsThreeCircle,
      Hue.violet,
    ),
    AppIcons.calendar: const NavGlyph(
      PhosphorIconsRegular.calendarBlank,
      PhosphorIconsFill.calendarBlank,
      Hue.blue,
    ),
    AppIcons.instructor: const NavGlyph(
      PhosphorIconsRegular.chalkboardTeacher,
      PhosphorIconsFill.chalkboardTeacher,
      Hue.green,
    ),
    AppIcons.certificate: const NavGlyph(
      PhosphorIconsRegular.certificate,
      PhosphorIconsFill.certificate,
      Hue.gold,
    ),
    AppIcons.reports: const NavGlyph(
      PhosphorIconsRegular.chartLine,
      PhosphorIconsFill.chartLine,
      Hue.violet,
    ),
    AppIcons.billing: const NavGlyph(
      PhosphorIconsRegular.creditCard,
      PhosphorIconsFill.creditCard,
      Hue.pink,
    ),
    AppIcons.notifications: const NavGlyph(
      PhosphorIconsRegular.bell,
      PhosphorIconsFill.bell,
      Hue.blue,
    ),
    AppIcons.help: const NavGlyph(
      PhosphorIconsRegular.question,
      PhosphorIconsFill.question,
      Hue.blue,
    ),
    AppIcons.rank: const NavGlyph(PhosphorIconsRegular.medal, PhosphorIconsFill.medal, Hue.green),
  };

  /// The navigation look for [icon] (assignments share the review glyph, and so its look); an icon
  /// with none of its own keeps its glyph, in the brand hue.
  static NavGlyph of(IconData icon) => _byIcon[icon] ?? NavGlyph(icon, icon, Hue.violet);
}
