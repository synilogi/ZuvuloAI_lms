import 'package:flutter/foundation.dart';

import '../../app/routing/routes.dart';

/// Links from outside the app (§5, §12, §18). A link is **untrusted input**: it arrives from a
/// browser, an e-mail or another app, and anything in it could have been written by anyone. So a link
/// is only followed when its host is one the academy serves and every id in it is the shape the API
/// uses — otherwise the app opens nothing and says the link is not one of its own.

/// The hosts whose links this app answers. A link from anywhere else is not the academy's, whatever it
/// claims to point at.
const linkHosts = <String>{'zuviloai.com'};

/// Ids the API issues are cuid2-like: letters and digits, long enough not to be guessed and short
/// enough to be an id rather than a payload.
final _id = RegExp(r'^[A-Za-z0-9_-]{8,64}$');

/// A credential id is printed on a certificate, so it also carries the academy's own separators.
final _credential = RegExp(r'^[A-Za-z0-9-]{4,64}$');

/// An LMS address in a join link (`/join/<address>`), exactly the server's rule for one.
final _workspace = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

bool _isWorkspace(String slug) =>
    slug.length >= 3 && slug.length <= 40 && _workspace.hasMatch(slug);

/// `?as=` on Create account (`/register`): the instructor's form rather than the learner's, for an
/// Admin's teaching link (`/join/<address>/teach`).
const registerAsInstructor = 'instructor';

/// Create account as an instructor, for the LMS at [workspace] — where a teaching link opens.
String teachRouteFor(String workspace) => Uri(
  path: AppRoutes.register,
  queryParameters: {'workspace': workspace, 'as': registerAsInstructor},
).toString();

/// A course slug as the catalogue builds them.
final _slug = RegExp(r'^[a-z0-9][a-z0-9-]{1,120}$');

/// A password-reset or invitation token, exactly as the API issues and checks it:
/// `randomBytes(32).toString('hex')`, and the API refuses anything but `^[a-f0-9]{64}$`. This is the
/// API's own rule, not a guess about it. Never logged (§18).
final _token = RegExp(r'^[a-f0-9]{64}$');

/// Why a link was not followed.
enum LinkRefusal {
  /// Not a URL at all, or not `https`.
  notAUrl,

  /// A host this app does not answer for.
  foreignHost,

  /// A path the app has no screen for.
  unknownPath,

  /// The right shape of path, with an id the API would never have issued.
  malformedId,
}

/// What an incoming link resolves to.
@immutable
class DeepLink {
  const DeepLink.to(this.route, {this.needsSignIn = false}) : refusal = null;

  const DeepLink.refused(this.refusal) : route = null, needsSignIn = false;

  /// The app route to open, or `null` when the link was refused.
  final String? route;

  /// Whether this destination is behind a sign-in, so the router should ask first and come back.
  final bool needsSignIn;

  final LinkRefusal? refusal;

  bool get isFollowed => route != null;

  @override
  bool operator ==(Object other) =>
      other is DeepLink &&
      other.route == route &&
      other.needsSignIn == needsSignIn &&
      other.refusal == refusal;

  @override
  int get hashCode => Object.hash(route, needsSignIn, refusal);
}

/// Resolves [raw] into the screen it points at.
///
/// [hosts] is the allow-list; a test may pass its own, and a dev build may add the machine serving
/// the web app. Nothing about the decision depends on the app's own state: whether the reader is
/// signed in is the router's business, and [DeepLink.needsSignIn] is what tells it (§5.4).
DeepLink resolveDeepLink(String raw, {Set<String> hosts = linkHosts}) {
  final url = Uri.tryParse(raw.trim());
  // Only https: a token or a credential must never travel over a link that can be read on the way,
  // and a custom scheme is not verifiable at all (§18).
  if (url == null || url.scheme != 'https' || url.host.isEmpty) {
    return const DeepLink.refused(LinkRefusal.notAUrl);
  }
  if (!hosts.contains(url.host.toLowerCase())) {
    return const DeepLink.refused(LinkRefusal.foreignHost);
  }

  final segments = [
    for (final segment in url.pathSegments)
      if (segment.isNotEmpty) segment,
  ];
  if (segments.isEmpty) return const DeepLink.to(AppRoutes.welcome);

  return switch (segments) {
    ['reset-password', final token] =>
      _token.hasMatch(token)
          ? DeepLink.to(AppRoutes.resetPassword(token))
          : const DeepLink.refused(LinkRefusal.malformedId),
    ['verify', final credentialId] =>
      _credential.hasMatch(credentialId)
          ? DeepLink.to(AppRoutes.verifyCredential(credentialId))
          : const DeepLink.refused(LinkRefusal.malformedId),
    ['courses', final slug] =>
      _slug.hasMatch(slug)
          ? DeepLink.to(AppRoutes.catalogCourse(slug))
          : const DeepLink.refused(LinkRefusal.malformedId),
    // An Admin's invitation for one learner: the token names the LMS and the role, server-side.
    ['invite', final token] =>
      _token.hasMatch(token)
          ? DeepLink.to(AppRoutes.invite(token))
          : const DeepLink.refused(LinkRefusal.malformedId),
    // An Admin's course link: the course names the LMS. Works signed out and signed in alike.
    ['courses', final courseId, 'enroll'] =>
      _id.hasMatch(courseId)
          ? DeepLink.to(AppRoutes.courseEnrol(courseId))
          : const DeepLink.refused(LinkRefusal.malformedId),
    // An Admin's join link: Create account, with the LMS address filled in.
    ['join', final slug] =>
      _isWorkspace(slug)
          ? DeepLink.to(AppRoutes.registerFor(slug))
          : const DeepLink.refused(LinkRefusal.malformedId),
    // An Admin's teaching link: register as an instructor there, for the LMS admin to approve.
    ['join', final slug, 'teach'] =>
      _isWorkspace(slug)
          ? DeepLink.to(teachRouteFor(slug))
          : const DeepLink.refused(LinkRefusal.malformedId),
    // Everything below is the reader's own: the router signs them in first and comes back (§5.4).
    ['learn', final courseId] =>
      _id.hasMatch(courseId)
          ? DeepLink.to(AppRoutes.learnCourse(courseId), needsSignIn: true)
          : const DeepLink.refused(LinkRefusal.malformedId),
    ['learn', final courseId, 'lessons', final lessonId] =>
      _id.hasMatch(courseId) && _id.hasMatch(lessonId)
          ? DeepLink.to(AppRoutes.learnLesson(courseId, lessonId), needsSignIn: true)
          : const DeepLink.refused(LinkRefusal.malformedId),
    // A class's own page, as the academy's reminders and "class started" notices link it.
    ['live', final liveClassId] =>
      _id.hasMatch(liveClassId)
          ? DeepLink.to(AppRoutes.liveClass(liveClassId), needsSignIn: true)
          : const DeepLink.refused(LinkRefusal.malformedId),
    ['notifications'] => const DeepLink.to(AppRoutes.notifications, needsSignIn: true),
    ['notifications', final notificationId] =>
      _id.hasMatch(notificationId)
          ? DeepLink.to(AppRoutes.notification(notificationId), needsSignIn: true)
          : const DeepLink.refused(LinkRefusal.malformedId),
    _ => const DeepLink.refused(LinkRefusal.unknownPath),
  };
}

/// The route a **pasted** link opens on Create account, or null when it is not a way into an LMS.
///
/// A learner joins through the link their teacher or school sent: an invitation, a course link or a
/// join link. Pasting one is the same as opening it, so it goes through [resolveDeepLink] and its
/// rules — the host, the scheme and every id are checked — and then only those destinations are
/// accepted (a teaching link, a join link's instructor form, among them). A certificate or a lesson
/// link is a real link, but not one that joins anything.
String? joinRouteFrom(String raw, {Set<String> hosts = linkHosts}) {
  final route = resolveDeepLink(raw, hosts: hosts).route;
  if (route == null) return null;
  final segments = Uri.parse(route).pathSegments;
  return switch (segments) {
    ['invite', _] || ['enrol', _] => route,
    ['register'] when Uri.parse(route).queryParameters['workspace'] != null => route,
    _ => null,
  };
}

/// Maps a location the app was **opened with** onto one of its own routes.
///
/// Android hands the router the incoming URL's *path*, and the web does not always spell a path the
/// way the app does: the catalogue is `/courses/:slug` on the web and `/catalog/:slug` here, and a
/// course link is `/courses/:id/enroll` on the web and `/enrol/:id` here.
///
/// This deliberately covers only what cannot have come from the app itself. `/courses/…` is never a
/// route the app navigates to, and a reset or invitation link is only ever arrived at from outside —
/// so they are mapped and validated here. `/verify`, `/learn`, `/live` and `/notifications` are
/// paths the app builds for itself from ids the API gave it, so their ids are **not** re-checked:
/// doing so would put this function's idea of an id between the app and its own navigation, and a
/// wrong guess about the API's id format would break the app rather than protect it. A bad id on those paths is
/// answered by the screen, which reads the API and draws its not-found or "this link has expired".
///
/// Returns the route to go to instead, or `null` to leave the location alone. [unroutableLocation] is
/// a path no route matches, so the router's own `errorBuilder` draws not-found.
String? deepLinkReplacement(String location) {
  final segments = [
    for (final segment in Uri.parse(location).pathSegments)
      if (segment.isNotEmpty) segment,
  ];
  return switch (segments) {
    ['courses', final slug] =>
      _slug.hasMatch(slug) ? AppRoutes.catalogCourse(slug) : unroutableLocation,
    ['courses', final courseId, 'enroll'] =>
      _id.hasMatch(courseId) ? AppRoutes.courseEnrol(courseId) : unroutableLocation,
    ['join', final slug] => _isWorkspace(slug) ? AppRoutes.registerFor(slug) : unroutableLocation,
    ['join', final slug, 'teach'] => _isWorkspace(slug) ? teachRouteFor(slug) : unroutableLocation,
    // An invitation token is the API's own shape too; anything else did not come from an Admin.
    ['invite', final token] => _token.hasMatch(token) ? null : unroutableLocation,
    // A reset token is 64 hex characters, which is what the API issues and all it will accept;
    // anything else did not come from the academy's e-mail.
    ['reset-password', final token] => _token.hasMatch(token) ? null : unroutableLocation,
    _ => null,
  };
}

/// A location no route matches, so the router draws its not-found screen.
const unroutableLocation = '/link-not-recognised';
