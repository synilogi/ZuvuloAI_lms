import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import 'academy_plan_provider.dart';
import 'dto/entitlements.dart';

/// The staff workspace's plan-gated modules (`WorkspaceModule`, `packages/domain/src/entitlement.ts`).
/// Everything else — the dashboard, students, calendar, instructors, help, billing — needs no plan
/// feature. Each module is sold under the same feature its routes check (`MODULE_FEATURE`); the web
/// uses this exact table.
enum WorkspaceModule {
  courses(FeatureKey.coursesManage),
  quizzes(FeatureKey.assessmentsManage),
  assignments(FeatureKey.assessmentsManage),
  certificates(FeatureKey.certificatesManage),
  live(FeatureKey.liveClasses),
  reports(FeatureKey.reportsBasic),
  branding(FeatureKey.customBranding);

  const WorkspaceModule(this.feature);

  /// The plan feature this module is sold under.
  final FeatureKey feature;
}

/// How a module appears to an academy's staff.
enum ModuleAccess {
  /// Plans are not enforced, or the plan includes the module's feature.
  open,

  /// The plan that included it has ended: what was made stays readable, nothing new is added.
  readOnly,

  /// No plan the academy is served (or had) includes it: shown with what unlocks it.
  locked,
}

/// `moduleAccess` of the shared domain, mirrored exactly:
///
/// 1. not enforced → open;
/// 2. the plan's features include the module's feature → open;
/// 3. the last plan's features did → read-only;
/// 4. otherwise → locked.
///
/// A plan that was not read ([plan] `null`) is open: the app never shuts a module on a guess, and the
/// server's refusal still decides every call.
ModuleAccess moduleAccess(AcademyPlan? plan, WorkspaceModule module) {
  if (plan == null || !plan.enforced) return ModuleAccess.open;
  if (plan.features.contains(module.feature)) return ModuleAccess.open;
  if (plan.lastFeatures.contains(module.feature)) return ModuleAccess.readOnly;
  return ModuleAccess.locked;
}

/// [moduleAccess] for the signed-in person's academy, rebuilt when the plan is re-read.
ModuleAccess watchModuleAccess(WidgetRef ref, WorkspaceModule module) =>
    moduleAccess(ref.watch(academyPlanProvider).value, module);

/// The module's name, as navigation and the plan screens say it.
String moduleName(AppLocalizations l10n, WorkspaceModule module) => switch (module) {
  WorkspaceModule.courses => l10n.moduleCoursesName,
  WorkspaceModule.quizzes => l10n.moduleQuizzesName,
  WorkspaceModule.assignments => l10n.moduleAssignmentsName,
  WorkspaceModule.certificates => l10n.moduleCertificatesName,
  WorkspaceModule.live => l10n.moduleLiveName,
  WorkspaceModule.reports => l10n.moduleReportsName,
  WorkspaceModule.branding => l10n.moduleBrandingName,
};

/// One sentence on what the module does, for the screen that says it is locked.
String moduleDescription(AppLocalizations l10n, WorkspaceModule module) => switch (module) {
  WorkspaceModule.courses => l10n.moduleCoursesDescription,
  WorkspaceModule.quizzes => l10n.moduleQuizzesDescription,
  WorkspaceModule.assignments => l10n.moduleAssignmentsDescription,
  WorkspaceModule.certificates => l10n.moduleCertificatesDescription,
  WorkspaceModule.live => l10n.moduleLiveDescription,
  WorkspaceModule.reports => l10n.moduleReportsDescription,
  WorkspaceModule.branding => l10n.moduleBrandingDescription,
};
