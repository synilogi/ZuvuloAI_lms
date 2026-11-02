import '../../shared/domain/user_profile.dart';

/// What a person can be offered in the app (§7). Feature code asks for a capability, never for a
/// role: `can(profile, Capability.gradeSubmissions)`.
///
/// Every capability names the permission key the backend checks and how it checks it:
/// `requireStaffPermission` lets an **instructor** through on role alone and asks an **admin** for
/// the key; `requirePermission` asks everyone for the key, so an instructor never passes.
///
/// This is UX only. A hidden button is a courtesy; the server's refusal is the truth and every
/// screen still handles it (§7).
enum Capability {
  // Catalogue
  viewCourses(PermissionKey.catalogView),
  editCourses(PermissionKey.catalogEdit),
  publishCourses(PermissionKey.catalogPublish),
  archiveCourses(PermissionKey.catalogArchive),
  manageCategories(PermissionKey.catalogCategoriesManage, adminOnly: true),

  // Assessment
  viewAssessments(PermissionKey.assessmentView),
  editAssessments(PermissionKey.assessmentEdit),
  gradeSubmissions(PermissionKey.assessmentGrade),

  // Learners
  viewLearners(PermissionKey.learnersView),
  enrollLearners(PermissionKey.learnersEnroll),
  messageLearners(PermissionKey.learnersMessage),
  suspendLearners(PermissionKey.learnersSuspend, adminOnly: true),

  // Instructors
  viewInstructors(PermissionKey.instructorsView),
  manageInstructors(PermissionKey.instructorsManage, adminOnly: true),
  setInstructorStatus(PermissionKey.instructorsStatus, adminOnly: true),

  // Certificates
  issueCertificates(PermissionKey.certificatesIssue),
  revokeCertificates(PermissionKey.certificatesRevoke, adminOnly: true),
  manageCertificateTemplates(PermissionKey.certificatesTemplatesManage, adminOnly: true),

  // Live classes
  manageLive(PermissionKey.liveManage),
  notifyLive(PermissionKey.liveNotify),

  // Reports
  viewReports(PermissionKey.reportsView),
  viewInstructorReport(PermissionKey.reportsInstructorsView, adminOnly: true),

  // Academy settings and billing
  viewBilling(PermissionKey.settingsView, adminOnly: true),
  changeBilling(PermissionKey.settingsEdit, adminOnly: true);

  const Capability(this.key, {this.adminOnly = false});

  /// The permission key the backend checks.
  final PermissionKey key;

  /// True when the route uses `requirePermission` — an academy admin with the key, nobody else.
  final bool adminOnly;
}

/// Whether [profile] may be offered [capability].
///
/// An admin needs the key on their account: a missing `permissions` list means **none**, never all
/// (§7). An instructor passes the staff capabilities on role, as `requireStaffPermission` does, and
/// never an admin-only one. Learners and unknown roles have none of these.
bool can(UserProfile? profile, Capability capability) {
  if (profile == null) return false;
  return switch (profile.role) {
    UserRole.admin => profile.has(capability.key),
    UserRole.instructor => !capability.adminOnly,
    UserRole.student || UserRole.superadmin || UserRole.unknown => false,
  };
}

/// Every capability [profile] currently has — for tests and for the shell's destination filter.
Set<Capability> capabilitiesOf(UserProfile? profile) => {
  for (final capability in Capability.values)
    if (can(profile, capability)) capability,
};
