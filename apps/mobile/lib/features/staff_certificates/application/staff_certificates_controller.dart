import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../data/dto/certificate_register.dart';
import '../data/staff_certificates_api.dart';

/// What the staff certificate screens read (§26).
export '../../../shared/domain/certificate.dart';
export '../data/dto/certificate_register.dart';

/// How many rows one page of the register holds.
const registerPageSize = StaffCertificatesApi.pageSize;

/// What the register is showing.
@immutable
class RegisterFilter {
  const RegisterFilter({this.status = 'all', this.search, this.courseId, this.page = 1});

  final String status;
  final String? search;
  final String? courseId;
  final int page;

  RegisterFilter copyWith({
    String? status,
    String? search,
    bool clearSearch = false,
    String? courseId,
    bool clearCourse = false,
    int? page,
  }) => RegisterFilter(
    status: status ?? this.status,
    search: clearSearch ? null : (search ?? this.search),
    courseId: clearCourse ? null : (courseId ?? this.courseId),
    // Any change of what is being looked at starts again at the first page.
    page: page ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      other is RegisterFilter &&
      other.status == status &&
      other.search == search &&
      other.courseId == courseId &&
      other.page == page;

  @override
  int get hashCode => Object.hash(status, search, courseId, page);
}

class RegisterFilterController extends Notifier<RegisterFilter> {
  @override
  RegisterFilter build() => const RegisterFilter();

  void showStatus(String status) => state = state.copyWith(status: status);

  void searchFor(String? text) => (text == null || text.trim().isEmpty)
      ? state = state.copyWith(clearSearch: true)
      : state = state.copyWith(search: text.trim());

  void inCourse(String? courseId) => courseId == null
      ? state = state.copyWith(clearCourse: true)
      : state = state.copyWith(courseId: courseId);

  void showPage(int page) => state = state.copyWith(page: page);
}

final registerFilterProvider = NotifierProvider<RegisterFilterController, RegisterFilter>(
  RegisterFilterController.new,
  isAutoDispose: true,
);

final certificateRegisterProvider = FutureProvider<CertificateRegister>((ref) {
  final filter = ref.watch(registerFilterProvider);
  return ref
      .watch(staffCertificatesApiProvider)
      .register(
        search: filter.search,
        courseId: filter.courseId,
        status: filter.status == 'all' ? null : filter.status,
        page: filter.page,
      );
}, isAutoDispose: true);

final staffCertificateProvider = FutureProvider.family<StaffCertificateDetail, String>(
  (ref, certificateId) => ref.watch(staffCertificatesApiProvider).certificate(certificateId),
  isAutoDispose: true,
);

/// What a certificate action left behind.
@immutable
class CertificateActionState {
  const CertificateActionState({this.busy = false, this.done = false, this.failure});

  final bool busy;

  /// The academy carried the action out.
  final bool done;
  final AppFailure? failure;
}

/// Issuing, revoking and restoring. Each is the academy's decision: a certificate that is not
/// pending cannot be issued and one that is not revoked cannot be restored, and the route says so in
/// its own words (§18).
class CertificateActionController extends Notifier<CertificateActionState> {
  @override
  CertificateActionState build() => const CertificateActionState();

  void clearAnswer() => state = const CertificateActionState();

  Future<bool> issue(String certificateId) =>
      _run(certificateId, (api) => api.issue(certificateId));

  /// Revokes it. The reason reaches the learner, so an empty or too-short one is never sent: the
  /// route answers 400 with no field for it (finding 31).
  Future<bool> revoke(String certificateId, {required String reason}) {
    if (!revokeReasonIsEnough(reason)) return Future.value(false);
    return _run(certificateId, (api) => api.revoke(certificateId, reason: reason));
  }

  Future<bool> restore(String certificateId) =>
      _run(certificateId, (api) => api.restore(certificateId));

  Future<bool> _run(
    String certificateId,
    Future<void> Function(StaffCertificatesApi api) action,
  ) async {
    if (state.busy) return false;
    state = const CertificateActionState(busy: true);
    try {
      await action(ref.read(staffCertificatesApiProvider));
      if (!ref.mounted) return true;
      state = const CertificateActionState(done: true);
      // The register's counts and this certificate have both moved.
      ref
        ..invalidate(certificateRegisterProvider)
        ..invalidate(staffCertificateProvider(certificateId));
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = CertificateActionState(failure: e.failure);
      return false;
    }
  }
}

final certificateActionProvider =
    NotifierProvider<CertificateActionController, CertificateActionState>(
      CertificateActionController.new,
      isAutoDispose: true,
    );
