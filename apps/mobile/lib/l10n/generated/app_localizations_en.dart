// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionClose => 'Close';

  @override
  String get actionBack => 'Back';

  @override
  String get actionGoHome => 'Go home';

  @override
  String get actionClearFilters => 'Clear filters';

  @override
  String get actionFilters => 'Filters';

  @override
  String filtersActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Filters, $count on',
      one: 'Filters, 1 on',
    );
    return '$_temp0';
  }

  @override
  String pagerPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get actionSave => 'Save';

  @override
  String get actionDone => 'Done';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionMore => 'More';

  @override
  String get actionSeeAll => 'See all';

  @override
  String get actionShowAll => 'Show all';

  @override
  String get actionShowLess => 'Show less';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionShowPassword => 'Show password';

  @override
  String get actionHidePassword => 'Hide password';

  @override
  String get actionClearSearch => 'Clear search';

  @override
  String get actionReviewPlan => 'Review plan';

  @override
  String get actionShowAsList => 'Show as list';

  @override
  String get actionShowAsChart => 'Show as chart';

  @override
  String get actionIncrease => 'Increase';

  @override
  String get actionDecrease => 'Decrease';

  @override
  String get actionPickDate => 'Choose date';

  @override
  String get actionPickTime => 'Choose time';

  @override
  String get actionRemoveFile => 'Remove file';

  @override
  String get actionCancelUpload => 'Cancel upload';

  @override
  String get actionPrevious => 'Previous';

  @override
  String get actionNext => 'Next';

  @override
  String get actionMarkComplete => 'Mark complete';

  @override
  String get actionOpenCurriculum => 'Curriculum';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get searchHint => 'Search';

  @override
  String get selectPlaceholder => 'Select';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get stillWorking => 'Still working…';

  @override
  String get requiredFieldMarker => 'Required';

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get stateErrorBody => 'We couldn\'t load this. Check your connection and try again.';

  @override
  String get stateOfflineBanner => 'You\'re offline. Showing what was loaded.';

  @override
  String get stateNoMatchesTitle => 'No matches';

  @override
  String get stateNoMatchesBody => 'Nothing matches these filters.';

  @override
  String get statePermissionDeniedTitle => 'You don\'t have access to this.';

  @override
  String get statePermissionDeniedBody => 'Ask your admin.';

  @override
  String get stateFeatureUnavailableTitle => 'Not included in your LMS plan.';

  @override
  String get stateFeatureUnavailableBodyAdmin => 'Review the plan to add this to your LMS.';

  @override
  String get stateFeatureUnavailableBodyMember =>
      'Your LMS plan doesn\'t include this. Contact your admin.';

  @override
  String get stateSubscriptionRequiredTitle => 'Your LMS needs an active plan.';

  @override
  String get stateSubscriptionExpiredTitle => 'Your LMS\'s subscription has ended.';

  @override
  String get stateSubscriptionBody => 'Existing content stays available.';

  @override
  String get stateSubscriptionBodyMember => 'Contact your admin to continue.';

  @override
  String get stateNotFoundTitle => 'This isn\'t available.';

  @override
  String get stateNotFoundBody => 'It may have been moved or removed.';

  @override
  String get stateLockedLessonTitle => 'This lesson is locked';

  @override
  String errorSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fix $count problems to continue',
      one: 'Fix 1 problem to continue',
    );
    return '$_temp0';
  }

  @override
  String get destructiveAcknowledge => 'I understand this can\'t be undone';

  @override
  String fileUploading(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get fileUploadFailed => 'Upload failed — try again';

  @override
  String fileSizeMb(String size) {
    return '$size MB';
  }

  @override
  String progressPercentComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String kpiDeltaUp(String value, String comparison) {
    return 'Up $value $comparison';
  }

  @override
  String kpiDeltaDown(String value, String comparison) {
    return 'Down $value $comparison';
  }

  @override
  String kpiDeltaFlat(String comparison) {
    return 'No change $comparison';
  }

  @override
  String chartReadoutItem(String label, String value) {
    return '$label: $value';
  }

  @override
  String studyDayMinutes(String day, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
      zero: 'no study',
    );
    return '$day: $_temp0';
  }

  @override
  String rankLabel(String name) {
    return 'Rank: $name';
  }

  @override
  String curriculumProgress(int done, int total) {
    return '$done of $total lessons';
  }

  @override
  String quizQuestionCount(int number, int total) {
    return 'Question $number of $total';
  }

  @override
  String rubricCriterionScore(String criterion, String score, String max) {
    return '$criterion: $score of $max';
  }

  @override
  String rubricTotal(String score, String max) {
    return 'Total $score / $max';
  }

  @override
  String certificateCredentialId(String id) {
    return 'Credential ID $id';
  }

  @override
  String certificateIssuedOn(String date) {
    return 'Issued $date';
  }

  @override
  String get certificateVerifiedSeal => 'Verified certificate';

  @override
  String get certificateAwardedTo => 'This certifies that';

  @override
  String get courseCoverLabel => 'Course cover';

  @override
  String get lessonTypeVideo => 'Video';

  @override
  String get lessonTypeReading => 'Reading';

  @override
  String get lessonTypeDocument => 'Document';

  @override
  String get lessonTypePractice => 'Practice';

  @override
  String get lessonTypeLive => 'Live class';

  @override
  String get lessonTypeQuiz => 'Quiz';

  @override
  String get lessonTypeAssignment => 'Assignment';

  @override
  String get statusLocked => 'Locked';

  @override
  String get statusNotEnrolled => 'Not enrolled';

  @override
  String get statusEnrolled => 'Enrolled';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusUpcoming => 'Upcoming';

  @override
  String get statusLive => 'Live now';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusUnderReview => 'Under review';

  @override
  String get statusPassed => 'Passed';

  @override
  String get statusNotPassed => 'Not passed';

  @override
  String get statusEligible => 'Eligible';

  @override
  String get statusNotEligible => 'Not yet eligible';

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get statusDraftSaved => 'Draft saved';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusStartingSoon => 'Starting soon';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPublished => 'Published';

  @override
  String get statusArchived => 'Archived';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusNotSubmitted => 'Not submitted';

  @override
  String get statusOverdueReview => 'Overdue review';

  @override
  String get statusToReview => 'To review';

  @override
  String get statusDraftReview => 'Draft review';

  @override
  String get statusResubmissionRequested => 'Resubmission requested';

  @override
  String get statusGraded => 'Graded';

  @override
  String get statusLate => 'Late';

  @override
  String get statusIssued => 'Issued';

  @override
  String get statusReadyToIssue => 'Ready to issue';

  @override
  String get statusRevoked => 'Revoked';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusEnded => 'Ended';

  @override
  String get statusRecordingExpired => 'Recording expired';

  @override
  String get statusDone => 'Done';

  @override
  String get statusDueSoon => 'Due soon';

  @override
  String get statusClosesSoon => 'Closes soon';

  @override
  String get statusActive => 'Active';

  @override
  String get statusAtRisk => 'At risk';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusInvited => 'Invited';

  @override
  String get statusHidden => 'Hidden';

  @override
  String get statusTrial => 'Trial';

  @override
  String get statusPastDue => 'Past due';

  @override
  String get statusCanceling => 'Canceling';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get statusVoided => 'Void';

  @override
  String get statusFreePreview => 'Free preview';

  @override
  String get statusImportant => 'Important';

  @override
  String get devComponentGallery => 'Component gallery';

  @override
  String get quizTrue => 'True';

  @override
  String get quizFalse => 'False';

  @override
  String get quizShortAnswerLabel => 'Your answer';

  @override
  String get quizChooseOne => 'Choose one answer';

  @override
  String get quizChooseAll => 'Choose all that apply';

  @override
  String lessonLockedReason(String reason) {
    return 'Locked: $reason';
  }

  @override
  String curriculumChapterLabel(String title, int done, int total) {
    return '$title, $done of $total lessons done';
  }

  @override
  String get lessonCompleteAction => 'Completed';

  @override
  String get certificateDateOfIssue => 'Date of issue';

  @override
  String get relativeNow => 'now';

  @override
  String relativeMinutesFuture(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count minutes',
      one: 'in 1 minute',
    );
    return '$_temp0';
  }

  @override
  String relativeMinutesPast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursFuture(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count hours',
      one: 'in 1 hour',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursPast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysFuture(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'tomorrow',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysPast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '${hours}h';
  }

  @override
  String durationHoursMinutes(int hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String timeWithZone(String time) {
    return '$time IST';
  }

  @override
  String timeRangeWithZone(String start, String end) {
    return '$start – $end IST';
  }

  @override
  String get errorBoundaryTitle => 'This screen stopped working';

  @override
  String get errorBoundaryBody => 'Something went wrong on our side. Go home and try again.';

  @override
  String get configErrorTitle => 'This build isn\'t set up correctly';

  @override
  String get appTagline => 'Learn anywhere with ZuviloAI.';

  @override
  String get welcomeIntro =>
      'Courses, live classes, assignments and certificates, all in one place.';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionCreateAccount => 'Create account';

  @override
  String get actionBrowseCourses => 'Browse courses';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionForgotPassword => 'Forgot password?';

  @override
  String get actionSendLink => 'Send link';

  @override
  String get actionSetPassword => 'Save password';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldEmailHint => 'name@example.com';

  @override
  String get fieldPasswordHint => 'Enter your password';

  @override
  String get fieldName => 'Full name';

  @override
  String get fieldWorkspace => 'LMS address';

  @override
  String get fieldWorkspaceHelp =>
      'From your join link, e.g. saraswati-coaching. You can paste the whole link.';

  @override
  String get validationWorkspace => 'Enter the LMS address from your join link.';

  @override
  String get registerWorkspaceNotFound => 'No LMS has this address';

  @override
  String get accountSuspendedTitle => 'This account is suspended';

  @override
  String get accountClosedTitle => 'This account has been closed';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get validationEmail => 'Enter a valid email address.';

  @override
  String get validationPasswordRequired => 'Enter your password.';

  @override
  String get validationPasswordMin => 'Use at least 8 characters.';

  @override
  String get validationNameMin => 'Enter your full name.';

  @override
  String get validationPasswordsMatch => 'Both passwords must match.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Continue where you left off.';

  @override
  String get loginFailedTitle => 'We couldn\'t sign you in.';

  @override
  String get loginNoAccount => 'New here?';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get accountTypeTitle => 'Create an account';

  @override
  String get accountTypeSubtitle => 'Choose how you will use ZuviloAI.';

  @override
  String get accountTypeLearnerTitle => 'I want to learn';

  @override
  String get accountTypeLearnerBody => 'Join ZuviloAI as a learner.';

  @override
  String get accountTypeAcademyTitle => 'I want to teach — start my LMS';

  @override
  String get accountTypeAcademyBody =>
      'Register your academy as its admin, then choose a plan or start a free trial.';

  @override
  String get accountTypeInstructorTitle => 'I\'m an instructor';

  @override
  String get accountTypeInstructorBody =>
      'Instructors are added by their academy\'s admin. Ask your admin to invite you, then sign in with the email they used.';

  @override
  String get academySignupTitle => 'Start your LMS';

  @override
  String get academySignupSubtitle =>
      'You\'ll be its admin. After this you can start a free trial or choose a plan.';

  @override
  String get fieldAcademyName => 'Academy or organisation name';

  @override
  String get fieldAcademyAddress => 'LMS address';

  @override
  String fieldAcademyAddressHelp(String address) {
    return 'Learners join at $address';
  }

  @override
  String get fieldYourName => 'Your full name';

  @override
  String get academySignupAgree => 'I agree to the Terms of Service and Privacy Policy';

  @override
  String get validationAcademyName => 'Enter your organisation\'s name.';

  @override
  String get validationAcademyAddress =>
      'Use 3 to 40 lowercase letters, digits and single hyphens.';

  @override
  String get validationAgreeTerms =>
      'Agree to the Terms of Service and Privacy Policy to continue.';

  @override
  String get academySignupFailedTitle => 'We couldn\'t start your LMS.';

  @override
  String get academyVerifyTitle => 'Check your email';

  @override
  String academyVerifySubtitle(String email) {
    return 'We sent a 6-digit code to $email. Enter it to create your LMS.';
  }

  @override
  String get fieldVerificationCode => 'Verification code';

  @override
  String get validationVerificationCode => 'Enter the 6-digit code from the email.';

  @override
  String get academyVerifyAction => 'Verify and create my LMS';

  @override
  String get academyVerifyFailedTitle => 'That code didn\'t work.';

  @override
  String get academyResendCode => 'Send a new code';

  @override
  String academyResendIn(int seconds) {
    return 'Send a new code in ${seconds}s';
  }

  @override
  String get academyCodeResent => 'A new code is on its way.';

  @override
  String get academyChangeDetails => 'Change my details';

  @override
  String accountVerifySubtitle(String email, String lms) {
    return 'We sent a 6-digit code to $email. Enter it to finish joining $lms.';
  }

  @override
  String accountVerifyInstructorSubtitle(String email, String lms) {
    return 'We sent a 6-digit code to $email. Enter it to send your request to teach at $lms.';
  }

  @override
  String accountVerifySubtitleGeneric(String email) {
    return 'We sent a 6-digit code to $email. Enter it to finish registering.';
  }

  @override
  String accountVerifyExpiresIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'The code works for $minutes more minutes.',
      one: 'The code works for 1 more minute.',
    );
    return '$_temp0';
  }

  @override
  String get accountVerifyExpired => 'This code has expired. Send a new code.';

  @override
  String get accountVerifyAction => 'Verify and create my account';

  @override
  String get accountVerifyInstructorAction => 'Verify and send my request';

  @override
  String get accountVerifyResendFailedTitle => 'We couldn\'t send a new code.';

  @override
  String get accountVerifyClosedTitle => 'This registration is no longer open';

  @override
  String get accountVerifyClosedBody => 'Start again to get a new code.';

  @override
  String get accountVerifyStartAgain => 'Start again';

  @override
  String get invitationRequiredTitle => 'Invitation needed';

  @override
  String get invitationRequiredBody =>
      'This LMS adds learners by invitation only. Ask your teacher or school for an invitation link.';

  @override
  String get fieldJoinLinkOrAddressHelp =>
      'Paste the link, or type the LMS address (for example saraswati-coaching).';

  @override
  String get instructorLinkTitle => 'Which LMS will you teach at?';

  @override
  String get instructorLinkBody =>
      'Open the teaching link the LMS sent you on this device, paste it here, or type the LMS address.';

  @override
  String get accountTypeInstructorAction =>
      'Register as an instructor and wait for the LMS Admin to approve you.';

  @override
  String get instructorSignupTitle => 'Register as an instructor';

  @override
  String get instructorSignupSubtitle =>
      'Your account is reviewed by the LMS Admin. You can sign in once it is approved.';

  @override
  String instructorSignupJoinTitle(String name) {
    return 'Teach at $name';
  }

  @override
  String get fieldInstructorTitle => 'Your title (optional)';

  @override
  String get fieldInstructorTitleHelp => 'For example: Senior Maths Faculty, Physics lecturer';

  @override
  String get instructorSignupAction => 'Submit registration';

  @override
  String get instructorSignupFailedTitle => 'We couldn\'t submit your registration.';

  @override
  String get instructorPendingScreenTitle => 'Registration submitted';

  @override
  String get instructorPendingHeading => 'Registration submitted successfully.';

  @override
  String get instructorPendingBody =>
      'Your account is pending Admin approval. You will be able to sign in after the Admin approves your account.';

  @override
  String get instructorPendingNext =>
      'Once approved, sign in with your registered email and password. We will also email you.';

  @override
  String get instructorPendingTitle => 'Waiting for Admin approval';

  @override
  String get instructorRejectedTitle => 'Registration not approved';

  @override
  String get instructorRequestsTitle => 'Pending instructor requests';

  @override
  String instructorRequestRegistered(String date) {
    return 'Registered $date';
  }

  @override
  String get instructorRequestPending => 'Pending';

  @override
  String get instructorRequestApprove => 'Approve';

  @override
  String get instructorRequestReject => 'Reject';

  @override
  String instructorRequestRejectTitle(String name) {
    return 'Reject $name?';
  }

  @override
  String get instructorRequestRejectBody =>
      'They will not be able to sign in as an instructor. They are told by email.';

  @override
  String instructorRequestApproved(String name) {
    return '$name is now an instructor and can sign in.';
  }

  @override
  String instructorRequestRejected(String name) {
    return '$name\'s request was rejected.';
  }

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Learners sign up here, or through a link from their teacher or school. Instructors ask to teach and wait for admin approval.';

  @override
  String get registerDefaultSubtitle => 'Enter your details to start learning.';

  @override
  String get registerFailedTitle => 'We couldn\'t create your account.';

  @override
  String get registerLimitReached => 'This LMS isn\'t accepting new learners right now.';

  @override
  String get registerLinkTitle => 'Open the link you were sent';

  @override
  String get registerLinkBody =>
      'An invitation, a course link or a join link from your teacher or school brings you straight to ZuviloAI. Open it on this device, or paste it here.';

  @override
  String get fieldJoinLink => 'Paste your link';

  @override
  String get fieldJoinLinkHelp => 'It starts with https://zuviloai.com/';

  @override
  String get validationJoinLink => 'Paste the link you were sent.';

  @override
  String get joinLinkNotRecognised =>
      'This isn\'t a valid link for joining. Check the link you were sent, or ask your teacher or school for a new one.';

  @override
  String get actionContinue => 'Continue';

  @override
  String get registerNoLinkNote =>
      'No link? Ask your teacher or school for one. Already have an account? Sign in with your email.';

  @override
  String joinLmsTitle(String lms) {
    return 'Join $lms';
  }

  @override
  String joinLmsSubtitle(String lms) {
    return 'Create your learner account at $lms.';
  }

  @override
  String get joinLmsClosedTitle => 'This LMS isn\'t accepting new learners right now';

  @override
  String get joinLmsClosedBody => 'Contact your teacher or school for help.';

  @override
  String joinSignedInTitle(String name) {
    return 'You\'re signed in as $name';
  }

  @override
  String get joinSignedInBody =>
      'This link is for joining an LMS. To use it, sign out first, then create your account or sign in with the account it is for.';

  @override
  String get actionSignOutAndContinue => 'Sign out and continue';

  @override
  String get joinOtherLmsTitle => 'This account belongs to another LMS';

  @override
  String get inviteInvalidTitle => 'This invitation link isn\'t valid';

  @override
  String get inviteInvalidBody =>
      'It may have expired, been used or been withdrawn. Ask your teacher or school for a new one.';

  @override
  String inviteSubtitle(String lms) {
    return 'You\'ve been invited to learn at $lms. Create your account, or sign in if you already learn there.';
  }

  @override
  String inviteSignInSubtitle(String lms) {
    return 'Sign in with the account you already have at $lms.';
  }

  @override
  String get inviteEmailLocked => 'This invitation is for this email address.';

  @override
  String get inviteWrongEmailTitle => 'This invitation is for a different email address';

  @override
  String get inviteNoAccount => 'No account yet?';

  @override
  String get actionSignInAndJoin => 'Sign in and join';

  @override
  String get courseLinkInvalidTitle => 'This course link isn\'t available';

  @override
  String get courseLinkInvalidBody =>
      'The course may no longer be offered, or the link was copied incorrectly. Ask your teacher or school for a new one.';

  @override
  String courseLinkSubtitle(String lms) {
    return 'A course at $lms.';
  }

  @override
  String courseLinkCreateBody(String lms) {
    return 'Create your learner account at $lms to enrol.';
  }

  @override
  String get actionCreateAndEnrol => 'Create account and enrol';

  @override
  String get courseLinkEnrolBody => 'Enrol to add it to My Courses.';

  @override
  String get courseLinkOtherLmsTitle => 'This course belongs to another LMS';

  @override
  String get courseLinkStaffTitle => 'Course links are for learners';

  @override
  String get courseLinkStaffBody =>
      'Staff accounts can\'t enrol in courses. Sign out and use a learner account to enrol.';

  @override
  String get courseLinkAccountReadyTitle => 'Your account is ready';

  @override
  String get courseLinkNotEnrolledBody => 'You\'re not enrolled in this course yet.';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotSubtitle => 'We\'ll email you a link to set a new password.';

  @override
  String get forgotConfirmationTitle => 'Check your email';

  @override
  String get forgotConfirmationBody =>
      'If an account exists for that email, we\'ve sent a link. It works for one hour.';

  @override
  String get resetTitle => 'Set a new password';

  @override
  String get resetSubtitle => 'Choose a password you have not used before.';

  @override
  String get resetInvalidTitle => 'This link is no longer valid';

  @override
  String get resetInvalidBody => 'Request a new reset link and try again.';

  @override
  String get resetDoneTitle => 'Password updated';

  @override
  String get resetDoneBody => 'Sign in with your new password.';

  @override
  String get sessionEndedMessage => 'Your session ended. Sign in again.';

  @override
  String get splashOfflineTitle => 'Can\'t reach ZuviloAI';

  @override
  String get splashOfflineBody => 'Check your connection and try again.';

  @override
  String get unsupportedRoleTitle => 'Platform administration is on the web';

  @override
  String get unsupportedRoleBody =>
      'Super Admin tools aren\'t available in the app. Sign in on the web to continue.';

  @override
  String get offlineActionDisabled => 'You\'re offline. Connect to continue.';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get roleLearner => 'Learner';

  @override
  String get roleInstructor => 'Instructor';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navLive => 'Live';

  @override
  String get navProfile => 'Profile';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navReview => 'Review';

  @override
  String get navCourses => 'Courses';

  @override
  String get navPeople => 'People';

  @override
  String get navMore => 'More';

  @override
  String get navStudents => 'Students';

  @override
  String get navQuizzes => 'Quizzes';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navInstructors => 'Instructors';

  @override
  String get navCertificates => 'Certificates';

  @override
  String get navReports => 'Reports';

  @override
  String get navBilling => 'Billing';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navHelp => 'Help';

  @override
  String get navAssignments => 'Assignments';

  @override
  String get navAssessments => 'Assessments';

  @override
  String get navRanks => 'Rank ladder';

  @override
  String get navSettings => 'Settings';

  @override
  String get navCatalog => 'Catalogue';

  @override
  String get navVerify => 'Verify a certificate';

  @override
  String get navTests => 'Tests';

  @override
  String get navMyCourses => 'My Courses';

  @override
  String get moreSheetTitle => 'More';

  @override
  String get moreGroupTeaching => 'Teaching';

  @override
  String get moreGroupAcademy => 'Platform';

  @override
  String get moreGroupAccount => 'Account';

  @override
  String get comingSoonTitle => 'Coming in a later update';

  @override
  String get comingSoonBody => 'This part of the app is still being built.';

  @override
  String get notificationsBellLabel => 'Notifications';

  @override
  String notificationsBellWithCount(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get myLearningInProgress => 'In progress';

  @override
  String get myLearningCompleted => 'Completed';

  @override
  String get myLearningSaved => 'Saved';

  @override
  String get entitlementLimitReachedTitle => 'This is as far as your plan goes';

  @override
  String get entitlementLimitReachedBody => 'Your LMS has reached what its plan allows.';

  @override
  String get restrictedBannerTitle => 'Your LMS has no active plan';

  @override
  String get restrictedBannerBody =>
      'Existing courses and learners stay available. New ones need a plan.';

  @override
  String get restrictedBannerMember => 'Your LMS plan has lapsed. Contact your admin.';

  @override
  String get subscriptionStatusTrialing => 'Trial';

  @override
  String get subscriptionStatusActive => 'Active';

  @override
  String get subscriptionStatusPastDue => 'Past due';

  @override
  String get subscriptionStatusPaused => 'Paused';

  @override
  String get subscriptionStatusCanceling => 'Canceling';

  @override
  String get subscriptionStatusCanceled => 'Canceled';

  @override
  String get subscriptionStatusExpired => 'Expired';

  @override
  String limitMeter(String label, String used, String allowed) {
    return '$label $used of $allowed';
  }

  @override
  String limitMeterUnlimited(String label, String used) {
    return '$label $used · unlimited';
  }

  @override
  String get permissionDeniedInline => 'You don\'t have access to this.';

  @override
  String get uploadRejectedType =>
      'Only MP4/WebM/MOV video, PDF documents and PNG/JPG/WebP images can be uploaded.';

  @override
  String get uploadRejectedVideoStaff => 'Only instructors and admins can upload video.';

  @override
  String get uploadRejectedContents =>
      'The file’s contents do not match its type. Upload the original PDF, image or video.';

  @override
  String uploadRejectedSizeVideo(int mb) {
    return 'Videos can be at most $mb MB.';
  }

  @override
  String uploadRejectedSizeDocument(int mb) {
    return 'Documents can be at most $mb MB.';
  }

  @override
  String uploadRejectedSizeImage(int mb) {
    return 'Images can be at most $mb MB.';
  }

  @override
  String get uploadChooseFile => 'Choose a file';

  @override
  String get uploadReplaceFile => 'Choose another file';

  @override
  String get mediaVideoFailed => 'This video couldn\'t be played';

  @override
  String get mediaVideoEnded => 'Finished';

  @override
  String mediaMobileDataNotice(String mb) {
    return 'You\'re on mobile data. This video is $mb MB.';
  }

  @override
  String get mediaMobileDataContinue => 'Play anyway';

  @override
  String get mediaDocumentFailed => 'This document couldn\'t be opened';

  @override
  String get mediaDocumentLoading => 'Opening document…';

  @override
  String mediaPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get mediaPlay => 'Play';

  @override
  String get mediaPause => 'Pause';

  @override
  String get mediaBack10 => 'Back 10 seconds';

  @override
  String get mediaForward10 => 'Forward 10 seconds';

  @override
  String get mediaFullscreen => 'Full screen';

  @override
  String get mediaExitFullscreen => 'Exit full screen';

  @override
  String get mediaSpeed => 'Playback speed';

  @override
  String mediaSpeedValue(String speed) {
    return '$speed×';
  }

  @override
  String get actionVerifyCertificate => 'Verify a certificate';

  @override
  String get actionHelpCentre => 'Help centre';

  @override
  String get catalogTitle => 'Courses';

  @override
  String get catalogSearchHint => 'Search courses';

  @override
  String get catalogFilterAllLevels => 'All levels';

  @override
  String get catalogFilterAllTopics => 'All topics';

  @override
  String get catalogEmptyTitle => 'No courses published yet';

  @override
  String get catalogEmptyBody => 'New courses appear here as soon as the LMS publishes them.';

  @override
  String catalogCourseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses',
      one: '1 course',
    );
    return '$_temp0';
  }

  @override
  String courseLessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
    );
    return '$_temp0';
  }

  @override
  String get coursePriceFree => 'Free';

  @override
  String courseRatingSummary(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String courseRatingLabel(String rating, int count) {
    return 'Rated $rating out of 5 by $count learners';
  }

  @override
  String courseWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get courseFormatSelfPaced => 'Self-paced';

  @override
  String get courseFormatCohort => 'Cohort';

  @override
  String get courseFormatHybrid => 'Hybrid';

  @override
  String get courseAboutTitle => 'About this course';

  @override
  String get courseOutcomesTitle => 'What you will learn';

  @override
  String get courseCurriculumTitle => 'Curriculum';

  @override
  String get courseInstructorsTitle => 'Taught by';

  @override
  String get courseCertificateLabel => 'Certificate';

  @override
  String get courseLanguageLabel => 'Language';

  @override
  String get courseFormatLabel => 'Format';

  @override
  String get courseLevelLabel => 'Level';

  @override
  String coursePreviewNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons are free to preview',
      one: '1 lesson is free to preview',
    );
    return '$_temp0';
  }

  @override
  String get actionEnrol => 'Enrol';

  @override
  String get actionSignInToEnrol => 'Sign in to enrol';

  @override
  String get actionOpenCourse => 'Open course';

  @override
  String get actionViewCourse => 'View course';

  @override
  String get coursePriceTagLabel => 'Price';

  @override
  String get courseIncludesTitle => 'What’s included';

  @override
  String courseIncludesVideos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video lessons',
      one: '1 video lesson',
    );
    return '$_temp0';
  }

  @override
  String courseIncludesReadings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings',
      one: '1 reading',
    );
    return '$_temp0';
  }

  @override
  String courseIncludesDocuments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PDF documents',
      one: '1 PDF document',
    );
    return '$_temp0';
  }

  @override
  String courseIncludesTests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tests',
      one: '1 test',
    );
    return '$_temp0';
  }

  @override
  String courseIncludesAssignments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assignments',
      one: '1 assignment',
    );
    return '$_temp0';
  }

  @override
  String courseIncludesLive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count live classes',
      one: '1 live class',
    );
    return '$_temp0';
  }

  @override
  String courseIncludesPreviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons free to preview',
      one: '1 lesson free to preview',
    );
    return '$_temp0';
  }

  @override
  String courseIncludesCertificate(String title) {
    return 'Certificate: $title';
  }

  @override
  String get previewTitle => 'Free preview';

  @override
  String get previewLockedTitle => 'Enrol to watch this lesson';

  @override
  String get previewLockedBody => 'This lesson is part of the course. Enrol to open it.';

  @override
  String get previewUnsupportedTitle => 'Preview not available';

  @override
  String get previewUnsupportedBody => 'Free previews cover readings, videos and documents.';

  @override
  String get verifyTitle => 'Verify a certificate';

  @override
  String get verifyIntro => 'Enter the credential ID printed on the certificate.';

  @override
  String get verifyFieldLabel => 'Credential ID';

  @override
  String get verifyFieldHint => 'SA-JY-2026-00142';

  @override
  String get actionVerify => 'Verify';

  @override
  String get actionVerifyAnother => 'Check another ID';

  @override
  String get verifyRequired => 'Enter a credential ID.';

  @override
  String get verifyTooLong => 'A credential ID is at most 64 characters.';

  @override
  String get verifyCheckingTitle => 'Checking this credential…';

  @override
  String get verifyNotFoundTitle => 'No certificate found for this ID';

  @override
  String get verifyNotFoundBody =>
      'Check the ID and try again. A certificate that has not been issued yet cannot be verified.';

  @override
  String get verifyValidTitle => 'This certificate is valid';

  @override
  String get verifyRevokedTitle => 'This certificate has been revoked';

  @override
  String get verifyRevokedBody => 'The LMS withdrew it, so it is no longer a valid credential.';

  @override
  String get verifyExpiredTitle => 'This certificate has expired';

  @override
  String verifyExpiredBody(String date) {
    return 'It was valid until $date.';
  }

  @override
  String get verifyAwardedToLabel => 'Awarded to';

  @override
  String get verifyCourseLabel => 'Course';

  @override
  String get verifyLevelLabel => 'Level';

  @override
  String get verifyCityLabel => 'City';

  @override
  String get verifyIssuedOnLabel => 'Issued on';

  @override
  String get verifyCompletedOnLabel => 'Completed on';

  @override
  String get verifyValidUntilLabel => 'Valid until';

  @override
  String get verifyScoreLabel => 'Final score';

  @override
  String verifyScoreValue(int score) {
    return '$score%';
  }

  @override
  String get verifyHoursLabel => 'Study hours';

  @override
  String verifyHoursValue(num hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get verifyRevokedReasonLabel => 'Reason';

  @override
  String get helpTitle => 'Help centre';

  @override
  String get helpSearchHint => 'Search help';

  @override
  String get helpPopularTitle => 'Popular articles';

  @override
  String get helpTopicsTitle => 'Browse by topic';

  @override
  String helpArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: 'No articles',
    );
    return '$_temp0';
  }

  @override
  String helpReadMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min read',
      one: '1 min read',
    );
    return '$_temp0';
  }

  @override
  String helpUpdatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String get helpRelatedTitle => 'Related articles';

  @override
  String get helpEmptyTitle => 'No articles yet';

  @override
  String get helpEmptyBody => 'The LMS has not published any help articles.';

  @override
  String get helpLinkFailed => 'That link could not be opened.';

  @override
  String get legalPrivacyTitle => 'Privacy policy';

  @override
  String get legalTermsTitle => 'Terms of use';

  @override
  String get legalBody =>
      'The current text is published on the web, so what you read is always the version in force.';

  @override
  String get actionOpenOnWeb => 'Open on the web';

  @override
  String get courseDurationLabel => 'Length';

  @override
  String get courseLessonsLabel => 'Lessons';

  @override
  String get courseLiveSessionsLabel => 'Live sessions';

  @override
  String get courseEnrolledLabel => 'Enrolled';

  @override
  String get previewSignInTitle => 'Sign in to watch this preview';

  @override
  String get previewSignInBody => 'The LMS serves course media to signed-in accounts only.';

  @override
  String get previewMissingTitle => 'Nothing to show yet';

  @override
  String get previewMissingBody => 'The LMS has not attached a file to this lesson.';

  @override
  String get actionOpenDocument => 'Open the document';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeContinueTitle => 'Continue learning';

  @override
  String get homeComingUpTitle => 'Coming up';

  @override
  String get homeYourCoursesTitle => 'Your courses';

  @override
  String get homeThisWeekTitle => 'This week';

  @override
  String get homeRecentTitle => 'Recently viewed';

  @override
  String get homeNextLiveTitle => 'Next live class';

  @override
  String get homeToDoTitle => 'To do';

  @override
  String get homeExploreBody => 'Find your next course in the LMS’s catalogue';

  @override
  String get homeEmptyTitle => 'Your learning starts here';

  @override
  String get homeEmptyBody => 'Browse the LMS’s courses and enrol in the one you want to begin.';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionStart => 'Start';

  @override
  String get actionExplore => 'Explore courses';

  @override
  String courseRemaining(String minutes) {
    return '$minutes left';
  }

  @override
  String lessonNumberAndLength(String number, String length) {
    return '$number · $length';
  }

  @override
  String homeWeekTotal(String minutes) {
    return '$minutes studied';
  }

  @override
  String get homeStudiedThisWeek => 'Studied this week';

  @override
  String homeEnrolledOn(String date) {
    return 'Enrolled $date';
  }

  @override
  String get homeDiscoverTitle => 'Discover more courses';

  @override
  String get upcomingKindLive => 'Live class';

  @override
  String get upcomingKindAssignment => 'Assignment';

  @override
  String get upcomingKindQuiz => 'Quiz';

  @override
  String get upcomingReadyNow => 'Ready now';

  @override
  String get myLearningTitle => 'My learning';

  @override
  String get myLearningEmptyInProgress => 'Nothing in progress';

  @override
  String get myLearningEmptyInProgressBody => 'Enrol in a course and it appears here.';

  @override
  String get myLearningEmptyCompleted => 'No courses completed yet';

  @override
  String get myLearningEmptyCompletedBody =>
      'Finish a course and it moves here with its certificate.';

  @override
  String get myLearningEmptySaved => 'Nothing saved';

  @override
  String get myLearningEmptySavedBody => 'Save a course from the Courses tab to come back to it.';

  @override
  String enrolmentExpiredOn(String date) {
    return 'Access ended on $date';
  }

  @override
  String get enrolmentPausedNote => 'Paused by the LMS.';

  @override
  String get exploreSearchHint => 'Search the LMS’s courses';

  @override
  String get exploreEnrolledFilter => 'Already enrolled';

  @override
  String get actionSaveCourse => 'Save this course';

  @override
  String get actionUnsaveCourse => 'Remove from saved';

  @override
  String get saveFailed => 'That could not be saved. Try again.';

  @override
  String get enrolConfirmTitle => 'Enrol in this course?';

  @override
  String get enrolConfirmBody =>
      'Your place is confirmed straight away and the course appears in My Courses, under Profile.';

  @override
  String get enrolFailedTitle => 'Could not enrol';

  @override
  String get enrolDoneMessage => 'You are enrolled. The course is in My Courses.';

  @override
  String enrolAccessEnds(String date) {
    return 'Access ends on $date';
  }

  @override
  String get courseEnrolToUnlock => 'Enrol to unlock';

  @override
  String courseLockedChapter(String chapter) {
    return 'Finish “$chapter” to open this chapter.';
  }

  @override
  String courseLockedQuiz(String chapter) {
    return 'Finish the other lessons in “$chapter” to take this quiz.';
  }

  @override
  String get courseLockedInOrder => 'This lesson opens after the ones before it.';

  @override
  String get courseFreePreviewsTitle => 'Try it free';

  @override
  String get actionPreviewLesson => 'Preview';

  @override
  String get courseScheduleLabel => 'Schedule';

  @override
  String get courseOverviewTitle => 'Course';

  @override
  String get exploreEnrolledAlready => 'You are already enrolled';

  @override
  String lessonPositionOf(int index, int total) {
    return '$index of $total';
  }

  @override
  String lessonCompletedOn(String date) {
    return 'Completed on $date';
  }

  @override
  String get lessonLockedTitle => 'Not open yet';

  @override
  String get lessonNotEnrolledTitle => 'Enrol to open this lesson';

  @override
  String get lessonNotEnrolledBody => 'This lesson is part of the course. Enrol to study it.';

  @override
  String get lessonUnavailableTitle => 'This lesson is not available';

  @override
  String get noteTitle => 'Your notes';

  @override
  String get noteHint => 'Write your working, or anything you want to remember.';

  @override
  String get noteSaving => 'Saving…';

  @override
  String noteSavedAt(String time) {
    return 'Saved $time';
  }

  @override
  String get noteFailed => 'Not saved. Try again.';

  @override
  String noteCounter(int count, int max) {
    return '$count of $max';
  }

  @override
  String get actionBookmarkLesson => 'Bookmark this lesson';

  @override
  String get actionRemoveBookmark => 'Remove bookmark';

  @override
  String get chapterCompleteTitle => 'Chapter complete';

  @override
  String chapterCompleteBody(String title) {
    return '$title is done.';
  }

  @override
  String get courseCompleteTitle => 'Course complete';

  @override
  String get courseCompleteBody => 'You have finished every lesson of this course.';

  @override
  String ruleHintWatched(int percent) {
    return 'Watch $percent% to complete';
  }

  @override
  String get ruleHintPassed => 'Pass the quiz to complete this lesson';

  @override
  String get ruleHintSubmitted => 'Hand in your work to complete this lesson';

  @override
  String get quizSummaryTitle => 'Quiz';

  @override
  String quizSummaryFacts(int questions, int passMark) {
    return '$questions questions · pass $passMark%';
  }

  @override
  String quizAttemptsAllowed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String quizBestScore(int percent) {
    return 'Best so far $percent%';
  }

  @override
  String quizTimeLimit(int minutes) {
    return '$minutes minute limit';
  }

  @override
  String get assignmentSummaryTitle => 'Assignment';

  @override
  String assignmentDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get actionOpenAssignment => 'Open assignment';

  @override
  String get liveSummaryTitle => 'Live class';

  @override
  String liveStartsAt(String when) {
    return 'Starts $when';
  }

  @override
  String liveDuration(int minutes) {
    return '$minutes minutes';
  }

  @override
  String lessonResumeFrom(String time) {
    return 'Resuming from $time';
  }

  @override
  String get courseNextLessonTitle => 'Next up';

  @override
  String get courseLiveTitle => 'Live classes';

  @override
  String get courseAssignmentsTitle => 'Assignments';

  @override
  String get actionOpenLesson => 'Open lesson';

  @override
  String get assessmentsTitle => 'Assessments';

  @override
  String get assessmentsEmptyTitle => 'No quizzes yet';

  @override
  String get assessmentsEmptyBody => 'Quizzes appear here as you reach them in your courses.';

  @override
  String assessmentRowFacts(int questions, int passMark) {
    return '$questions questions · pass $passMark%';
  }

  @override
  String assessmentAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts left',
      one: '1 attempt left',
      zero: 'No attempts left',
    );
    return '$_temp0';
  }

  @override
  String get assessmentAttemptsUnlimited => 'Unlimited attempts';

  @override
  String get quizIntroTitle => 'Before you start';

  @override
  String get actionStartQuiz => 'Start the quiz';

  @override
  String get actionReviewAnswers => 'Review answers';

  @override
  String get actionSubmitQuiz => 'Submit';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get quizSubmitConfirmTitle => 'Submit this attempt?';

  @override
  String get quizSubmitConfirmBody =>
      'Your answers go to the LMS to be marked. You cannot change them afterwards.';

  @override
  String quizUnansweredWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions are unanswered',
      one: '1 question is unanswered',
    );
    return '$_temp0';
  }

  @override
  String get quizAllAnswered => 'Every question is answered.';

  @override
  String get quizReviewTitle => 'Your answers';

  @override
  String get quizAnsweredLabel => 'Answered';

  @override
  String get quizUnansweredLabel => 'Not answered';

  @override
  String quizTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get quizTimeUp => 'Time is up. Your saved answers are being handed in.';

  @override
  String get quizPassedTitle => 'Passed';

  @override
  String get quizNotPassedTitle => 'Not passed this time';

  @override
  String quizBestAfterAttempt(int percent) {
    return 'Your best score is $percent%';
  }

  @override
  String get actionContinueCourse => 'Back to the course';

  @override
  String get quizQuestionNavigator => 'Questions';

  @override
  String get quizSubmitOffline => 'You are offline. Your answers are kept until you reconnect.';

  @override
  String get assignmentsEmptyTitle => 'No assignments yet';

  @override
  String get assignmentsEmptyBody => 'Coursework appears here as you reach it in your courses.';

  @override
  String get assignmentBriefTitle => 'The brief';

  @override
  String get assignmentAttachmentsTitle => 'From your instructor';

  @override
  String get assignmentRubricTitle => 'How it is marked';

  @override
  String assignmentRubricPoints(int points) {
    return '$points points';
  }

  @override
  String get assignmentWorkTitle => 'Your work';

  @override
  String get assignmentWorkHint => 'Write your answer here.';

  @override
  String assignmentWordCount(int count) {
    return '$count words';
  }

  @override
  String assignmentWordLimit(int count, int limit) {
    return '$count of $limit words';
  }

  @override
  String get assignmentFilesTitle => 'Your files';

  @override
  String get assignmentChartTitle => 'Birth details';

  @override
  String get assignmentChartLabel => 'Whose chart';

  @override
  String get assignmentChartDate => 'Date of birth';

  @override
  String get assignmentChartTime => 'Time of birth';

  @override
  String get assignmentChartPlace => 'Place of birth';

  @override
  String get assignmentChartLagna => 'Lagna';

  @override
  String get assignmentChartMoonSign => 'Moon sign';

  @override
  String get assignmentChartNakshatra => 'Nakshatra';

  @override
  String get assignmentDraftSaving => 'Saving…';

  @override
  String assignmentDraftSaved(String time) {
    return 'Draft saved $time';
  }

  @override
  String get assignmentDraftFailed => 'Draft not saved. Try again.';

  @override
  String get assignmentDraftOffline =>
      'You are offline. Your work is kept here until you reconnect.';

  @override
  String get actionSubmitAssignment => 'Submit';

  @override
  String get actionResubmitAssignment => 'Submit again';

  @override
  String get assignmentSubmitConfirmTitle => 'Hand this in?';

  @override
  String get assignmentSubmitConfirmBody => 'Your work goes to your instructor to be marked.';

  @override
  String assignmentLateWarning(int percent) {
    return 'This is past its deadline. The LMS takes $percent% off a late hand-in.';
  }

  @override
  String get assignmentLateNoPenalty =>
      'This is past its deadline, and late work is still accepted.';

  @override
  String assignmentSubmittedOn(String date) {
    return 'Handed in $date';
  }

  @override
  String assignmentAttemptNumber(int number) {
    return 'Attempt $number';
  }

  @override
  String get assignmentLateBadge => 'Handed in late';

  @override
  String get assignmentReviewTitle => 'Your review';

  @override
  String assignmentScore(String score, int max) {
    return '$score of $max';
  }

  @override
  String assignmentPassMark(int points) {
    return 'Pass mark $points';
  }

  @override
  String get assignmentPassMarkLabel => 'Pass mark';

  @override
  String get assignmentTotalLabel => 'Total';

  @override
  String get assignmentReturnedTitle => 'Returned for changes';

  @override
  String get assignmentAwaitingReview => 'With your instructor.';

  @override
  String get assignmentClosedNote => 'This assignment is closed to new submissions.';

  @override
  String assignmentDueRelative(String when) {
    return 'Due $when';
  }

  @override
  String get assignmentNoDeadline => 'No deadline';

  @override
  String get assignmentSaveDraft => 'Save draft';

  @override
  String get assignmentSubmissionTitle => 'What you handed in';

  @override
  String get assignmentFeedbackTitle => 'Feedback';

  @override
  String get assignmentNoFiles => 'No files yet.';

  @override
  String assignmentFilesLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up to $count files.',
      one: 'One file.',
    );
    return '$_temp0';
  }

  @override
  String assignmentTotalPoints(int points) {
    return 'Out of $points points';
  }

  @override
  String assignmentCriterionScore(String score, int points) {
    return '$score of $points';
  }

  @override
  String assignmentLatePenaltyNote(int percent) {
    return '$percent% is taken off work handed in late.';
  }

  @override
  String get assignmentChartNote => 'Fill in every detail — the chart is taken as one.';

  @override
  String get assignmentTextTooLong => 'Your answer is too long to save. Shorten it.';

  @override
  String get assignmentInterpretationLabel => 'Your interpretation';

  @override
  String assignmentAttachmentSize(String size) {
    return '$size MB';
  }

  @override
  String get certificatesTabIssued => 'Issued';

  @override
  String get certificatesTabPending => 'Pending';

  @override
  String get certificatesTabWorking => 'Working towards';

  @override
  String get certificatesEmptyTitle => 'No certificates yet';

  @override
  String get certificatesEmptyBody => 'Complete a course to earn your first certificate.';

  @override
  String get certificatesPendingEmpty => 'Nothing waiting to be claimed.';

  @override
  String get certificatesWorkingEmpty => 'You are not working towards a certificate right now.';

  @override
  String get certificateClaimAction => 'Claim certificate';

  @override
  String get certificateClaimedTitle => 'Certificate issued';

  @override
  String get certificateClaimedBody =>
      'It is in your wallet, and the credential can be verified by anyone you share it with.';

  @override
  String get certificateShareAction => 'Share verification link';

  @override
  String get certificateOpenVerification => 'Open the verification page';

  @override
  String certificateShareSubject(String title) {
    return 'My certificate: $title';
  }

  @override
  String get certificateDetailsTitle => 'Certificate details';

  @override
  String certificateCompletedOn(String date) {
    return 'Completed $date';
  }

  @override
  String certificateVerificationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verified $count times',
      one: 'Verified once',
      zero: 'Not verified yet',
    );
    return '$_temp0';
  }

  @override
  String get certificateRevokedTitle => 'Withdrawn by the LMS';

  @override
  String get certificatePendingNote => 'You have earned this. Claim it to add it to your wallet.';

  @override
  String certificateCanvasLabel(String heading, String course, String name, String id) {
    return '$heading for $course, awarded to $name. Credential $id.';
  }

  @override
  String get certificateCanvasUnavailable =>
      'The certificate cannot be drawn here. Its details are below.';

  @override
  String get certificateCriteriaTitle => 'What is left';

  @override
  String certificateCriterionProgress(String current, String required, String unit) {
    return '$current$unit of $required$unit';
  }

  @override
  String get ranksTitle => 'Rank ladder';

  @override
  String get ranksCurrentLabel => 'Where you are now';

  @override
  String get ranksAchievedLabel => 'Reached';

  @override
  String get ranksNextLabel => 'Next rank';

  @override
  String get ranksFutureLabel => 'Later';

  @override
  String get ranksRequirementsTitle => 'What it asks for';

  @override
  String ranksRequirement(String label, String required, String unit) {
    return '$label: $required$unit';
  }

  @override
  String get ranksNoRequirements => 'No requirements — this is where everyone starts.';

  @override
  String get ranksProgressUnknown => 'Your LMS does not publish how far along you are.';

  @override
  String get ranksEmptyTitle => 'No ranks yet';

  @override
  String get ranksEmptyBody => 'Your LMS has not set up a rank ladder.';

  @override
  String get liveTabLiveNow => 'Live now';

  @override
  String get liveTabUpcoming => 'Upcoming';

  @override
  String get liveTabRecordings => 'Recordings';

  @override
  String get liveEmptyTitle => 'No live classes scheduled';

  @override
  String get liveEmptyBody => 'Live classes for your courses appear here.';

  @override
  String get liveJoinAction => 'Join the class';

  @override
  String get liveJoinOpensNote => 'Join opens 15 minutes before the start.';

  @override
  String get liveRoomUnavailable =>
      'The class couldn’t open on this phone. Check your connection and try again.';

  @override
  String get liveConnecting => 'Connecting to the class…';

  @override
  String liveWaitingForHost(String name) {
    return 'Waiting for $name to start the class. Join appears here as soon as they do.';
  }

  @override
  String liveJoinedSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners have joined',
      one: '1 learner has joined',
      zero: 'Nobody has joined yet',
    );
    return '$_temp0';
  }

  @override
  String get liveYouAttended => 'You attended this class';

  @override
  String get liveYouMissed => 'You missed this class';

  @override
  String get liveAttendanceTitle => 'Your attendance';

  @override
  String get liveAttendedBadge => 'Attended';

  @override
  String get liveMissedBadge => 'Missed';

  @override
  String get liveJoinedBadge => 'Joined';

  @override
  String get liveOpenedLinkBadge => 'Opened the link';

  @override
  String get liveConnectionLost =>
      'The class connection was lost. If the class is still on, join again.';

  @override
  String get liveLinkUnusable =>
      'This class’s meeting link can’t be opened. Ask your LMS for a new one.';

  @override
  String get liveLinkNotOpened =>
      'The meeting link couldn’t be opened on this phone. Check that a browser is installed, then try again.';

  @override
  String get liveRefreshFailed => 'Couldn’t refresh. Showing the last update.';

  @override
  String liveJoinOtherHostBody(String host) {
    return 'The meeting is now on $host. This opens it outside the app.';
  }

  @override
  String get liveWatchRecording => 'Watch recording';

  @override
  String get liveRecordingProcessing =>
      'The recording is being prepared. It is usually ready a few minutes after the class.';

  @override
  String get liveRegisterAction => 'Save my seat';

  @override
  String get liveUnregisterAction => 'Give up my seat';

  @override
  String get liveRegisteredBadge => 'Registered';

  @override
  String liveSpotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats left',
      one: '1 seat left',
      zero: 'No seats left',
    );
    return '$_temp0';
  }

  @override
  String liveCapacityLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: '1 seat',
    );
    return '$_temp0';
  }

  @override
  String get liveCancelledNote => 'This class was cancelled.';

  @override
  String liveEndedOn(String date) {
    return 'Ended $date';
  }

  @override
  String liveRecordingUntil(String date) {
    return 'Recording available until $date';
  }

  @override
  String liveRecordingLength(int minutes) {
    return 'Recording · $minutes minutes';
  }

  @override
  String get liveRecordingNotPlayable => 'This recording can’t be played here.';

  @override
  String get liveAgendaTitle => 'What happens';

  @override
  String liveAgendaItem(String title, int minutes) {
    return '$title · $minutes min';
  }

  @override
  String liveWithInstructor(String name) {
    return 'With $name';
  }

  @override
  String get liveRemindersNote => 'Registrants are reminded before it starts.';

  @override
  String get liveJoinConfirmTitle => 'Open the meeting?';

  @override
  String liveJoinConfirmBody(String host) {
    return 'This opens $host outside the app.';
  }

  @override
  String get liveNotInSchedule => 'This class is not in your schedule.';

  @override
  String get liveAboutTitle => 'About this class';

  @override
  String get notificationsTabAll => 'All';

  @override
  String get notificationsTabUnread => 'Unread';

  @override
  String get notificationsEmptyTitle => 'You\'re all caught up';

  @override
  String get notificationsEmptyBody => 'New notices from your LMS appear here.';

  @override
  String get notificationsFilterEmpty => 'Nothing here right now.';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String notificationsMarkedRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marked read',
      one: '1 marked read',
      zero: 'Nothing to mark',
    );
    return '$_temp0';
  }

  @override
  String get notificationsClear => 'Clear';

  @override
  String get notificationsClearConfirmTitle => 'Clear these notifications?';

  @override
  String notificationsClearConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications will be removed.',
      one: '1 notification will be removed.',
    );
    return '$_temp0';
  }

  @override
  String notificationsCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cleared',
      one: '1 cleared',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMarkRead => 'Mark read';

  @override
  String get notificationsMarkUnread => 'Mark unread';

  @override
  String get notificationsRemove => 'Remove';

  @override
  String get notificationsRemoved => 'Notification removed';

  @override
  String get notificationsRestored => 'Put back';

  @override
  String notificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
    );
    return '$_temp0';
  }

  @override
  String get notificationsShowMore => 'Show older';

  @override
  String get notificationImportant => 'Important';

  @override
  String get notificationRelatedTitle => 'More like this';

  @override
  String notificationSentOn(String channels) {
    return 'Sent to: $channels';
  }

  @override
  String get notificationChannelApp => 'the app';

  @override
  String get notificationChannelEmail => 'email';

  @override
  String get notificationChannelSms => 'SMS';

  @override
  String get notificationCategoryCourse => 'Courses';

  @override
  String get notificationCategoryAssignment => 'Assignments';

  @override
  String get notificationCategoryQuiz => 'Quizzes';

  @override
  String get notificationCategoryLive => 'Live classes';

  @override
  String get notificationCategoryCertificate => 'Certificates';

  @override
  String get notificationCategoryEnrollment => 'Enrolments';

  @override
  String get notificationCategorySystem => 'Account';

  @override
  String get notificationPrefsTitle => 'Notification settings';

  @override
  String get notificationPrefsCategoriesTitle => 'What you hear about';

  @override
  String get notificationPrefsChannelApp => 'In the app';

  @override
  String get notificationPrefsChannelEmail => 'Email';

  @override
  String get notificationPrefsChannelSms => 'SMS';

  @override
  String get notificationPrefsSmsUnavailable => 'Your LMS cannot send text messages yet.';

  @override
  String get notificationPrefsLocked =>
      'Account and security notices stay on in the app and by email.';

  @override
  String get notificationPrefsDigestTitle => 'Email digest';

  @override
  String get notificationPrefsDigestInstant => 'As they happen';

  @override
  String get notificationPrefsDigestDaily => 'Once a day';

  @override
  String get notificationPrefsDigestWeekly => 'Once a week';

  @override
  String get notificationPrefsDigestOff => 'No email digest';

  @override
  String get notificationPrefsQuietTitle => 'Quiet hours';

  @override
  String get notificationPrefsQuietEnabled => 'Nothing between these times';

  @override
  String get notificationPrefsQuietFrom => 'From';

  @override
  String get notificationPrefsQuietTo => 'To';

  @override
  String get notificationPrefsQuietNote => 'Times are your LMS’s, in IST.';

  @override
  String get notificationPrefsPauseTitle => 'Pause';

  @override
  String notificationPrefsPausedUntil(String date) {
    return 'Paused until $date';
  }

  @override
  String get notificationPrefsPauseAction => 'Pause notifications';

  @override
  String get notificationPrefsResumeAction => 'Turn notifications back on';

  @override
  String get notificationPrefsPauseNote =>
      'Important notices still arrive while notifications are paused.';

  @override
  String get notificationPrefsSaved => 'Settings saved';

  @override
  String get notificationPrefsUnsavedTitle => 'Leave without saving?';

  @override
  String get notificationPrefsUnsavedBody => 'Your changes to these settings have not been saved.';

  @override
  String get notificationPrefsDiscard => 'Leave';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSignedInAs => 'Signed in as';

  @override
  String get profileRankTitle => 'Your standing';

  @override
  String get profileActivityTitle => 'Recently';

  @override
  String get profileActivityEmpty => 'What you do in your courses shows up here.';

  @override
  String get profileWeekTitle => 'This week';

  @override
  String profileWeekMinutes(int minutes) {
    return '$minutes minutes this week';
  }

  @override
  String get profileLinksTitle => 'More';

  @override
  String get profileGroupAccount => 'Account';

  @override
  String get profileGroupLearning => 'Learning';

  @override
  String get profileMyCoursesSubtitle => 'In progress, completed and saved';

  @override
  String get profileGroupSupport => 'Help & support';

  @override
  String get profileGroupAbout => 'About';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String profileChangePasswordBody(String email) {
    return 'Your LMS sends a link to $email. Open it to set a new password.';
  }

  @override
  String get profileChangePasswordSent => 'Check your email for the link.';

  @override
  String get profileSignOutConfirmTitle => 'Sign out?';

  @override
  String get profileSignOutConfirmBody =>
      'Your downloads and cached pages on this device are removed. Your work stays with your LMS.';

  @override
  String get profileAboutTitle => 'About this app';

  @override
  String profileAboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get profileContactSupport => 'Contact support';

  @override
  String get profileContactSupportBody =>
      'Email synilogicteam@gmail.com. We reply within a working day.';

  @override
  String get supportEmailSubject => 'ZuviloAI app support';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountIntro =>
      'Deleting your account is immediate and cannot be undone. You will be signed out on every device, and you cannot sign back in to this account.';

  @override
  String get deleteAccountRemovedTitle => 'What is deleted';

  @override
  String get deleteAccountRemovedIdentity =>
      'Your name and email address. The address is free to register again.';

  @override
  String get deleteAccountRemovedPersonal =>
      'Your lesson notes, bookmarks, saved courses, assignment drafts and live-class registrations.';

  @override
  String get deleteAccountRemovedDevice =>
      'Your notifications, notification preferences and every signed-in session and device.';

  @override
  String get deleteAccountKeptTitle => 'What is kept';

  @override
  String get deleteAccountKeptRecords =>
      'Course progress, quiz and assignment records and issued certificates stay with the LMS, no longer linked to your name, so a credential someone relies on still verifies.';

  @override
  String get deleteAccountWeb =>
      'You can also delete your account on the web at zuviloai.com/delete-account.';

  @override
  String get deleteAccountAction => 'Delete my account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmBody => 'Enter your password to confirm it is you.';

  @override
  String get deleteAccountAcknowledge => 'I understand my account is deleted for good.';

  @override
  String get deleteAccountDoneMessage => 'Your account has been deleted.';

  @override
  String get deleteAccountStaffTitle => 'Deleting a staff account';

  @override
  String get deleteAccountStaffBody =>
      'Instructor and admin accounts belong to your LMS, so its admin closes them. Ask them to remove your account, or contact support.';

  @override
  String get registerAgreement =>
      'By creating an account you agree to the terms of use and acknowledge the privacy policy.';

  @override
  String get settingsTitle => 'App settings';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsThemeSystem => 'Match my phone';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsReducedMotion => 'Reduce motion';

  @override
  String get settingsReducedMotionBody =>
      'Less movement in animations, on top of your phone’s own setting.';

  @override
  String get settingsTextSizeTitle => 'Text size';

  @override
  String get settingsTextSizeBody =>
      'This is a preview. Your phone’s own text size setting is what really decides.';

  @override
  String get settingsTextSizeSample => 'The Moon is in Rohini today.';

  @override
  String get settingsStorageTitle => 'Storage';

  @override
  String get settingsClearImageCache => 'Clear cached images';

  @override
  String get settingsClearImageCacheBody =>
      'Frees space on this device. Nothing is removed from your LMS.';

  @override
  String get settingsImageCacheCleared => 'Cached images cleared';

  @override
  String get activityEnrolled => 'Enrolled';

  @override
  String get activityLessonCompleted => 'Lesson completed';

  @override
  String get activityChapterCompleted => 'Chapter completed';

  @override
  String get activityLiveAttended => 'Live class attended';

  @override
  String get activityAssignmentSubmitted => 'Assignment handed in';

  @override
  String get activityAssessmentPassed => 'Quiz passed';

  @override
  String get activityCertificateIssued => 'Certificate issued';

  @override
  String get activityRankAchieved => 'New rank';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardAttentionTitle => 'Needs you';

  @override
  String get dashboardHeroTitle => 'Your platform at a glance';

  @override
  String get dashboardHeroAttention => 'Waiting on you';

  @override
  String get dashboardHeroLive => 'Live classes ahead';

  @override
  String get dashboardHeroLearners => 'Your learners';

  @override
  String get dashboardAttentionEmpty => 'Nothing is waiting for you.';

  @override
  String get dashboardQuickActionsTitle => 'Do next';

  @override
  String get dashboardActionReview => 'Review queue';

  @override
  String get dashboardActionScheduleLive => 'Schedule a live class';

  @override
  String get dashboardActionStudents => 'Learners';

  @override
  String get dashboardActionEnrol => 'Add an enrolment';

  @override
  String get dashboardUpcomingLiveTitle => 'Coming up live';

  @override
  String get dashboardKpisTitle => 'How things stand';

  @override
  String get dashboardKpiCourses => 'Courses';

  @override
  String get dashboardKpiStudents => 'Learners';

  @override
  String get dashboardKpiInstructors => 'Active instructors';

  @override
  String get dashboardKpiWaitingReview => 'Waiting for review';

  @override
  String get dashboardKpiCompletion => 'Completion rate';

  @override
  String get dashboardComparison => 'vs the period before';

  @override
  String get dashboardTrendsTitle => 'Enrolments and completions';

  @override
  String get dashboardTrendEnrollments => 'New enrolments';

  @override
  String get dashboardTrendCompletions => 'Completions';

  @override
  String get dashboardEngagementTitle => 'Engagement this week';

  @override
  String get dashboardEngagementLessons => 'Lessons completed';

  @override
  String get dashboardEngagementQuizzes => 'Quiz attempts';

  @override
  String get dashboardEngagementSubmissions => 'Hand-ins';

  @override
  String get dashboardEngagementLive => 'Live attendance';

  @override
  String get dashboardActivityTitle => 'Recently';

  @override
  String get dashboardActivityEmpty => 'Nothing has happened yet.';

  @override
  String get dashboardCoursesTitle => 'Course performance';

  @override
  String dashboardCourseFacts(int enrolled, int active) {
    return '$enrolled enrolled · $active active in the last 2 weeks';
  }

  @override
  String dashboardCourseProgress(String completion, String progress) {
    return '$completion% complete · $progress% average progress';
  }

  @override
  String get dashboardScopeAcademy => 'Whole platform';

  @override
  String get dashboardScopeInstructor => 'One instructor';

  @override
  String get dashboardScopePick => 'Choose an instructor';

  @override
  String dashboardGeneratedAt(String time) {
    return 'As of $time';
  }

  @override
  String get dashboardEmptyTitle => 'Nothing to show yet';

  @override
  String get dashboardEmptyBody => 'Figures appear here as your LMS teaches.';

  @override
  String dashboardSparkline(String label, int count) {
    return '$label over the last $count periods';
  }

  @override
  String get staffCoursesTitle => 'Courses';

  @override
  String get staffCoursesSearch => 'Search courses';

  @override
  String get staffCoursesEmptyTitle => 'No courses yet';

  @override
  String get staffCoursesEmptyBody =>
      'Courses are created on the web. They appear here once they exist.';

  @override
  String get staffCourseStatusAll => 'All';

  @override
  String get staffCourseStatusDraft => 'Draft';

  @override
  String get staffCourseStatusPublished => 'Published';

  @override
  String get staffCourseStatusArchived => 'Archived';

  @override
  String get staffCourseSortUpdated => 'Recently updated';

  @override
  String get staffCourseSortTitle => 'Title';

  @override
  String get staffCourseSortLearners => 'Learners';

  @override
  String get staffCourseSortCreated => 'Newest';

  @override
  String staffCourseLearners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners',
      one: '1 learner',
    );
    return '$_temp0';
  }

  @override
  String staffCourseLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
    );
    return '$_temp0';
  }

  @override
  String get staffCourseOverviewTitle => 'Overview';

  @override
  String get staffCourseStatsTitle => 'How it is going';

  @override
  String get staffCourseStatEnrolled => 'Enrolled';

  @override
  String get staffCourseStatActive => 'Active';

  @override
  String get staffCourseStatCompletion => 'Completion';

  @override
  String get staffCourseStatProgress => 'Average progress';

  @override
  String get staffCourseStatCertificates => 'Certificates issued';

  @override
  String get staffCourseStatReviews => 'Waiting for review';

  @override
  String get staffCourseStatMinutes => 'Published minutes';

  @override
  String get staffCourseCurriculumTitle => 'Curriculum';

  @override
  String staffCourseCurriculumFacts(int chapters, int lessons) {
    return '$chapters chapters · $lessons lessons';
  }

  @override
  String staffCourseChapterProgress(String started, String completed) {
    return '$started% started · $completed% completed';
  }

  @override
  String staffCourseLessonCompleted(String percent) {
    return '$percent% completed it';
  }

  @override
  String get staffCourseOutcomesTitle => 'What learners will be able to do';

  @override
  String get staffCourseInstructorsTitle => 'Who teaches it';

  @override
  String get staffCourseRecentTitle => 'Recent learners';

  @override
  String get staffCourseActionPublish => 'Publish';

  @override
  String get staffCourseActionUnpublish => 'Unpublish';

  @override
  String get staffCourseActionArchive => 'Archive';

  @override
  String get staffCourseActionRestore => 'Restore';

  @override
  String get staffCourseEditOnWeb => 'Edit on the web';

  @override
  String get staffCoursePublishConfirmTitle => 'Take this course live?';

  @override
  String get staffCoursePublishConfirmBody =>
      'Learners will find it in the catalogue and can enrol.';

  @override
  String get staffCourseUnpublishConfirmTitle => 'Take it out of the catalogue?';

  @override
  String get staffCourseUnpublishConfirmBody =>
      'Learners already enrolled keep their access; nobody new can find it.';

  @override
  String get staffCourseArchiveConfirmTitle => 'Archive this course?';

  @override
  String get staffCourseArchiveConfirmBody =>
      'It leaves the catalogue and the course lists. It can be restored later.';

  @override
  String get staffCourseRestoreConfirmTitle => 'Bring this course back?';

  @override
  String get staffCourseRestoreConfirmBody => 'It returns as a draft.';

  @override
  String get staffCourseChecklistTitle => 'Not ready to publish yet';

  @override
  String get staffCourseChecklistBody => 'Your LMS asks for these before a course goes live.';

  @override
  String get staffCoursePublished => 'The course is live';

  @override
  String get staffCourseUnpublished => 'The course is a draft again';

  @override
  String get staffCourseArchived => 'The course is archived';

  @override
  String get staffCourseRestored => 'The course is back as a draft';

  @override
  String get staffLessonPreviewBadge => 'Free preview';

  @override
  String get staffLessonObjectivesTitle => 'What this lesson covers';

  @override
  String get staffLessonContentUnavailable => 'This lesson has nothing in it yet.';

  @override
  String get staffLessonEditOnWeb => 'Edit this lesson on the web';

  @override
  String get staffCoursesFilterAnyCategory => 'Any category';

  @override
  String get staffCoursesFilterAnyInstructor => 'Any instructor';

  @override
  String get staffCoursesCategoryLabel => 'Category';

  @override
  String get staffCoursesInstructorLabel => 'Instructor';

  @override
  String get staffCoursesSortLabel => 'Sort by';

  @override
  String staffCoursesPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get staffCourseVisibilityLabel => 'Who can find it';

  @override
  String get staffCourseVisibilityPublic => 'Anyone';

  @override
  String get staffCourseVisibilityUnlisted => 'Only with the link';

  @override
  String get staffCourseVisibilityPrivate => 'Invited learners only';

  @override
  String get staffCourseProgressSpreadTitle => 'How far learners have got';

  @override
  String get staffCourseWeeklyTitle => 'New enrolments a week';

  @override
  String get staffCourseUpcomingLiveTitle => 'Live classes coming up';

  @override
  String get staffCourseCurriculumEmpty => 'No chapters yet. Build the curriculum on the web.';

  @override
  String get staffCourseNoLearnersYet => 'Nobody has enrolled yet.';

  @override
  String get staffCourseActionsTitle => 'Course actions';

  @override
  String get staffCourseArchiveAcknowledge =>
      'I understand learners will no longer find this course';

  @override
  String get staffCourseChecklistMet => 'Done';

  @override
  String get staffCourseChecklistUnmet => 'Still needed';

  @override
  String staffCourseChapterLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
    );
    return '$_temp0';
  }

  @override
  String staffLessonNeighbourHint(int index, int total) {
    return 'Lesson $index of $total in this course';
  }

  @override
  String staffLessonDueAfterDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Due $count days after a learner starts it',
      one: 'Due 1 day after a learner starts it',
    );
    return '$_temp0';
  }

  @override
  String get staffLessonDeliversTitle => 'What it delivers';

  @override
  String get staffLessonContentTitle => 'Lesson content';

  @override
  String get reviewTitle => 'Review';

  @override
  String get reviewQueueToReview => 'To review';

  @override
  String get reviewQueueOverdue => 'Overdue';

  @override
  String get reviewQueueByCourse => 'By course';

  @override
  String get reviewQueueClearTitle => 'Nothing to review';

  @override
  String get reviewQueueClearBody => 'Every hand-in has been looked at. Nice work.';

  @override
  String get reviewSearchHint => 'Search by learner';

  @override
  String get reviewTabToReview => 'To review';

  @override
  String get reviewTabGraded => 'Graded';

  @override
  String get reviewTabReturned => 'Returned';

  @override
  String get reviewTabMissing => 'Missing';

  @override
  String get reviewTabAll => 'All';

  @override
  String get reviewSortLabel => 'Sort by';

  @override
  String get reviewSortOldest => 'Oldest first';

  @override
  String get reviewSortNewest => 'Newest first';

  @override
  String get reviewSortScore => 'Highest score';

  @override
  String get reviewAssignmentLabel => 'Assignment';

  @override
  String get reviewAllAssignments => 'Every assignment';

  @override
  String get reviewNotHandedIn => 'Nothing handed in yet';

  @override
  String reviewAttemptNumber(int number) {
    return 'Attempt $number';
  }

  @override
  String reviewSubmittedOn(String date) {
    return 'Handed in $date';
  }

  @override
  String reviewScoreOf(String score, String max) {
    return '$score of $max';
  }

  @override
  String get staffReviewCourseLabel => 'Course';

  @override
  String get staffReviewAllCourses => 'Every course';

  @override
  String reviewPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get reviewEmptyTitle => 'Nothing here';

  @override
  String get reviewEmptyBody => 'No hand-in matches what you are looking at.';

  @override
  String get reviewBriefTitle => 'The brief';

  @override
  String get reviewLearnerWorkTitle => 'What the learner handed in';

  @override
  String reviewLearnerProgress(String percent) {
    return '$percent% through the course';
  }

  @override
  String reviewEnrolledOn(String date) {
    return 'Enrolled $date';
  }

  @override
  String get reviewScoreTitle => 'The score';

  @override
  String reviewPointsLabel(String max) {
    return 'Points out of $max';
  }

  @override
  String get reviewFeedbackTitle => 'Feedback for the learner';

  @override
  String get reviewFeedbackHint => 'What was good, and what to do next.';

  @override
  String get reviewPrivateNoteTitle => 'Private note';

  @override
  String get reviewPrivateNoteHint => 'Anything you want to remember about this hand-in.';

  @override
  String get reviewPrivateNoteOnlyStaff => 'Only staff see this. The learner never does.';

  @override
  String get reviewActionSaveDraft => 'Save draft';

  @override
  String get reviewActionReturn => 'Return for changes';

  @override
  String get reviewActionGrade => 'Grade';

  @override
  String get reviewDraftSaved => 'Your draft review is saved';

  @override
  String get reviewGradedMessage => 'Graded. The learner has been told.';

  @override
  String get reviewReturnedMessage => 'Sent back for another attempt.';

  @override
  String get reviewGradeConfirmTitle => 'Send this grade to the learner?';

  @override
  String get reviewGradeConfirmBody =>
      'They will be told their score and can read your feedback. The LMS works the final score out itself.';

  @override
  String reviewGradeEstimate(String score, String max) {
    return 'About $score of $max — the LMS works out the final score';
  }

  @override
  String reviewGradeEstimatePass(String passMark) {
    return 'Above the pass mark of $passMark';
  }

  @override
  String reviewGradeEstimateFail(String passMark) {
    return 'Below the pass mark of $passMark';
  }

  @override
  String reviewLatePenaltyNote(String percent) {
    return 'This hand-in was late. The LMS may take $percent% off.';
  }

  @override
  String get reviewReturnConfirmTitle => 'Ask for another attempt?';

  @override
  String get reviewReturnConfirmBody => 'The learner keeps your feedback and can hand in again.';

  @override
  String get reviewNextInQueue => 'Next to review';

  @override
  String reviewQueuePosition(int position, int total) {
    return '$position of $total waiting';
  }

  @override
  String get reviewLeaveConfirmTitle => 'Leave without saving?';

  @override
  String get reviewLeaveConfirmBody =>
      'Your score and feedback have not been sent. Save a draft first to keep them.';

  @override
  String get reviewLeaveConfirmAction => 'Leave';

  @override
  String get reviewRemindAction => 'Remind who is missing';

  @override
  String get reviewRemindConfirmTitle => 'Remind the learners who owe this?';

  @override
  String get reviewRemindConfirmBody =>
      'Everyone who has not handed in gets a notice. The LMS decides who that is.';

  @override
  String reviewRemindSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners were reminded',
      one: '1 learner was reminded',
      zero: 'Nobody needed a reminder',
    );
    return '$_temp0';
  }

  @override
  String get reviewMissingTitle => 'Still to hand in';

  @override
  String get reviewOpenAssignment => 'All hand-ins for this assignment';

  @override
  String reviewScoredOutOf(String points) {
    return 'Scored out of $points';
  }

  @override
  String get staffQuizzesTitle => 'Quizzes';

  @override
  String get staffQuizzesSearch => 'Search quizzes';

  @override
  String get staffQuizzesEmptyTitle => 'No quizzes yet';

  @override
  String get staffQuizzesEmptyBody =>
      'Quizzes are built on the web. They appear here once they exist.';

  @override
  String get staffQuizCourseLabel => 'Course';

  @override
  String get staffQuizAllCourses => 'Every course';

  @override
  String get staffQuizStatusAll => 'All';

  @override
  String get staffQuizStatusDraft => 'Draft';

  @override
  String get staffQuizStatusPublished => 'Published';

  @override
  String staffQuizPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String staffQuizQuestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String staffQuizAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
      zero: 'No attempts yet',
    );
    return '$_temp0';
  }

  @override
  String get staffQuizNoAttemptsTitle => 'No attempts yet';

  @override
  String get staffQuizNoAttemptsBody =>
      'Once learners take it, this is where the LMS’s figures appear.';

  @override
  String get staffQuizStatAttempts => 'Attempts';

  @override
  String get staffQuizStatLearners => 'Learners';

  @override
  String get staffQuizStatPassRate => 'Pass rate';

  @override
  String get staffQuizStatAvgScore => 'Average score';

  @override
  String get staffQuizStatMedianTime => 'Typical time';

  @override
  String get staffQuizDistributionTitle => 'How the scores fell';

  @override
  String get staffQuizSettingsTitle => 'How it is set up';

  @override
  String get staffQuizPassMarkLabel => 'Pass mark';

  @override
  String get staffQuizAttemptsLabel => 'Attempts allowed';

  @override
  String get staffQuizAttemptsUnlimited => 'As many as they like';

  @override
  String get staffQuizTimeLimitLabel => 'Time limit';

  @override
  String get staffQuizNoTimeLimit => 'No limit';

  @override
  String get staffQuizShuffleLabel => 'Shuffled';

  @override
  String get staffQuizShuffleQuestions => 'Questions';

  @override
  String get staffQuizShuffleOptions => 'Answers';

  @override
  String get staffQuizShuffleNothing => 'Nothing';

  @override
  String get staffQuizResultsLabel => 'What learners see afterwards';

  @override
  String get staffQuizResultsScoreAndAnswers => 'Their score and the answers';

  @override
  String get staffQuizResultsScoreOnly => 'Their score only';

  @override
  String get staffQuizResultsHidden => 'Nothing';

  @override
  String get staffQuizQuestionsTitle => 'The questions';

  @override
  String get staffQuizAnswerKeyNote => 'The answers below are shown to staff only.';

  @override
  String get staffQuizCorrectAnswer => 'Correct';

  @override
  String staffQuizAcceptedAnswers(String answers) {
    return 'Accepted: $answers';
  }

  @override
  String get staffQuizExplanationLabel => 'Explanation';

  @override
  String get staffQuizOptionalQuestion => 'Optional';

  @override
  String staffQuizCorrectRate(String percent) {
    return '$percent% got it right';
  }

  @override
  String staffQuizCommonWrong(String option) {
    return 'Most often chosen instead: $option';
  }

  @override
  String get staffQuizEditOnWeb => 'Edit on the web';

  @override
  String staffQuizMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get staffQuizStatsTitle => 'How learners did';

  @override
  String get studentsTitle => 'Learners';

  @override
  String get studentsSearch => 'Search by name or email';

  @override
  String get studentsEmptyTitle => 'No learners yet';

  @override
  String get studentsEmptyBody => 'Learners appear here once they enrol in one of your courses.';

  @override
  String get studentsTabAll => 'All';

  @override
  String get studentsTabActive => 'Active';

  @override
  String get studentsTabAtRisk => 'At risk';

  @override
  String get studentsTabInactive => 'Inactive';

  @override
  String get studentsTabSuspended => 'Suspended';

  @override
  String get studentsSortLabel => 'Sort by';

  @override
  String get studentsSortActive => 'Last active';

  @override
  String get studentsSortName => 'Name';

  @override
  String get studentsSortProgress => 'Progress';

  @override
  String get studentsSortJoined => 'Recently joined';

  @override
  String get studentsCourseLabel => 'Course';

  @override
  String get studentsAllCourses => 'Every course';

  @override
  String get staffStudentsProgressByCourse => 'Course by course';

  @override
  String get staffStudentsEnrolmentLabel => 'Enrolment';

  @override
  String studentsPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String studentsCourseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses',
      one: '1 course',
      zero: 'No courses',
    );
    return '$_temp0';
  }

  @override
  String studentsProgressLabel(String percent) {
    return '$percent% through';
  }

  @override
  String studentsQuietDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quiet for $count days',
      one: 'Quiet for a day',
      zero: 'Active today',
    );
    return '$_temp0';
  }

  @override
  String studentsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners selected',
      one: '1 learner selected',
    );
    return '$_temp0';
  }

  @override
  String get studentsSelectAction => 'Select';

  @override
  String get studentsClearSelection => 'Clear';

  @override
  String get studentsMessageAction => 'Message';

  @override
  String get studentsMessageTitle => 'Message the learners you picked';

  @override
  String get studentsMessageSubject => 'Subject';

  @override
  String get studentsMessageBody => 'Message';

  @override
  String get studentsMessageBodyHint => 'What you want them to know.';

  @override
  String get studentsMessageChannels => 'Send it';

  @override
  String get studentsMessageChannelApp => 'In the app';

  @override
  String get studentsMessageChannelEmail => 'By email';

  @override
  String get studentsMessageSend => 'Send';

  @override
  String studentsMessageSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sent to $count learners',
      one: 'Sent to 1 learner',
      zero: 'Nobody could be reached',
    );
    return '$_temp0';
  }

  @override
  String studentsMessageBodyTooShort(int count) {
    return 'Write at least $count characters so the message says something.';
  }

  @override
  String get studentTabOverview => 'Overview';

  @override
  String get studentTabCourses => 'Courses';

  @override
  String get studentTabProgress => 'Progress';

  @override
  String get studentTabActivity => 'Activity';

  @override
  String studentJoinedOn(String date) {
    return 'Joined $date';
  }

  @override
  String get studentSummaryTitle => 'How they are doing';

  @override
  String get studentStatEnrolled => 'Enrolled';

  @override
  String get studentStatActive => 'In progress';

  @override
  String get studentStatCompleted => 'Completed';

  @override
  String get studentStatAvgProgress => 'Average progress';

  @override
  String get studentStatStudyMinutes => 'Time studying';

  @override
  String get studentStatSubmissions => 'Hand-ins';

  @override
  String get studentStatAvgScore => 'Average score';

  @override
  String get studentCertificatesTitle => 'Certificates';

  @override
  String studentCertificateIssued(String date, String credential) {
    return 'Issued $date · $credential';
  }

  @override
  String get studentNoCertificates => 'No certificates yet.';

  @override
  String get studentCoursesEmpty => 'Not on any of your courses.';

  @override
  String studentCourseFacts(int chaptersDone, int chapters, int lessonsDone, int lessons) {
    return '$chaptersDone of $chapters chapters · $lessonsDone of $lessons lessons';
  }

  @override
  String studentNextUp(String title) {
    return 'Up next: $title';
  }

  @override
  String studentTaughtBy(String names) {
    return 'Taught by $names';
  }

  @override
  String get studentEnrolAction => 'Enrol in a course';

  @override
  String get studentEnrolConfirmTitle => 'Enrol this learner?';

  @override
  String get studentEnrolConfirmBody =>
      'They get access straight away and are told about it. The LMS sets how long access lasts.';

  @override
  String get studentEnrolled => 'They are enrolled';

  @override
  String get studentPauseAction => 'Pause';

  @override
  String get studentResumeAction => 'Resume';

  @override
  String get studentPauseConfirmTitle => 'Pause this enrolment?';

  @override
  String get studentPauseConfirmBody =>
      'They keep their progress but the course stops counting towards their standing.';

  @override
  String get studentPaused => 'The enrolment is paused';

  @override
  String get studentResumed => 'The enrolment is active again';

  @override
  String get studentRemoveAction => 'Remove';

  @override
  String get studentRemoveConfirmTitle => 'Remove this enrolment?';

  @override
  String get studentRemoveConfirmBody =>
      'They lose access to the course. Their progress goes with it.';

  @override
  String get studentRemoveAcknowledge => 'I understand their progress in this course will be lost';

  @override
  String get studentRemoved => 'The enrolment is removed';

  @override
  String get studentSuspendAction => 'Suspend';

  @override
  String get studentRestoreAction => 'Restore';

  @override
  String get studentSuspendConfirmTitle => 'Suspend this learner?';

  @override
  String get studentSuspendConfirmBody => 'They cannot sign in or learn until they are restored.';

  @override
  String get studentSuspendAcknowledge => 'I understand they will be signed out';

  @override
  String get studentSuspendReasonLabel => 'Why (only staff see this)';

  @override
  String get studentRestoreConfirmTitle => 'Restore this learner?';

  @override
  String get studentRestoreConfirmBody => 'They can sign in and carry on where they left off.';

  @override
  String get studentSuspended => 'The learner is suspended';

  @override
  String get studentRestored => 'The learner is restored';

  @override
  String get studentProgressEmpty => 'Nothing to show yet.';

  @override
  String get studentQuizzesTitle => 'Quizzes';

  @override
  String studentQuizBest(String percent, String passMark) {
    return 'Best $percent% of a pass mark of $passMark%';
  }

  @override
  String get studentAssignmentsTitle => 'Hand-ins';

  @override
  String get studentStudyWeeksTitle => 'Time studying, week by week';

  @override
  String get studentActivityEmpty => 'Nothing recorded yet.';

  @override
  String get studentActivityAll => 'Everything';

  @override
  String get studentContactTitle => 'How to reach them';

  @override
  String get studentStaffOnlyNote => 'Contact details are shown to staff only.';

  @override
  String get studentPhoneLabel => 'Phone';

  @override
  String get studentJoinedLabel => 'Joined';

  @override
  String get studentEmailLabel => 'Email';

  @override
  String get staffLiveTitle => 'Live classes';

  @override
  String get staffLiveSearch => 'Search classes';

  @override
  String get staffLiveTabUpcoming => 'Upcoming';

  @override
  String get staffLiveTabLive => 'Live now';

  @override
  String get staffLiveTabHistory => 'History';

  @override
  String get staffLiveTabCancelled => 'Cancelled';

  @override
  String get staffLiveEmptyTitle => 'Nothing scheduled';

  @override
  String get staffLiveEmptyBody =>
      'Schedule a class and the enrolled learners are told straight away.';

  @override
  String staffLivePageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get staffLiveScheduleAction => 'Schedule a class';

  @override
  String staffLiveRegisteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats taken',
      one: '1 seat taken',
      zero: 'No seats taken',
    );
    return '$_temp0';
  }

  @override
  String staffLiveOfCapacity(int taken, int capacity) {
    return '$taken of $capacity seats taken';
  }

  @override
  String get staffLiveAttendeesTitle => 'Who registered';

  @override
  String get staffLiveNoAttendees => 'Nobody has taken a seat yet.';

  @override
  String get staffLiveAttended => 'Came';

  @override
  String get staffLiveMissed => 'Did not come';

  @override
  String get staffLiveJoinAction => 'Open the meeting';

  @override
  String get staffLiveJoinNotReady => 'The join link opens 15 minutes before the start.';

  @override
  String get staffLiveRoomNote =>
      'Learners join in the app or on the web once you start the class. Attendance is taken as they join.';

  @override
  String get staffLiveStartAction => 'Start class';

  @override
  String get staffLiveRejoinAction => 'Rejoin as host';

  @override
  String get staffLiveEndAction => 'End class';

  @override
  String get staffLiveEndConfirmTitle => 'End this class?';

  @override
  String get staffLiveEndConfirmBody =>
      'The room closes and nobody else can join. Learners who held a place and never came are marked missed.';

  @override
  String get staffLiveEnded => 'Class ended. Attendance is saved.';

  @override
  String get staffLiveStartNote =>
      'Learners can join once you start the class. They are told the moment you do.';

  @override
  String get staffLiveStartNotYet =>
      'You can start the class from 15 minutes before its start time.';

  @override
  String staffLiveJoinedAt(String time) {
    return 'Joined $time';
  }

  @override
  String get staffLiveLinkUnusable =>
      'This class’s meeting link can’t be opened. Edit the class and paste the full link, starting with https://';

  @override
  String staffLiveOpenedLinkAt(String time) {
    return 'Opened the link $time';
  }

  @override
  String get staffLiveFormMeetingKind => 'Where the class runs';

  @override
  String get staffLiveMeetingRoom => 'Built-in live room';

  @override
  String get staffLiveMeetingExternal => 'Outside meeting link';

  @override
  String get staffLiveRecordingNone => 'The video service doesn’t record classes yet.';

  @override
  String get staffLiveRecordingHow =>
      'Start recording from the room’s menu. Learners can watch it here after the class.';

  @override
  String get staffLiveEditAction => 'Edit';

  @override
  String get staffLiveEditClosedStarted => 'A class that has started can no longer be edited.';

  @override
  String get staffLiveEditClosedCancelled => 'A cancelled class can no longer be edited.';

  @override
  String get staffLiveRemindAction => 'Remind them now';

  @override
  String staffLiveRemindSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners were reminded',
      one: '1 learner was reminded',
      zero: 'Nobody needed a reminder',
    );
    return '$_temp0';
  }

  @override
  String get staffLiveCancelAction => 'Cancel the class';

  @override
  String get staffLiveCancelConfirmTitle => 'Call this class off?';

  @override
  String get staffLiveCancelConfirmBody =>
      'Registered learners are told at once, with the reason you give.';

  @override
  String get staffLiveCancelReasonLabel => 'Why (learners see this)';

  @override
  String get staffLiveCancelled => 'The class is cancelled';

  @override
  String staffLiveCancelReason(String reason) {
    return 'Cancelled: $reason';
  }

  @override
  String get staffLiveRemindersTitle => 'When learners are reminded';

  @override
  String staffLiveReminderOffset(int minutes) {
    return '$minutes min before';
  }

  @override
  String staffLiveReminderHours(int hours) {
    return '$hours h before';
  }

  @override
  String get staffLiveReminderDay => 'A day before';

  @override
  String get staffLiveRemindersSaved => 'Reminders saved';

  @override
  String get staffLiveNewTitle => 'Schedule a class';

  @override
  String get staffLiveEditTitle => 'Edit the class';

  @override
  String get staffLiveFormCourse => 'Course';

  @override
  String get staffLiveFormTitle => 'Title';

  @override
  String get staffLiveFormInstructor => 'Who teaches it';

  @override
  String get staffLiveFormStart => 'Starts';

  @override
  String get staffLiveFormDuration => 'How long (minutes)';

  @override
  String staffLiveFormDurationHelp(int min, int max) {
    return 'Between $min and $max minutes.';
  }

  @override
  String get staffLiveFormCapacity => 'Seats (optional)';

  @override
  String get staffLiveFormDescription => 'What it covers';

  @override
  String get staffLiveFormVisibility => 'Who can see it';

  @override
  String get staffLiveVisibilityEnrolled => 'Learners on the course';

  @override
  String get staffLiveVisibilityCohort => 'The cohort';

  @override
  String get staffLiveVisibilityPublic => 'Anyone';

  @override
  String get staffLiveFormMeeting => 'Meeting link';

  @override
  String get staffLiveFormMeetingHelp => 'Starts with https://';

  @override
  String get staffLiveFormAgenda => 'What happens';

  @override
  String get staffLiveFormAgendaAdd => 'Add an item';

  @override
  String get staffLiveFormAgendaItem => 'Item';

  @override
  String get staffLiveFormAgendaMinutes => 'Minutes';

  @override
  String staffLiveFormAgendaTooLong(int agenda) {
    return 'The agenda runs $agenda minutes — longer than the class.';
  }

  @override
  String get staffLiveFormSave => 'Save';

  @override
  String get staffLiveFormSchedule => 'Schedule it';

  @override
  String get staffLiveScheduled => 'The class is scheduled and the learners are told';

  @override
  String get staffLiveSaved => 'The class is saved';

  @override
  String get staffLiveLeaveConfirmTitle => 'Leave without saving?';

  @override
  String get staffLiveLeaveConfirmBody => 'The class has not been saved.';

  @override
  String get staffLiveLeaveConfirmAction => 'Leave';

  @override
  String get staffLiveStartInPast => 'Choose a time later than now.';

  @override
  String staffLiveRecordingViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Watched $count times',
      one: 'Watched once',
    );
    return '$_temp0';
  }

  @override
  String get staffLiveFormAgendaRemove => 'Remove this item';

  @override
  String get staffLiveDetailsTitle => 'Class details';

  @override
  String get staffLiveFormSectionClass => 'The class';

  @override
  String get staffLiveFormSectionWhen => 'Date and length';

  @override
  String get staffLiveFormSectionWhere => 'Where it happens';

  @override
  String get staffLiveFormSectionLearners => 'For learners';

  @override
  String get staffCalendarDetailsTitle => 'Event details';

  @override
  String get staffCalendarFormSectionEvent => 'The event';

  @override
  String get staffCalendarFormSectionWhen => 'Date and time';

  @override
  String get staffCalendarFormSectionLinks => 'Audience and links';

  @override
  String get staffCalendarFormSectionNotes => 'Reminder and notes';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarToday => 'Today';

  @override
  String calendarWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get calendarMonthView => 'Month';

  @override
  String get calendarWeekView => 'Week';

  @override
  String get calendarDayEmpty => 'Nothing on this day';

  @override
  String get calendarRangeEmpty => 'Nothing in this range';

  @override
  String get calendarRangeEmptyBody =>
      'Live classes, deadlines and your own reminders appear here.';

  @override
  String get calendarTypeAll => 'Everything';

  @override
  String get calendarTypeLive => 'Live';

  @override
  String get calendarTypeAssignment => 'Deadlines';

  @override
  String get calendarTypeQuiz => 'Quizzes';

  @override
  String get calendarTypeMilestone => 'Milestones';

  @override
  String get calendarTypeReminder => 'Reminders';

  @override
  String get calendarAllDay => 'All day';

  @override
  String calendarMoment(String time) {
    return 'At $time';
  }

  @override
  String get calendarAddAction => 'Add to the calendar';

  @override
  String get calendarNewTitle => 'Add to the calendar';

  @override
  String get calendarEditTitle => 'Edit the event';

  @override
  String get calendarFormType => 'What it is';

  @override
  String get calendarFormTitle => 'Title';

  @override
  String get calendarFormDescription => 'Notes';

  @override
  String get calendarFormTiming => 'When';

  @override
  String get calendarTimingTimed => 'A time and a length';

  @override
  String get calendarTimingMoment => 'A moment';

  @override
  String get calendarTimingAllDay => 'The whole day';

  @override
  String get calendarFormStart => 'Starts';

  @override
  String get calendarFormDay => 'Day';

  @override
  String get calendarFormDuration => 'How long (minutes)';

  @override
  String calendarFormDurationHelp(int min) {
    return 'Between $min minutes and 12 hours.';
  }

  @override
  String get calendarFormCourse => 'Course';

  @override
  String get calendarFormChapter => 'Chapter';

  @override
  String get calendarFormQuiz => 'Quiz';

  @override
  String get calendarFormMilestone => 'What kind of milestone';

  @override
  String get calendarFormAudience => 'Who it is for';

  @override
  String get calendarAudienceMe => 'Only me';

  @override
  String get calendarAudienceLearners => 'The course’s learners';

  @override
  String get calendarFormNotify => 'Remind me';

  @override
  String get calendarNotifyNone => 'No reminder';

  @override
  String get calendarFormSave => 'Save';

  @override
  String get calendarFormAdd => 'Add it';

  @override
  String get calendarAdded => 'It is on the calendar';

  @override
  String get calendarSaved => 'The event is saved';

  @override
  String get calendarRemoveAction => 'Remove';

  @override
  String get calendarRemoveConfirmTitle => 'Remove this event?';

  @override
  String get calendarRemoveConfirmBody =>
      'It disappears from the calendar. Anyone it reminds will not be reminded.';

  @override
  String get calendarRemoved => 'The event is removed';

  @override
  String get calendarDoneAction => 'Mark it done';

  @override
  String get calendarUndoneAction => 'Not done after all';

  @override
  String get calendarDoneBadge => 'Done';

  @override
  String get calendarLeaveConfirmTitle => 'Leave without saving?';

  @override
  String get calendarLeaveConfirmBody => 'The event has not been saved.';

  @override
  String get calendarLeaveConfirmAction => 'Leave';

  @override
  String get calendarNotEditableLive => 'A live class is changed in Live classes.';

  @override
  String get calendarNotEditableAssignment => 'A deadline is changed on the assignment itself.';

  @override
  String get calendarNotEditableOther => 'This event belongs to someone else.';

  @override
  String get calendarOpenLive => 'Open the live class';

  @override
  String get calendarOpenSubmissions => 'See the hand-ins';

  @override
  String get calendarOpenQuiz => 'Open the quiz';

  @override
  String calendarAudienceSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners',
      one: '1 learner',
    );
    return '$_temp0';
  }

  @override
  String calendarDueSummary(int submitted, int learners) {
    return '$submitted of $learners have handed in';
  }

  @override
  String get calendarLearnersDueTitle => 'Still to hand in';

  @override
  String get calendarHandedIn => 'Handed in';

  @override
  String get calendarMilestoneCohortStarts => 'A cohort starts';

  @override
  String get calendarMilestoneChapterRelease => 'A chapter opens';

  @override
  String get calendarMilestoneEnrolmentCloses => 'Enrolment closes';

  @override
  String get calendarMilestoneCohortEnds => 'A cohort ends';

  @override
  String get calendarMilestoneCourseLaunch => 'A course launches';

  @override
  String get calendarStartInPast => 'Choose a time later than now.';

  @override
  String get calendarDayInPast => 'Choose a day that has not passed.';

  @override
  String calendarEventsOnDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String get instructorsSearch => 'Search by name or title';

  @override
  String get instructorsTabAll => 'All';

  @override
  String get instructorsTabActive => 'Active';

  @override
  String get instructorsTabInvited => 'Invited';

  @override
  String get instructorsTabInactive => 'Inactive';

  @override
  String get instructorsSortLabel => 'Sort by';

  @override
  String get instructorsSortName => 'Name';

  @override
  String get instructorsSortStudents => 'Most learners';

  @override
  String get instructorsSortRating => 'Highest rated';

  @override
  String get instructorsSortJoined => 'Recently joined';

  @override
  String get instructorsExpertiseLabel => 'Expertise';

  @override
  String get instructorsAllExpertise => 'Any expertise';

  @override
  String get instructorsEmptyTitle => 'No instructors yet';

  @override
  String get instructorsEmptyBody =>
      'Invite the first instructor and they will be sent a link to choose a password.';

  @override
  String get instructorsInviteAction => 'Invite an instructor';

  @override
  String instructorsCourseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses',
      one: '1 course',
      zero: 'No courses',
    );
    return '$_temp0';
  }

  @override
  String instructorsLearnerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners',
      one: '1 learner',
    );
    return '$_temp0';
  }

  @override
  String instructorsRating(String rating, int count) {
    return '$rating from $count ratings';
  }

  @override
  String get instructorsNotRated => 'Not rated yet';

  @override
  String instructorsCompletion(int percent) {
    return '$percent% complete the course';
  }

  @override
  String instructorsToReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to review',
      one: '1 to review',
    );
    return '$_temp0';
  }

  @override
  String instructorsOverdue(int count) {
    return '$count past the review window';
  }

  @override
  String get instructorTabOverview => 'Overview';

  @override
  String get instructorTabCourses => 'Courses';

  @override
  String get instructorTabPerformance => 'Performance';

  @override
  String get instructorAboutTitle => 'About';

  @override
  String get instructorNoBio => 'No bio yet. Learners see this on every course page.';

  @override
  String get instructorDetailsTitle => 'Details';

  @override
  String get instructorEmailLabel => 'Email';

  @override
  String get instructorPhoneLabel => 'Phone';

  @override
  String get instructorCityLabel => 'City';

  @override
  String get instructorLanguagesLabel => 'Teaches in';

  @override
  String get instructorYearsLabel => 'Years teaching';

  @override
  String get instructorJoinedLabel => 'Joined';

  @override
  String get instructorExpertiseTitle => 'Expertise';

  @override
  String get instructorReachTitle => 'Their learners';

  @override
  String get instructorReachStudents => 'Learners';

  @override
  String get instructorReachActive => 'Active';

  @override
  String get instructorReachCompleted => 'Completed';

  @override
  String get instructorReachNewThisMonth => 'New this month';

  @override
  String get instructorCitiesTitle => 'Where they are';

  @override
  String instructorCityLearners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners',
      one: '1 learner',
    );
    return '$_temp0';
  }

  @override
  String get instructorActivityTitle => 'Recent work';

  @override
  String get instructorActivityEmpty => 'Nothing recorded yet.';

  @override
  String get instructorCoursesEmpty => 'No courses assigned yet.';

  @override
  String get instructorRoleLead => 'Lead instructor';

  @override
  String get instructorRoleCo => 'Co-instructor';

  @override
  String instructorCourseEnrolled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enrolled',
      one: '1 enrolled',
    );
    return '$_temp0';
  }

  @override
  String instructorCourseActive(int count) {
    return '$count active in the last fortnight';
  }

  @override
  String instructorCourseLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
    );
    return '$_temp0';
  }

  @override
  String get instructorPerformanceRating => 'Rating';

  @override
  String get instructorPerformanceCompletion => 'Completion';

  @override
  String get instructorVsAcademy => 'vs the platform';

  @override
  String get instructorReviewTitle => 'Reviewing';

  @override
  String get instructorReviewMedian => 'Median turnaround';

  @override
  String instructorReviewMedianHours(int hours) {
    return '${hours}h';
  }

  @override
  String get instructorReviewOnTime => 'Inside 48 hours';

  @override
  String get instructorReviewed => 'Reviewed';

  @override
  String get instructorReviewWaiting => 'Waiting';

  @override
  String get instructorLiveTitle => 'Live teaching';

  @override
  String get instructorLiveDelivered => 'Delivered';

  @override
  String get instructorLiveUpcoming => 'Upcoming';

  @override
  String get instructorAttendance => 'Attendance';

  @override
  String get instructorEnrolmentsTitle => 'Enrolments by month';

  @override
  String get instructorNoFigureYet => '—';

  @override
  String get instructorEditAction => 'Edit details';

  @override
  String get instructorResendInviteAction => 'Send the invitation again';

  @override
  String instructorResendInviteSent(String email) {
    return 'Invitation sent to $email';
  }

  @override
  String get instructorMakeActiveAction => 'Make active';

  @override
  String get instructorMakeInactiveAction => 'Make inactive';

  @override
  String get instructorMakeActiveTitle => 'Make this instructor active?';

  @override
  String get instructorMakeActiveBody => 'They will be able to sign in and teach.';

  @override
  String get instructorMakeInactiveTitle => 'Make this instructor inactive?';

  @override
  String get instructorMakeInactiveBody =>
      'They will no longer be able to sign in. Their courses and their learners stay exactly as they are.';

  @override
  String get instructorStatusChanged => 'Status changed.';

  @override
  String get instructorFormInviteTitle => 'Invite an instructor';

  @override
  String get instructorFormEditTitle => 'Edit the instructor';

  @override
  String get instructorFormNameLabel => 'Full name';

  @override
  String get instructorFormTitleLabel => 'Professional title';

  @override
  String get instructorFormTitleHint => 'Senior Maths Faculty';

  @override
  String get instructorFormEmailLabel => 'Email';

  @override
  String get instructorFormEmailHelp => 'The invitation to choose a password is sent here.';

  @override
  String get instructorFormBioLabel => 'Bio';

  @override
  String get instructorFormBioHelp =>
      'At least 60 characters once they are active — learners read it on every course page.';

  @override
  String get instructorFormCityLabel => 'City';

  @override
  String get instructorFormPhoneLabel => 'Phone';

  @override
  String get instructorFormYearsLabel => 'Years teaching';

  @override
  String get instructorFormStatusLabel => 'Status';

  @override
  String get instructorFormStatusInvited => 'Invited — send them an invitation';

  @override
  String get instructorFormStatusActive => 'Active — they can sign in already';

  @override
  String get instructorFormStatusInactive => 'Inactive — no sign-in, no seat';

  @override
  String get instructorFormExpertiseLabel => 'Expertise';

  @override
  String get instructorFormExpertiseHint => 'Add an area of expertise';

  @override
  String get instructorFormLanguagesLabel => 'Languages';

  @override
  String get instructorFormLanguagesHint => 'Add a language';

  @override
  String get instructorFormCoursesLabel => 'Courses they teach';

  @override
  String get instructorFormCoursesHelp =>
      'They can edit these courses, run their live classes and review their submissions.';

  @override
  String get instructorFormNoPhoto =>
      'A photo is added on the web. Learners see their initials until then.';

  @override
  String get instructorFormSaveAction => 'Save the instructor';

  @override
  String get instructorFormInviteAction => 'Send the invitation';

  @override
  String get instructorFormAddTag => 'Add';

  @override
  String get staffInstructorsFormWhoTitle => 'Who they are';

  @override
  String get staffInstructorsFormProfileTitle => 'Their profile';

  @override
  String get instructorSaved => 'Instructor saved.';

  @override
  String get instructorInvited => 'Invitation sent.';

  @override
  String get instructorProblemName => 'Enter their full name.';

  @override
  String get instructorProblemTitle => 'Add a professional title.';

  @override
  String get instructorProblemEmail => 'Enter a valid email address.';

  @override
  String get instructorProblemPhone => 'Enter 8 to 15 digits, or leave it empty.';

  @override
  String get instructorProblemBio => 'Write a bio of at least 60 characters.';

  @override
  String get instructorProblemExpertise => 'Add at least one area of expertise.';

  @override
  String get instructorProblemLanguages => 'Add the languages they teach in.';

  @override
  String get instructorProblemYears => 'Years teaching should be between 0 and 70.';

  @override
  String get registerSearch => 'Search by learner, email or credential';

  @override
  String get registerTabAll => 'All';

  @override
  String get registerTabRevoked => 'Revoked';

  @override
  String get registerCourseLabel => 'Course';

  @override
  String get registerAllCourses => 'All courses';

  @override
  String get registerEmptyTitle => 'No certificates yet';

  @override
  String get registerEmptyBody =>
      'A certificate appears here once a learner finishes a course that awards one.';

  @override
  String registerRevokedOn(String date) {
    return 'Revoked $date';
  }

  @override
  String get registerPendingNote => 'Not issued yet. Nothing is public until it is.';

  @override
  String get registerIssueAction => 'Issue the certificate';

  @override
  String get registerIssueTitle => 'Issue this certificate?';

  @override
  String get registerIssueBody =>
      'The learner is told at once and the credential can be verified publicly from then on.';

  @override
  String get registerIssued => 'Certificate issued.';

  @override
  String get registerRevokeAction => 'Revoke';

  @override
  String get registerRevokeTitle => 'Revoke this certificate?';

  @override
  String get registerRevokeBody =>
      'The learner is told, and the reason you give is what they read. Public verification will show it as revoked.';

  @override
  String get registerRevokeReasonLabel => 'Reason';

  @override
  String get registerRevokeReasonHelp => 'At least 3 characters. The learner reads this.';

  @override
  String get registerRevoked => 'Certificate revoked.';

  @override
  String get registerRestoreAction => 'Restore';

  @override
  String get registerRestoreTitle => 'Restore this certificate?';

  @override
  String get registerRestoreBody => 'It goes back to issued, and the revocation reason is cleared.';

  @override
  String get registerRestored => 'Certificate restored.';

  @override
  String get registerRevokedReasonTitle => 'Why it was revoked';

  @override
  String get registerLearnerTitle => 'The learner';

  @override
  String get registerVerifyTitle => 'Public verification';

  @override
  String registerVerifyPath(String path) {
    return 'Anyone can check this credential at $path on the web.';
  }

  @override
  String get registerOpenLearner => 'Open the learner';

  @override
  String get instructorFormLeaveTitle => 'Leave without saving?';

  @override
  String get instructorFormLeaveBody =>
      'The changes to this instructor have not been sent to the LMS.';

  @override
  String get instructorFormLeaveAction => 'Leave';

  @override
  String registerPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get registerCredentialLabel => 'Credential';

  @override
  String get registerCompletedLabel => 'Finished';

  @override
  String get registerIssuedLabel => 'Issued';

  @override
  String get registerRevokedLabel => 'Revoked';

  @override
  String get registerLearnerNameLabel => 'Name';

  @override
  String get registerLearnerEmailLabel => 'Email';

  @override
  String get registerLearnerCityLabel => 'City';

  @override
  String get reportsTabOverview => 'Overview';

  @override
  String get reportsTabCourses => 'Courses';

  @override
  String get reportsTabLearners => 'Learners';

  @override
  String get reportsTabInstructors => 'Instructors';

  @override
  String get reportsTabEnrolments => 'Enrolments';

  @override
  String get reportsFiltersAction => 'Filters';

  @override
  String get reportsFiltersTitle => 'What these reports cover';

  @override
  String get reportsRangeLabel => 'Period';

  @override
  String get reportsRange30d => 'Last 30 days';

  @override
  String get reportsRange90d => 'Last 90 days';

  @override
  String get reportsRange6m => 'Last 6 months';

  @override
  String get reportsRange12m => 'Last 12 months';

  @override
  String get reportsSegmentLabel => 'Learners';

  @override
  String get reportsSegmentAll => 'All learners';

  @override
  String get reportsSegmentNew => 'New';

  @override
  String get reportsSegmentActive => 'Active';

  @override
  String get reportsSegmentAtRisk => 'At risk';

  @override
  String get reportsSegmentInactive => 'Inactive';

  @override
  String get reportsSegmentCompleters => 'Completed a course';

  @override
  String get reportsCategoryLabel => 'Category';

  @override
  String get reportsAllCategories => 'All categories';

  @override
  String get reportsCourseLabel => 'Course';

  @override
  String get reportsAllCourses => 'All courses';

  @override
  String get reportsInstructorLabel => 'Instructor';

  @override
  String get reportsAllInstructors => 'All instructors';

  @override
  String get reportsClearFilters => 'Clear the filters';

  @override
  String get reportsApplyFilters => 'Show the reports';

  @override
  String reportsCovering(String period, int courses) {
    String _temp0 = intl.Intl.pluralLogic(
      courses,
      locale: localeName,
      other: '$courses courses',
      one: '1 course',
    );
    return '$period · $_temp0';
  }

  @override
  String reportsNarrowedBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters',
      one: '1 filter',
    );
    return '$_temp0';
  }

  @override
  String reportsComparedWith(String period) {
    return 'vs the previous $period';
  }

  @override
  String get reportsNoFigure => '—';

  @override
  String get reportsEmptyTitle => 'Nothing to report yet';

  @override
  String get reportsEmptyBody => 'Once learners enrol and start work, their figures appear here.';

  @override
  String get reportsFilteredEmpty => 'No figures match these filters.';

  @override
  String get reportsReadOut => 'Read the figures';

  @override
  String get reportsEnrolments => 'Enrolments';

  @override
  String get reportsCompletions => 'Completions';

  @override
  String get reportsCompletionRate => 'Completion rate';

  @override
  String get reportsActiveLearners => 'Active learners';

  @override
  String get reportsAvgProgress => 'Average progress';

  @override
  String get reportsQuizzesTitle => 'Quizzes';

  @override
  String get reportsQuizAttempts => 'Attempts';

  @override
  String get reportsPassRate => 'Pass rate';

  @override
  String get reportsAvgScore => 'Average score';

  @override
  String get reportsAssignmentsTitle => 'Assignments';

  @override
  String get reportsSubmitted => 'Handed in';

  @override
  String get reportsOnTime => 'Reviewed on time';

  @override
  String get reportsReviewHours => 'Median review hours';

  @override
  String get reportsEngagementTitle => 'Engagement';

  @override
  String get reportsLessonsCompleted => 'Lessons finished';

  @override
  String get reportsLessonsPerLearner => 'Lessons per learner';

  @override
  String get reportsLiveAttendance => 'Live attendance';

  @override
  String get reportsProgressBandsTitle => 'How far learners have got';

  @override
  String get reportsCategoriesTitle => 'By category';

  @override
  String get reportsTopCoursesTitle => 'Busiest courses';

  @override
  String get reportsSeriesEnrolments => 'Enrolments over time';

  @override
  String get reportsSeriesCompletions => 'Completions over time';

  @override
  String get reportsSeriesActive => 'Active learners over time';

  @override
  String reportsBandLearners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners',
      one: '1 learner',
    );
    return '$_temp0';
  }

  @override
  String reportsCategoryEnrolments(int count, int rate) {
    return '$count enrolled · $rate% complete';
  }

  @override
  String reportsCategoryEnrolmentsOnly(int count) {
    return '$count enrolled';
  }

  @override
  String reportsCourseEnrolments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enrolments',
      one: '1 enrolment',
    );
    return '$_temp0';
  }

  @override
  String reportsCoursePrevious(int count) {
    return '$count in the previous period';
  }

  @override
  String reportsCourseActive(int count) {
    return '$count active';
  }

  @override
  String reportsCourseCompletions(int count) {
    return '$count completed';
  }

  @override
  String reportsCourseRating(String rating) {
    return 'Rated $rating';
  }

  @override
  String get reportsCoursesEmpty => 'No course had any activity in this period.';

  @override
  String get reportsOpenCourseReport => 'Open the course report';

  @override
  String get reportsCourseFunnelTitle => 'How far the intake got';

  @override
  String get reportsCourseChaptersTitle => 'Chapters reached';

  @override
  String reportsCourseChapterReached(int percent) {
    return '$percent% reached it';
  }

  @override
  String get reportsCourseQuizzesTitle => 'Quizzes in this course';

  @override
  String get reportsCourseAssignmentsTitle => 'Assignments in this course';

  @override
  String reportsQuizSummary(int attempts, int pass) {
    return '$attempts attempts · $pass% passed';
  }

  @override
  String reportsAssignmentSummary(int submitted, int pass) {
    return '$submitted handed in · $pass% passed';
  }

  @override
  String get reportsCourseNotFound =>
      'There is no report for this course — it may still be a draft.';

  @override
  String get reportsLearnersCount => 'Learners';

  @override
  String get reportsLearnersActive => 'Active';

  @override
  String get reportsLearnersAtRisk => 'At risk';

  @override
  String get reportsLearnerSearch => 'Search learners';

  @override
  String get reportsSortLabel => 'Order by';

  @override
  String get reportsSortName => 'Name';

  @override
  String get reportsSortCourses => 'Courses';

  @override
  String get reportsSortProgress => 'Progress';

  @override
  String get reportsSortAssignments => 'Assignment average';

  @override
  String get reportsSortLastActive => 'Last seen';

  @override
  String get reportsSortDescending => 'Highest first';

  @override
  String get reportsSortAscending => 'Lowest first';

  @override
  String reportsLearnerCourses(int courses, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      courses,
      locale: localeName,
      other: '$courses courses',
      one: '1 course',
    );
    return '$_temp0 · $completed completed';
  }

  @override
  String reportsLearnerProgress(int percent) {
    return '$percent% through';
  }

  @override
  String reportsLearnerAssignments(int percent) {
    return 'Assignments $percent%';
  }

  @override
  String reportsLearnerLastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String get reportsLearnerNeverSeen => 'Not seen yet';

  @override
  String get reportsStatusesTitle => 'Where learners stand';

  @override
  String get reportsLearnersEmpty => 'No learner matches this search.';

  @override
  String reportsPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get reportsSelfShare => 'Enrolled themselves';

  @override
  String get reportsSourcesTitle => 'Where enrolments came from';

  @override
  String get reportsSourceSelf => 'Learner themselves';

  @override
  String get reportsSourceAdmin => 'Added by the LMS';

  @override
  String get reportsSourceImport => 'Imported';

  @override
  String get reportsSourceGift => 'Gifted';

  @override
  String reportsSourceSummary(int count, int share) {
    return '$count · $share% of all';
  }

  @override
  String get reportsCohortsTitle => 'Each month’s intake';

  @override
  String reportsCohortEnrolled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enrolled',
      one: '1 enrolled',
    );
    return '$_temp0';
  }

  @override
  String reportsCohortWithin(int days) {
    return 'Finished within $days days';
  }

  @override
  String get reportsCohortToDate => 'Finished so far';

  @override
  String get reportsInstructorsTitle => 'How the teaching is going';

  @override
  String get reportsInstructorReviews => 'Reviews';

  @override
  String get reportsInstructorReviewHours => 'Median review hours';

  @override
  String get reportsInstructorOnTime => 'Reviewed on time';

  @override
  String get reportsInstructorAttendance => 'Live attendance';

  @override
  String reportsInstructorSummary(int courses, int learners) {
    String _temp0 = intl.Intl.pluralLogic(
      courses,
      locale: localeName,
      other: '$courses courses',
      one: '1 course',
    );
    String _temp1 = intl.Intl.pluralLogic(
      learners,
      locale: localeName,
      other: '$learners learners',
      one: '1 learner',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get reportsInstructorsEmpty => 'No instructor had activity in this period.';

  @override
  String get reportsPeriod30d => '30 days';

  @override
  String get reportsPeriod90d => '90 days';

  @override
  String get reportsPeriod6m => '6 months';

  @override
  String get reportsPeriod12m => '12 months';

  @override
  String get billingTitle => 'Your plan';

  @override
  String get billingNoPlanTitle => 'Your LMS isn’t on a plan yet';

  @override
  String get billingNoPlanBody =>
      'Everything you have stays as it is. A plan adds room to grow, and the LMS will tell you what each one includes.';

  @override
  String get billingSeePlans => 'See the plans';

  @override
  String get billingUpgradeAction => 'Upgrade to a paid plan';

  @override
  String get billingPlanCycleMonthly => 'Billed monthly';

  @override
  String get billingPlanCycleAnnual => 'Billed yearly';

  @override
  String billingRenewsOn(String date) {
    return 'Renews $date';
  }

  @override
  String billingEndsOn(String date) {
    return 'Ends $date';
  }

  @override
  String billingTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days of your trial left',
      one: '1 day of your trial left',
      zero: 'Your trial ends today',
    );
    return '$_temp0';
  }

  @override
  String get billingPastDueTitle => 'A payment didn’t go through';

  @override
  String billingPastDueBody(String amount, String date) {
    return 'Your account owes $amount. Access stays open until $date.';
  }

  @override
  String billingRetryOn(String date) {
    return 'The next attempt is $date';
  }

  @override
  String billingCancelingTitle(String date) {
    return 'Your plan ends $date';
  }

  @override
  String get billingCancelingBody => 'Everything keeps working until then.';

  @override
  String get billingPausedTitle => 'Your plan is paused';

  @override
  String billingPausedResumes(String date) {
    return 'It resumes $date';
  }

  @override
  String get billingExpiredTitle => 'Your plan has ended';

  @override
  String get billingExpiredBody =>
      'You keep and can edit everything you have. Renewing reopens the room to add more.';

  @override
  String get billingNotEnforcedNote =>
      'Plan limits aren’t enforced yet, so nothing is being blocked.';

  @override
  String get billingUsageTitle => 'What you’re using';

  @override
  String billingUsageOf(String used, String allowed) {
    return '$used of $allowed';
  }

  @override
  String get billingUnlimited => 'Unlimited';

  @override
  String billingUsageRemaining(int count) {
    return '$count left';
  }

  @override
  String get billingUsageFull => 'Nothing left';

  @override
  String get billingFeaturesTitle => 'What your plan includes';

  @override
  String get billingFeatureIncluded => 'Included';

  @override
  String get billingFeatureNotIncluded => 'Not included';

  @override
  String get billingFeaturePlanned => 'Coming soon';

  @override
  String get billingInvoicesTitle => 'Invoices';

  @override
  String get billingInvoicesEmpty => 'No invoices yet.';

  @override
  String get billingPaymentsTitle => 'Payments';

  @override
  String get billingPaymentsEmpty => 'No payments yet.';

  @override
  String billingOpenChangeUpgradeTitle(String plan) {
    return 'An upgrade to $plan is waiting to be paid';
  }

  @override
  String billingOpenChangeScheduledTitle(String plan, String date) {
    return 'Moving to $plan on $date';
  }

  @override
  String billingOpenChangeCharge(String amount) {
    return '$amount to pay now';
  }

  @override
  String billingOpenChangeCredit(String amount) {
    return '$amount credited from what you have already paid';
  }

  @override
  String get billingOpenChangeGiveUp => 'Give up this change';

  @override
  String get billingOpenChangeGiveUpTitle => 'Give up this plan change?';

  @override
  String get billingOpenChangeGiveUpBody =>
      'The quote is withdrawn. Nothing you have now changes, and you can ask again at any time.';

  @override
  String get billingOpenChangeGaveUp => 'The plan change was given up.';

  @override
  String get billingChangePlanAction => 'Change plan';

  @override
  String get billingCancelAction => 'Cancel the plan';

  @override
  String get billingCancelTitle => 'Cancel at the end of the period?';

  @override
  String get billingCancelBody =>
      'Everything keeps working until the period ends. After that the LMS keeps what it has and cannot add more until it renews.';

  @override
  String get billingCancelReasonLabel => 'Why are you cancelling?';

  @override
  String get billingCancelReasonHelp => 'At least 3 characters. The LMS keeps this on its record.';

  @override
  String get billingCanceled => 'Your plan will end when the period does.';

  @override
  String get billingResumeAction => 'Resume the plan';

  @override
  String get billingResumeTitle => 'Resume this plan?';

  @override
  String get billingResumeBody =>
      'The plan carries on as it was, and billing resumes on its usual date.';

  @override
  String get billingResumed => 'Your plan is running again.';

  @override
  String get billingPaymentUnavailable =>
      'Online payment isn’t available yet. The platform team will tell you when it is.';

  @override
  String get billingPayInvoiceAction => 'Pay this invoice';

  @override
  String get billingPayChangeAction => 'Pay for this upgrade';

  @override
  String get billingPaymentNotCompleted =>
      'Payment not completed. Nothing has changed — you can try again.';

  @override
  String get billingPaymentWaiting => 'Your bank hasn’t settled this yet. Checking again…';

  @override
  String get billingBilledTo => 'Billed to';

  @override
  String get billingPaymentMethod => 'Paid by';

  @override
  String invoiceTitle(String number) {
    return 'Invoice $number';
  }

  @override
  String invoicePeriod(String from, String to) {
    return '$from to $to';
  }

  @override
  String invoiceIssued(String date) {
    return 'Issued $date';
  }

  @override
  String invoicePaidOn(String date) {
    return 'Paid $date';
  }

  @override
  String get invoiceLinesTitle => 'What this covers';

  @override
  String invoiceLineQuantity(int count) {
    return '×$count';
  }

  @override
  String get invoiceSubtotal => 'Subtotal';

  @override
  String get invoiceTax => 'Tax';

  @override
  String invoiceTaxPercent(String percent) {
    return 'Tax ($percent%)';
  }

  @override
  String get invoiceTotal => 'Total';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusPending => 'Open';

  @override
  String get invoiceStatusFailed => 'Failed';

  @override
  String get invoiceStatusRefunded => 'Refunded';

  @override
  String get invoiceStatusVoid => 'Withdrawn';

  @override
  String get invoiceAmountsMissing => 'This invoice’s totals were not sent.';

  @override
  String get plansTitle => 'Plans';

  @override
  String get plansEmpty => 'No plans are on sale right now.';

  @override
  String plansPerMonth(String amount) {
    return '$amount a month';
  }

  @override
  String plansPerYear(String amount) {
    return '$amount a year';
  }

  @override
  String plansTrial(int days) {
    return '$days-day free trial';
  }

  @override
  String get plansLimitsTitle => 'What it allows';

  @override
  String get plansFeaturesTitle => 'What it includes';

  @override
  String get plansCurrentPlan => 'Your plan';

  @override
  String get plansChooseMonthly => 'Choose monthly';

  @override
  String get plansChooseAnnual => 'Choose yearly';

  @override
  String get plansQuoted => 'This change has been quoted.';

  @override
  String get plansLimitUnlimited => 'Unlimited';

  @override
  String get plansSubscribeMonthly => 'Subscribe monthly';

  @override
  String get plansSubscribeAnnual => 'Subscribe yearly';

  @override
  String get billingInvoiceReadyTitle => 'Your invoice is ready';

  @override
  String billingInvoiceReady(String number, String amount) {
    return 'Your invoice $number for $amount is ready. Online payment isn’t available right now, so it stays open until it is.';
  }

  @override
  String get billingPaymentNotOffered => 'Online payment isn’t available right now';

  @override
  String get billingCheckoutHostedTitle => 'Finish paying on the payment page';

  @override
  String get billingCheckoutHostedBody =>
      'The payment page opened outside the app. Your plan changes here only once the payment is confirmed to the platform.';

  @override
  String get billingCheckoutConfirmed => 'The payment is confirmed.';

  @override
  String get billingDetailsTitle => 'Billing details';

  @override
  String get billingDetailsBody =>
      'Invoices are addressed to these details, and tax is worked out from the country and region.';

  @override
  String get billingDetailsLegalName => 'Name to bill';

  @override
  String get billingDetailsEmail => 'Email for invoices';

  @override
  String get billingDetailsAddressLine1 => 'Street address';

  @override
  String get billingDetailsAddressLine2 => 'Address line 2';

  @override
  String get billingDetailsCity => 'City';

  @override
  String get billingDetailsRegion => 'Region code';

  @override
  String get billingDetailsPostalCode => 'Postal code';

  @override
  String get billingDetailsCountry => 'Country code';

  @override
  String get billingDetailsTaxRegistration => 'Tax registration';

  @override
  String get billingDetailsSave => 'Save billing details';

  @override
  String get billingDetailsSaved => 'Billing details saved.';

  @override
  String get billingDetailsErrorLegalName => 'Give the name the LMS bills under.';

  @override
  String get billingDetailsErrorEmail => 'Give an email address for invoices.';

  @override
  String get billingDetailsErrorAddress => 'Give the street address.';

  @override
  String get billingDetailsErrorCity => 'Give the city.';

  @override
  String get billingDetailsErrorPostalCode => 'Give the postal code.';

  @override
  String get billingDetailsErrorCountry => 'Choose the country by its two-letter code, e.g. IN.';

  @override
  String get billingDetailsErrorRegion => 'A region is a short code, e.g. KA.';

  @override
  String get billingDetailsErrorTax => 'A tax registration is 3–32 letters, digits or hyphens.';

  @override
  String get billingDetailsNeeded =>
      'This change is charged, and its tax depends on the LMS’s billing address. Add it first.';

  @override
  String get billingDetailsAddAction => 'Add billing details';

  @override
  String planChangeTitle(String plan) {
    return 'Move to $plan';
  }

  @override
  String get planChangeCredit => 'Credit for the time already paid';

  @override
  String get planChangeNet => 'Charge';

  @override
  String get planChangeTax => 'Tax';

  @override
  String get planChangeTotal => 'Total to pay';

  @override
  String get planChangeAppliesOnPayment => 'It applies as soon as it is paid.';

  @override
  String planChangeAppliesOn(String date) {
    return 'It applies on $date. Nothing is charged now.';
  }

  @override
  String get planChangeConflictsTitle => 'Already over the new plan’s limits';

  @override
  String planChangeConflict(String limit, int usage, int allowed) {
    return '$limit: you use $usage, the new plan allows $allowed';
  }

  @override
  String get planChangeConfirm => 'Ask for this change';

  @override
  String get planChangeContinueToPayment => 'Continue to payment';

  @override
  String get pastDueBannerTitle => 'Payment overdue';

  @override
  String get pastDueBannerBody => 'A payment for your LMS plan didn’t go through.';

  @override
  String get actionOpenBilling => 'Open billing';

  @override
  String get moduleCoursesName => 'Courses';

  @override
  String get moduleQuizzesName => 'Quizzes';

  @override
  String get moduleAssignmentsName => 'Assignments';

  @override
  String get moduleCertificatesName => 'Certificates';

  @override
  String get moduleLiveName => 'Live classes';

  @override
  String get moduleReportsName => 'Reports';

  @override
  String get moduleBrandingName => 'Custom branding';

  @override
  String get moduleCoursesDescription =>
      'Build courses with chapters and lessons, and publish them to your learners.';

  @override
  String get moduleQuizzesDescription => 'Create quizzes and see how your learners score.';

  @override
  String get moduleAssignmentsDescription =>
      'Set assignments and review and grade what learners hand in.';

  @override
  String get moduleCertificatesDescription =>
      'Issue, verify and manage the certificates your learners earn.';

  @override
  String get moduleLiveDescription =>
      'Schedule live classes, send reminders and teach in real time.';

  @override
  String get moduleReportsDescription => 'See how your courses, learners and enrolments are doing.';

  @override
  String get moduleBrandingDescription => 'Give your LMS its own look.';

  @override
  String get restrictedBannerBodyNew =>
      'Start a free trial or choose a plan to open courses, classes and more.';

  @override
  String get actionChoosePlan => 'Choose a plan';

  @override
  String get actionSeePlans => 'See plans';

  @override
  String trialBannerTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Free trial · $days days left',
      one: 'Free trial · 1 day left',
      zero: 'Free trial · ends today',
    );
    return '$_temp0';
  }

  @override
  String get trialBannerBody => 'Choose a plan before it ends to keep everything open.';

  @override
  String trialBannerBodyPlan(String plan) {
    return 'You’re trying $plan. Choose a plan before it ends.';
  }

  @override
  String readOnlyBannerTitle(String module) {
    return '$module is read-only';
  }

  @override
  String get readOnlyBannerBodyAdmin =>
      'Your plan no longer includes it. What you made stays readable; adding new needs a plan.';

  @override
  String get readOnlyBannerBodyMember =>
      'Your LMS plan no longer includes it. What you made stays readable; ask your admin to renew.';

  @override
  String readOnlyActionReason(String module) {
    return 'Adding to $module needs an active plan.';
  }

  @override
  String get navLockedHint => 'Locked. Upgrade the plan to use it.';

  @override
  String get navReadOnlyHint => 'Read-only';

  @override
  String get navUpgradeBadge => 'Upgrade';

  @override
  String get navReadOnlyBadge => 'Read-only';

  @override
  String get academySetupTitle => 'Your LMS is being set up';

  @override
  String academySetupBody(String module) {
    return 'Your admin is choosing a plan. $module will open here as soon as they do.';
  }

  @override
  String get limitLearners => 'Learners';

  @override
  String get limitInstructors => 'Instructors';

  @override
  String get limitCourses => 'Courses';

  @override
  String get limitStorage => 'Media storage';

  @override
  String get limitLiveClasses => 'Live classes a month';

  @override
  String get limitAdminAccounts => 'Admin accounts';

  @override
  String limitStorageGb(String size) {
    return '$size GB';
  }

  @override
  String limitStorageMb(String size) {
    return '$size MB';
  }

  @override
  String get featureCoursesManage => 'Course management';

  @override
  String get featureAssessmentsManage => 'Quizzes and assignments';

  @override
  String get featureCertificatesManage => 'Certificates';

  @override
  String get featureLiveClasses => 'Live classes';

  @override
  String get featureReportsBasic => 'Reports';

  @override
  String get featureReportsAdvanced => 'Advanced reports';

  @override
  String get featureAnalyticsAdvanced => 'Advanced analytics';

  @override
  String get featureCustomBranding => 'Custom branding';

  @override
  String get featurePrioritySupport => 'Priority support';

  @override
  String get trialErrorPlanUnavailable =>
      'This plan doesn’t offer a free trial any more. The plans have been refreshed.';

  @override
  String get trialErrorAlreadySubscribed =>
      'Your LMS already has a plan or has used its free trial. The plans have been refreshed.';

  @override
  String get onboardingAppBarTitle => 'Get started';

  @override
  String get onboardingTitle => 'Welcome! Choose a plan to get started';

  @override
  String onboardingTitleAcademy(String academy) {
    return 'Welcome to $academy';
  }

  @override
  String get onboardingBodyTrial =>
      'Start a free trial to open courses, quizzes, live classes and more. No payment needed — choose a paid plan any time.';

  @override
  String get onboardingBody => 'Choose a plan to open courses, quizzes, live classes and more.';

  @override
  String get onboardingNoBillingEdit =>
      'Only an admin who can change billing can start a plan. Ask them to choose one.';

  @override
  String get onboardingTrialUsed => 'Your LMS has already used its free trial.';

  @override
  String get onboardingNoPlansTitle => 'No plans on sale';

  @override
  String get onboardingCycleLabel => 'Billing cycle';

  @override
  String get onboardingCycleMonthly => 'Monthly';

  @override
  String get onboardingCycleAnnual => 'Yearly';

  @override
  String get onboardingNotSoldMonthly => 'Not sold monthly';

  @override
  String get onboardingNotSoldAnnual => 'Not sold yearly';

  @override
  String onboardingStartTrial(int days) {
    return 'Start $days-day free trial';
  }

  @override
  String onboardingBuy(String price) {
    return 'Buy for $price';
  }

  @override
  String get onboardingPaymentUnavailable =>
      'Paid plans can’t be bought in the app right now. You can still start a free trial.';

  @override
  String get onboardingNotNow => 'Not now — go to the dashboard';

  @override
  String get onboardingTrialStartedTitle => 'Your free trial has started';

  @override
  String get onboardingTrialStartedBody =>
      'Everything in the plan is open. Choose a paid plan any time before the trial ends.';

  @override
  String onboardingTrialStartedUntil(String date) {
    return 'Everything in the plan is open until $date. Choose a paid plan any time before then.';
  }

  @override
  String get onboardingGoToDashboard => 'Go to the dashboard';

  @override
  String get onboardingAlreadyOnPlanTitle => 'Your LMS is on a plan';

  @override
  String trialOfferTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Try a plan free for $days days',
      one: 'Try a plan free for 1 day',
    );
    return '$_temp0';
  }

  @override
  String get trialOfferBody =>
      'Start a free trial to see everything your LMS can do. No payment needed.';

  @override
  String get trialOfferDismiss => 'Dismiss the free trial offer';

  @override
  String get trialOfferAction => 'See plans and start a trial';

  @override
  String get planGateLockedTitle => 'Not included in your LMS plan';

  @override
  String get planGateAskAdmin => 'Ask your admin to upgrade the plan.';

  @override
  String get planGateNoPlanIncludes => 'No plan on sale includes this yet.';

  @override
  String get planGateIncludedIn => 'Included in';

  @override
  String get planGatePlansUnavailable => 'The plans couldn’t be loaded.';

  @override
  String get reportsSourcePurchase => 'Purchased';

  @override
  String get coursePriceNotOpen => 'Not open yet';

  @override
  String get courseSaleUnavailable => 'Not open for enrolment yet';

  @override
  String get courseNotSoldInApp => 'This course can’t be bought in the app.';

  @override
  String actionBuyCourse(String price) {
    return 'Buy course · $price';
  }

  @override
  String actionPayAmount(String price) {
    return 'Pay $price';
  }

  @override
  String get purchaseSummaryTitle => 'Order summary';

  @override
  String get purchaseSummaryCourse => 'Course';

  @override
  String get purchaseSummaryTotal => 'Total';

  @override
  String get purchaseSummaryAllInclusive => 'All-inclusive price';

  @override
  String get purchaseSummaryNote => 'The course opens as soon as your payment is confirmed.';

  @override
  String get purchaseStarting => 'Opening the payment…';

  @override
  String get purchaseAtGateway => 'Finish paying in the payment window.';

  @override
  String get purchaseConfirming => 'Confirming your payment…';

  @override
  String get purchaseWaiting =>
      'Your payment is being confirmed. The course opens as soon as it is.';

  @override
  String get purchaseStillWaiting =>
      'Your payment is still being confirmed. The course opens as soon as it is, even if you leave this page.';

  @override
  String get purchaseAwayAtPage => 'Finish paying on the payment page, then come back here.';

  @override
  String get purchasePaid => 'Payment confirmed. The course is open.';

  @override
  String get purchaseFailed =>
      'The payment didn’t go through, so the course wasn’t opened. You can try again.';

  @override
  String get purchaseCancelled => 'Payment cancelled. You weren’t charged.';

  @override
  String get purchaseOffline => 'We’ll confirm your payment when you’re back online.';

  @override
  String get purchaseNotSetUp => 'Online payments aren’t available yet.';

  @override
  String get purchaseNotForSale => 'This course isn’t open for enrolment yet.';

  @override
  String get purchaseAlreadyEnrolled => 'You already have this course.';

  @override
  String get purchaseUnsupported => 'This payment can’t be completed in this version of the app.';

  @override
  String get purchaseRefused => 'The payment couldn’t be started.';

  @override
  String get actionCheckAgain => 'Check again';

  @override
  String get purchasesTitle => 'Purchases';

  @override
  String get purchasesSubtitle => 'Courses you’ve bought';

  @override
  String get purchasesEmptyTitle => 'No purchases yet';

  @override
  String get purchasesEmptyBody => 'Courses you buy are listed here.';

  @override
  String get purchaseNeedsReview => 'This payment is being reviewed.';

  @override
  String quizTotalPoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marks',
      one: '1 mark',
    );
    return '$_temp0';
  }

  @override
  String get quizNoTimeLimit => 'No time limit';

  @override
  String quizAttemptsUsedOf(int used, int allowed) {
    return '$used of $allowed attempts used';
  }

  @override
  String quizAttemptsUsedUnlimited(int used) {
    String _temp0 = intl.Intl.pluralLogic(
      used,
      locale: localeName,
      other: '$used attempts used',
      one: '1 attempt used',
      zero: 'No attempts used',
    );
    return '$_temp0 · no limit';
  }

  @override
  String quizOpensAt(String time) {
    return 'Opens $time';
  }

  @override
  String quizClosesAt(String time) {
    return 'Closes $time';
  }

  @override
  String quizClosedAt(String time) {
    return 'Closed $time';
  }

  @override
  String get quizNegativeMarkingNotice =>
      'Wrong answers lose marks. Leaving a question blank costs nothing.';

  @override
  String get quizResultsAfterClose => 'Results are shown once the quiz closes.';

  @override
  String get quizPassedPractice => 'You’ve passed. Further attempts are practice.';

  @override
  String get actionResumeQuiz => 'Resume the quiz';

  @override
  String quizAttemptUnderWay(int number) {
    return 'Attempt $number is under way.';
  }

  @override
  String get quizStartTimedNotice =>
      'The timer starts when you tap Start and keeps running if you leave the app.';

  @override
  String get quizStartUsesAttempt => 'Starting uses one attempt.';

  @override
  String get quizStandingFailed => 'We couldn’t check your attempts.';

  @override
  String quizNotOpenUntil(String time) {
    return 'This quiz opens $time.';
  }

  @override
  String get quizNoLongerOpen => 'This quiz is no longer open for attempts.';

  @override
  String get quizStartFailed => 'The quiz didn’t start. Check your connection and try again.';

  @override
  String quizTimerSemantics(String time) {
    return 'Time left: $time';
  }

  @override
  String get quizWarnFiveMinutes => '5 minutes left.';

  @override
  String get quizWarnOneMinute =>
      '1 minute left. Your saved answers are handed in when time runs out.';

  @override
  String get quizSaveUnsaved => 'Not saved yet';

  @override
  String get quizSaveSaving => 'Saving…';

  @override
  String get quizSaveSaved => 'Saved';

  @override
  String get quizSaveRetrying => 'Retrying…';

  @override
  String get quizSaveFailed => 'Not saved';

  @override
  String get quizSaveUnsavedHint => 'Answered on this phone, not saved yet.';

  @override
  String get quizSaveSavingHint => 'Sending your answers to the server.';

  @override
  String get quizSaveSavedHint => 'Your answers are saved on the server.';

  @override
  String get quizSaveRetryingHint => 'Couldn’t reach the server. Trying again.';

  @override
  String get quizSaveFailedHint => 'Your latest answers are not saved.';

  @override
  String get quizOfflineBanner =>
      'You’re offline. Your answers stay on this phone and are saved when you reconnect. The timer keeps running.';

  @override
  String quizPaletteItem(int number, String status) {
    return 'Question $number, $status';
  }

  @override
  String quizPaletteCurrent(int number, String status) {
    return 'Question $number, $status, on screen';
  }

  @override
  String quizQuestionMarks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marks',
      one: '1 mark',
    );
    return '$_temp0';
  }

  @override
  String quizQuestionNegative(String marks, String negative) {
    return '$marks · a wrong answer costs $negative';
  }

  @override
  String get quizAnsweredNotSaved => 'Answered · not saved yet';

  @override
  String get actionBackToQuestions => 'Back to questions';

  @override
  String get quizSubmitFailed =>
      'Couldn’t hand in your attempt. Your saved answers are safe — try again.';

  @override
  String get quizHandingIn => 'Handing in your attempt…';

  @override
  String get quizHandInRetrying => 'Still handing in — waiting for the connection.';

  @override
  String get quizReceivedTitle => 'Attempt handed in';

  @override
  String quizResultPercent(int percent) {
    return '$percent%';
  }

  @override
  String quizResultPoints(String points, String max) {
    return '$points of $max marks';
  }

  @override
  String quizResultPassMark(int passMark) {
    return 'Pass mark $passMark%';
  }

  @override
  String quizResultSemantics(int percent, String points, String max) {
    return 'Score $percent percent, $points of $max marks';
  }

  @override
  String get quizKeyWithheld => 'Correct answers are shown once you pass or have no attempts left.';

  @override
  String quizResultsHeldUntil(String time) {
    return 'Your attempt is in. Results are shown on $time.';
  }

  @override
  String get quizResultsHidden => 'Your attempt is in. This quiz doesn’t show scores.';

  @override
  String get quizExpiredNotice => 'Time ran out — your saved answers were marked.';

  @override
  String get quizNegativeScoreNote => 'Wrong answers cost marks, so a total can fall below zero.';

  @override
  String get quizBreakdownTitle => 'Question by question';

  @override
  String get quizAnswerCorrect => 'Correct';

  @override
  String get quizAnswerIncorrect => 'Wrong';

  @override
  String get quizAnswerPartial => 'Partly right';

  @override
  String get quizAnswerUnanswered => 'Not answered';

  @override
  String quizQuestionNumber(int number) {
    return 'Question $number';
  }

  @override
  String quizQuestionScored(String marks) {
    return '$marks marks';
  }

  @override
  String quizYourAnswer(String answer) {
    return 'Your answer: $answer';
  }

  @override
  String quizRightAnswer(String answer) {
    return 'Answer: $answer';
  }

  @override
  String get quizHistoryTitle => 'Your attempts';

  @override
  String quizHistoryAttempt(int number) {
    return 'Attempt $number';
  }

  @override
  String get quizHistoryExpired => 'Time ran out';

  @override
  String get quizHistoryHeld => 'Result after the quiz closes';

  @override
  String get quizHistoryReceived => 'Handed in';

  @override
  String get quizResultUnavailable => 'Your attempt was handed in. We couldn’t load the result.';

  @override
  String get quizLeaveTitle => 'Leave the quiz?';

  @override
  String get quizLeaveBodyTimed => 'Your answers are saved; the timer keeps running.';

  @override
  String get quizLeaveBodyUntimed => 'Your answers are saved. You can come back and finish.';

  @override
  String get quizLeaveUnsaved => 'Answers not saved yet are sent as you leave.';

  @override
  String get quizLeaveAction => 'Leave';

  @override
  String assessmentInProgressDeadline(String time) {
    return 'Hand in by $time';
  }

  @override
  String assessmentOpensAt(String time) {
    return 'Opens $time';
  }

  @override
  String assessmentClosedAt(String time) {
    return 'Closed $time';
  }

  @override
  String assessmentClosesAt(String time) {
    return 'Closes $time';
  }

  @override
  String get assessmentResultsHeld => 'Score shown after the quiz closes';

  @override
  String get staffQuizStatusArchived => 'Archived';

  @override
  String get assessmentNegativeMarking => 'Negative marking: wrong answers lose marks';

  @override
  String assessmentResultsHeldUntil(String time) {
    return 'Score shown $time';
  }
}
