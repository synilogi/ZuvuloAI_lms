import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get actionGoHome;

  /// No description provided for @actionClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get actionClearFilters;

  /// A list's Filters button, and the title of the sheet it opens.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get actionFilters;

  /// The Filters button's label while some of a list's filters are on.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Filters, 1 on} other{Filters, {count} on}}'**
  String filtersActiveCount(int count);

  /// Between Previous and Next under a paged list.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String pagerPageOf(int page, int pages);

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get actionMore;

  /// A section header's link to the full list behind it.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get actionSeeAll;

  /// No description provided for @actionShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get actionShowAll;

  /// No description provided for @actionShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get actionShowLess;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get actionShowPassword;

  /// No description provided for @actionHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get actionHidePassword;

  /// No description provided for @actionClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get actionClearSearch;

  /// No description provided for @actionReviewPlan.
  ///
  /// In en, this message translates to:
  /// **'Review plan'**
  String get actionReviewPlan;

  /// No description provided for @actionShowAsList.
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get actionShowAsList;

  /// No description provided for @actionShowAsChart.
  ///
  /// In en, this message translates to:
  /// **'Show as chart'**
  String get actionShowAsChart;

  /// No description provided for @actionIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get actionIncrease;

  /// No description provided for @actionDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get actionDecrease;

  /// No description provided for @actionPickDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get actionPickDate;

  /// No description provided for @actionPickTime.
  ///
  /// In en, this message translates to:
  /// **'Choose time'**
  String get actionPickTime;

  /// No description provided for @actionRemoveFile.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get actionRemoveFile;

  /// No description provided for @actionCancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get actionCancelUpload;

  /// No description provided for @actionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get actionPrevious;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get actionMarkComplete;

  /// No description provided for @actionOpenCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get actionOpenCurriculum;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @selectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectPlaceholder;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// No description provided for @stillWorking.
  ///
  /// In en, this message translates to:
  /// **'Still working…'**
  String get stillWorking;

  /// No description provided for @requiredFieldMarker.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredFieldMarker;

  /// No description provided for @stateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get stateErrorTitle;

  /// No description provided for @stateErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this. Check your connection and try again.'**
  String get stateErrorBody;

  /// No description provided for @stateOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing what was loaded.'**
  String get stateOfflineBanner;

  /// No description provided for @stateNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get stateNoMatchesTitle;

  /// No description provided for @stateNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters.'**
  String get stateNoMatchesBody;

  /// No description provided for @statePermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get statePermissionDeniedTitle;

  /// No description provided for @statePermissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your admin.'**
  String get statePermissionDeniedBody;

  /// No description provided for @stateFeatureUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Not included in your LMS plan.'**
  String get stateFeatureUnavailableTitle;

  /// No description provided for @stateFeatureUnavailableBodyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Review the plan to add this to your LMS.'**
  String get stateFeatureUnavailableBodyAdmin;

  /// No description provided for @stateFeatureUnavailableBodyMember.
  ///
  /// In en, this message translates to:
  /// **'Your LMS plan doesn\'t include this. Contact your admin.'**
  String get stateFeatureUnavailableBodyMember;

  /// No description provided for @stateSubscriptionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your LMS needs an active plan.'**
  String get stateSubscriptionRequiredTitle;

  /// No description provided for @stateSubscriptionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your LMS\'s subscription has ended.'**
  String get stateSubscriptionExpiredTitle;

  /// No description provided for @stateSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'Existing content stays available.'**
  String get stateSubscriptionBody;

  /// No description provided for @stateSubscriptionBodyMember.
  ///
  /// In en, this message translates to:
  /// **'Contact your admin to continue.'**
  String get stateSubscriptionBodyMember;

  /// No description provided for @stateNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t available.'**
  String get stateNotFoundTitle;

  /// No description provided for @stateNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been moved or removed.'**
  String get stateNotFoundBody;

  /// No description provided for @stateLockedLessonTitle.
  ///
  /// In en, this message translates to:
  /// **'This lesson is locked'**
  String get stateLockedLessonTitle;

  /// No description provided for @errorSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Fix 1 problem to continue} other{Fix {count} problems to continue}}'**
  String errorSummaryTitle(int count);

  /// No description provided for @destructiveAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand this can\'t be undone'**
  String get destructiveAcknowledge;

  /// No description provided for @fileUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {percent}%'**
  String fileUploading(int percent);

  /// No description provided for @fileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed — try again'**
  String get fileUploadFailed;

  /// No description provided for @fileSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String fileSizeMb(String size);

  /// No description provided for @progressPercentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String progressPercentComplete(int percent);

  /// No description provided for @kpiDeltaUp.
  ///
  /// In en, this message translates to:
  /// **'Up {value} {comparison}'**
  String kpiDeltaUp(String value, String comparison);

  /// No description provided for @kpiDeltaDown.
  ///
  /// In en, this message translates to:
  /// **'Down {value} {comparison}'**
  String kpiDeltaDown(String value, String comparison);

  /// No description provided for @kpiDeltaFlat.
  ///
  /// In en, this message translates to:
  /// **'No change {comparison}'**
  String kpiDeltaFlat(String comparison);

  /// No description provided for @chartReadoutItem.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String chartReadoutItem(String label, String value);

  /// No description provided for @studyDayMinutes.
  ///
  /// In en, this message translates to:
  /// **'{day}: {minutes, plural, =0{no study} =1{1 minute} other{{minutes} minutes}}'**
  String studyDayMinutes(String day, int minutes);

  /// No description provided for @rankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank: {name}'**
  String rankLabel(String name);

  /// No description provided for @curriculumProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} lessons'**
  String curriculumProgress(int done, int total);

  /// No description provided for @quizQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'Question {number} of {total}'**
  String quizQuestionCount(int number, int total);

  /// No description provided for @rubricCriterionScore.
  ///
  /// In en, this message translates to:
  /// **'{criterion}: {score} of {max}'**
  String rubricCriterionScore(String criterion, String score, String max);

  /// No description provided for @rubricTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {score} / {max}'**
  String rubricTotal(String score, String max);

  /// No description provided for @certificateCredentialId.
  ///
  /// In en, this message translates to:
  /// **'Credential ID {id}'**
  String certificateCredentialId(String id);

  /// No description provided for @certificateIssuedOn.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String certificateIssuedOn(String date);

  /// No description provided for @certificateVerifiedSeal.
  ///
  /// In en, this message translates to:
  /// **'Verified certificate'**
  String get certificateVerifiedSeal;

  /// No description provided for @certificateAwardedTo.
  ///
  /// In en, this message translates to:
  /// **'This certifies that'**
  String get certificateAwardedTo;

  /// No description provided for @courseCoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Course cover'**
  String get courseCoverLabel;

  /// No description provided for @lessonTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get lessonTypeVideo;

  /// No description provided for @lessonTypeReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get lessonTypeReading;

  /// No description provided for @lessonTypeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get lessonTypeDocument;

  /// No description provided for @lessonTypePractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get lessonTypePractice;

  /// No description provided for @lessonTypeLive.
  ///
  /// In en, this message translates to:
  /// **'Live class'**
  String get lessonTypeLive;

  /// No description provided for @lessonTypeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get lessonTypeQuiz;

  /// No description provided for @lessonTypeAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get lessonTypeAssignment;

  /// No description provided for @statusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get statusLocked;

  /// No description provided for @statusNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Not enrolled'**
  String get statusNotEnrolled;

  /// No description provided for @statusEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get statusEnrolled;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusLive.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get statusLive;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get statusUnderReview;

  /// No description provided for @statusPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get statusPassed;

  /// No description provided for @statusNotPassed.
  ///
  /// In en, this message translates to:
  /// **'Not passed'**
  String get statusNotPassed;

  /// No description provided for @statusEligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible'**
  String get statusEligible;

  /// No description provided for @statusNotEligible.
  ///
  /// In en, this message translates to:
  /// **'Not yet eligible'**
  String get statusNotEligible;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statusNotStarted;

  /// No description provided for @statusDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get statusDraftSaved;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusStartingSoon.
  ///
  /// In en, this message translates to:
  /// **'Starting soon'**
  String get statusStartingSoon;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusPublished;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get statusNotSubmitted;

  /// No description provided for @statusOverdueReview.
  ///
  /// In en, this message translates to:
  /// **'Overdue review'**
  String get statusOverdueReview;

  /// No description provided for @statusToReview.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get statusToReview;

  /// No description provided for @statusDraftReview.
  ///
  /// In en, this message translates to:
  /// **'Draft review'**
  String get statusDraftReview;

  /// No description provided for @statusResubmissionRequested.
  ///
  /// In en, this message translates to:
  /// **'Resubmission requested'**
  String get statusResubmissionRequested;

  /// No description provided for @statusGraded.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get statusGraded;

  /// No description provided for @statusLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get statusLate;

  /// No description provided for @statusIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get statusIssued;

  /// No description provided for @statusReadyToIssue.
  ///
  /// In en, this message translates to:
  /// **'Ready to issue'**
  String get statusReadyToIssue;

  /// No description provided for @statusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get statusRevoked;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @statusRecordingExpired.
  ///
  /// In en, this message translates to:
  /// **'Recording expired'**
  String get statusRecordingExpired;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get statusDueSoon;

  /// No description provided for @statusClosesSoon.
  ///
  /// In en, this message translates to:
  /// **'Closes soon'**
  String get statusClosesSoon;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get statusAtRisk;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get statusInvited;

  /// No description provided for @statusHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get statusHidden;

  /// No description provided for @statusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get statusTrial;

  /// No description provided for @statusPastDue.
  ///
  /// In en, this message translates to:
  /// **'Past due'**
  String get statusPastDue;

  /// No description provided for @statusCanceling.
  ///
  /// In en, this message translates to:
  /// **'Canceling'**
  String get statusCanceling;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @statusVoided.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get statusVoided;

  /// No description provided for @statusFreePreview.
  ///
  /// In en, this message translates to:
  /// **'Free preview'**
  String get statusFreePreview;

  /// No description provided for @statusImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get statusImportant;

  /// No description provided for @devComponentGallery.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get devComponentGallery;

  /// No description provided for @quizTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get quizTrue;

  /// No description provided for @quizFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get quizFalse;

  /// No description provided for @quizShortAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get quizShortAnswerLabel;

  /// No description provided for @quizChooseOne.
  ///
  /// In en, this message translates to:
  /// **'Choose one answer'**
  String get quizChooseOne;

  /// No description provided for @quizChooseAll.
  ///
  /// In en, this message translates to:
  /// **'Choose all that apply'**
  String get quizChooseAll;

  /// No description provided for @lessonLockedReason.
  ///
  /// In en, this message translates to:
  /// **'Locked: {reason}'**
  String lessonLockedReason(String reason);

  /// No description provided for @curriculumChapterLabel.
  ///
  /// In en, this message translates to:
  /// **'{title}, {done} of {total} lessons done'**
  String curriculumChapterLabel(String title, int done, int total);

  /// No description provided for @lessonCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lessonCompleteAction;

  /// No description provided for @certificateDateOfIssue.
  ///
  /// In en, this message translates to:
  /// **'Date of issue'**
  String get certificateDateOfIssue;

  /// No description provided for @relativeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get relativeNow;

  /// No description provided for @relativeMinutesFuture.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 minute} other{in {count} minutes}}'**
  String relativeMinutesFuture(int count);

  /// No description provided for @relativeMinutesPast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String relativeMinutesPast(int count);

  /// No description provided for @relativeHoursFuture.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 hour} other{in {count} hours}}'**
  String relativeHoursFuture(int count);

  /// No description provided for @relativeHoursPast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String relativeHoursPast(int count);

  /// No description provided for @relativeDaysFuture.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{tomorrow} other{in {count} days}}'**
  String relativeDaysFuture(int count);

  /// No description provided for @relativeDaysPast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String relativeDaysPast(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, String minutes);

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @timeWithZone.
  ///
  /// In en, this message translates to:
  /// **'{time} IST'**
  String timeWithZone(String time);

  /// No description provided for @timeRangeWithZone.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} IST'**
  String timeRangeWithZone(String start, String end);

  /// No description provided for @errorBoundaryTitle.
  ///
  /// In en, this message translates to:
  /// **'This screen stopped working'**
  String get errorBoundaryTitle;

  /// No description provided for @errorBoundaryBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Go home and try again.'**
  String get errorBoundaryBody;

  /// No description provided for @configErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'This build isn\'t set up correctly'**
  String get configErrorTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Learn from your school or coaching’s own LMS.'**
  String get appTagline;

  /// No description provided for @welcomeIntro.
  ///
  /// In en, this message translates to:
  /// **'Courses, live classes, assignments and certificates from the LMS you study with.'**
  String get welcomeIntro;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get actionSignIn;

  /// No description provided for @actionCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get actionCreateAccount;

  /// No description provided for @actionBrowseCourses.
  ///
  /// In en, this message translates to:
  /// **'Browse courses'**
  String get actionBrowseCourses;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @actionForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get actionForgotPassword;

  /// No description provided for @actionSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get actionSendLink;

  /// No description provided for @actionSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get actionSetPassword;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get fieldEmailHint;

  /// No description provided for @fieldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get fieldPasswordHint;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldName;

  /// No description provided for @fieldWorkspace.
  ///
  /// In en, this message translates to:
  /// **'LMS address'**
  String get fieldWorkspace;

  /// No description provided for @fieldWorkspaceHelp.
  ///
  /// In en, this message translates to:
  /// **'From your join link, e.g. saraswati-coaching. You can paste the whole link.'**
  String get fieldWorkspaceHelp;

  /// No description provided for @validationWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Enter the LMS address from your join link.'**
  String get validationWorkspace;

  /// No description provided for @registerWorkspaceNotFound.
  ///
  /// In en, this message translates to:
  /// **'No LMS has this address'**
  String get registerWorkspaceNotFound;

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'This account is suspended'**
  String get accountSuspendedTitle;

  /// No description provided for @accountClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'This account has been closed'**
  String get accountClosedTitle;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get fieldConfirmPassword;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmail;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get validationPasswordMin;

  /// No description provided for @validationNameMin.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get validationNameMin;

  /// No description provided for @validationPasswordsMatch.
  ///
  /// In en, this message translates to:
  /// **'Both passwords must match.'**
  String get validationPasswordsMatch;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off.'**
  String get loginSubtitle;

  /// No description provided for @loginFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you in.'**
  String get loginFailedTitle;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get loginNoAccount;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @accountTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get accountTypeTitle;

  /// No description provided for @accountTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you will use ZuviloAI.'**
  String get accountTypeSubtitle;

  /// No description provided for @accountTypeLearnerTitle.
  ///
  /// In en, this message translates to:
  /// **'I want to learn'**
  String get accountTypeLearnerTitle;

  /// No description provided for @accountTypeLearnerBody.
  ///
  /// In en, this message translates to:
  /// **'Join your teacher\'s or school\'s LMS as a learner.'**
  String get accountTypeLearnerBody;

  /// No description provided for @accountTypeAcademyTitle.
  ///
  /// In en, this message translates to:
  /// **'I want to teach — start my LMS'**
  String get accountTypeAcademyTitle;

  /// No description provided for @accountTypeAcademyBody.
  ///
  /// In en, this message translates to:
  /// **'Register your academy as its admin, then choose a plan or start a free trial.'**
  String get accountTypeAcademyBody;

  /// No description provided for @accountTypeInstructorTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m an instructor'**
  String get accountTypeInstructorTitle;

  /// No description provided for @accountTypeInstructorBody.
  ///
  /// In en, this message translates to:
  /// **'Instructors are added by their academy\'s admin. Ask your admin to invite you, then sign in with the email they used.'**
  String get accountTypeInstructorBody;

  /// No description provided for @academySignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your LMS'**
  String get academySignupTitle;

  /// No description provided for @academySignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be its admin. After this you can start a free trial or choose a plan.'**
  String get academySignupSubtitle;

  /// No description provided for @fieldAcademyName.
  ///
  /// In en, this message translates to:
  /// **'Academy or organisation name'**
  String get fieldAcademyName;

  /// No description provided for @fieldAcademyAddress.
  ///
  /// In en, this message translates to:
  /// **'LMS address'**
  String get fieldAcademyAddress;

  /// No description provided for @fieldAcademyAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Learners join at {address}'**
  String fieldAcademyAddressHelp(String address);

  /// No description provided for @fieldYourName.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get fieldYourName;

  /// No description provided for @academySignupAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get academySignupAgree;

  /// No description provided for @validationAcademyName.
  ///
  /// In en, this message translates to:
  /// **'Enter your organisation\'s name.'**
  String get validationAcademyName;

  /// No description provided for @validationAcademyAddress.
  ///
  /// In en, this message translates to:
  /// **'Use 3 to 40 lowercase letters, digits and single hyphens.'**
  String get validationAcademyAddress;

  /// No description provided for @validationAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'Agree to the Terms of Service and Privacy Policy to continue.'**
  String get validationAgreeTerms;

  /// No description provided for @academySignupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t start your LMS.'**
  String get academySignupFailedTitle;

  /// No description provided for @academyVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get academyVerifyTitle;

  /// No description provided for @academyVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. Enter it to create your LMS.'**
  String academyVerifySubtitle(String email);

  /// No description provided for @fieldVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get fieldVerificationCode;

  /// No description provided for @validationVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from the email.'**
  String get validationVerificationCode;

  /// No description provided for @academyVerifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify and create my LMS'**
  String get academyVerifyAction;

  /// No description provided for @academyVerifyFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work.'**
  String get academyVerifyFailedTitle;

  /// No description provided for @academyResendCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get academyResendCode;

  /// No description provided for @academyResendIn.
  ///
  /// In en, this message translates to:
  /// **'Send a new code in {seconds}s'**
  String academyResendIn(int seconds);

  /// No description provided for @academyCodeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get academyCodeResent;

  /// No description provided for @academyChangeDetails.
  ///
  /// In en, this message translates to:
  /// **'Change my details'**
  String get academyChangeDetails;

  /// No description provided for @accountVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. Enter it to finish joining {lms}.'**
  String accountVerifySubtitle(String email, String lms);

  /// No description provided for @accountVerifyInstructorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. Enter it to send your request to teach at {lms}.'**
  String accountVerifyInstructorSubtitle(String email, String lms);

  /// No description provided for @accountVerifySubtitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. Enter it to finish registering.'**
  String accountVerifySubtitleGeneric(String email);

  /// No description provided for @accountVerifyExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{The code works for 1 more minute.} other{The code works for {minutes} more minutes.}}'**
  String accountVerifyExpiresIn(int minutes);

  /// No description provided for @accountVerifyExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Send a new code.'**
  String get accountVerifyExpired;

  /// No description provided for @accountVerifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify and create my account'**
  String get accountVerifyAction;

  /// No description provided for @accountVerifyInstructorAction.
  ///
  /// In en, this message translates to:
  /// **'Verify and send my request'**
  String get accountVerifyInstructorAction;

  /// No description provided for @accountVerifyResendFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send a new code.'**
  String get accountVerifyResendFailedTitle;

  /// No description provided for @accountVerifyClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'This registration is no longer open'**
  String get accountVerifyClosedTitle;

  /// No description provided for @accountVerifyClosedBody.
  ///
  /// In en, this message translates to:
  /// **'Start again to get a new code.'**
  String get accountVerifyClosedBody;

  /// No description provided for @accountVerifyStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get accountVerifyStartAgain;

  /// No description provided for @invitationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation needed'**
  String get invitationRequiredTitle;

  /// No description provided for @invitationRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This LMS adds learners by invitation only. Ask your teacher or school for an invitation link.'**
  String get invitationRequiredBody;

  /// No description provided for @fieldJoinLinkOrAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste the link, or type the LMS address (for example saraswati-coaching).'**
  String get fieldJoinLinkOrAddressHelp;

  /// No description provided for @instructorLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Which LMS will you teach at?'**
  String get instructorLinkTitle;

  /// No description provided for @instructorLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Open the teaching link the LMS sent you on this device, paste it here, or type the LMS address.'**
  String get instructorLinkBody;

  /// No description provided for @accountTypeInstructorAction.
  ///
  /// In en, this message translates to:
  /// **'Register as an instructor and wait for the LMS Admin to approve you.'**
  String get accountTypeInstructorAction;

  /// No description provided for @instructorSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Register as an instructor'**
  String get instructorSignupTitle;

  /// No description provided for @instructorSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is reviewed by the LMS Admin. You can sign in once it is approved.'**
  String get instructorSignupSubtitle;

  /// No description provided for @instructorSignupJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Teach at {name}'**
  String instructorSignupJoinTitle(String name);

  /// No description provided for @fieldInstructorTitle.
  ///
  /// In en, this message translates to:
  /// **'Your title (optional)'**
  String get fieldInstructorTitle;

  /// No description provided for @fieldInstructorTitleHelp.
  ///
  /// In en, this message translates to:
  /// **'For example: Senior Maths Faculty, Physics lecturer'**
  String get fieldInstructorTitleHelp;

  /// No description provided for @instructorSignupAction.
  ///
  /// In en, this message translates to:
  /// **'Submit registration'**
  String get instructorSignupAction;

  /// No description provided for @instructorSignupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t submit your registration.'**
  String get instructorSignupFailedTitle;

  /// No description provided for @instructorPendingScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration submitted'**
  String get instructorPendingScreenTitle;

  /// No description provided for @instructorPendingHeading.
  ///
  /// In en, this message translates to:
  /// **'Registration submitted successfully.'**
  String get instructorPendingHeading;

  /// No description provided for @instructorPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending Admin approval. You will be able to sign in after the Admin approves your account.'**
  String get instructorPendingBody;

  /// No description provided for @instructorPendingNext.
  ///
  /// In en, this message translates to:
  /// **'Once approved, sign in with your registered email and password. We will also email you.'**
  String get instructorPendingNext;

  /// No description provided for @instructorPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Admin approval'**
  String get instructorPendingTitle;

  /// No description provided for @instructorRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration not approved'**
  String get instructorRejectedTitle;

  /// No description provided for @instructorRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending instructor requests'**
  String get instructorRequestsTitle;

  /// No description provided for @instructorRequestRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered {date}'**
  String instructorRequestRegistered(String date);

  /// No description provided for @instructorRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get instructorRequestPending;

  /// No description provided for @instructorRequestApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get instructorRequestApprove;

  /// No description provided for @instructorRequestReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get instructorRequestReject;

  /// No description provided for @instructorRequestRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject {name}?'**
  String instructorRequestRejectTitle(String name);

  /// No description provided for @instructorRequestRejectBody.
  ///
  /// In en, this message translates to:
  /// **'They will not be able to sign in as an instructor. They are told by email.'**
  String get instructorRequestRejectBody;

  /// No description provided for @instructorRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} is now an instructor and can sign in.'**
  String instructorRequestApproved(String name);

  /// No description provided for @instructorRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s request was rejected.'**
  String instructorRequestRejected(String name);

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learners join through the link their teacher or school sends. Instructors and admins are added by their LMS admin.'**
  String get registerSubtitle;

  /// No description provided for @registerDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to start learning.'**
  String get registerDefaultSubtitle;

  /// No description provided for @registerFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create your account.'**
  String get registerFailedTitle;

  /// No description provided for @registerLimitReached.
  ///
  /// In en, this message translates to:
  /// **'This LMS isn\'t accepting new learners right now.'**
  String get registerLimitReached;

  /// No description provided for @registerLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the link you were sent'**
  String get registerLinkTitle;

  /// No description provided for @registerLinkBody.
  ///
  /// In en, this message translates to:
  /// **'An invitation, a course link or a join link from your teacher or school brings you straight to their LMS. Open it on this device, or paste it here.'**
  String get registerLinkBody;

  /// No description provided for @fieldJoinLink.
  ///
  /// In en, this message translates to:
  /// **'Paste your link'**
  String get fieldJoinLink;

  /// No description provided for @fieldJoinLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'It starts with https://zuviloai.com/'**
  String get fieldJoinLinkHelp;

  /// No description provided for @validationJoinLink.
  ///
  /// In en, this message translates to:
  /// **'Paste the link you were sent.'**
  String get validationJoinLink;

  /// No description provided for @joinLinkNotRecognised.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a link for joining an LMS. Check the link you were sent, or ask your teacher or school for a new one.'**
  String get joinLinkNotRecognised;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @registerNoLinkNote.
  ///
  /// In en, this message translates to:
  /// **'No link? Ask your teacher or school for one. Already have an account? Sign in — your LMS is found from your email.'**
  String get registerNoLinkNote;

  /// No description provided for @joinLmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Join {lms}'**
  String joinLmsTitle(String lms);

  /// No description provided for @joinLmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your learner account at {lms}.'**
  String joinLmsSubtitle(String lms);

  /// No description provided for @joinLmsClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'This LMS isn\'t accepting new learners right now'**
  String get joinLmsClosedTitle;

  /// No description provided for @joinLmsClosedBody.
  ///
  /// In en, this message translates to:
  /// **'Contact your teacher or school for help.'**
  String get joinLmsClosedBody;

  /// No description provided for @joinSignedInTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in as {name}'**
  String joinSignedInTitle(String name);

  /// No description provided for @joinSignedInBody.
  ///
  /// In en, this message translates to:
  /// **'This link is for joining an LMS. To use it, sign out first, then create your account or sign in with the account it is for.'**
  String get joinSignedInBody;

  /// No description provided for @actionSignOutAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign out and continue'**
  String get actionSignOutAndContinue;

  /// No description provided for @joinOtherLmsTitle.
  ///
  /// In en, this message translates to:
  /// **'This account belongs to another LMS'**
  String get joinOtherLmsTitle;

  /// No description provided for @inviteInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'This invitation link isn\'t valid'**
  String get inviteInvalidTitle;

  /// No description provided for @inviteInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'It may have expired, been used or been withdrawn. Ask your teacher or school for a new one.'**
  String get inviteInvalidBody;

  /// No description provided for @inviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited to learn at {lms}. Create your account, or sign in if you already learn there.'**
  String inviteSubtitle(String lms);

  /// No description provided for @inviteSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the account you already have at {lms}.'**
  String inviteSignInSubtitle(String lms);

  /// No description provided for @inviteEmailLocked.
  ///
  /// In en, this message translates to:
  /// **'This invitation is for this email address.'**
  String get inviteEmailLocked;

  /// No description provided for @inviteWrongEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'This invitation is for a different email address'**
  String get inviteWrongEmailTitle;

  /// No description provided for @inviteNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get inviteNoAccount;

  /// No description provided for @actionSignInAndJoin.
  ///
  /// In en, this message translates to:
  /// **'Sign in and join'**
  String get actionSignInAndJoin;

  /// No description provided for @courseLinkInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'This course link isn\'t available'**
  String get courseLinkInvalidTitle;

  /// No description provided for @courseLinkInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'The course may no longer be offered, or the link was copied incorrectly. Ask your teacher or school for a new one.'**
  String get courseLinkInvalidBody;

  /// No description provided for @courseLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A course at {lms}.'**
  String courseLinkSubtitle(String lms);

  /// No description provided for @courseLinkCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Create your learner account at {lms} to enrol.'**
  String courseLinkCreateBody(String lms);

  /// No description provided for @actionCreateAndEnrol.
  ///
  /// In en, this message translates to:
  /// **'Create account and enrol'**
  String get actionCreateAndEnrol;

  /// No description provided for @courseLinkEnrolBody.
  ///
  /// In en, this message translates to:
  /// **'Enrol to add it to My Courses.'**
  String get courseLinkEnrolBody;

  /// No description provided for @courseLinkOtherLmsTitle.
  ///
  /// In en, this message translates to:
  /// **'This course belongs to another LMS'**
  String get courseLinkOtherLmsTitle;

  /// No description provided for @courseLinkStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Course links are for learners'**
  String get courseLinkStaffTitle;

  /// No description provided for @courseLinkStaffBody.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts can\'t enrol in courses. Sign out and use a learner account to enrol.'**
  String get courseLinkStaffBody;

  /// No description provided for @courseLinkAccountReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready'**
  String get courseLinkAccountReadyTitle;

  /// No description provided for @courseLinkNotEnrolledBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re not enrolled in this course yet.'**
  String get courseLinkNotEnrolledBody;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to set a new password.'**
  String get forgotSubtitle;

  /// No description provided for @forgotConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotConfirmationTitle;

  /// No description provided for @forgotConfirmationBody.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, we\'ve sent a link. It works for one hour.'**
  String get forgotConfirmationBody;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get resetTitle;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a password you have not used before.'**
  String get resetSubtitle;

  /// No description provided for @resetInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'This link is no longer valid'**
  String get resetInvalidTitle;

  /// No description provided for @resetInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'Request a new reset link and try again.'**
  String get resetInvalidBody;

  /// No description provided for @resetDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get resetDoneTitle;

  /// No description provided for @resetDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your new password.'**
  String get resetDoneBody;

  /// No description provided for @sessionEndedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again.'**
  String get sessionEndedMessage;

  /// No description provided for @splashOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach ZuviloAI'**
  String get splashOfflineTitle;

  /// No description provided for @splashOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get splashOfflineBody;

  /// No description provided for @unsupportedRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform administration is on the web'**
  String get unsupportedRoleTitle;

  /// No description provided for @unsupportedRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Super Admin tools aren\'t available in the app. Sign in on the web to continue.'**
  String get unsupportedRoleBody;

  /// No description provided for @offlineActionDisabled.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to continue.'**
  String get offlineActionDisabled;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @roleLearner.
  ///
  /// In en, this message translates to:
  /// **'Learner'**
  String get roleLearner;

  /// No description provided for @roleInstructor.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get roleInstructor;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get navLive;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// No description provided for @navCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get navCourses;

  /// No description provided for @navPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get navPeople;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get navStudents;

  /// No description provided for @navQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get navQuizzes;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navInstructors.
  ///
  /// In en, this message translates to:
  /// **'Instructors'**
  String get navInstructors;

  /// No description provided for @navCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get navCertificates;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get navBilling;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get navHelp;

  /// No description provided for @navAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get navAssignments;

  /// No description provided for @navAssessments.
  ///
  /// In en, this message translates to:
  /// **'Assessments'**
  String get navAssessments;

  /// No description provided for @navRanks.
  ///
  /// In en, this message translates to:
  /// **'Rank ladder'**
  String get navRanks;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get navCatalog;

  /// No description provided for @navVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify a certificate'**
  String get navVerify;

  /// No description provided for @navTests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get navTests;

  /// No description provided for @navMyCourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get navMyCourses;

  /// No description provided for @moreSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreSheetTitle;

  /// Heading in the staff More sheet over the day-to-day teaching pages (review, students, calendar, quizzes).
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get moreGroupTeaching;

  /// Heading in the staff More sheet over the academy's own pages (instructors, reports, billing).
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get moreGroupAcademy;

  /// Heading in the staff More sheet over the person's own pages (profile, notifications, help).
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get moreGroupAccount;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later update'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This part of the app is still being built.'**
  String get comingSoonBody;

  /// No description provided for @notificationsBellLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsBellLabel;

  /// No description provided for @notificationsBellWithCount.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String notificationsBellWithCount(int count);

  /// No description provided for @myLearningInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get myLearningInProgress;

  /// No description provided for @myLearningCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get myLearningCompleted;

  /// No description provided for @myLearningSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get myLearningSaved;

  /// No description provided for @entitlementLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'This is as far as your plan goes'**
  String get entitlementLimitReachedTitle;

  /// No description provided for @entitlementLimitReachedBody.
  ///
  /// In en, this message translates to:
  /// **'Your LMS has reached what its plan allows.'**
  String get entitlementLimitReachedBody;

  /// No description provided for @restrictedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your LMS has no active plan'**
  String get restrictedBannerTitle;

  /// No description provided for @restrictedBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Existing courses and learners stay available. New ones need a plan.'**
  String get restrictedBannerBody;

  /// No description provided for @restrictedBannerMember.
  ///
  /// In en, this message translates to:
  /// **'Your LMS plan has lapsed. Contact your admin.'**
  String get restrictedBannerMember;

  /// No description provided for @subscriptionStatusTrialing.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get subscriptionStatusTrialing;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionStatusActive;

  /// No description provided for @subscriptionStatusPastDue.
  ///
  /// In en, this message translates to:
  /// **'Past due'**
  String get subscriptionStatusPastDue;

  /// No description provided for @subscriptionStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get subscriptionStatusPaused;

  /// No description provided for @subscriptionStatusCanceling.
  ///
  /// In en, this message translates to:
  /// **'Canceling'**
  String get subscriptionStatusCanceling;

  /// No description provided for @subscriptionStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get subscriptionStatusCanceled;

  /// No description provided for @subscriptionStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subscriptionStatusExpired;

  /// No description provided for @limitMeter.
  ///
  /// In en, this message translates to:
  /// **'{label} {used} of {allowed}'**
  String limitMeter(String label, String used, String allowed);

  /// No description provided for @limitMeterUnlimited.
  ///
  /// In en, this message translates to:
  /// **'{label} {used} · unlimited'**
  String limitMeterUnlimited(String label, String used);

  /// No description provided for @permissionDeniedInline.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get permissionDeniedInline;

  /// No description provided for @uploadRejectedType.
  ///
  /// In en, this message translates to:
  /// **'Only MP4/WebM/MOV video, PDF documents and PNG/JPG/WebP images can be uploaded.'**
  String get uploadRejectedType;

  /// No description provided for @uploadRejectedVideoStaff.
  ///
  /// In en, this message translates to:
  /// **'Only instructors and admins can upload video.'**
  String get uploadRejectedVideoStaff;

  /// No description provided for @uploadRejectedContents.
  ///
  /// In en, this message translates to:
  /// **'The file’s contents do not match its type. Upload the original PDF, image or video.'**
  String get uploadRejectedContents;

  /// No description provided for @uploadRejectedSizeVideo.
  ///
  /// In en, this message translates to:
  /// **'Videos can be at most {mb} MB.'**
  String uploadRejectedSizeVideo(int mb);

  /// No description provided for @uploadRejectedSizeDocument.
  ///
  /// In en, this message translates to:
  /// **'Documents can be at most {mb} MB.'**
  String uploadRejectedSizeDocument(int mb);

  /// No description provided for @uploadRejectedSizeImage.
  ///
  /// In en, this message translates to:
  /// **'Images can be at most {mb} MB.'**
  String uploadRejectedSizeImage(int mb);

  /// No description provided for @uploadChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get uploadChooseFile;

  /// No description provided for @uploadReplaceFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get uploadReplaceFile;

  /// No description provided for @mediaVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'This video couldn\'t be played'**
  String get mediaVideoFailed;

  /// No description provided for @mediaVideoEnded.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get mediaVideoEnded;

  /// No description provided for @mediaMobileDataNotice.
  ///
  /// In en, this message translates to:
  /// **'You\'re on mobile data. This video is {mb} MB.'**
  String mediaMobileDataNotice(String mb);

  /// No description provided for @mediaMobileDataContinue.
  ///
  /// In en, this message translates to:
  /// **'Play anyway'**
  String get mediaMobileDataContinue;

  /// No description provided for @mediaDocumentFailed.
  ///
  /// In en, this message translates to:
  /// **'This document couldn\'t be opened'**
  String get mediaDocumentFailed;

  /// No description provided for @mediaDocumentLoading.
  ///
  /// In en, this message translates to:
  /// **'Opening document…'**
  String get mediaDocumentLoading;

  /// No description provided for @mediaPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String mediaPageOf(int page, int total);

  /// No description provided for @mediaPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get mediaPlay;

  /// No description provided for @mediaPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get mediaPause;

  /// No description provided for @mediaBack10.
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get mediaBack10;

  /// No description provided for @mediaForward10.
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get mediaForward10;

  /// No description provided for @mediaFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get mediaFullscreen;

  /// No description provided for @mediaExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get mediaExitFullscreen;

  /// No description provided for @mediaSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get mediaSpeed;

  /// No description provided for @mediaSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{speed}×'**
  String mediaSpeedValue(String speed);

  /// No description provided for @actionVerifyCertificate.
  ///
  /// In en, this message translates to:
  /// **'Verify a certificate'**
  String get actionVerifyCertificate;

  /// No description provided for @actionHelpCentre.
  ///
  /// In en, this message translates to:
  /// **'Help centre'**
  String get actionHelpCentre;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get catalogTitle;

  /// No description provided for @catalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search courses'**
  String get catalogSearchHint;

  /// No description provided for @catalogFilterAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get catalogFilterAllLevels;

  /// No description provided for @catalogFilterAllTopics.
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get catalogFilterAllTopics;

  /// No description provided for @catalogEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No courses published yet'**
  String get catalogEmptyTitle;

  /// No description provided for @catalogEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New courses appear here as soon as the LMS publishes them.'**
  String get catalogEmptyBody;

  /// No description provided for @catalogCourseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 course} other{{count} courses}}'**
  String catalogCourseCount(int count);

  /// No description provided for @courseLessonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson} other{{count} lessons}}'**
  String courseLessonCount(int count);

  /// No description provided for @coursePriceFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get coursePriceFree;

  /// No description provided for @courseRatingSummary.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count})'**
  String courseRatingSummary(String rating, int count);

  /// No description provided for @courseRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} out of 5 by {count} learners'**
  String courseRatingLabel(String rating, int count);

  /// No description provided for @courseWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String courseWeeks(int count);

  /// No description provided for @courseFormatSelfPaced.
  ///
  /// In en, this message translates to:
  /// **'Self-paced'**
  String get courseFormatSelfPaced;

  /// No description provided for @courseFormatCohort.
  ///
  /// In en, this message translates to:
  /// **'Cohort'**
  String get courseFormatCohort;

  /// No description provided for @courseFormatHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get courseFormatHybrid;

  /// No description provided for @courseAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About this course'**
  String get courseAboutTitle;

  /// No description provided for @courseOutcomesTitle.
  ///
  /// In en, this message translates to:
  /// **'What you will learn'**
  String get courseOutcomesTitle;

  /// No description provided for @courseCurriculumTitle.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get courseCurriculumTitle;

  /// No description provided for @courseInstructorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Taught by'**
  String get courseInstructorsTitle;

  /// No description provided for @courseCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get courseCertificateLabel;

  /// No description provided for @courseLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get courseLanguageLabel;

  /// No description provided for @courseFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get courseFormatLabel;

  /// No description provided for @courseLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get courseLevelLabel;

  /// No description provided for @coursePreviewNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson is free to preview} other{{count} lessons are free to preview}}'**
  String coursePreviewNote(int count);

  /// No description provided for @actionEnrol.
  ///
  /// In en, this message translates to:
  /// **'Enrol'**
  String get actionEnrol;

  /// No description provided for @actionSignInToEnrol.
  ///
  /// In en, this message translates to:
  /// **'Sign in to enrol'**
  String get actionSignInToEnrol;

  /// No description provided for @actionOpenCourse.
  ///
  /// In en, this message translates to:
  /// **'Open course'**
  String get actionOpenCourse;

  /// No description provided for @actionViewCourse.
  ///
  /// In en, this message translates to:
  /// **'View course'**
  String get actionViewCourse;

  /// No description provided for @coursePriceTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get coursePriceTagLabel;

  /// No description provided for @courseIncludesTitle.
  ///
  /// In en, this message translates to:
  /// **'What’s included'**
  String get courseIncludesTitle;

  /// No description provided for @courseIncludesVideos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 video lesson} other{{count} video lessons}}'**
  String courseIncludesVideos(int count);

  /// No description provided for @courseIncludesReadings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reading} other{{count} readings}}'**
  String courseIncludesReadings(int count);

  /// No description provided for @courseIncludesDocuments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 PDF document} other{{count} PDF documents}}'**
  String courseIncludesDocuments(int count);

  /// No description provided for @courseIncludesTests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 test} other{{count} tests}}'**
  String courseIncludesTests(int count);

  /// No description provided for @courseIncludesAssignments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 assignment} other{{count} assignments}}'**
  String courseIncludesAssignments(int count);

  /// No description provided for @courseIncludesLive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 live class} other{{count} live classes}}'**
  String courseIncludesLive(int count);

  /// No description provided for @courseIncludesPreviews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson free to preview} other{{count} lessons free to preview}}'**
  String courseIncludesPreviews(int count);

  /// No description provided for @courseIncludesCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate: {title}'**
  String courseIncludesCertificate(String title);

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Free preview'**
  String get previewTitle;

  /// No description provided for @previewLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrol to watch this lesson'**
  String get previewLockedTitle;

  /// No description provided for @previewLockedBody.
  ///
  /// In en, this message translates to:
  /// **'This lesson is part of the course. Enrol to open it.'**
  String get previewLockedBody;

  /// No description provided for @previewUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview not available'**
  String get previewUnsupportedTitle;

  /// No description provided for @previewUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'Free previews cover readings, videos and documents.'**
  String get previewUnsupportedBody;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify a certificate'**
  String get verifyTitle;

  /// No description provided for @verifyIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the credential ID printed on the certificate.'**
  String get verifyIntro;

  /// No description provided for @verifyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Credential ID'**
  String get verifyFieldLabel;

  /// No description provided for @verifyFieldHint.
  ///
  /// In en, this message translates to:
  /// **'SA-JY-2026-00142'**
  String get verifyFieldHint;

  /// No description provided for @actionVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get actionVerify;

  /// No description provided for @actionVerifyAnother.
  ///
  /// In en, this message translates to:
  /// **'Check another ID'**
  String get actionVerifyAnother;

  /// No description provided for @verifyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a credential ID.'**
  String get verifyRequired;

  /// No description provided for @verifyTooLong.
  ///
  /// In en, this message translates to:
  /// **'A credential ID is at most 64 characters.'**
  String get verifyTooLong;

  /// No description provided for @verifyCheckingTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking this credential…'**
  String get verifyCheckingTitle;

  /// No description provided for @verifyNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No certificate found for this ID'**
  String get verifyNotFoundTitle;

  /// No description provided for @verifyNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Check the ID and try again. A certificate that has not been issued yet cannot be verified.'**
  String get verifyNotFoundBody;

  /// No description provided for @verifyValidTitle.
  ///
  /// In en, this message translates to:
  /// **'This certificate is valid'**
  String get verifyValidTitle;

  /// No description provided for @verifyRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'This certificate has been revoked'**
  String get verifyRevokedTitle;

  /// No description provided for @verifyRevokedBody.
  ///
  /// In en, this message translates to:
  /// **'The LMS withdrew it, so it is no longer a valid credential.'**
  String get verifyRevokedBody;

  /// No description provided for @verifyExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'This certificate has expired'**
  String get verifyExpiredTitle;

  /// No description provided for @verifyExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'It was valid until {date}.'**
  String verifyExpiredBody(String date);

  /// No description provided for @verifyAwardedToLabel.
  ///
  /// In en, this message translates to:
  /// **'Awarded to'**
  String get verifyAwardedToLabel;

  /// No description provided for @verifyCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get verifyCourseLabel;

  /// No description provided for @verifyLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get verifyLevelLabel;

  /// No description provided for @verifyCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get verifyCityLabel;

  /// No description provided for @verifyIssuedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued on'**
  String get verifyIssuedOnLabel;

  /// No description provided for @verifyCompletedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed on'**
  String get verifyCompletedOnLabel;

  /// No description provided for @verifyValidUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get verifyValidUntilLabel;

  /// No description provided for @verifyScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Final score'**
  String get verifyScoreLabel;

  /// No description provided for @verifyScoreValue.
  ///
  /// In en, this message translates to:
  /// **'{score}%'**
  String verifyScoreValue(int score);

  /// No description provided for @verifyHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Study hours'**
  String get verifyHoursLabel;

  /// A course's study hours, which the academy rounds to the nearest half hour — so it is not always whole.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String verifyHoursValue(num hours);

  /// No description provided for @verifyRevokedReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get verifyRevokedReasonLabel;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help centre'**
  String get helpTitle;

  /// No description provided for @helpSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search help'**
  String get helpSearchHint;

  /// No description provided for @helpPopularTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular articles'**
  String get helpPopularTitle;

  /// No description provided for @helpTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse by topic'**
  String get helpTopicsTitle;

  /// No description provided for @helpArticleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No articles} =1{1 article} other{{count} articles}}'**
  String helpArticleCount(int count);

  /// No description provided for @helpReadMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min read} other{{count} min read}}'**
  String helpReadMinutes(int count);

  /// No description provided for @helpUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String helpUpdatedOn(String date);

  /// No description provided for @helpRelatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Related articles'**
  String get helpRelatedTitle;

  /// No description provided for @helpEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles yet'**
  String get helpEmptyTitle;

  /// No description provided for @helpEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The LMS has not published any help articles.'**
  String get helpEmptyBody;

  /// No description provided for @helpLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'That link could not be opened.'**
  String get helpLinkFailed;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get legalPrivacyTitle;

  /// No description provided for @legalTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get legalTermsTitle;

  /// No description provided for @legalBody.
  ///
  /// In en, this message translates to:
  /// **'The current text is published on the web, so what you read is always the version in force.'**
  String get legalBody;

  /// No description provided for @actionOpenOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Open on the web'**
  String get actionOpenOnWeb;

  /// No description provided for @courseDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get courseDurationLabel;

  /// No description provided for @courseLessonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get courseLessonsLabel;

  /// No description provided for @courseLiveSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Live sessions'**
  String get courseLiveSessionsLabel;

  /// No description provided for @courseEnrolledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get courseEnrolledLabel;

  /// No description provided for @previewSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to watch this preview'**
  String get previewSignInTitle;

  /// No description provided for @previewSignInBody.
  ///
  /// In en, this message translates to:
  /// **'The LMS serves course media to signed-in accounts only.'**
  String get previewSignInBody;

  /// No description provided for @previewMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get previewMissingTitle;

  /// No description provided for @previewMissingBody.
  ///
  /// In en, this message translates to:
  /// **'The LMS has not attached a file to this lesson.'**
  String get previewMissingBody;

  /// No description provided for @actionOpenDocument.
  ///
  /// In en, this message translates to:
  /// **'Open the document'**
  String get actionOpenDocument;

  /// No description provided for @homeGreetingName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String homeGreetingName(String greeting, String name);

  /// No description provided for @homeContinueTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get homeContinueTitle;

  /// No description provided for @homeComingUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get homeComingUpTitle;

  /// No description provided for @homeYourCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your courses'**
  String get homeYourCoursesTitle;

  /// No description provided for @homeThisWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get homeThisWeekTitle;

  /// No description provided for @homeRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get homeRecentTitle;

  /// No description provided for @homeNextLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Next live class'**
  String get homeNextLiveTitle;

  /// No description provided for @homeToDoTitle.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get homeToDoTitle;

  /// No description provided for @homeExploreBody.
  ///
  /// In en, this message translates to:
  /// **'Find your next course in the LMS’s catalogue'**
  String get homeExploreBody;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your learning starts here'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Browse the LMS’s courses and enrol in the one you want to begin.'**
  String get homeEmptyBody;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore courses'**
  String get actionExplore;

  /// No description provided for @courseRemaining.
  ///
  /// In en, this message translates to:
  /// **'{minutes} left'**
  String courseRemaining(String minutes);

  /// No description provided for @lessonNumberAndLength.
  ///
  /// In en, this message translates to:
  /// **'{number} · {length}'**
  String lessonNumberAndLength(String number, String length);

  /// No description provided for @homeWeekTotal.
  ///
  /// In en, this message translates to:
  /// **'{minutes} studied'**
  String homeWeekTotal(String minutes);

  /// No description provided for @homeStudiedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Studied this week'**
  String get homeStudiedThisWeek;

  /// No description provided for @homeEnrolledOn.
  ///
  /// In en, this message translates to:
  /// **'Enrolled {date}'**
  String homeEnrolledOn(String date);

  /// No description provided for @homeDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover more courses'**
  String get homeDiscoverTitle;

  /// No description provided for @upcomingKindLive.
  ///
  /// In en, this message translates to:
  /// **'Live class'**
  String get upcomingKindLive;

  /// No description provided for @upcomingKindAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get upcomingKindAssignment;

  /// No description provided for @upcomingKindQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get upcomingKindQuiz;

  /// No description provided for @upcomingReadyNow.
  ///
  /// In en, this message translates to:
  /// **'Ready now'**
  String get upcomingReadyNow;

  /// No description provided for @myLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'My learning'**
  String get myLearningTitle;

  /// No description provided for @myLearningEmptyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Nothing in progress'**
  String get myLearningEmptyInProgress;

  /// No description provided for @myLearningEmptyInProgressBody.
  ///
  /// In en, this message translates to:
  /// **'Enrol in a course and it appears here.'**
  String get myLearningEmptyInProgressBody;

  /// No description provided for @myLearningEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'No courses completed yet'**
  String get myLearningEmptyCompleted;

  /// No description provided for @myLearningEmptyCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Finish a course and it moves here with its certificate.'**
  String get myLearningEmptyCompletedBody;

  /// No description provided for @myLearningEmptySaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved'**
  String get myLearningEmptySaved;

  /// No description provided for @myLearningEmptySavedBody.
  ///
  /// In en, this message translates to:
  /// **'Save a course from the Courses tab to come back to it.'**
  String get myLearningEmptySavedBody;

  /// No description provided for @enrolmentExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'Access ended on {date}'**
  String enrolmentExpiredOn(String date);

  /// No description provided for @enrolmentPausedNote.
  ///
  /// In en, this message translates to:
  /// **'Paused by the LMS.'**
  String get enrolmentPausedNote;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the LMS’s courses'**
  String get exploreSearchHint;

  /// No description provided for @exploreEnrolledFilter.
  ///
  /// In en, this message translates to:
  /// **'Already enrolled'**
  String get exploreEnrolledFilter;

  /// No description provided for @actionSaveCourse.
  ///
  /// In en, this message translates to:
  /// **'Save this course'**
  String get actionSaveCourse;

  /// No description provided for @actionUnsaveCourse.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get actionUnsaveCourse;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'That could not be saved. Try again.'**
  String get saveFailed;

  /// No description provided for @enrolConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrol in this course?'**
  String get enrolConfirmTitle;

  /// No description provided for @enrolConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your place is confirmed straight away and the course appears in My Courses, under Profile.'**
  String get enrolConfirmBody;

  /// No description provided for @enrolFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not enrol'**
  String get enrolFailedTitle;

  /// No description provided for @enrolDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'You are enrolled. The course is in My Courses.'**
  String get enrolDoneMessage;

  /// No description provided for @enrolAccessEnds.
  ///
  /// In en, this message translates to:
  /// **'Access ends on {date}'**
  String enrolAccessEnds(String date);

  /// No description provided for @courseEnrolToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enrol to unlock'**
  String get courseEnrolToUnlock;

  /// No description provided for @courseLockedChapter.
  ///
  /// In en, this message translates to:
  /// **'Finish “{chapter}” to open this chapter.'**
  String courseLockedChapter(String chapter);

  /// No description provided for @courseLockedQuiz.
  ///
  /// In en, this message translates to:
  /// **'Finish the other lessons in “{chapter}” to take this quiz.'**
  String courseLockedQuiz(String chapter);

  /// No description provided for @courseLockedInOrder.
  ///
  /// In en, this message translates to:
  /// **'This lesson opens after the ones before it.'**
  String get courseLockedInOrder;

  /// No description provided for @courseFreePreviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Try it free'**
  String get courseFreePreviewsTitle;

  /// No description provided for @actionPreviewLesson.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get actionPreviewLesson;

  /// No description provided for @courseScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get courseScheduleLabel;

  /// No description provided for @courseOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get courseOverviewTitle;

  /// No description provided for @exploreEnrolledAlready.
  ///
  /// In en, this message translates to:
  /// **'You are already enrolled'**
  String get exploreEnrolledAlready;

  /// No description provided for @lessonPositionOf.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String lessonPositionOf(int index, int total);

  /// No description provided for @lessonCompletedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed on {date}'**
  String lessonCompletedOn(String date);

  /// No description provided for @lessonLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not open yet'**
  String get lessonLockedTitle;

  /// No description provided for @lessonNotEnrolledTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrol to open this lesson'**
  String get lessonNotEnrolledTitle;

  /// No description provided for @lessonNotEnrolledBody.
  ///
  /// In en, this message translates to:
  /// **'This lesson is part of the course. Enrol to study it.'**
  String get lessonNotEnrolledBody;

  /// No description provided for @lessonUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'This lesson is not available'**
  String get lessonUnavailableTitle;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get noteTitle;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Write your working, or anything you want to remember.'**
  String get noteHint;

  /// No description provided for @noteSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get noteSaving;

  /// No description provided for @noteSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved {time}'**
  String noteSavedAt(String time);

  /// No description provided for @noteFailed.
  ///
  /// In en, this message translates to:
  /// **'Not saved. Try again.'**
  String get noteFailed;

  /// No description provided for @noteCounter.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max}'**
  String noteCounter(int count, int max);

  /// No description provided for @actionBookmarkLesson.
  ///
  /// In en, this message translates to:
  /// **'Bookmark this lesson'**
  String get actionBookmarkLesson;

  /// No description provided for @actionRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get actionRemoveBookmark;

  /// No description provided for @chapterCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter complete'**
  String get chapterCompleteTitle;

  /// No description provided for @chapterCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'{title} is done.'**
  String chapterCompleteBody(String title);

  /// No description provided for @courseCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Course complete'**
  String get courseCompleteTitle;

  /// No description provided for @courseCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You have finished every lesson of this course.'**
  String get courseCompleteBody;

  /// No description provided for @ruleHintWatched.
  ///
  /// In en, this message translates to:
  /// **'Watch {percent}% to complete'**
  String ruleHintWatched(int percent);

  /// No description provided for @ruleHintPassed.
  ///
  /// In en, this message translates to:
  /// **'Pass the quiz to complete this lesson'**
  String get ruleHintPassed;

  /// No description provided for @ruleHintSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Hand in your work to complete this lesson'**
  String get ruleHintSubmitted;

  /// No description provided for @quizSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizSummaryTitle;

  /// No description provided for @quizSummaryFacts.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions · pass {passMark}%'**
  String quizSummaryFacts(int questions, int passMark);

  /// No description provided for @quizAttemptsAllowed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String quizAttemptsAllowed(int count);

  /// No description provided for @quizBestScore.
  ///
  /// In en, this message translates to:
  /// **'Best so far {percent}%'**
  String quizBestScore(int percent);

  /// No description provided for @quizTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minute limit'**
  String quizTimeLimit(int minutes);

  /// No description provided for @assignmentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignmentSummaryTitle;

  /// No description provided for @assignmentDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String assignmentDueOn(String date);

  /// No description provided for @actionOpenAssignment.
  ///
  /// In en, this message translates to:
  /// **'Open assignment'**
  String get actionOpenAssignment;

  /// No description provided for @liveSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Live class'**
  String get liveSummaryTitle;

  /// No description provided for @liveStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts {when}'**
  String liveStartsAt(String when);

  /// No description provided for @liveDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String liveDuration(int minutes);

  /// No description provided for @lessonResumeFrom.
  ///
  /// In en, this message translates to:
  /// **'Resuming from {time}'**
  String lessonResumeFrom(String time);

  /// No description provided for @courseNextLessonTitle.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get courseNextLessonTitle;

  /// No description provided for @courseLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live classes'**
  String get courseLiveTitle;

  /// No description provided for @courseAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get courseAssignmentsTitle;

  /// No description provided for @actionOpenLesson.
  ///
  /// In en, this message translates to:
  /// **'Open lesson'**
  String get actionOpenLesson;

  /// No description provided for @assessmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessments'**
  String get assessmentsTitle;

  /// No description provided for @assessmentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet'**
  String get assessmentsEmptyTitle;

  /// No description provided for @assessmentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Quizzes appear here as you reach them in your courses.'**
  String get assessmentsEmptyBody;

  /// No description provided for @assessmentRowFacts.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions · pass {passMark}%'**
  String assessmentRowFacts(int questions, int passMark);

  /// No description provided for @assessmentAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No attempts left} =1{1 attempt left} other{{count} attempts left}}'**
  String assessmentAttemptsLeft(int count);

  /// No description provided for @assessmentAttemptsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited attempts'**
  String get assessmentAttemptsUnlimited;

  /// No description provided for @quizIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get quizIntroTitle;

  /// No description provided for @actionStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start the quiz'**
  String get actionStartQuiz;

  /// No description provided for @actionReviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Review answers'**
  String get actionReviewAnswers;

  /// No description provided for @actionSubmitQuiz.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmitQuiz;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @quizSubmitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit this attempt?'**
  String get quizSubmitConfirmTitle;

  /// No description provided for @quizSubmitConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers go to the LMS to be marked. You cannot change them afterwards.'**
  String get quizSubmitConfirmBody;

  /// No description provided for @quizUnansweredWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question is unanswered} other{{count} questions are unanswered}}'**
  String quizUnansweredWarning(int count);

  /// No description provided for @quizAllAnswered.
  ///
  /// In en, this message translates to:
  /// **'Every question is answered.'**
  String get quizAllAnswered;

  /// No description provided for @quizReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your answers'**
  String get quizReviewTitle;

  /// No description provided for @quizAnsweredLabel.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get quizAnsweredLabel;

  /// No description provided for @quizUnansweredLabel.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get quizUnansweredLabel;

  /// No description provided for @quizTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String quizTimeLeft(String time);

  /// No description provided for @quizTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time is up. Your saved answers are being handed in.'**
  String get quizTimeUp;

  /// No description provided for @quizPassedTitle.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get quizPassedTitle;

  /// No description provided for @quizNotPassedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not passed this time'**
  String get quizNotPassedTitle;

  /// No description provided for @quizBestAfterAttempt.
  ///
  /// In en, this message translates to:
  /// **'Your best score is {percent}%'**
  String quizBestAfterAttempt(int percent);

  /// No description provided for @actionContinueCourse.
  ///
  /// In en, this message translates to:
  /// **'Back to the course'**
  String get actionContinueCourse;

  /// No description provided for @quizQuestionNavigator.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get quizQuestionNavigator;

  /// No description provided for @quizSubmitOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your answers are kept until you reconnect.'**
  String get quizSubmitOffline;

  /// No description provided for @assignmentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet'**
  String get assignmentsEmptyTitle;

  /// No description provided for @assignmentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Coursework appears here as you reach it in your courses.'**
  String get assignmentsEmptyBody;

  /// No description provided for @assignmentBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'The brief'**
  String get assignmentBriefTitle;

  /// No description provided for @assignmentAttachmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'From your instructor'**
  String get assignmentAttachmentsTitle;

  /// No description provided for @assignmentRubricTitle.
  ///
  /// In en, this message translates to:
  /// **'How it is marked'**
  String get assignmentRubricTitle;

  /// No description provided for @assignmentRubricPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String assignmentRubricPoints(int points);

  /// No description provided for @assignmentWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Your work'**
  String get assignmentWorkTitle;

  /// No description provided for @assignmentWorkHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer here.'**
  String get assignmentWorkHint;

  /// No description provided for @assignmentWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String assignmentWordCount(int count);

  /// No description provided for @assignmentWordLimit.
  ///
  /// In en, this message translates to:
  /// **'{count} of {limit} words'**
  String assignmentWordLimit(int count, int limit);

  /// No description provided for @assignmentFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your files'**
  String get assignmentFilesTitle;

  /// No description provided for @assignmentChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Birth details'**
  String get assignmentChartTitle;

  /// No description provided for @assignmentChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Whose chart'**
  String get assignmentChartLabel;

  /// No description provided for @assignmentChartDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get assignmentChartDate;

  /// No description provided for @assignmentChartTime.
  ///
  /// In en, this message translates to:
  /// **'Time of birth'**
  String get assignmentChartTime;

  /// No description provided for @assignmentChartPlace.
  ///
  /// In en, this message translates to:
  /// **'Place of birth'**
  String get assignmentChartPlace;

  /// No description provided for @assignmentChartLagna.
  ///
  /// In en, this message translates to:
  /// **'Lagna'**
  String get assignmentChartLagna;

  /// No description provided for @assignmentChartMoonSign.
  ///
  /// In en, this message translates to:
  /// **'Moon sign'**
  String get assignmentChartMoonSign;

  /// No description provided for @assignmentChartNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get assignmentChartNakshatra;

  /// No description provided for @assignmentDraftSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get assignmentDraftSaving;

  /// No description provided for @assignmentDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved {time}'**
  String assignmentDraftSaved(String time);

  /// No description provided for @assignmentDraftFailed.
  ///
  /// In en, this message translates to:
  /// **'Draft not saved. Try again.'**
  String get assignmentDraftFailed;

  /// No description provided for @assignmentDraftOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your work is kept here until you reconnect.'**
  String get assignmentDraftOffline;

  /// No description provided for @actionSubmitAssignment.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmitAssignment;

  /// No description provided for @actionResubmitAssignment.
  ///
  /// In en, this message translates to:
  /// **'Submit again'**
  String get actionResubmitAssignment;

  /// No description provided for @assignmentSubmitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand this in?'**
  String get assignmentSubmitConfirmTitle;

  /// No description provided for @assignmentSubmitConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your work goes to your instructor to be marked.'**
  String get assignmentSubmitConfirmBody;

  /// No description provided for @assignmentLateWarning.
  ///
  /// In en, this message translates to:
  /// **'This is past its deadline. The LMS takes {percent}% off a late hand-in.'**
  String assignmentLateWarning(int percent);

  /// No description provided for @assignmentLateNoPenalty.
  ///
  /// In en, this message translates to:
  /// **'This is past its deadline, and late work is still accepted.'**
  String get assignmentLateNoPenalty;

  /// No description provided for @assignmentSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Handed in {date}'**
  String assignmentSubmittedOn(String date);

  /// No description provided for @assignmentAttemptNumber.
  ///
  /// In en, this message translates to:
  /// **'Attempt {number}'**
  String assignmentAttemptNumber(int number);

  /// No description provided for @assignmentLateBadge.
  ///
  /// In en, this message translates to:
  /// **'Handed in late'**
  String get assignmentLateBadge;

  /// No description provided for @assignmentReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get assignmentReviewTitle;

  /// No description provided for @assignmentScore.
  ///
  /// In en, this message translates to:
  /// **'{score} of {max}'**
  String assignmentScore(String score, int max);

  /// No description provided for @assignmentPassMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark {points}'**
  String assignmentPassMark(int points);

  /// No description provided for @assignmentPassMarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Pass mark'**
  String get assignmentPassMarkLabel;

  /// No description provided for @assignmentTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get assignmentTotalLabel;

  /// No description provided for @assignmentReturnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Returned for changes'**
  String get assignmentReturnedTitle;

  /// No description provided for @assignmentAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'With your instructor.'**
  String get assignmentAwaitingReview;

  /// No description provided for @assignmentClosedNote.
  ///
  /// In en, this message translates to:
  /// **'This assignment is closed to new submissions.'**
  String get assignmentClosedNote;

  /// No description provided for @assignmentDueRelative.
  ///
  /// In en, this message translates to:
  /// **'Due {when}'**
  String assignmentDueRelative(String when);

  /// No description provided for @assignmentNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get assignmentNoDeadline;

  /// No description provided for @assignmentSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get assignmentSaveDraft;

  /// No description provided for @assignmentSubmissionTitle.
  ///
  /// In en, this message translates to:
  /// **'What you handed in'**
  String get assignmentSubmissionTitle;

  /// No description provided for @assignmentFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get assignmentFeedbackTitle;

  /// No description provided for @assignmentNoFiles.
  ///
  /// In en, this message translates to:
  /// **'No files yet.'**
  String get assignmentNoFiles;

  /// No description provided for @assignmentFilesLimit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One file.} other{Up to {count} files.}}'**
  String assignmentFilesLimit(int count);

  /// No description provided for @assignmentTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'Out of {points} points'**
  String assignmentTotalPoints(int points);

  /// No description provided for @assignmentCriterionScore.
  ///
  /// In en, this message translates to:
  /// **'{score} of {points}'**
  String assignmentCriterionScore(String score, int points);

  /// No description provided for @assignmentLatePenaltyNote.
  ///
  /// In en, this message translates to:
  /// **'{percent}% is taken off work handed in late.'**
  String assignmentLatePenaltyNote(int percent);

  /// No description provided for @assignmentChartNote.
  ///
  /// In en, this message translates to:
  /// **'Fill in every detail — the chart is taken as one.'**
  String get assignmentChartNote;

  /// No description provided for @assignmentTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'Your answer is too long to save. Shorten it.'**
  String get assignmentTextTooLong;

  /// No description provided for @assignmentInterpretationLabel.
  ///
  /// In en, this message translates to:
  /// **'Your interpretation'**
  String get assignmentInterpretationLabel;

  /// No description provided for @assignmentAttachmentSize.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String assignmentAttachmentSize(String size);

  /// No description provided for @certificatesTabIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get certificatesTabIssued;

  /// No description provided for @certificatesTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get certificatesTabPending;

  /// No description provided for @certificatesTabWorking.
  ///
  /// In en, this message translates to:
  /// **'Working towards'**
  String get certificatesTabWorking;

  /// No description provided for @certificatesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet'**
  String get certificatesEmptyTitle;

  /// No description provided for @certificatesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a course to earn your first certificate.'**
  String get certificatesEmptyBody;

  /// No description provided for @certificatesPendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting to be claimed.'**
  String get certificatesPendingEmpty;

  /// No description provided for @certificatesWorkingEmpty.
  ///
  /// In en, this message translates to:
  /// **'You are not working towards a certificate right now.'**
  String get certificatesWorkingEmpty;

  /// No description provided for @certificateClaimAction.
  ///
  /// In en, this message translates to:
  /// **'Claim certificate'**
  String get certificateClaimAction;

  /// No description provided for @certificateClaimedTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate issued'**
  String get certificateClaimedTitle;

  /// No description provided for @certificateClaimedBody.
  ///
  /// In en, this message translates to:
  /// **'It is in your wallet, and the credential can be verified by anyone you share it with.'**
  String get certificateClaimedBody;

  /// No description provided for @certificateShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share verification link'**
  String get certificateShareAction;

  /// No description provided for @certificateOpenVerification.
  ///
  /// In en, this message translates to:
  /// **'Open the verification page'**
  String get certificateOpenVerification;

  /// No description provided for @certificateShareSubject.
  ///
  /// In en, this message translates to:
  /// **'My certificate: {title}'**
  String certificateShareSubject(String title);

  /// No description provided for @certificateDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate details'**
  String get certificateDetailsTitle;

  /// No description provided for @certificateCompletedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String certificateCompletedOn(String date);

  /// No description provided for @certificateVerificationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not verified yet} =1{Verified once} other{Verified {count} times}}'**
  String certificateVerificationCount(int count);

  /// No description provided for @certificateRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn by the LMS'**
  String get certificateRevokedTitle;

  /// No description provided for @certificatePendingNote.
  ///
  /// In en, this message translates to:
  /// **'You have earned this. Claim it to add it to your wallet.'**
  String get certificatePendingNote;

  /// No description provided for @certificateCanvasLabel.
  ///
  /// In en, this message translates to:
  /// **'{heading} for {course}, awarded to {name}. Credential {id}.'**
  String certificateCanvasLabel(String heading, String course, String name, String id);

  /// No description provided for @certificateCanvasUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The certificate cannot be drawn here. Its details are below.'**
  String get certificateCanvasUnavailable;

  /// No description provided for @certificateCriteriaTitle.
  ///
  /// In en, this message translates to:
  /// **'What is left'**
  String get certificateCriteriaTitle;

  /// No description provided for @certificateCriterionProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}{unit} of {required}{unit}'**
  String certificateCriterionProgress(String current, String required, String unit);

  /// No description provided for @ranksTitle.
  ///
  /// In en, this message translates to:
  /// **'Rank ladder'**
  String get ranksTitle;

  /// No description provided for @ranksCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Where you are now'**
  String get ranksCurrentLabel;

  /// No description provided for @ranksAchievedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get ranksAchievedLabel;

  /// No description provided for @ranksNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next rank'**
  String get ranksNextLabel;

  /// No description provided for @ranksFutureLabel.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get ranksFutureLabel;

  /// No description provided for @ranksRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'What it asks for'**
  String get ranksRequirementsTitle;

  /// No description provided for @ranksRequirement.
  ///
  /// In en, this message translates to:
  /// **'{label}: {required}{unit}'**
  String ranksRequirement(String label, String required, String unit);

  /// No description provided for @ranksNoRequirements.
  ///
  /// In en, this message translates to:
  /// **'No requirements — this is where everyone starts.'**
  String get ranksNoRequirements;

  /// No description provided for @ranksProgressUnknown.
  ///
  /// In en, this message translates to:
  /// **'Your LMS does not publish how far along you are.'**
  String get ranksProgressUnknown;

  /// No description provided for @ranksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No ranks yet'**
  String get ranksEmptyTitle;

  /// No description provided for @ranksEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your LMS has not set up a rank ladder.'**
  String get ranksEmptyBody;

  /// No description provided for @liveTabLiveNow.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get liveTabLiveNow;

  /// No description provided for @liveTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get liveTabUpcoming;

  /// No description provided for @liveTabRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get liveTabRecordings;

  /// No description provided for @liveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No live classes scheduled'**
  String get liveEmptyTitle;

  /// No description provided for @liveEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Live classes for your courses appear here.'**
  String get liveEmptyBody;

  /// No description provided for @liveJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Join the class'**
  String get liveJoinAction;

  /// No description provided for @liveJoinOpensNote.
  ///
  /// In en, this message translates to:
  /// **'Join opens 15 minutes before the start.'**
  String get liveJoinOpensNote;

  /// No description provided for @liveRoomUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The class couldn’t open on this phone. Check your connection and try again.'**
  String get liveRoomUnavailable;

  /// No description provided for @liveConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the class…'**
  String get liveConnecting;

  /// No description provided for @liveWaitingForHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to start the class. Join appears here as soon as they do.'**
  String liveWaitingForHost(String name);

  /// No description provided for @liveJoinedSoFar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nobody has joined yet} =1{1 learner has joined} other{{count} learners have joined}}'**
  String liveJoinedSoFar(int count);

  /// No description provided for @liveYouAttended.
  ///
  /// In en, this message translates to:
  /// **'You attended this class'**
  String get liveYouAttended;

  /// No description provided for @liveYouMissed.
  ///
  /// In en, this message translates to:
  /// **'You missed this class'**
  String get liveYouMissed;

  /// No description provided for @liveAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Your attendance'**
  String get liveAttendanceTitle;

  /// No description provided for @liveAttendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get liveAttendedBadge;

  /// No description provided for @liveMissedBadge.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get liveMissedBadge;

  /// No description provided for @liveJoinedBadge.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get liveJoinedBadge;

  /// No description provided for @liveOpenedLinkBadge.
  ///
  /// In en, this message translates to:
  /// **'Opened the link'**
  String get liveOpenedLinkBadge;

  /// No description provided for @liveConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'The class connection was lost. If the class is still on, join again.'**
  String get liveConnectionLost;

  /// No description provided for @liveLinkUnusable.
  ///
  /// In en, this message translates to:
  /// **'This class’s meeting link can’t be opened. Ask your LMS for a new one.'**
  String get liveLinkUnusable;

  /// No description provided for @liveLinkNotOpened.
  ///
  /// In en, this message translates to:
  /// **'The meeting link couldn’t be opened on this phone. Check that a browser is installed, then try again.'**
  String get liveLinkNotOpened;

  /// No description provided for @liveRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t refresh. Showing the last update.'**
  String get liveRefreshFailed;

  /// No description provided for @liveJoinOtherHostBody.
  ///
  /// In en, this message translates to:
  /// **'The meeting is now on {host}. This opens it outside the app.'**
  String liveJoinOtherHostBody(String host);

  /// No description provided for @liveWatchRecording.
  ///
  /// In en, this message translates to:
  /// **'Watch recording'**
  String get liveWatchRecording;

  /// No description provided for @liveRecordingProcessing.
  ///
  /// In en, this message translates to:
  /// **'The recording is being prepared. It is usually ready a few minutes after the class.'**
  String get liveRecordingProcessing;

  /// No description provided for @liveRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Save my seat'**
  String get liveRegisterAction;

  /// No description provided for @liveUnregisterAction.
  ///
  /// In en, this message translates to:
  /// **'Give up my seat'**
  String get liveUnregisterAction;

  /// No description provided for @liveRegisteredBadge.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get liveRegisteredBadge;

  /// No description provided for @liveSpotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No seats left} =1{1 seat left} other{{count} seats left}}'**
  String liveSpotsLeft(int count);

  /// No description provided for @liveCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 seat} other{{count} seats}}'**
  String liveCapacityLabel(int count);

  /// No description provided for @liveCancelledNote.
  ///
  /// In en, this message translates to:
  /// **'This class was cancelled.'**
  String get liveCancelledNote;

  /// No description provided for @liveEndedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}'**
  String liveEndedOn(String date);

  /// No description provided for @liveRecordingUntil.
  ///
  /// In en, this message translates to:
  /// **'Recording available until {date}'**
  String liveRecordingUntil(String date);

  /// No description provided for @liveRecordingLength.
  ///
  /// In en, this message translates to:
  /// **'Recording · {minutes} minutes'**
  String liveRecordingLength(int minutes);

  /// No description provided for @liveRecordingNotPlayable.
  ///
  /// In en, this message translates to:
  /// **'This recording can’t be played here.'**
  String get liveRecordingNotPlayable;

  /// No description provided for @liveAgendaTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens'**
  String get liveAgendaTitle;

  /// No description provided for @liveAgendaItem.
  ///
  /// In en, this message translates to:
  /// **'{title} · {minutes} min'**
  String liveAgendaItem(String title, int minutes);

  /// No description provided for @liveWithInstructor.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String liveWithInstructor(String name);

  /// No description provided for @liveRemindersNote.
  ///
  /// In en, this message translates to:
  /// **'Registrants are reminded before it starts.'**
  String get liveRemindersNote;

  /// No description provided for @liveJoinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the meeting?'**
  String get liveJoinConfirmTitle;

  /// No description provided for @liveJoinConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This opens {host} outside the app.'**
  String liveJoinConfirmBody(String host);

  /// No description provided for @liveNotInSchedule.
  ///
  /// In en, this message translates to:
  /// **'This class is not in your schedule.'**
  String get liveNotInSchedule;

  /// No description provided for @liveAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About this class'**
  String get liveAboutTitle;

  /// No description provided for @notificationsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsTabAll;

  /// No description provided for @notificationsTabUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsTabUnread;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New notices from your LMS appear here.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here right now.'**
  String get notificationsFilterEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to mark} =1{1 marked read} other{{count} marked read}}'**
  String notificationsMarkedRead(int count);

  /// No description provided for @notificationsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get notificationsClear;

  /// No description provided for @notificationsClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear these notifications?'**
  String get notificationsClearConfirmTitle;

  /// No description provided for @notificationsClearConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification will be removed.} other{{count} notifications will be removed.}}'**
  String notificationsClearConfirmBody(int count);

  /// No description provided for @notificationsCleared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cleared} other{{count} cleared}}'**
  String notificationsCleared(int count);

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get notificationsMarkRead;

  /// No description provided for @notificationsMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark unread'**
  String get notificationsMarkUnread;

  /// No description provided for @notificationsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get notificationsRemove;

  /// No description provided for @notificationsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Notification removed'**
  String get notificationsRemoved;

  /// No description provided for @notificationsRestored.
  ///
  /// In en, this message translates to:
  /// **'Put back'**
  String get notificationsRestored;

  /// No description provided for @notificationsUnreadBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread notification} other{{count} unread notifications}}'**
  String notificationsUnreadBadge(int count);

  /// No description provided for @notificationsShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show older'**
  String get notificationsShowMore;

  /// No description provided for @notificationImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get notificationImportant;

  /// No description provided for @notificationRelatedTitle.
  ///
  /// In en, this message translates to:
  /// **'More like this'**
  String get notificationRelatedTitle;

  /// No description provided for @notificationSentOn.
  ///
  /// In en, this message translates to:
  /// **'Sent to: {channels}'**
  String notificationSentOn(String channels);

  /// No description provided for @notificationChannelApp.
  ///
  /// In en, this message translates to:
  /// **'the app'**
  String get notificationChannelApp;

  /// No description provided for @notificationChannelEmail.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get notificationChannelEmail;

  /// No description provided for @notificationChannelSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get notificationChannelSms;

  /// No description provided for @notificationCategoryCourse.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get notificationCategoryCourse;

  /// No description provided for @notificationCategoryAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get notificationCategoryAssignment;

  /// No description provided for @notificationCategoryQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get notificationCategoryQuiz;

  /// No description provided for @notificationCategoryLive.
  ///
  /// In en, this message translates to:
  /// **'Live classes'**
  String get notificationCategoryLive;

  /// No description provided for @notificationCategoryCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get notificationCategoryCertificate;

  /// No description provided for @notificationCategoryEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Enrolments'**
  String get notificationCategoryEnrollment;

  /// No description provided for @notificationCategorySystem.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get notificationCategorySystem;

  /// No description provided for @notificationPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationPrefsTitle;

  /// No description provided for @notificationPrefsCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'What you hear about'**
  String get notificationPrefsCategoriesTitle;

  /// No description provided for @notificationPrefsChannelApp.
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get notificationPrefsChannelApp;

  /// No description provided for @notificationPrefsChannelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get notificationPrefsChannelEmail;

  /// No description provided for @notificationPrefsChannelSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get notificationPrefsChannelSms;

  /// No description provided for @notificationPrefsSmsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your LMS cannot send text messages yet.'**
  String get notificationPrefsSmsUnavailable;

  /// No description provided for @notificationPrefsLocked.
  ///
  /// In en, this message translates to:
  /// **'Account and security notices stay on in the app and by email.'**
  String get notificationPrefsLocked;

  /// No description provided for @notificationPrefsDigestTitle.
  ///
  /// In en, this message translates to:
  /// **'Email digest'**
  String get notificationPrefsDigestTitle;

  /// No description provided for @notificationPrefsDigestInstant.
  ///
  /// In en, this message translates to:
  /// **'As they happen'**
  String get notificationPrefsDigestInstant;

  /// No description provided for @notificationPrefsDigestDaily.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get notificationPrefsDigestDaily;

  /// No description provided for @notificationPrefsDigestWeekly.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get notificationPrefsDigestWeekly;

  /// No description provided for @notificationPrefsDigestOff.
  ///
  /// In en, this message translates to:
  /// **'No email digest'**
  String get notificationPrefsDigestOff;

  /// No description provided for @notificationPrefsQuietTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notificationPrefsQuietTitle;

  /// No description provided for @notificationPrefsQuietEnabled.
  ///
  /// In en, this message translates to:
  /// **'Nothing between these times'**
  String get notificationPrefsQuietEnabled;

  /// No description provided for @notificationPrefsQuietFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get notificationPrefsQuietFrom;

  /// No description provided for @notificationPrefsQuietTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get notificationPrefsQuietTo;

  /// No description provided for @notificationPrefsQuietNote.
  ///
  /// In en, this message translates to:
  /// **'Times are your LMS’s, in IST.'**
  String get notificationPrefsQuietNote;

  /// No description provided for @notificationPrefsPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get notificationPrefsPauseTitle;

  /// No description provided for @notificationPrefsPausedUntil.
  ///
  /// In en, this message translates to:
  /// **'Paused until {date}'**
  String notificationPrefsPausedUntil(String date);

  /// No description provided for @notificationPrefsPauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause notifications'**
  String get notificationPrefsPauseAction;

  /// No description provided for @notificationPrefsResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Turn notifications back on'**
  String get notificationPrefsResumeAction;

  /// No description provided for @notificationPrefsPauseNote.
  ///
  /// In en, this message translates to:
  /// **'Important notices still arrive while notifications are paused.'**
  String get notificationPrefsPauseNote;

  /// No description provided for @notificationPrefsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get notificationPrefsSaved;

  /// No description provided for @notificationPrefsUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get notificationPrefsUnsavedTitle;

  /// No description provided for @notificationPrefsUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes to these settings have not been saved.'**
  String get notificationPrefsUnsavedBody;

  /// No description provided for @notificationPrefsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get notificationPrefsDiscard;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get profileSignedInAs;

  /// No description provided for @profileRankTitle.
  ///
  /// In en, this message translates to:
  /// **'Your standing'**
  String get profileRankTitle;

  /// No description provided for @profileActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get profileActivityTitle;

  /// No description provided for @profileActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'What you do in your courses shows up here.'**
  String get profileActivityEmpty;

  /// No description provided for @profileWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get profileWeekTitle;

  /// No description provided for @profileWeekMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes this week'**
  String profileWeekMinutes(int minutes);

  /// No description provided for @profileLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get profileLinksTitle;

  /// No description provided for @profileGroupAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileGroupAccount;

  /// No description provided for @profileGroupLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get profileGroupLearning;

  /// No description provided for @profileMyCoursesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In progress, completed and saved'**
  String get profileMyCoursesSubtitle;

  /// No description provided for @profileGroupSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get profileGroupSupport;

  /// No description provided for @profileGroupAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileGroupAbout;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePassword;

  /// No description provided for @profileChangePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Your LMS sends a link to {email}. Open it to set a new password.'**
  String profileChangePasswordBody(String email);

  /// No description provided for @profileChangePasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for the link.'**
  String get profileChangePasswordSent;

  /// No description provided for @profileSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutConfirmTitle;

  /// No description provided for @profileSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your downloads and cached pages on this device are removed. Your work stays with your LMS.'**
  String get profileSignOutConfirmBody;

  /// No description provided for @profileAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get profileAboutTitle;

  /// No description provided for @profileAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String profileAboutVersion(String version, String build);

  /// No description provided for @profileContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get profileContactSupport;

  /// No description provided for @profileContactSupportBody.
  ///
  /// In en, this message translates to:
  /// **'Email synilogicteam@gmail.com. We reply within a working day.'**
  String get profileContactSupportBody;

  /// No description provided for @supportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'ZuviloAI app support'**
  String get supportEmailSubject;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountIntro.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is immediate and cannot be undone. You will be signed out on every device, and you cannot sign back in to this account.'**
  String get deleteAccountIntro;

  /// No description provided for @deleteAccountRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'What is deleted'**
  String get deleteAccountRemovedTitle;

  /// No description provided for @deleteAccountRemovedIdentity.
  ///
  /// In en, this message translates to:
  /// **'Your name and email address. The address is free to register again.'**
  String get deleteAccountRemovedIdentity;

  /// No description provided for @deleteAccountRemovedPersonal.
  ///
  /// In en, this message translates to:
  /// **'Your lesson notes, bookmarks, saved courses, assignment drafts and live-class registrations.'**
  String get deleteAccountRemovedPersonal;

  /// No description provided for @deleteAccountRemovedDevice.
  ///
  /// In en, this message translates to:
  /// **'Your notifications, notification preferences and every signed-in session and device.'**
  String get deleteAccountRemovedDevice;

  /// No description provided for @deleteAccountKeptTitle.
  ///
  /// In en, this message translates to:
  /// **'What is kept'**
  String get deleteAccountKeptTitle;

  /// No description provided for @deleteAccountKeptRecords.
  ///
  /// In en, this message translates to:
  /// **'Course progress, quiz and assignment records and issued certificates stay with the LMS, no longer linked to your name, so a credential someone relies on still verifies.'**
  String get deleteAccountKeptRecords;

  /// No description provided for @deleteAccountWeb.
  ///
  /// In en, this message translates to:
  /// **'You can also delete your account on the web at zuviloai.com/delete-account.'**
  String get deleteAccountWeb;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountAction;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm it is you.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand my account is deleted for good.'**
  String get deleteAccountAcknowledge;

  /// No description provided for @deleteAccountDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteAccountDoneMessage;

  /// No description provided for @deleteAccountStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting a staff account'**
  String get deleteAccountStaffTitle;

  /// No description provided for @deleteAccountStaffBody.
  ///
  /// In en, this message translates to:
  /// **'Instructor and admin accounts belong to your LMS, so its admin closes them. Ask them to remove your account, or contact support.'**
  String get deleteAccountStaffBody;

  /// No description provided for @registerAgreement.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to the terms of use and acknowledge the privacy policy.'**
  String get registerAgreement;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match my phone'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsReducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReducedMotion;

  /// No description provided for @settingsReducedMotionBody.
  ///
  /// In en, this message translates to:
  /// **'Less movement in animations, on top of your phone’s own setting.'**
  String get settingsReducedMotionBody;

  /// No description provided for @settingsTextSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSizeTitle;

  /// No description provided for @settingsTextSizeBody.
  ///
  /// In en, this message translates to:
  /// **'This is a preview. Your phone’s own text size setting is what really decides.'**
  String get settingsTextSizeBody;

  /// No description provided for @settingsTextSizeSample.
  ///
  /// In en, this message translates to:
  /// **'The Moon is in Rohini today.'**
  String get settingsTextSizeSample;

  /// No description provided for @settingsStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorageTitle;

  /// No description provided for @settingsClearImageCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cached images'**
  String get settingsClearImageCache;

  /// No description provided for @settingsClearImageCacheBody.
  ///
  /// In en, this message translates to:
  /// **'Frees space on this device. Nothing is removed from your LMS.'**
  String get settingsClearImageCacheBody;

  /// No description provided for @settingsImageCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cached images cleared'**
  String get settingsImageCacheCleared;

  /// No description provided for @activityEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get activityEnrolled;

  /// No description provided for @activityLessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lesson completed'**
  String get activityLessonCompleted;

  /// No description provided for @activityChapterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Chapter completed'**
  String get activityChapterCompleted;

  /// No description provided for @activityLiveAttended.
  ///
  /// In en, this message translates to:
  /// **'Live class attended'**
  String get activityLiveAttended;

  /// No description provided for @activityAssignmentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Assignment handed in'**
  String get activityAssignmentSubmitted;

  /// No description provided for @activityAssessmentPassed.
  ///
  /// In en, this message translates to:
  /// **'Quiz passed'**
  String get activityAssessmentPassed;

  /// No description provided for @activityCertificateIssued.
  ///
  /// In en, this message translates to:
  /// **'Certificate issued'**
  String get activityCertificateIssued;

  /// No description provided for @activityRankAchieved.
  ///
  /// In en, this message translates to:
  /// **'New rank'**
  String get activityRankAchieved;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get dashboardAttentionTitle;

  /// No description provided for @dashboardHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your LMS at a glance'**
  String get dashboardHeroTitle;

  /// No description provided for @dashboardHeroAttention.
  ///
  /// In en, this message translates to:
  /// **'Waiting on you'**
  String get dashboardHeroAttention;

  /// No description provided for @dashboardHeroLive.
  ///
  /// In en, this message translates to:
  /// **'Live classes ahead'**
  String get dashboardHeroLive;

  /// No description provided for @dashboardHeroLearners.
  ///
  /// In en, this message translates to:
  /// **'Your learners'**
  String get dashboardHeroLearners;

  /// No description provided for @dashboardAttentionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for you.'**
  String get dashboardAttentionEmpty;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Do next'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardActionReview.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get dashboardActionReview;

  /// No description provided for @dashboardActionScheduleLive.
  ///
  /// In en, this message translates to:
  /// **'Schedule a live class'**
  String get dashboardActionScheduleLive;

  /// No description provided for @dashboardActionStudents.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get dashboardActionStudents;

  /// No description provided for @dashboardActionEnrol.
  ///
  /// In en, this message translates to:
  /// **'Add an enrolment'**
  String get dashboardActionEnrol;

  /// No description provided for @dashboardUpcomingLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming up live'**
  String get dashboardUpcomingLiveTitle;

  /// No description provided for @dashboardKpisTitle.
  ///
  /// In en, this message translates to:
  /// **'How things stand'**
  String get dashboardKpisTitle;

  /// No description provided for @dashboardKpiCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get dashboardKpiCourses;

  /// No description provided for @dashboardKpiStudents.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get dashboardKpiStudents;

  /// No description provided for @dashboardKpiInstructors.
  ///
  /// In en, this message translates to:
  /// **'Active instructors'**
  String get dashboardKpiInstructors;

  /// No description provided for @dashboardKpiWaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get dashboardKpiWaitingReview;

  /// No description provided for @dashboardKpiCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get dashboardKpiCompletion;

  /// No description provided for @dashboardComparison.
  ///
  /// In en, this message translates to:
  /// **'vs the period before'**
  String get dashboardComparison;

  /// No description provided for @dashboardTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrolments and completions'**
  String get dashboardTrendsTitle;

  /// No description provided for @dashboardTrendEnrollments.
  ///
  /// In en, this message translates to:
  /// **'New enrolments'**
  String get dashboardTrendEnrollments;

  /// No description provided for @dashboardTrendCompletions.
  ///
  /// In en, this message translates to:
  /// **'Completions'**
  String get dashboardTrendCompletions;

  /// No description provided for @dashboardEngagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Engagement this week'**
  String get dashboardEngagementTitle;

  /// No description provided for @dashboardEngagementLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons completed'**
  String get dashboardEngagementLessons;

  /// No description provided for @dashboardEngagementQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quiz attempts'**
  String get dashboardEngagementQuizzes;

  /// No description provided for @dashboardEngagementSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Hand-ins'**
  String get dashboardEngagementSubmissions;

  /// No description provided for @dashboardEngagementLive.
  ///
  /// In en, this message translates to:
  /// **'Live attendance'**
  String get dashboardEngagementLive;

  /// No description provided for @dashboardActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get dashboardActivityTitle;

  /// No description provided for @dashboardActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has happened yet.'**
  String get dashboardActivityEmpty;

  /// No description provided for @dashboardCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Course performance'**
  String get dashboardCoursesTitle;

  /// No description provided for @dashboardCourseFacts.
  ///
  /// In en, this message translates to:
  /// **'{enrolled} enrolled · {active} active in the last 2 weeks'**
  String dashboardCourseFacts(int enrolled, int active);

  /// No description provided for @dashboardCourseProgress.
  ///
  /// In en, this message translates to:
  /// **'{completion}% complete · {progress}% average progress'**
  String dashboardCourseProgress(String completion, String progress);

  /// No description provided for @dashboardScopeAcademy.
  ///
  /// In en, this message translates to:
  /// **'Whole LMS'**
  String get dashboardScopeAcademy;

  /// No description provided for @dashboardScopeInstructor.
  ///
  /// In en, this message translates to:
  /// **'One instructor'**
  String get dashboardScopeInstructor;

  /// No description provided for @dashboardScopePick.
  ///
  /// In en, this message translates to:
  /// **'Choose an instructor'**
  String get dashboardScopePick;

  /// No description provided for @dashboardGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'As of {time}'**
  String dashboardGeneratedAt(String time);

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Figures appear here as your LMS teaches.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardSparkline.
  ///
  /// In en, this message translates to:
  /// **'{label} over the last {count} periods'**
  String dashboardSparkline(String label, int count);

  /// No description provided for @staffCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get staffCoursesTitle;

  /// No description provided for @staffCoursesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search courses'**
  String get staffCoursesSearch;

  /// No description provided for @staffCoursesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No courses yet'**
  String get staffCoursesEmptyTitle;

  /// No description provided for @staffCoursesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Courses are created on the web. They appear here once they exist.'**
  String get staffCoursesEmptyBody;

  /// No description provided for @staffCourseStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get staffCourseStatusAll;

  /// No description provided for @staffCourseStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get staffCourseStatusDraft;

  /// No description provided for @staffCourseStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get staffCourseStatusPublished;

  /// No description provided for @staffCourseStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get staffCourseStatusArchived;

  /// No description provided for @staffCourseSortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get staffCourseSortUpdated;

  /// No description provided for @staffCourseSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get staffCourseSortTitle;

  /// No description provided for @staffCourseSortLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get staffCourseSortLearners;

  /// No description provided for @staffCourseSortCreated.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get staffCourseSortCreated;

  /// No description provided for @staffCourseLearners.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 learner} other{{count} learners}}'**
  String staffCourseLearners(int count);

  /// No description provided for @staffCourseLessons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson} other{{count} lessons}}'**
  String staffCourseLessons(int count);

  /// No description provided for @staffCourseOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get staffCourseOverviewTitle;

  /// No description provided for @staffCourseStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'How it is going'**
  String get staffCourseStatsTitle;

  /// No description provided for @staffCourseStatEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get staffCourseStatEnrolled;

  /// No description provided for @staffCourseStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get staffCourseStatActive;

  /// No description provided for @staffCourseStatCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get staffCourseStatCompletion;

  /// No description provided for @staffCourseStatProgress.
  ///
  /// In en, this message translates to:
  /// **'Average progress'**
  String get staffCourseStatProgress;

  /// No description provided for @staffCourseStatCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates issued'**
  String get staffCourseStatCertificates;

  /// No description provided for @staffCourseStatReviews.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get staffCourseStatReviews;

  /// No description provided for @staffCourseStatMinutes.
  ///
  /// In en, this message translates to:
  /// **'Published minutes'**
  String get staffCourseStatMinutes;

  /// No description provided for @staffCourseCurriculumTitle.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get staffCourseCurriculumTitle;

  /// No description provided for @staffCourseCurriculumFacts.
  ///
  /// In en, this message translates to:
  /// **'{chapters} chapters · {lessons} lessons'**
  String staffCourseCurriculumFacts(int chapters, int lessons);

  /// No description provided for @staffCourseChapterProgress.
  ///
  /// In en, this message translates to:
  /// **'{started}% started · {completed}% completed'**
  String staffCourseChapterProgress(String started, String completed);

  /// No description provided for @staffCourseLessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed it'**
  String staffCourseLessonCompleted(String percent);

  /// No description provided for @staffCourseOutcomesTitle.
  ///
  /// In en, this message translates to:
  /// **'What learners will be able to do'**
  String get staffCourseOutcomesTitle;

  /// No description provided for @staffCourseInstructorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Who teaches it'**
  String get staffCourseInstructorsTitle;

  /// No description provided for @staffCourseRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent learners'**
  String get staffCourseRecentTitle;

  /// No description provided for @staffCourseActionPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get staffCourseActionPublish;

  /// No description provided for @staffCourseActionUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get staffCourseActionUnpublish;

  /// No description provided for @staffCourseActionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get staffCourseActionArchive;

  /// No description provided for @staffCourseActionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get staffCourseActionRestore;

  /// No description provided for @staffCourseEditOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Edit on the web'**
  String get staffCourseEditOnWeb;

  /// No description provided for @staffCoursePublishConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Take this course live?'**
  String get staffCoursePublishConfirmTitle;

  /// No description provided for @staffCoursePublishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Learners will find it in the catalogue and can enrol.'**
  String get staffCoursePublishConfirmBody;

  /// No description provided for @staffCourseUnpublishConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Take it out of the catalogue?'**
  String get staffCourseUnpublishConfirmTitle;

  /// No description provided for @staffCourseUnpublishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Learners already enrolled keep their access; nobody new can find it.'**
  String get staffCourseUnpublishConfirmBody;

  /// No description provided for @staffCourseArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this course?'**
  String get staffCourseArchiveConfirmTitle;

  /// No description provided for @staffCourseArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the catalogue and the course lists. It can be restored later.'**
  String get staffCourseArchiveConfirmBody;

  /// No description provided for @staffCourseRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring this course back?'**
  String get staffCourseRestoreConfirmTitle;

  /// No description provided for @staffCourseRestoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It returns as a draft and counts against your LMS plan again.'**
  String get staffCourseRestoreConfirmBody;

  /// No description provided for @staffCourseChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Not ready to publish yet'**
  String get staffCourseChecklistTitle;

  /// No description provided for @staffCourseChecklistBody.
  ///
  /// In en, this message translates to:
  /// **'Your LMS asks for these before a course goes live.'**
  String get staffCourseChecklistBody;

  /// No description provided for @staffCoursePublished.
  ///
  /// In en, this message translates to:
  /// **'The course is live'**
  String get staffCoursePublished;

  /// No description provided for @staffCourseUnpublished.
  ///
  /// In en, this message translates to:
  /// **'The course is a draft again'**
  String get staffCourseUnpublished;

  /// No description provided for @staffCourseArchived.
  ///
  /// In en, this message translates to:
  /// **'The course is archived'**
  String get staffCourseArchived;

  /// No description provided for @staffCourseRestored.
  ///
  /// In en, this message translates to:
  /// **'The course is back as a draft'**
  String get staffCourseRestored;

  /// No description provided for @staffLessonPreviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Free preview'**
  String get staffLessonPreviewBadge;

  /// No description provided for @staffLessonObjectivesTitle.
  ///
  /// In en, this message translates to:
  /// **'What this lesson covers'**
  String get staffLessonObjectivesTitle;

  /// No description provided for @staffLessonContentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This lesson has nothing in it yet.'**
  String get staffLessonContentUnavailable;

  /// No description provided for @staffLessonEditOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Edit this lesson on the web'**
  String get staffLessonEditOnWeb;

  /// No description provided for @staffCoursesFilterAnyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get staffCoursesFilterAnyCategory;

  /// No description provided for @staffCoursesFilterAnyInstructor.
  ///
  /// In en, this message translates to:
  /// **'Any instructor'**
  String get staffCoursesFilterAnyInstructor;

  /// No description provided for @staffCoursesCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get staffCoursesCategoryLabel;

  /// No description provided for @staffCoursesInstructorLabel.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get staffCoursesInstructorLabel;

  /// No description provided for @staffCoursesSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get staffCoursesSortLabel;

  /// No description provided for @staffCoursesPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String staffCoursesPageOf(int page, int pages);

  /// No description provided for @staffCourseVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Who can find it'**
  String get staffCourseVisibilityLabel;

  /// No description provided for @staffCourseVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get staffCourseVisibilityPublic;

  /// No description provided for @staffCourseVisibilityUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Only with the link'**
  String get staffCourseVisibilityUnlisted;

  /// No description provided for @staffCourseVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Invited learners only'**
  String get staffCourseVisibilityPrivate;

  /// No description provided for @staffCourseProgressSpreadTitle.
  ///
  /// In en, this message translates to:
  /// **'How far learners have got'**
  String get staffCourseProgressSpreadTitle;

  /// No description provided for @staffCourseWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'New enrolments a week'**
  String get staffCourseWeeklyTitle;

  /// No description provided for @staffCourseUpcomingLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live classes coming up'**
  String get staffCourseUpcomingLiveTitle;

  /// No description provided for @staffCourseCurriculumEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chapters yet. Build the curriculum on the web.'**
  String get staffCourseCurriculumEmpty;

  /// No description provided for @staffCourseNoLearnersYet.
  ///
  /// In en, this message translates to:
  /// **'Nobody has enrolled yet.'**
  String get staffCourseNoLearnersYet;

  /// No description provided for @staffCourseActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Course actions'**
  String get staffCourseActionsTitle;

  /// No description provided for @staffCourseArchiveAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand learners will no longer find this course'**
  String get staffCourseArchiveAcknowledge;

  /// No description provided for @staffCourseChecklistMet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get staffCourseChecklistMet;

  /// No description provided for @staffCourseChecklistUnmet.
  ///
  /// In en, this message translates to:
  /// **'Still needed'**
  String get staffCourseChecklistUnmet;

  /// No description provided for @staffCourseChapterLessons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson} other{{count} lessons}}'**
  String staffCourseChapterLessons(int count);

  /// No description provided for @staffLessonNeighbourHint.
  ///
  /// In en, this message translates to:
  /// **'Lesson {index} of {total} in this course'**
  String staffLessonNeighbourHint(int index, int total);

  /// No description provided for @staffLessonDueAfterDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Due 1 day after a learner starts it} other{Due {count} days after a learner starts it}}'**
  String staffLessonDueAfterDays(int count);

  /// No description provided for @staffLessonDeliversTitle.
  ///
  /// In en, this message translates to:
  /// **'What it delivers'**
  String get staffLessonDeliversTitle;

  /// No description provided for @staffLessonContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson content'**
  String get staffLessonContentTitle;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// No description provided for @reviewQueueToReview.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get reviewQueueToReview;

  /// No description provided for @reviewQueueOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get reviewQueueOverdue;

  /// No description provided for @reviewQueueByCourse.
  ///
  /// In en, this message translates to:
  /// **'By course'**
  String get reviewQueueByCourse;

  /// No description provided for @reviewQueueClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get reviewQueueClearTitle;

  /// No description provided for @reviewQueueClearBody.
  ///
  /// In en, this message translates to:
  /// **'Every hand-in has been looked at. Nice work.'**
  String get reviewQueueClearBody;

  /// No description provided for @reviewSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by learner'**
  String get reviewSearchHint;

  /// No description provided for @reviewTabToReview.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get reviewTabToReview;

  /// No description provided for @reviewTabGraded.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get reviewTabGraded;

  /// No description provided for @reviewTabReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get reviewTabReturned;

  /// No description provided for @reviewTabMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get reviewTabMissing;

  /// No description provided for @reviewTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reviewTabAll;

  /// No description provided for @reviewSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get reviewSortLabel;

  /// No description provided for @reviewSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get reviewSortOldest;

  /// No description provided for @reviewSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get reviewSortNewest;

  /// No description provided for @reviewSortScore.
  ///
  /// In en, this message translates to:
  /// **'Highest score'**
  String get reviewSortScore;

  /// No description provided for @reviewAssignmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get reviewAssignmentLabel;

  /// No description provided for @reviewAllAssignments.
  ///
  /// In en, this message translates to:
  /// **'Every assignment'**
  String get reviewAllAssignments;

  /// No description provided for @reviewNotHandedIn.
  ///
  /// In en, this message translates to:
  /// **'Nothing handed in yet'**
  String get reviewNotHandedIn;

  /// No description provided for @reviewAttemptNumber.
  ///
  /// In en, this message translates to:
  /// **'Attempt {number}'**
  String reviewAttemptNumber(int number);

  /// No description provided for @reviewSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Handed in {date}'**
  String reviewSubmittedOn(String date);

  /// No description provided for @reviewScoreOf.
  ///
  /// In en, this message translates to:
  /// **'{score} of {max}'**
  String reviewScoreOf(String score, String max);

  /// No description provided for @staffReviewCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get staffReviewCourseLabel;

  /// No description provided for @staffReviewAllCourses.
  ///
  /// In en, this message translates to:
  /// **'Every course'**
  String get staffReviewAllCourses;

  /// No description provided for @reviewPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String reviewPageOf(int page, int pages);

  /// No description provided for @reviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get reviewEmptyTitle;

  /// No description provided for @reviewEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No hand-in matches what you are looking at.'**
  String get reviewEmptyBody;

  /// No description provided for @reviewBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'The brief'**
  String get reviewBriefTitle;

  /// No description provided for @reviewLearnerWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'What the learner handed in'**
  String get reviewLearnerWorkTitle;

  /// No description provided for @reviewLearnerProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% through the course'**
  String reviewLearnerProgress(String percent);

  /// No description provided for @reviewEnrolledOn.
  ///
  /// In en, this message translates to:
  /// **'Enrolled {date}'**
  String reviewEnrolledOn(String date);

  /// No description provided for @reviewScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'The score'**
  String get reviewScoreTitle;

  /// No description provided for @reviewPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points out of {max}'**
  String reviewPointsLabel(String max);

  /// No description provided for @reviewFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback for the learner'**
  String get reviewFeedbackTitle;

  /// No description provided for @reviewFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'What was good, and what to do next.'**
  String get reviewFeedbackHint;

  /// No description provided for @reviewPrivateNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Private note'**
  String get reviewPrivateNoteTitle;

  /// No description provided for @reviewPrivateNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Anything you want to remember about this hand-in.'**
  String get reviewPrivateNoteHint;

  /// No description provided for @reviewPrivateNoteOnlyStaff.
  ///
  /// In en, this message translates to:
  /// **'Only staff see this. The learner never does.'**
  String get reviewPrivateNoteOnlyStaff;

  /// No description provided for @reviewActionSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get reviewActionSaveDraft;

  /// No description provided for @reviewActionReturn.
  ///
  /// In en, this message translates to:
  /// **'Return for changes'**
  String get reviewActionReturn;

  /// No description provided for @reviewActionGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get reviewActionGrade;

  /// No description provided for @reviewDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Your draft review is saved'**
  String get reviewDraftSaved;

  /// No description provided for @reviewGradedMessage.
  ///
  /// In en, this message translates to:
  /// **'Graded. The learner has been told.'**
  String get reviewGradedMessage;

  /// No description provided for @reviewReturnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sent back for another attempt.'**
  String get reviewReturnedMessage;

  /// No description provided for @reviewGradeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this grade to the learner?'**
  String get reviewGradeConfirmTitle;

  /// No description provided for @reviewGradeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will be told their score and can read your feedback. The LMS works the final score out itself.'**
  String get reviewGradeConfirmBody;

  /// No description provided for @reviewGradeEstimate.
  ///
  /// In en, this message translates to:
  /// **'About {score} of {max} — the LMS works out the final score'**
  String reviewGradeEstimate(String score, String max);

  /// No description provided for @reviewGradeEstimatePass.
  ///
  /// In en, this message translates to:
  /// **'Above the pass mark of {passMark}'**
  String reviewGradeEstimatePass(String passMark);

  /// No description provided for @reviewGradeEstimateFail.
  ///
  /// In en, this message translates to:
  /// **'Below the pass mark of {passMark}'**
  String reviewGradeEstimateFail(String passMark);

  /// No description provided for @reviewLatePenaltyNote.
  ///
  /// In en, this message translates to:
  /// **'This hand-in was late. The LMS may take {percent}% off.'**
  String reviewLatePenaltyNote(String percent);

  /// No description provided for @reviewReturnConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask for another attempt?'**
  String get reviewReturnConfirmTitle;

  /// No description provided for @reviewReturnConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The learner keeps your feedback and can hand in again.'**
  String get reviewReturnConfirmBody;

  /// No description provided for @reviewNextInQueue.
  ///
  /// In en, this message translates to:
  /// **'Next to review'**
  String get reviewNextInQueue;

  /// No description provided for @reviewQueuePosition.
  ///
  /// In en, this message translates to:
  /// **'{position} of {total} waiting'**
  String reviewQueuePosition(int position, int total);

  /// No description provided for @reviewLeaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get reviewLeaveConfirmTitle;

  /// No description provided for @reviewLeaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your score and feedback have not been sent. Save a draft first to keep them.'**
  String get reviewLeaveConfirmBody;

  /// No description provided for @reviewLeaveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get reviewLeaveConfirmAction;

  /// No description provided for @reviewRemindAction.
  ///
  /// In en, this message translates to:
  /// **'Remind who is missing'**
  String get reviewRemindAction;

  /// No description provided for @reviewRemindConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind the learners who owe this?'**
  String get reviewRemindConfirmTitle;

  /// No description provided for @reviewRemindConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone who has not handed in gets a notice. The LMS decides who that is.'**
  String get reviewRemindConfirmBody;

  /// No description provided for @reviewRemindSent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nobody needed a reminder} =1{1 learner was reminded} other{{count} learners were reminded}}'**
  String reviewRemindSent(int count);

  /// No description provided for @reviewMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Still to hand in'**
  String get reviewMissingTitle;

  /// No description provided for @reviewOpenAssignment.
  ///
  /// In en, this message translates to:
  /// **'All hand-ins for this assignment'**
  String get reviewOpenAssignment;

  /// No description provided for @reviewScoredOutOf.
  ///
  /// In en, this message translates to:
  /// **'Scored out of {points}'**
  String reviewScoredOutOf(String points);

  /// No description provided for @staffQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get staffQuizzesTitle;

  /// No description provided for @staffQuizzesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search quizzes'**
  String get staffQuizzesSearch;

  /// No description provided for @staffQuizzesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet'**
  String get staffQuizzesEmptyTitle;

  /// No description provided for @staffQuizzesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Quizzes are built on the web. They appear here once they exist.'**
  String get staffQuizzesEmptyBody;

  /// No description provided for @staffQuizCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get staffQuizCourseLabel;

  /// No description provided for @staffQuizAllCourses.
  ///
  /// In en, this message translates to:
  /// **'Every course'**
  String get staffQuizAllCourses;

  /// No description provided for @staffQuizStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get staffQuizStatusAll;

  /// No description provided for @staffQuizStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get staffQuizStatusDraft;

  /// No description provided for @staffQuizStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get staffQuizStatusPublished;

  /// No description provided for @staffQuizPoints.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{1 point} other{{points} points}}'**
  String staffQuizPoints(int points);

  /// No description provided for @staffQuizQuestions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String staffQuizQuestions(int count);

  /// No description provided for @staffQuizAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No attempts yet} =1{1 attempt} other{{count} attempts}}'**
  String staffQuizAttempts(int count);

  /// No description provided for @staffQuizNoAttemptsTitle.
  ///
  /// In en, this message translates to:
  /// **'No attempts yet'**
  String get staffQuizNoAttemptsTitle;

  /// No description provided for @staffQuizNoAttemptsBody.
  ///
  /// In en, this message translates to:
  /// **'Once learners take it, this is where the LMS’s figures appear.'**
  String get staffQuizNoAttemptsBody;

  /// No description provided for @staffQuizStatAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get staffQuizStatAttempts;

  /// No description provided for @staffQuizStatLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get staffQuizStatLearners;

  /// No description provided for @staffQuizStatPassRate.
  ///
  /// In en, this message translates to:
  /// **'Pass rate'**
  String get staffQuizStatPassRate;

  /// No description provided for @staffQuizStatAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get staffQuizStatAvgScore;

  /// No description provided for @staffQuizStatMedianTime.
  ///
  /// In en, this message translates to:
  /// **'Typical time'**
  String get staffQuizStatMedianTime;

  /// No description provided for @staffQuizDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'How the scores fell'**
  String get staffQuizDistributionTitle;

  /// No description provided for @staffQuizSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'How it is set up'**
  String get staffQuizSettingsTitle;

  /// No description provided for @staffQuizPassMarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Pass mark'**
  String get staffQuizPassMarkLabel;

  /// No description provided for @staffQuizAttemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attempts allowed'**
  String get staffQuizAttemptsLabel;

  /// No description provided for @staffQuizAttemptsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'As many as they like'**
  String get staffQuizAttemptsUnlimited;

  /// No description provided for @staffQuizTimeLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get staffQuizTimeLimitLabel;

  /// No description provided for @staffQuizNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get staffQuizNoTimeLimit;

  /// No description provided for @staffQuizShuffleLabel.
  ///
  /// In en, this message translates to:
  /// **'Shuffled'**
  String get staffQuizShuffleLabel;

  /// No description provided for @staffQuizShuffleQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get staffQuizShuffleQuestions;

  /// No description provided for @staffQuizShuffleOptions.
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get staffQuizShuffleOptions;

  /// No description provided for @staffQuizShuffleNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get staffQuizShuffleNothing;

  /// No description provided for @staffQuizResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'What learners see afterwards'**
  String get staffQuizResultsLabel;

  /// No description provided for @staffQuizResultsScoreAndAnswers.
  ///
  /// In en, this message translates to:
  /// **'Their score and the answers'**
  String get staffQuizResultsScoreAndAnswers;

  /// No description provided for @staffQuizResultsScoreOnly.
  ///
  /// In en, this message translates to:
  /// **'Their score only'**
  String get staffQuizResultsScoreOnly;

  /// No description provided for @staffQuizResultsHidden.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get staffQuizResultsHidden;

  /// No description provided for @staffQuizQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'The questions'**
  String get staffQuizQuestionsTitle;

  /// No description provided for @staffQuizAnswerKeyNote.
  ///
  /// In en, this message translates to:
  /// **'The answers below are shown to staff only.'**
  String get staffQuizAnswerKeyNote;

  /// No description provided for @staffQuizCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get staffQuizCorrectAnswer;

  /// No description provided for @staffQuizAcceptedAnswers.
  ///
  /// In en, this message translates to:
  /// **'Accepted: {answers}'**
  String staffQuizAcceptedAnswers(String answers);

  /// No description provided for @staffQuizExplanationLabel.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get staffQuizExplanationLabel;

  /// No description provided for @staffQuizOptionalQuestion.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get staffQuizOptionalQuestion;

  /// No description provided for @staffQuizCorrectRate.
  ///
  /// In en, this message translates to:
  /// **'{percent}% got it right'**
  String staffQuizCorrectRate(String percent);

  /// No description provided for @staffQuizCommonWrong.
  ///
  /// In en, this message translates to:
  /// **'Most often chosen instead: {option}'**
  String staffQuizCommonWrong(String option);

  /// No description provided for @staffQuizEditOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Edit on the web'**
  String get staffQuizEditOnWeb;

  /// No description provided for @staffQuizMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String staffQuizMinutes(String minutes);

  /// No description provided for @staffQuizStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'How learners did'**
  String get staffQuizStatsTitle;

  /// No description provided for @studentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get studentsTitle;

  /// No description provided for @studentsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get studentsSearch;

  /// No description provided for @studentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No learners yet'**
  String get studentsEmptyTitle;

  /// No description provided for @studentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Learners appear here once they enrol in one of your courses.'**
  String get studentsEmptyBody;

  /// No description provided for @studentsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get studentsTabAll;

  /// No description provided for @studentsTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get studentsTabActive;

  /// No description provided for @studentsTabAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get studentsTabAtRisk;

  /// No description provided for @studentsTabInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get studentsTabInactive;

  /// No description provided for @studentsTabSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get studentsTabSuspended;

  /// No description provided for @studentsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get studentsSortLabel;

  /// No description provided for @studentsSortActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get studentsSortActive;

  /// No description provided for @studentsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get studentsSortName;

  /// No description provided for @studentsSortProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get studentsSortProgress;

  /// No description provided for @studentsSortJoined.
  ///
  /// In en, this message translates to:
  /// **'Recently joined'**
  String get studentsSortJoined;

  /// No description provided for @studentsCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get studentsCourseLabel;

  /// No description provided for @studentsAllCourses.
  ///
  /// In en, this message translates to:
  /// **'Every course'**
  String get studentsAllCourses;

  /// No description provided for @staffStudentsProgressByCourse.
  ///
  /// In en, this message translates to:
  /// **'Course by course'**
  String get staffStudentsProgressByCourse;

  /// No description provided for @staffStudentsEnrolmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Enrolment'**
  String get staffStudentsEnrolmentLabel;

  /// No description provided for @studentsPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String studentsPageOf(int page, int pages);

  /// No description provided for @studentsCourseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No courses} =1{1 course} other{{count} courses}}'**
  String studentsCourseCount(int count);

  /// No description provided for @studentsProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% through'**
  String studentsProgressLabel(String percent);

  /// No description provided for @studentsQuietDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Active today} =1{Quiet for a day} other{Quiet for {count} days}}'**
  String studentsQuietDays(int count);

  /// No description provided for @studentsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 learner selected} other{{count} learners selected}}'**
  String studentsSelected(int count);

  /// No description provided for @studentsSelectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get studentsSelectAction;

  /// No description provided for @studentsClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get studentsClearSelection;

  /// No description provided for @studentsMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get studentsMessageAction;

  /// No description provided for @studentsMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Message the learners you picked'**
  String get studentsMessageTitle;

  /// No description provided for @studentsMessageSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get studentsMessageSubject;

  /// No description provided for @studentsMessageBody.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get studentsMessageBody;

  /// No description provided for @studentsMessageBodyHint.
  ///
  /// In en, this message translates to:
  /// **'What you want them to know.'**
  String get studentsMessageBodyHint;

  /// No description provided for @studentsMessageChannels.
  ///
  /// In en, this message translates to:
  /// **'Send it'**
  String get studentsMessageChannels;

  /// No description provided for @studentsMessageChannelApp.
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get studentsMessageChannelApp;

  /// No description provided for @studentsMessageChannelEmail.
  ///
  /// In en, this message translates to:
  /// **'By email'**
  String get studentsMessageChannelEmail;

  /// No description provided for @studentsMessageSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get studentsMessageSend;

  /// No description provided for @studentsMessageSent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nobody could be reached} =1{Sent to 1 learner} other{Sent to {count} learners}}'**
  String studentsMessageSent(int count);

  /// No description provided for @studentsMessageBodyTooShort.
  ///
  /// In en, this message translates to:
  /// **'Write at least {count} characters so the message says something.'**
  String studentsMessageBodyTooShort(int count);

  /// No description provided for @studentTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get studentTabOverview;

  /// No description provided for @studentTabCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get studentTabCourses;

  /// No description provided for @studentTabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get studentTabProgress;

  /// No description provided for @studentTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get studentTabActivity;

  /// No description provided for @studentJoinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String studentJoinedOn(String date);

  /// No description provided for @studentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'How they are doing'**
  String get studentSummaryTitle;

  /// No description provided for @studentStatEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get studentStatEnrolled;

  /// No description provided for @studentStatActive.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get studentStatActive;

  /// No description provided for @studentStatCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get studentStatCompleted;

  /// No description provided for @studentStatAvgProgress.
  ///
  /// In en, this message translates to:
  /// **'Average progress'**
  String get studentStatAvgProgress;

  /// No description provided for @studentStatStudyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Time studying'**
  String get studentStatStudyMinutes;

  /// No description provided for @studentStatSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Hand-ins'**
  String get studentStatSubmissions;

  /// No description provided for @studentStatAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get studentStatAvgScore;

  /// No description provided for @studentCertificatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get studentCertificatesTitle;

  /// No description provided for @studentCertificateIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued {date} · {credential}'**
  String studentCertificateIssued(String date, String credential);

  /// No description provided for @studentNoCertificates.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet.'**
  String get studentNoCertificates;

  /// No description provided for @studentCoursesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not on any of your courses.'**
  String get studentCoursesEmpty;

  /// No description provided for @studentCourseFacts.
  ///
  /// In en, this message translates to:
  /// **'{chaptersDone} of {chapters} chapters · {lessonsDone} of {lessons} lessons'**
  String studentCourseFacts(int chaptersDone, int chapters, int lessonsDone, int lessons);

  /// No description provided for @studentNextUp.
  ///
  /// In en, this message translates to:
  /// **'Up next: {title}'**
  String studentNextUp(String title);

  /// No description provided for @studentTaughtBy.
  ///
  /// In en, this message translates to:
  /// **'Taught by {names}'**
  String studentTaughtBy(String names);

  /// No description provided for @studentEnrolAction.
  ///
  /// In en, this message translates to:
  /// **'Enrol in a course'**
  String get studentEnrolAction;

  /// No description provided for @studentEnrolConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrol this learner?'**
  String get studentEnrolConfirmTitle;

  /// No description provided for @studentEnrolConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They get access straight away and are told about it. The LMS sets how long access lasts.'**
  String get studentEnrolConfirmBody;

  /// No description provided for @studentEnrolled.
  ///
  /// In en, this message translates to:
  /// **'They are enrolled'**
  String get studentEnrolled;

  /// No description provided for @studentPauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get studentPauseAction;

  /// No description provided for @studentResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get studentResumeAction;

  /// No description provided for @studentPauseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause this enrolment?'**
  String get studentPauseConfirmTitle;

  /// No description provided for @studentPauseConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They keep their progress but the course stops counting towards their standing.'**
  String get studentPauseConfirmBody;

  /// No description provided for @studentPaused.
  ///
  /// In en, this message translates to:
  /// **'The enrolment is paused'**
  String get studentPaused;

  /// No description provided for @studentResumed.
  ///
  /// In en, this message translates to:
  /// **'The enrolment is active again'**
  String get studentResumed;

  /// No description provided for @studentRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get studentRemoveAction;

  /// No description provided for @studentRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this enrolment?'**
  String get studentRemoveConfirmTitle;

  /// No description provided for @studentRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They lose access to the course. Their progress goes with it.'**
  String get studentRemoveConfirmBody;

  /// No description provided for @studentRemoveAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand their progress in this course will be lost'**
  String get studentRemoveAcknowledge;

  /// No description provided for @studentRemoved.
  ///
  /// In en, this message translates to:
  /// **'The enrolment is removed'**
  String get studentRemoved;

  /// No description provided for @studentSuspendAction.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get studentSuspendAction;

  /// No description provided for @studentRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get studentRestoreAction;

  /// No description provided for @studentSuspendConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend this learner?'**
  String get studentSuspendConfirmTitle;

  /// No description provided for @studentSuspendConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They cannot sign in or learn until they are restored.'**
  String get studentSuspendConfirmBody;

  /// No description provided for @studentSuspendAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand they will be signed out'**
  String get studentSuspendAcknowledge;

  /// No description provided for @studentSuspendReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Why (only staff see this)'**
  String get studentSuspendReasonLabel;

  /// No description provided for @studentRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this learner?'**
  String get studentRestoreConfirmTitle;

  /// No description provided for @studentRestoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They can sign in and carry on where they left off.'**
  String get studentRestoreConfirmBody;

  /// No description provided for @studentSuspended.
  ///
  /// In en, this message translates to:
  /// **'The learner is suspended'**
  String get studentSuspended;

  /// No description provided for @studentRestored.
  ///
  /// In en, this message translates to:
  /// **'The learner is restored'**
  String get studentRestored;

  /// No description provided for @studentProgressEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet.'**
  String get studentProgressEmpty;

  /// No description provided for @studentQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get studentQuizzesTitle;

  /// No description provided for @studentQuizBest.
  ///
  /// In en, this message translates to:
  /// **'Best {percent}% of a pass mark of {passMark}%'**
  String studentQuizBest(String percent, String passMark);

  /// No description provided for @studentAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand-ins'**
  String get studentAssignmentsTitle;

  /// No description provided for @studentStudyWeeksTitle.
  ///
  /// In en, this message translates to:
  /// **'Time studying, week by week'**
  String get studentStudyWeeksTitle;

  /// No description provided for @studentActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet.'**
  String get studentActivityEmpty;

  /// No description provided for @studentActivityAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get studentActivityAll;

  /// No description provided for @studentContactTitle.
  ///
  /// In en, this message translates to:
  /// **'How to reach them'**
  String get studentContactTitle;

  /// No description provided for @studentStaffOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Contact details are shown to staff only.'**
  String get studentStaffOnlyNote;

  /// No description provided for @studentPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get studentPhoneLabel;

  /// No description provided for @studentJoinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get studentJoinedLabel;

  /// No description provided for @studentEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get studentEmailLabel;

  /// No description provided for @staffLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live classes'**
  String get staffLiveTitle;

  /// No description provided for @staffLiveSearch.
  ///
  /// In en, this message translates to:
  /// **'Search classes'**
  String get staffLiveSearch;

  /// No description provided for @staffLiveTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get staffLiveTabUpcoming;

  /// No description provided for @staffLiveTabLive.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get staffLiveTabLive;

  /// No description provided for @staffLiveTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get staffLiveTabHistory;

  /// No description provided for @staffLiveTabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get staffLiveTabCancelled;

  /// No description provided for @staffLiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get staffLiveEmptyTitle;

  /// No description provided for @staffLiveEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Schedule a class and the enrolled learners are told straight away.'**
  String get staffLiveEmptyBody;

  /// No description provided for @staffLivePageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String staffLivePageOf(int page, int pages);

  /// No description provided for @staffLiveScheduleAction.
  ///
  /// In en, this message translates to:
  /// **'Schedule a class'**
  String get staffLiveScheduleAction;

  /// No description provided for @staffLiveRegisteredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No seats taken} =1{1 seat taken} other{{count} seats taken}}'**
  String staffLiveRegisteredCount(int count);

  /// No description provided for @staffLiveOfCapacity.
  ///
  /// In en, this message translates to:
  /// **'{taken} of {capacity} seats taken'**
  String staffLiveOfCapacity(int taken, int capacity);

  /// No description provided for @staffLiveAttendeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Who registered'**
  String get staffLiveAttendeesTitle;

  /// No description provided for @staffLiveNoAttendees.
  ///
  /// In en, this message translates to:
  /// **'Nobody has taken a seat yet.'**
  String get staffLiveNoAttendees;

  /// No description provided for @staffLiveAttended.
  ///
  /// In en, this message translates to:
  /// **'Came'**
  String get staffLiveAttended;

  /// No description provided for @staffLiveMissed.
  ///
  /// In en, this message translates to:
  /// **'Did not come'**
  String get staffLiveMissed;

  /// No description provided for @staffLiveJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Open the meeting'**
  String get staffLiveJoinAction;

  /// No description provided for @staffLiveJoinNotReady.
  ///
  /// In en, this message translates to:
  /// **'The join link opens 15 minutes before the start.'**
  String get staffLiveJoinNotReady;

  /// No description provided for @staffLiveRoomNote.
  ///
  /// In en, this message translates to:
  /// **'Learners join in the app or on the web once you start the class. Attendance is taken as they join.'**
  String get staffLiveRoomNote;

  /// No description provided for @staffLiveStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start class'**
  String get staffLiveStartAction;

  /// No description provided for @staffLiveRejoinAction.
  ///
  /// In en, this message translates to:
  /// **'Rejoin as host'**
  String get staffLiveRejoinAction;

  /// No description provided for @staffLiveEndAction.
  ///
  /// In en, this message translates to:
  /// **'End class'**
  String get staffLiveEndAction;

  /// No description provided for @staffLiveEndConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'End this class?'**
  String get staffLiveEndConfirmTitle;

  /// No description provided for @staffLiveEndConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The room closes and nobody else can join. Learners who held a place and never came are marked missed.'**
  String get staffLiveEndConfirmBody;

  /// No description provided for @staffLiveEnded.
  ///
  /// In en, this message translates to:
  /// **'Class ended. Attendance is saved.'**
  String get staffLiveEnded;

  /// No description provided for @staffLiveStartNote.
  ///
  /// In en, this message translates to:
  /// **'Learners can join once you start the class. They are told the moment you do.'**
  String get staffLiveStartNote;

  /// No description provided for @staffLiveStartNotYet.
  ///
  /// In en, this message translates to:
  /// **'You can start the class from 15 minutes before its start time.'**
  String get staffLiveStartNotYet;

  /// No description provided for @staffLiveJoinedAt.
  ///
  /// In en, this message translates to:
  /// **'Joined {time}'**
  String staffLiveJoinedAt(String time);

  /// No description provided for @staffLiveLinkUnusable.
  ///
  /// In en, this message translates to:
  /// **'This class’s meeting link can’t be opened. Edit the class and paste the full link, starting with https://'**
  String get staffLiveLinkUnusable;

  /// No description provided for @staffLiveOpenedLinkAt.
  ///
  /// In en, this message translates to:
  /// **'Opened the link {time}'**
  String staffLiveOpenedLinkAt(String time);

  /// No description provided for @staffLiveFormMeetingKind.
  ///
  /// In en, this message translates to:
  /// **'Where the class runs'**
  String get staffLiveFormMeetingKind;

  /// No description provided for @staffLiveMeetingRoom.
  ///
  /// In en, this message translates to:
  /// **'Built-in live room'**
  String get staffLiveMeetingRoom;

  /// No description provided for @staffLiveMeetingExternal.
  ///
  /// In en, this message translates to:
  /// **'Outside meeting link'**
  String get staffLiveMeetingExternal;

  /// No description provided for @staffLiveRecordingNone.
  ///
  /// In en, this message translates to:
  /// **'Your academy’s video service doesn’t record classes yet.'**
  String get staffLiveRecordingNone;

  /// No description provided for @staffLiveRecordingHow.
  ///
  /// In en, this message translates to:
  /// **'Start recording from the room’s menu. Learners can watch it here after the class.'**
  String get staffLiveRecordingHow;

  /// No description provided for @staffLiveEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get staffLiveEditAction;

  /// No description provided for @staffLiveEditClosedStarted.
  ///
  /// In en, this message translates to:
  /// **'A class that has started can no longer be edited.'**
  String get staffLiveEditClosedStarted;

  /// No description provided for @staffLiveEditClosedCancelled.
  ///
  /// In en, this message translates to:
  /// **'A cancelled class can no longer be edited.'**
  String get staffLiveEditClosedCancelled;

  /// No description provided for @staffLiveRemindAction.
  ///
  /// In en, this message translates to:
  /// **'Remind them now'**
  String get staffLiveRemindAction;

  /// No description provided for @staffLiveRemindSent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nobody needed a reminder} =1{1 learner was reminded} other{{count} learners were reminded}}'**
  String staffLiveRemindSent(int count);

  /// No description provided for @staffLiveCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel the class'**
  String get staffLiveCancelAction;

  /// No description provided for @staffLiveCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Call this class off?'**
  String get staffLiveCancelConfirmTitle;

  /// No description provided for @staffLiveCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Registered learners are told at once, with the reason you give.'**
  String get staffLiveCancelConfirmBody;

  /// No description provided for @staffLiveCancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Why (learners see this)'**
  String get staffLiveCancelReasonLabel;

  /// No description provided for @staffLiveCancelled.
  ///
  /// In en, this message translates to:
  /// **'The class is cancelled'**
  String get staffLiveCancelled;

  /// No description provided for @staffLiveCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancelled: {reason}'**
  String staffLiveCancelReason(String reason);

  /// No description provided for @staffLiveRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'When learners are reminded'**
  String get staffLiveRemindersTitle;

  /// No description provided for @staffLiveReminderOffset.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String staffLiveReminderOffset(int minutes);

  /// No description provided for @staffLiveReminderHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h before'**
  String staffLiveReminderHours(int hours);

  /// No description provided for @staffLiveReminderDay.
  ///
  /// In en, this message translates to:
  /// **'A day before'**
  String get staffLiveReminderDay;

  /// No description provided for @staffLiveRemindersSaved.
  ///
  /// In en, this message translates to:
  /// **'Reminders saved'**
  String get staffLiveRemindersSaved;

  /// No description provided for @staffLiveNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule a class'**
  String get staffLiveNewTitle;

  /// No description provided for @staffLiveEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit the class'**
  String get staffLiveEditTitle;

  /// No description provided for @staffLiveFormCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get staffLiveFormCourse;

  /// No description provided for @staffLiveFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get staffLiveFormTitle;

  /// No description provided for @staffLiveFormInstructor.
  ///
  /// In en, this message translates to:
  /// **'Who teaches it'**
  String get staffLiveFormInstructor;

  /// No description provided for @staffLiveFormStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get staffLiveFormStart;

  /// No description provided for @staffLiveFormDuration.
  ///
  /// In en, this message translates to:
  /// **'How long (minutes)'**
  String get staffLiveFormDuration;

  /// No description provided for @staffLiveFormDurationHelp.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max} minutes.'**
  String staffLiveFormDurationHelp(int min, int max);

  /// No description provided for @staffLiveFormCapacity.
  ///
  /// In en, this message translates to:
  /// **'Seats (optional)'**
  String get staffLiveFormCapacity;

  /// No description provided for @staffLiveFormDescription.
  ///
  /// In en, this message translates to:
  /// **'What it covers'**
  String get staffLiveFormDescription;

  /// No description provided for @staffLiveFormVisibility.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get staffLiveFormVisibility;

  /// No description provided for @staffLiveVisibilityEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Learners on the course'**
  String get staffLiveVisibilityEnrolled;

  /// No description provided for @staffLiveVisibilityCohort.
  ///
  /// In en, this message translates to:
  /// **'The cohort'**
  String get staffLiveVisibilityCohort;

  /// No description provided for @staffLiveVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get staffLiveVisibilityPublic;

  /// No description provided for @staffLiveFormMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting link'**
  String get staffLiveFormMeeting;

  /// No description provided for @staffLiveFormMeetingHelp.
  ///
  /// In en, this message translates to:
  /// **'Starts with https://'**
  String get staffLiveFormMeetingHelp;

  /// No description provided for @staffLiveFormAgenda.
  ///
  /// In en, this message translates to:
  /// **'What happens'**
  String get staffLiveFormAgenda;

  /// No description provided for @staffLiveFormAgendaAdd.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get staffLiveFormAgendaAdd;

  /// No description provided for @staffLiveFormAgendaItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get staffLiveFormAgendaItem;

  /// No description provided for @staffLiveFormAgendaMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get staffLiveFormAgendaMinutes;

  /// No description provided for @staffLiveFormAgendaTooLong.
  ///
  /// In en, this message translates to:
  /// **'The agenda runs {agenda} minutes — longer than the class.'**
  String staffLiveFormAgendaTooLong(int agenda);

  /// No description provided for @staffLiveFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get staffLiveFormSave;

  /// No description provided for @staffLiveFormSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule it'**
  String get staffLiveFormSchedule;

  /// No description provided for @staffLiveScheduled.
  ///
  /// In en, this message translates to:
  /// **'The class is scheduled and the learners are told'**
  String get staffLiveScheduled;

  /// No description provided for @staffLiveSaved.
  ///
  /// In en, this message translates to:
  /// **'The class is saved'**
  String get staffLiveSaved;

  /// No description provided for @staffLiveLeaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get staffLiveLeaveConfirmTitle;

  /// No description provided for @staffLiveLeaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The class has not been saved.'**
  String get staffLiveLeaveConfirmBody;

  /// No description provided for @staffLiveLeaveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get staffLiveLeaveConfirmAction;

  /// No description provided for @staffLiveStartInPast.
  ///
  /// In en, this message translates to:
  /// **'Choose a time later than now.'**
  String get staffLiveStartInPast;

  /// No description provided for @staffLiveRecordingViews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Watched once} other{Watched {count} times}}'**
  String staffLiveRecordingViews(int count);

  /// No description provided for @staffLiveFormAgendaRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this item'**
  String get staffLiveFormAgendaRemove;

  /// No description provided for @staffLiveDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Class details'**
  String get staffLiveDetailsTitle;

  /// No description provided for @staffLiveFormSectionClass.
  ///
  /// In en, this message translates to:
  /// **'The class'**
  String get staffLiveFormSectionClass;

  /// No description provided for @staffLiveFormSectionWhen.
  ///
  /// In en, this message translates to:
  /// **'Date and length'**
  String get staffLiveFormSectionWhen;

  /// No description provided for @staffLiveFormSectionWhere.
  ///
  /// In en, this message translates to:
  /// **'Where it happens'**
  String get staffLiveFormSectionWhere;

  /// No description provided for @staffLiveFormSectionLearners.
  ///
  /// In en, this message translates to:
  /// **'For learners'**
  String get staffLiveFormSectionLearners;

  /// No description provided for @staffCalendarDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get staffCalendarDetailsTitle;

  /// No description provided for @staffCalendarFormSectionEvent.
  ///
  /// In en, this message translates to:
  /// **'The event'**
  String get staffCalendarFormSectionEvent;

  /// No description provided for @staffCalendarFormSectionWhen.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get staffCalendarFormSectionWhen;

  /// No description provided for @staffCalendarFormSectionLinks.
  ///
  /// In en, this message translates to:
  /// **'Audience and links'**
  String get staffCalendarFormSectionLinks;

  /// No description provided for @staffCalendarFormSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Reminder and notes'**
  String get staffCalendarFormSectionNotes;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarWeekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String calendarWeekOf(String date);

  /// No description provided for @calendarMonthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonthView;

  /// No description provided for @calendarWeekView.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarWeekView;

  /// No description provided for @calendarDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get calendarDayEmpty;

  /// No description provided for @calendarRangeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this range'**
  String get calendarRangeEmpty;

  /// No description provided for @calendarRangeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Live classes, deadlines and your own reminders appear here.'**
  String get calendarRangeEmptyBody;

  /// No description provided for @calendarTypeAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get calendarTypeAll;

  /// No description provided for @calendarTypeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get calendarTypeLive;

  /// No description provided for @calendarTypeAssignment.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get calendarTypeAssignment;

  /// No description provided for @calendarTypeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get calendarTypeQuiz;

  /// No description provided for @calendarTypeMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get calendarTypeMilestone;

  /// No description provided for @calendarTypeReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get calendarTypeReminder;

  /// No description provided for @calendarAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDay;

  /// No description provided for @calendarMoment.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String calendarMoment(String time);

  /// No description provided for @calendarAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add to the calendar'**
  String get calendarAddAction;

  /// No description provided for @calendarNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to the calendar'**
  String get calendarNewTitle;

  /// No description provided for @calendarEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit the event'**
  String get calendarEditTitle;

  /// No description provided for @calendarFormType.
  ///
  /// In en, this message translates to:
  /// **'What it is'**
  String get calendarFormType;

  /// No description provided for @calendarFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get calendarFormTitle;

  /// No description provided for @calendarFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get calendarFormDescription;

  /// No description provided for @calendarFormTiming.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get calendarFormTiming;

  /// No description provided for @calendarTimingTimed.
  ///
  /// In en, this message translates to:
  /// **'A time and a length'**
  String get calendarTimingTimed;

  /// No description provided for @calendarTimingMoment.
  ///
  /// In en, this message translates to:
  /// **'A moment'**
  String get calendarTimingMoment;

  /// No description provided for @calendarTimingAllDay.
  ///
  /// In en, this message translates to:
  /// **'The whole day'**
  String get calendarTimingAllDay;

  /// No description provided for @calendarFormStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get calendarFormStart;

  /// No description provided for @calendarFormDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendarFormDay;

  /// No description provided for @calendarFormDuration.
  ///
  /// In en, this message translates to:
  /// **'How long (minutes)'**
  String get calendarFormDuration;

  /// No description provided for @calendarFormDurationHelp.
  ///
  /// In en, this message translates to:
  /// **'Between {min} minutes and 12 hours.'**
  String calendarFormDurationHelp(int min);

  /// No description provided for @calendarFormCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get calendarFormCourse;

  /// No description provided for @calendarFormChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get calendarFormChapter;

  /// No description provided for @calendarFormQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get calendarFormQuiz;

  /// No description provided for @calendarFormMilestone.
  ///
  /// In en, this message translates to:
  /// **'What kind of milestone'**
  String get calendarFormMilestone;

  /// No description provided for @calendarFormAudience.
  ///
  /// In en, this message translates to:
  /// **'Who it is for'**
  String get calendarFormAudience;

  /// No description provided for @calendarAudienceMe.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get calendarAudienceMe;

  /// No description provided for @calendarAudienceLearners.
  ///
  /// In en, this message translates to:
  /// **'The course’s learners'**
  String get calendarAudienceLearners;

  /// No description provided for @calendarFormNotify.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get calendarFormNotify;

  /// No description provided for @calendarNotifyNone.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get calendarNotifyNone;

  /// No description provided for @calendarFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get calendarFormSave;

  /// No description provided for @calendarFormAdd.
  ///
  /// In en, this message translates to:
  /// **'Add it'**
  String get calendarFormAdd;

  /// No description provided for @calendarAdded.
  ///
  /// In en, this message translates to:
  /// **'It is on the calendar'**
  String get calendarAdded;

  /// No description provided for @calendarSaved.
  ///
  /// In en, this message translates to:
  /// **'The event is saved'**
  String get calendarSaved;

  /// No description provided for @calendarRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get calendarRemoveAction;

  /// No description provided for @calendarRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this event?'**
  String get calendarRemoveConfirmTitle;

  /// No description provided for @calendarRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It disappears from the calendar. Anyone it reminds will not be reminded.'**
  String get calendarRemoveConfirmBody;

  /// No description provided for @calendarRemoved.
  ///
  /// In en, this message translates to:
  /// **'The event is removed'**
  String get calendarRemoved;

  /// No description provided for @calendarDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Mark it done'**
  String get calendarDoneAction;

  /// No description provided for @calendarUndoneAction.
  ///
  /// In en, this message translates to:
  /// **'Not done after all'**
  String get calendarUndoneAction;

  /// No description provided for @calendarDoneBadge.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get calendarDoneBadge;

  /// No description provided for @calendarLeaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get calendarLeaveConfirmTitle;

  /// No description provided for @calendarLeaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The event has not been saved.'**
  String get calendarLeaveConfirmBody;

  /// No description provided for @calendarLeaveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get calendarLeaveConfirmAction;

  /// No description provided for @calendarNotEditableLive.
  ///
  /// In en, this message translates to:
  /// **'A live class is changed in Live classes.'**
  String get calendarNotEditableLive;

  /// No description provided for @calendarNotEditableAssignment.
  ///
  /// In en, this message translates to:
  /// **'A deadline is changed on the assignment itself.'**
  String get calendarNotEditableAssignment;

  /// No description provided for @calendarNotEditableOther.
  ///
  /// In en, this message translates to:
  /// **'This event belongs to someone else.'**
  String get calendarNotEditableOther;

  /// No description provided for @calendarOpenLive.
  ///
  /// In en, this message translates to:
  /// **'Open the live class'**
  String get calendarOpenLive;

  /// No description provided for @calendarOpenSubmissions.
  ///
  /// In en, this message translates to:
  /// **'See the hand-ins'**
  String get calendarOpenSubmissions;

  /// No description provided for @calendarOpenQuiz.
  ///
  /// In en, this message translates to:
  /// **'Open the quiz'**
  String get calendarOpenQuiz;

  /// No description provided for @calendarAudienceSize.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 learner} other{{count} learners}}'**
  String calendarAudienceSize(int count);

  /// No description provided for @calendarDueSummary.
  ///
  /// In en, this message translates to:
  /// **'{submitted} of {learners} have handed in'**
  String calendarDueSummary(int submitted, int learners);

  /// No description provided for @calendarLearnersDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Still to hand in'**
  String get calendarLearnersDueTitle;

  /// No description provided for @calendarHandedIn.
  ///
  /// In en, this message translates to:
  /// **'Handed in'**
  String get calendarHandedIn;

  /// No description provided for @calendarMilestoneCohortStarts.
  ///
  /// In en, this message translates to:
  /// **'A cohort starts'**
  String get calendarMilestoneCohortStarts;

  /// No description provided for @calendarMilestoneChapterRelease.
  ///
  /// In en, this message translates to:
  /// **'A chapter opens'**
  String get calendarMilestoneChapterRelease;

  /// No description provided for @calendarMilestoneEnrolmentCloses.
  ///
  /// In en, this message translates to:
  /// **'Enrolment closes'**
  String get calendarMilestoneEnrolmentCloses;

  /// No description provided for @calendarMilestoneCohortEnds.
  ///
  /// In en, this message translates to:
  /// **'A cohort ends'**
  String get calendarMilestoneCohortEnds;

  /// No description provided for @calendarMilestoneCourseLaunch.
  ///
  /// In en, this message translates to:
  /// **'A course launches'**
  String get calendarMilestoneCourseLaunch;

  /// No description provided for @calendarStartInPast.
  ///
  /// In en, this message translates to:
  /// **'Choose a time later than now.'**
  String get calendarStartInPast;

  /// No description provided for @calendarDayInPast.
  ///
  /// In en, this message translates to:
  /// **'Choose a day that has not passed.'**
  String get calendarDayInPast;

  /// No description provided for @calendarEventsOnDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String calendarEventsOnDay(int count);

  /// No description provided for @instructorsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name or title'**
  String get instructorsSearch;

  /// No description provided for @instructorsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get instructorsTabAll;

  /// No description provided for @instructorsTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get instructorsTabActive;

  /// No description provided for @instructorsTabInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get instructorsTabInvited;

  /// No description provided for @instructorsTabInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get instructorsTabInactive;

  /// No description provided for @instructorsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get instructorsSortLabel;

  /// No description provided for @instructorsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get instructorsSortName;

  /// No description provided for @instructorsSortStudents.
  ///
  /// In en, this message translates to:
  /// **'Most learners'**
  String get instructorsSortStudents;

  /// No description provided for @instructorsSortRating.
  ///
  /// In en, this message translates to:
  /// **'Highest rated'**
  String get instructorsSortRating;

  /// No description provided for @instructorsSortJoined.
  ///
  /// In en, this message translates to:
  /// **'Recently joined'**
  String get instructorsSortJoined;

  /// No description provided for @instructorsExpertiseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expertise'**
  String get instructorsExpertiseLabel;

  /// No description provided for @instructorsAllExpertise.
  ///
  /// In en, this message translates to:
  /// **'Any expertise'**
  String get instructorsAllExpertise;

  /// No description provided for @instructorsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No instructors yet'**
  String get instructorsEmptyTitle;

  /// No description provided for @instructorsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Invite the first instructor and they will be sent a link to choose a password.'**
  String get instructorsEmptyBody;

  /// No description provided for @instructorsInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite an instructor'**
  String get instructorsInviteAction;

  /// No description provided for @instructorsCourseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No courses} =1{1 course} other{{count} courses}}'**
  String instructorsCourseCount(int count);

  /// No description provided for @instructorsLearnerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 learner} other{{count} learners}}'**
  String instructorsLearnerCount(int count);

  /// No description provided for @instructorsRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} from {count} ratings'**
  String instructorsRating(String rating, int count);

  /// No description provided for @instructorsNotRated.
  ///
  /// In en, this message translates to:
  /// **'Not rated yet'**
  String get instructorsNotRated;

  /// No description provided for @instructorsCompletion.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete the course'**
  String instructorsCompletion(int percent);

  /// No description provided for @instructorsToReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 to review} other{{count} to review}}'**
  String instructorsToReview(int count);

  /// No description provided for @instructorsOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} past the review window'**
  String instructorsOverdue(int count);

  /// No description provided for @instructorTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get instructorTabOverview;

  /// No description provided for @instructorTabCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get instructorTabCourses;

  /// No description provided for @instructorTabPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get instructorTabPerformance;

  /// No description provided for @instructorAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get instructorAboutTitle;

  /// No description provided for @instructorNoBio.
  ///
  /// In en, this message translates to:
  /// **'No bio yet. Learners see this on every course page.'**
  String get instructorNoBio;

  /// No description provided for @instructorDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get instructorDetailsTitle;

  /// No description provided for @instructorEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get instructorEmailLabel;

  /// No description provided for @instructorPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get instructorPhoneLabel;

  /// No description provided for @instructorCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get instructorCityLabel;

  /// No description provided for @instructorLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Teaches in'**
  String get instructorLanguagesLabel;

  /// No description provided for @instructorYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Years teaching'**
  String get instructorYearsLabel;

  /// No description provided for @instructorJoinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get instructorJoinedLabel;

  /// No description provided for @instructorExpertiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expertise'**
  String get instructorExpertiseTitle;

  /// No description provided for @instructorReachTitle.
  ///
  /// In en, this message translates to:
  /// **'Their learners'**
  String get instructorReachTitle;

  /// No description provided for @instructorReachStudents.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get instructorReachStudents;

  /// No description provided for @instructorReachActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get instructorReachActive;

  /// No description provided for @instructorReachCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get instructorReachCompleted;

  /// No description provided for @instructorReachNewThisMonth.
  ///
  /// In en, this message translates to:
  /// **'New this month'**
  String get instructorReachNewThisMonth;

  /// No description provided for @instructorCitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Where they are'**
  String get instructorCitiesTitle;

  /// No description provided for @instructorCityLearners.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 learner} other{{count} learners}}'**
  String instructorCityLearners(int count);

  /// No description provided for @instructorActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent work'**
  String get instructorActivityTitle;

  /// No description provided for @instructorActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet.'**
  String get instructorActivityEmpty;

  /// No description provided for @instructorCoursesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No courses assigned yet.'**
  String get instructorCoursesEmpty;

  /// No description provided for @instructorRoleLead.
  ///
  /// In en, this message translates to:
  /// **'Lead instructor'**
  String get instructorRoleLead;

  /// No description provided for @instructorRoleCo.
  ///
  /// In en, this message translates to:
  /// **'Co-instructor'**
  String get instructorRoleCo;

  /// No description provided for @instructorCourseEnrolled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 enrolled} other{{count} enrolled}}'**
  String instructorCourseEnrolled(int count);

  /// No description provided for @instructorCourseActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active in the last fortnight'**
  String instructorCourseActive(int count);

  /// No description provided for @instructorCourseLessons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson} other{{count} lessons}}'**
  String instructorCourseLessons(int count);

  /// No description provided for @instructorPerformanceRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get instructorPerformanceRating;

  /// No description provided for @instructorPerformanceCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get instructorPerformanceCompletion;

  /// No description provided for @instructorVsAcademy.
  ///
  /// In en, this message translates to:
  /// **'vs the LMS'**
  String get instructorVsAcademy;

  /// No description provided for @instructorReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get instructorReviewTitle;

  /// No description provided for @instructorReviewMedian.
  ///
  /// In en, this message translates to:
  /// **'Median turnaround'**
  String get instructorReviewMedian;

  /// No description provided for @instructorReviewMedianHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String instructorReviewMedianHours(int hours);

  /// No description provided for @instructorReviewOnTime.
  ///
  /// In en, this message translates to:
  /// **'Inside 48 hours'**
  String get instructorReviewOnTime;

  /// No description provided for @instructorReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get instructorReviewed;

  /// No description provided for @instructorReviewWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get instructorReviewWaiting;

  /// No description provided for @instructorLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live teaching'**
  String get instructorLiveTitle;

  /// No description provided for @instructorLiveDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get instructorLiveDelivered;

  /// No description provided for @instructorLiveUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get instructorLiveUpcoming;

  /// No description provided for @instructorAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get instructorAttendance;

  /// No description provided for @instructorEnrolmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrolments by month'**
  String get instructorEnrolmentsTitle;

  /// No description provided for @instructorNoFigureYet.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get instructorNoFigureYet;

  /// No description provided for @instructorEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get instructorEditAction;

  /// No description provided for @instructorResendInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Send the invitation again'**
  String get instructorResendInviteAction;

  /// No description provided for @instructorResendInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {email}'**
  String instructorResendInviteSent(String email);

  /// No description provided for @instructorMakeActiveAction.
  ///
  /// In en, this message translates to:
  /// **'Make active'**
  String get instructorMakeActiveAction;

  /// No description provided for @instructorMakeInactiveAction.
  ///
  /// In en, this message translates to:
  /// **'Make inactive'**
  String get instructorMakeInactiveAction;

  /// No description provided for @instructorMakeActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Make this instructor active?'**
  String get instructorMakeActiveTitle;

  /// No description provided for @instructorMakeActiveBody.
  ///
  /// In en, this message translates to:
  /// **'They will be able to sign in and teach, and they take a seat on the LMS plan.'**
  String get instructorMakeActiveBody;

  /// No description provided for @instructorMakeInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Make this instructor inactive?'**
  String get instructorMakeInactiveTitle;

  /// No description provided for @instructorMakeInactiveBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to sign in. Their courses and their learners stay exactly as they are.'**
  String get instructorMakeInactiveBody;

  /// No description provided for @instructorStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed.'**
  String get instructorStatusChanged;

  /// No description provided for @instructorFormInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite an instructor'**
  String get instructorFormInviteTitle;

  /// No description provided for @instructorFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit the instructor'**
  String get instructorFormEditTitle;

  /// No description provided for @instructorFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get instructorFormNameLabel;

  /// No description provided for @instructorFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Professional title'**
  String get instructorFormTitleLabel;

  /// No description provided for @instructorFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Senior Maths Faculty'**
  String get instructorFormTitleHint;

  /// No description provided for @instructorFormEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get instructorFormEmailLabel;

  /// No description provided for @instructorFormEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'The invitation to choose a password is sent here.'**
  String get instructorFormEmailHelp;

  /// No description provided for @instructorFormBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get instructorFormBioLabel;

  /// No description provided for @instructorFormBioHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 60 characters once they are active — learners read it on every course page.'**
  String get instructorFormBioHelp;

  /// No description provided for @instructorFormCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get instructorFormCityLabel;

  /// No description provided for @instructorFormPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get instructorFormPhoneLabel;

  /// No description provided for @instructorFormYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Years teaching'**
  String get instructorFormYearsLabel;

  /// No description provided for @instructorFormStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get instructorFormStatusLabel;

  /// No description provided for @instructorFormStatusInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited — send them an invitation'**
  String get instructorFormStatusInvited;

  /// No description provided for @instructorFormStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active — they can sign in already'**
  String get instructorFormStatusActive;

  /// No description provided for @instructorFormStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive — no sign-in, no seat'**
  String get instructorFormStatusInactive;

  /// No description provided for @instructorFormExpertiseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expertise'**
  String get instructorFormExpertiseLabel;

  /// No description provided for @instructorFormExpertiseHint.
  ///
  /// In en, this message translates to:
  /// **'Add an area of expertise'**
  String get instructorFormExpertiseHint;

  /// No description provided for @instructorFormLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get instructorFormLanguagesLabel;

  /// No description provided for @instructorFormLanguagesHint.
  ///
  /// In en, this message translates to:
  /// **'Add a language'**
  String get instructorFormLanguagesHint;

  /// No description provided for @instructorFormCoursesLabel.
  ///
  /// In en, this message translates to:
  /// **'Courses they teach'**
  String get instructorFormCoursesLabel;

  /// No description provided for @instructorFormCoursesHelp.
  ///
  /// In en, this message translates to:
  /// **'They can edit these courses, run their live classes and review their submissions.'**
  String get instructorFormCoursesHelp;

  /// No description provided for @instructorFormNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'A photo is added on the web. Learners see their initials until then.'**
  String get instructorFormNoPhoto;

  /// No description provided for @instructorFormSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save the instructor'**
  String get instructorFormSaveAction;

  /// No description provided for @instructorFormInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Send the invitation'**
  String get instructorFormInviteAction;

  /// No description provided for @instructorFormAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get instructorFormAddTag;

  /// Instructor invite/edit form: heading over name, title, email and status.
  ///
  /// In en, this message translates to:
  /// **'Who they are'**
  String get staffInstructorsFormWhoTitle;

  /// Instructor invite/edit form: heading over bio, city, phone and years teaching.
  ///
  /// In en, this message translates to:
  /// **'Their profile'**
  String get staffInstructorsFormProfileTitle;

  /// No description provided for @instructorSaved.
  ///
  /// In en, this message translates to:
  /// **'Instructor saved.'**
  String get instructorSaved;

  /// No description provided for @instructorInvited.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent.'**
  String get instructorInvited;

  /// No description provided for @instructorProblemName.
  ///
  /// In en, this message translates to:
  /// **'Enter their full name.'**
  String get instructorProblemName;

  /// No description provided for @instructorProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a professional title.'**
  String get instructorProblemTitle;

  /// No description provided for @instructorProblemEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get instructorProblemEmail;

  /// No description provided for @instructorProblemPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter 8 to 15 digits, or leave it empty.'**
  String get instructorProblemPhone;

  /// No description provided for @instructorProblemBio.
  ///
  /// In en, this message translates to:
  /// **'Write a bio of at least 60 characters.'**
  String get instructorProblemBio;

  /// No description provided for @instructorProblemExpertise.
  ///
  /// In en, this message translates to:
  /// **'Add at least one area of expertise.'**
  String get instructorProblemExpertise;

  /// No description provided for @instructorProblemLanguages.
  ///
  /// In en, this message translates to:
  /// **'Add the languages they teach in.'**
  String get instructorProblemLanguages;

  /// No description provided for @instructorProblemYears.
  ///
  /// In en, this message translates to:
  /// **'Years teaching should be between 0 and 70.'**
  String get instructorProblemYears;

  /// No description provided for @registerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by learner, email or credential'**
  String get registerSearch;

  /// No description provided for @registerTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get registerTabAll;

  /// No description provided for @registerTabRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get registerTabRevoked;

  /// No description provided for @registerCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get registerCourseLabel;

  /// No description provided for @registerAllCourses.
  ///
  /// In en, this message translates to:
  /// **'All courses'**
  String get registerAllCourses;

  /// No description provided for @registerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet'**
  String get registerEmptyTitle;

  /// No description provided for @registerEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A certificate appears here once a learner finishes a course that awards one.'**
  String get registerEmptyBody;

  /// No description provided for @registerRevokedOn.
  ///
  /// In en, this message translates to:
  /// **'Revoked {date}'**
  String registerRevokedOn(String date);

  /// No description provided for @registerPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Not issued yet. Nothing is public until it is.'**
  String get registerPendingNote;

  /// No description provided for @registerIssueAction.
  ///
  /// In en, this message translates to:
  /// **'Issue the certificate'**
  String get registerIssueAction;

  /// No description provided for @registerIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue this certificate?'**
  String get registerIssueTitle;

  /// No description provided for @registerIssueBody.
  ///
  /// In en, this message translates to:
  /// **'The learner is told at once and the credential can be verified publicly from then on.'**
  String get registerIssueBody;

  /// No description provided for @registerIssued.
  ///
  /// In en, this message translates to:
  /// **'Certificate issued.'**
  String get registerIssued;

  /// No description provided for @registerRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get registerRevokeAction;

  /// No description provided for @registerRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this certificate?'**
  String get registerRevokeTitle;

  /// No description provided for @registerRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'The learner is told, and the reason you give is what they read. Public verification will show it as revoked.'**
  String get registerRevokeBody;

  /// No description provided for @registerRevokeReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get registerRevokeReasonLabel;

  /// No description provided for @registerRevokeReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters. The learner reads this.'**
  String get registerRevokeReasonHelp;

  /// No description provided for @registerRevoked.
  ///
  /// In en, this message translates to:
  /// **'Certificate revoked.'**
  String get registerRevoked;

  /// No description provided for @registerRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get registerRestoreAction;

  /// No description provided for @registerRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this certificate?'**
  String get registerRestoreTitle;

  /// No description provided for @registerRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'It goes back to issued, and the revocation reason is cleared.'**
  String get registerRestoreBody;

  /// No description provided for @registerRestored.
  ///
  /// In en, this message translates to:
  /// **'Certificate restored.'**
  String get registerRestored;

  /// No description provided for @registerRevokedReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why it was revoked'**
  String get registerRevokedReasonTitle;

  /// No description provided for @registerLearnerTitle.
  ///
  /// In en, this message translates to:
  /// **'The learner'**
  String get registerLearnerTitle;

  /// No description provided for @registerVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Public verification'**
  String get registerVerifyTitle;

  /// No description provided for @registerVerifyPath.
  ///
  /// In en, this message translates to:
  /// **'Anyone can check this credential at {path} on the web.'**
  String registerVerifyPath(String path);

  /// No description provided for @registerOpenLearner.
  ///
  /// In en, this message translates to:
  /// **'Open the learner'**
  String get registerOpenLearner;

  /// No description provided for @instructorFormLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get instructorFormLeaveTitle;

  /// No description provided for @instructorFormLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'The changes to this instructor have not been sent to the LMS.'**
  String get instructorFormLeaveBody;

  /// No description provided for @instructorFormLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get instructorFormLeaveAction;

  /// No description provided for @registerPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String registerPageOf(int page, int pages);

  /// No description provided for @registerCredentialLabel.
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get registerCredentialLabel;

  /// No description provided for @registerCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get registerCompletedLabel;

  /// No description provided for @registerIssuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get registerIssuedLabel;

  /// No description provided for @registerRevokedLabel.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get registerRevokedLabel;

  /// No description provided for @registerLearnerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get registerLearnerNameLabel;

  /// No description provided for @registerLearnerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerLearnerEmailLabel;

  /// No description provided for @registerLearnerCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get registerLearnerCityLabel;

  /// No description provided for @reportsTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reportsTabOverview;

  /// No description provided for @reportsTabCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get reportsTabCourses;

  /// No description provided for @reportsTabLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get reportsTabLearners;

  /// No description provided for @reportsTabInstructors.
  ///
  /// In en, this message translates to:
  /// **'Instructors'**
  String get reportsTabInstructors;

  /// No description provided for @reportsTabEnrolments.
  ///
  /// In en, this message translates to:
  /// **'Enrolments'**
  String get reportsTabEnrolments;

  /// No description provided for @reportsFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get reportsFiltersAction;

  /// No description provided for @reportsFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'What these reports cover'**
  String get reportsFiltersTitle;

  /// No description provided for @reportsRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportsRangeLabel;

  /// No description provided for @reportsRange30d.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get reportsRange30d;

  /// No description provided for @reportsRange90d.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get reportsRange90d;

  /// No description provided for @reportsRange6m.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get reportsRange6m;

  /// No description provided for @reportsRange12m.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get reportsRange12m;

  /// No description provided for @reportsSegmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get reportsSegmentLabel;

  /// No description provided for @reportsSegmentAll.
  ///
  /// In en, this message translates to:
  /// **'All learners'**
  String get reportsSegmentAll;

  /// No description provided for @reportsSegmentNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get reportsSegmentNew;

  /// No description provided for @reportsSegmentActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get reportsSegmentActive;

  /// No description provided for @reportsSegmentAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get reportsSegmentAtRisk;

  /// No description provided for @reportsSegmentInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get reportsSegmentInactive;

  /// No description provided for @reportsSegmentCompleters.
  ///
  /// In en, this message translates to:
  /// **'Completed a course'**
  String get reportsSegmentCompleters;

  /// No description provided for @reportsCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportsCategoryLabel;

  /// No description provided for @reportsAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get reportsAllCategories;

  /// No description provided for @reportsCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get reportsCourseLabel;

  /// No description provided for @reportsAllCourses.
  ///
  /// In en, this message translates to:
  /// **'All courses'**
  String get reportsAllCourses;

  /// No description provided for @reportsInstructorLabel.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get reportsInstructorLabel;

  /// No description provided for @reportsAllInstructors.
  ///
  /// In en, this message translates to:
  /// **'All instructors'**
  String get reportsAllInstructors;

  /// No description provided for @reportsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear the filters'**
  String get reportsClearFilters;

  /// No description provided for @reportsApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Show the reports'**
  String get reportsApplyFilters;

  /// No description provided for @reportsCovering.
  ///
  /// In en, this message translates to:
  /// **'{period} · {courses, plural, =1{1 course} other{{courses} courses}}'**
  String reportsCovering(String period, int courses);

  /// No description provided for @reportsNarrowedBy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 filter} other{{count} filters}}'**
  String reportsNarrowedBy(int count);

  /// No description provided for @reportsComparedWith.
  ///
  /// In en, this message translates to:
  /// **'vs the previous {period}'**
  String reportsComparedWith(String period);

  /// No description provided for @reportsNoFigure.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get reportsNoFigure;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to report yet'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once learners enrol and start work, their figures appear here.'**
  String get reportsEmptyBody;

  /// No description provided for @reportsFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No figures match these filters.'**
  String get reportsFilteredEmpty;

  /// No description provided for @reportsReadOut.
  ///
  /// In en, this message translates to:
  /// **'Read the figures'**
  String get reportsReadOut;

  /// No description provided for @reportsEnrolments.
  ///
  /// In en, this message translates to:
  /// **'Enrolments'**
  String get reportsEnrolments;

  /// No description provided for @reportsCompletions.
  ///
  /// In en, this message translates to:
  /// **'Completions'**
  String get reportsCompletions;

  /// No description provided for @reportsCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get reportsCompletionRate;

  /// No description provided for @reportsActiveLearners.
  ///
  /// In en, this message translates to:
  /// **'Active learners'**
  String get reportsActiveLearners;

  /// No description provided for @reportsAvgProgress.
  ///
  /// In en, this message translates to:
  /// **'Average progress'**
  String get reportsAvgProgress;

  /// No description provided for @reportsQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get reportsQuizzesTitle;

  /// No description provided for @reportsQuizAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get reportsQuizAttempts;

  /// No description provided for @reportsPassRate.
  ///
  /// In en, this message translates to:
  /// **'Pass rate'**
  String get reportsPassRate;

  /// No description provided for @reportsAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get reportsAvgScore;

  /// No description provided for @reportsAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get reportsAssignmentsTitle;

  /// No description provided for @reportsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Handed in'**
  String get reportsSubmitted;

  /// No description provided for @reportsOnTime.
  ///
  /// In en, this message translates to:
  /// **'Reviewed on time'**
  String get reportsOnTime;

  /// No description provided for @reportsReviewHours.
  ///
  /// In en, this message translates to:
  /// **'Median review hours'**
  String get reportsReviewHours;

  /// No description provided for @reportsEngagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get reportsEngagementTitle;

  /// No description provided for @reportsLessonsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lessons finished'**
  String get reportsLessonsCompleted;

  /// No description provided for @reportsLessonsPerLearner.
  ///
  /// In en, this message translates to:
  /// **'Lessons per learner'**
  String get reportsLessonsPerLearner;

  /// No description provided for @reportsLiveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Live attendance'**
  String get reportsLiveAttendance;

  /// No description provided for @reportsProgressBandsTitle.
  ///
  /// In en, this message translates to:
  /// **'How far learners have got'**
  String get reportsProgressBandsTitle;

  /// No description provided for @reportsCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get reportsCategoriesTitle;

  /// No description provided for @reportsTopCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Busiest courses'**
  String get reportsTopCoursesTitle;

  /// No description provided for @reportsSeriesEnrolments.
  ///
  /// In en, this message translates to:
  /// **'Enrolments over time'**
  String get reportsSeriesEnrolments;

  /// No description provided for @reportsSeriesCompletions.
  ///
  /// In en, this message translates to:
  /// **'Completions over time'**
  String get reportsSeriesCompletions;

  /// No description provided for @reportsSeriesActive.
  ///
  /// In en, this message translates to:
  /// **'Active learners over time'**
  String get reportsSeriesActive;

  /// No description provided for @reportsBandLearners.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 learner} other{{count} learners}}'**
  String reportsBandLearners(int count);

  /// No description provided for @reportsCategoryEnrolments.
  ///
  /// In en, this message translates to:
  /// **'{count} enrolled · {rate}% complete'**
  String reportsCategoryEnrolments(int count, int rate);

  /// No description provided for @reportsCategoryEnrolmentsOnly.
  ///
  /// In en, this message translates to:
  /// **'{count} enrolled'**
  String reportsCategoryEnrolmentsOnly(int count);

  /// No description provided for @reportsCourseEnrolments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 enrolment} other{{count} enrolments}}'**
  String reportsCourseEnrolments(int count);

  /// No description provided for @reportsCoursePrevious.
  ///
  /// In en, this message translates to:
  /// **'{count} in the previous period'**
  String reportsCoursePrevious(int count);

  /// No description provided for @reportsCourseActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String reportsCourseActive(int count);

  /// No description provided for @reportsCourseCompletions.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String reportsCourseCompletions(int count);

  /// No description provided for @reportsCourseRating.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating}'**
  String reportsCourseRating(String rating);

  /// No description provided for @reportsCoursesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No course had any activity in this period.'**
  String get reportsCoursesEmpty;

  /// No description provided for @reportsOpenCourseReport.
  ///
  /// In en, this message translates to:
  /// **'Open the course report'**
  String get reportsOpenCourseReport;

  /// No description provided for @reportsCourseFunnelTitle.
  ///
  /// In en, this message translates to:
  /// **'How far the intake got'**
  String get reportsCourseFunnelTitle;

  /// No description provided for @reportsCourseChaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapters reached'**
  String get reportsCourseChaptersTitle;

  /// No description provided for @reportsCourseChapterReached.
  ///
  /// In en, this message translates to:
  /// **'{percent}% reached it'**
  String reportsCourseChapterReached(int percent);

  /// No description provided for @reportsCourseQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quizzes in this course'**
  String get reportsCourseQuizzesTitle;

  /// No description provided for @reportsCourseAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments in this course'**
  String get reportsCourseAssignmentsTitle;

  /// No description provided for @reportsQuizSummary.
  ///
  /// In en, this message translates to:
  /// **'{attempts} attempts · {pass}% passed'**
  String reportsQuizSummary(int attempts, int pass);

  /// No description provided for @reportsAssignmentSummary.
  ///
  /// In en, this message translates to:
  /// **'{submitted} handed in · {pass}% passed'**
  String reportsAssignmentSummary(int submitted, int pass);

  /// No description provided for @reportsCourseNotFound.
  ///
  /// In en, this message translates to:
  /// **'There is no report for this course — it may still be a draft.'**
  String get reportsCourseNotFound;

  /// No description provided for @reportsLearnersCount.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get reportsLearnersCount;

  /// No description provided for @reportsLearnersActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get reportsLearnersActive;

  /// No description provided for @reportsLearnersAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get reportsLearnersAtRisk;

  /// No description provided for @reportsLearnerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search learners'**
  String get reportsLearnerSearch;

  /// No description provided for @reportsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Order by'**
  String get reportsSortLabel;

  /// No description provided for @reportsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get reportsSortName;

  /// No description provided for @reportsSortCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get reportsSortCourses;

  /// No description provided for @reportsSortProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get reportsSortProgress;

  /// No description provided for @reportsSortAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignment average'**
  String get reportsSortAssignments;

  /// No description provided for @reportsSortLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get reportsSortLastActive;

  /// No description provided for @reportsSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Highest first'**
  String get reportsSortDescending;

  /// No description provided for @reportsSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Lowest first'**
  String get reportsSortAscending;

  /// No description provided for @reportsLearnerCourses.
  ///
  /// In en, this message translates to:
  /// **'{courses, plural, =1{1 course} other{{courses} courses}} · {completed} completed'**
  String reportsLearnerCourses(int courses, int completed);

  /// No description provided for @reportsLearnerProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% through'**
  String reportsLearnerProgress(int percent);

  /// No description provided for @reportsLearnerAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments {percent}%'**
  String reportsLearnerAssignments(int percent);

  /// No description provided for @reportsLearnerLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String reportsLearnerLastSeen(String when);

  /// No description provided for @reportsLearnerNeverSeen.
  ///
  /// In en, this message translates to:
  /// **'Not seen yet'**
  String get reportsLearnerNeverSeen;

  /// No description provided for @reportsStatusesTitle.
  ///
  /// In en, this message translates to:
  /// **'Where learners stand'**
  String get reportsStatusesTitle;

  /// No description provided for @reportsLearnersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No learner matches this search.'**
  String get reportsLearnersEmpty;

  /// No description provided for @reportsPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String reportsPageOf(int page, int pages);

  /// No description provided for @reportsSelfShare.
  ///
  /// In en, this message translates to:
  /// **'Enrolled themselves'**
  String get reportsSelfShare;

  /// No description provided for @reportsSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Where enrolments came from'**
  String get reportsSourcesTitle;

  /// No description provided for @reportsSourceSelf.
  ///
  /// In en, this message translates to:
  /// **'Learner themselves'**
  String get reportsSourceSelf;

  /// No description provided for @reportsSourceAdmin.
  ///
  /// In en, this message translates to:
  /// **'Added by the LMS'**
  String get reportsSourceAdmin;

  /// No description provided for @reportsSourceImport.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get reportsSourceImport;

  /// No description provided for @reportsSourceGift.
  ///
  /// In en, this message translates to:
  /// **'Gifted'**
  String get reportsSourceGift;

  /// No description provided for @reportsSourceSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} · {share}% of all'**
  String reportsSourceSummary(int count, int share);

  /// No description provided for @reportsCohortsTitle.
  ///
  /// In en, this message translates to:
  /// **'Each month’s intake'**
  String get reportsCohortsTitle;

  /// No description provided for @reportsCohortEnrolled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 enrolled} other{{count} enrolled}}'**
  String reportsCohortEnrolled(int count);

  /// No description provided for @reportsCohortWithin.
  ///
  /// In en, this message translates to:
  /// **'Finished within {days} days'**
  String reportsCohortWithin(int days);

  /// No description provided for @reportsCohortToDate.
  ///
  /// In en, this message translates to:
  /// **'Finished so far'**
  String get reportsCohortToDate;

  /// No description provided for @reportsInstructorsTitle.
  ///
  /// In en, this message translates to:
  /// **'How the teaching is going'**
  String get reportsInstructorsTitle;

  /// No description provided for @reportsInstructorReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reportsInstructorReviews;

  /// No description provided for @reportsInstructorReviewHours.
  ///
  /// In en, this message translates to:
  /// **'Median review hours'**
  String get reportsInstructorReviewHours;

  /// No description provided for @reportsInstructorOnTime.
  ///
  /// In en, this message translates to:
  /// **'Reviewed on time'**
  String get reportsInstructorOnTime;

  /// No description provided for @reportsInstructorAttendance.
  ///
  /// In en, this message translates to:
  /// **'Live attendance'**
  String get reportsInstructorAttendance;

  /// No description provided for @reportsInstructorSummary.
  ///
  /// In en, this message translates to:
  /// **'{courses, plural, =1{1 course} other{{courses} courses}} · {learners, plural, =1{1 learner} other{{learners} learners}}'**
  String reportsInstructorSummary(int courses, int learners);

  /// No description provided for @reportsInstructorsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No instructor had activity in this period.'**
  String get reportsInstructorsEmpty;

  /// No description provided for @reportsPeriod30d.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get reportsPeriod30d;

  /// No description provided for @reportsPeriod90d.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get reportsPeriod90d;

  /// No description provided for @reportsPeriod6m.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get reportsPeriod6m;

  /// No description provided for @reportsPeriod12m.
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get reportsPeriod12m;

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get billingTitle;

  /// No description provided for @billingNoPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your LMS isn’t on a plan yet'**
  String get billingNoPlanTitle;

  /// No description provided for @billingNoPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you have stays as it is. A plan adds room to grow, and the LMS will tell you what each one includes.'**
  String get billingNoPlanBody;

  /// No description provided for @billingSeePlans.
  ///
  /// In en, this message translates to:
  /// **'See the plans'**
  String get billingSeePlans;

  /// No description provided for @billingUpgradeAction.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to a paid plan'**
  String get billingUpgradeAction;

  /// No description provided for @billingPlanCycleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get billingPlanCycleMonthly;

  /// No description provided for @billingPlanCycleAnnual.
  ///
  /// In en, this message translates to:
  /// **'Billed yearly'**
  String get billingPlanCycleAnnual;

  /// No description provided for @billingRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews {date}'**
  String billingRenewsOn(String date);

  /// No description provided for @billingEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String billingEndsOn(String date);

  /// No description provided for @billingTrialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Your trial ends today} =1{1 day of your trial left} other{{days} days of your trial left}}'**
  String billingTrialDaysLeft(int days);

  /// No description provided for @billingPastDueTitle.
  ///
  /// In en, this message translates to:
  /// **'A payment didn’t go through'**
  String get billingPastDueTitle;

  /// No description provided for @billingPastDueBody.
  ///
  /// In en, this message translates to:
  /// **'Your account owes {amount}. Access stays open until {date}.'**
  String billingPastDueBody(String amount, String date);

  /// No description provided for @billingRetryOn.
  ///
  /// In en, this message translates to:
  /// **'The next attempt is {date}'**
  String billingRetryOn(String date);

  /// No description provided for @billingCancelingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan ends {date}'**
  String billingCancelingTitle(String date);

  /// No description provided for @billingCancelingBody.
  ///
  /// In en, this message translates to:
  /// **'Everything keeps working until then.'**
  String get billingCancelingBody;

  /// No description provided for @billingPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan is paused'**
  String get billingPausedTitle;

  /// No description provided for @billingPausedResumes.
  ///
  /// In en, this message translates to:
  /// **'It resumes {date}'**
  String billingPausedResumes(String date);

  /// No description provided for @billingExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan has ended'**
  String get billingExpiredTitle;

  /// No description provided for @billingExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'You keep and can edit everything you have. Renewing reopens the room to add more.'**
  String get billingExpiredBody;

  /// No description provided for @billingNotEnforcedNote.
  ///
  /// In en, this message translates to:
  /// **'Plan limits aren’t enforced yet, so nothing is being blocked.'**
  String get billingNotEnforcedNote;

  /// No description provided for @billingUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'What you’re using'**
  String get billingUsageTitle;

  /// No description provided for @billingUsageOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {allowed}'**
  String billingUsageOf(String used, String allowed);

  /// No description provided for @billingUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get billingUnlimited;

  /// No description provided for @billingUsageRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String billingUsageRemaining(int count);

  /// No description provided for @billingUsageFull.
  ///
  /// In en, this message translates to:
  /// **'Nothing left'**
  String get billingUsageFull;

  /// No description provided for @billingFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'What your plan includes'**
  String get billingFeaturesTitle;

  /// No description provided for @billingFeatureIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get billingFeatureIncluded;

  /// No description provided for @billingFeatureNotIncluded.
  ///
  /// In en, this message translates to:
  /// **'Not included'**
  String get billingFeatureNotIncluded;

  /// No description provided for @billingFeaturePlanned.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get billingFeaturePlanned;

  /// No description provided for @billingInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get billingInvoicesTitle;

  /// No description provided for @billingInvoicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet.'**
  String get billingInvoicesEmpty;

  /// No description provided for @billingPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get billingPaymentsTitle;

  /// No description provided for @billingPaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get billingPaymentsEmpty;

  /// No description provided for @billingOpenChangeUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'An upgrade to {plan} is waiting to be paid'**
  String billingOpenChangeUpgradeTitle(String plan);

  /// No description provided for @billingOpenChangeScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Moving to {plan} on {date}'**
  String billingOpenChangeScheduledTitle(String plan, String date);

  /// No description provided for @billingOpenChangeCharge.
  ///
  /// In en, this message translates to:
  /// **'{amount} to pay now'**
  String billingOpenChangeCharge(String amount);

  /// No description provided for @billingOpenChangeCredit.
  ///
  /// In en, this message translates to:
  /// **'{amount} credited from what you have already paid'**
  String billingOpenChangeCredit(String amount);

  /// No description provided for @billingOpenChangeGiveUp.
  ///
  /// In en, this message translates to:
  /// **'Give up this change'**
  String get billingOpenChangeGiveUp;

  /// No description provided for @billingOpenChangeGiveUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Give up this plan change?'**
  String get billingOpenChangeGiveUpTitle;

  /// No description provided for @billingOpenChangeGiveUpBody.
  ///
  /// In en, this message translates to:
  /// **'The quote is withdrawn. Nothing you have now changes, and you can ask again at any time.'**
  String get billingOpenChangeGiveUpBody;

  /// No description provided for @billingOpenChangeGaveUp.
  ///
  /// In en, this message translates to:
  /// **'The plan change was given up.'**
  String get billingOpenChangeGaveUp;

  /// No description provided for @billingChangePlanAction.
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get billingChangePlanAction;

  /// No description provided for @billingCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel the plan'**
  String get billingCancelAction;

  /// No description provided for @billingCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel at the end of the period?'**
  String get billingCancelTitle;

  /// No description provided for @billingCancelBody.
  ///
  /// In en, this message translates to:
  /// **'Everything keeps working until the period ends. After that the LMS keeps what it has and cannot add more until it renews.'**
  String get billingCancelBody;

  /// No description provided for @billingCancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get billingCancelReasonLabel;

  /// No description provided for @billingCancelReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters. The LMS keeps this on its record.'**
  String get billingCancelReasonHelp;

  /// No description provided for @billingCanceled.
  ///
  /// In en, this message translates to:
  /// **'Your plan will end when the period does.'**
  String get billingCanceled;

  /// No description provided for @billingResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume the plan'**
  String get billingResumeAction;

  /// No description provided for @billingResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume this plan?'**
  String get billingResumeTitle;

  /// No description provided for @billingResumeBody.
  ///
  /// In en, this message translates to:
  /// **'The plan carries on as it was, and billing resumes on its usual date.'**
  String get billingResumeBody;

  /// No description provided for @billingResumed.
  ///
  /// In en, this message translates to:
  /// **'Your plan is running again.'**
  String get billingResumed;

  /// No description provided for @billingPaymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online payment isn’t available yet. The platform team will tell you when it is.'**
  String get billingPaymentUnavailable;

  /// No description provided for @billingPayInvoiceAction.
  ///
  /// In en, this message translates to:
  /// **'Pay this invoice'**
  String get billingPayInvoiceAction;

  /// No description provided for @billingPayChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Pay for this upgrade'**
  String get billingPayChangeAction;

  /// No description provided for @billingPaymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment not completed. Nothing has changed — you can try again.'**
  String get billingPaymentNotCompleted;

  /// No description provided for @billingPaymentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your bank hasn’t settled this yet. Checking again…'**
  String get billingPaymentWaiting;

  /// No description provided for @billingBilledTo.
  ///
  /// In en, this message translates to:
  /// **'Billed to'**
  String get billingBilledTo;

  /// No description provided for @billingPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get billingPaymentMethod;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number}'**
  String invoiceTitle(String number);

  /// No description provided for @invoicePeriod.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String invoicePeriod(String from, String to);

  /// No description provided for @invoiceIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String invoiceIssued(String date);

  /// No description provided for @invoicePaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String invoicePaidOn(String date);

  /// No description provided for @invoiceLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'What this covers'**
  String get invoiceLinesTitle;

  /// No description provided for @invoiceLineQuantity.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String invoiceLineQuantity(int count);

  /// No description provided for @invoiceSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get invoiceSubtotal;

  /// No description provided for @invoiceTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get invoiceTax;

  /// No description provided for @invoiceTaxPercent.
  ///
  /// In en, this message translates to:
  /// **'Tax ({percent}%)'**
  String invoiceTaxPercent(String percent);

  /// No description provided for @invoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get invoiceTotal;

  /// No description provided for @invoiceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoiceStatusPaid;

  /// No description provided for @invoiceStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get invoiceStatusPending;

  /// No description provided for @invoiceStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get invoiceStatusFailed;

  /// No description provided for @invoiceStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get invoiceStatusRefunded;

  /// No description provided for @invoiceStatusVoid.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get invoiceStatusVoid;

  /// No description provided for @invoiceAmountsMissing.
  ///
  /// In en, this message translates to:
  /// **'This invoice’s totals were not sent.'**
  String get invoiceAmountsMissing;

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plansTitle;

  /// No description provided for @plansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plans are on sale right now.'**
  String get plansEmpty;

  /// No description provided for @plansPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month'**
  String plansPerMonth(String amount);

  /// No description provided for @plansPerYear.
  ///
  /// In en, this message translates to:
  /// **'{amount} a year'**
  String plansPerYear(String amount);

  /// No description provided for @plansTrial.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial'**
  String plansTrial(int days);

  /// No description provided for @plansLimitsTitle.
  ///
  /// In en, this message translates to:
  /// **'What it allows'**
  String get plansLimitsTitle;

  /// No description provided for @plansFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'What it includes'**
  String get plansFeaturesTitle;

  /// No description provided for @plansCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get plansCurrentPlan;

  /// No description provided for @plansChooseMonthly.
  ///
  /// In en, this message translates to:
  /// **'Choose monthly'**
  String get plansChooseMonthly;

  /// No description provided for @plansChooseAnnual.
  ///
  /// In en, this message translates to:
  /// **'Choose yearly'**
  String get plansChooseAnnual;

  /// No description provided for @plansQuoted.
  ///
  /// In en, this message translates to:
  /// **'This change has been quoted.'**
  String get plansQuoted;

  /// No description provided for @plansLimitUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get plansLimitUnlimited;

  /// No description provided for @plansSubscribeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Subscribe monthly'**
  String get plansSubscribeMonthly;

  /// No description provided for @plansSubscribeAnnual.
  ///
  /// In en, this message translates to:
  /// **'Subscribe yearly'**
  String get plansSubscribeAnnual;

  /// No description provided for @billingInvoiceReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your invoice is ready'**
  String get billingInvoiceReadyTitle;

  /// No description provided for @billingInvoiceReady.
  ///
  /// In en, this message translates to:
  /// **'Your invoice {number} for {amount} is ready. Online payment isn’t available right now, so it stays open until it is.'**
  String billingInvoiceReady(String number, String amount);

  /// No description provided for @billingPaymentNotOffered.
  ///
  /// In en, this message translates to:
  /// **'Online payment isn’t available right now'**
  String get billingPaymentNotOffered;

  /// No description provided for @billingCheckoutHostedTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish paying on the payment page'**
  String get billingCheckoutHostedTitle;

  /// No description provided for @billingCheckoutHostedBody.
  ///
  /// In en, this message translates to:
  /// **'The payment page opened outside the app. Your plan changes here only once the payment is confirmed to the platform.'**
  String get billingCheckoutHostedBody;

  /// No description provided for @billingCheckoutConfirmed.
  ///
  /// In en, this message translates to:
  /// **'The payment is confirmed.'**
  String get billingCheckoutConfirmed;

  /// No description provided for @billingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing details'**
  String get billingDetailsTitle;

  /// No description provided for @billingDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Invoices are addressed to these details, and tax is worked out from the country and region.'**
  String get billingDetailsBody;

  /// No description provided for @billingDetailsLegalName.
  ///
  /// In en, this message translates to:
  /// **'Name to bill'**
  String get billingDetailsLegalName;

  /// No description provided for @billingDetailsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email for invoices'**
  String get billingDetailsEmail;

  /// No description provided for @billingDetailsAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get billingDetailsAddressLine1;

  /// No description provided for @billingDetailsAddressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2'**
  String get billingDetailsAddressLine2;

  /// No description provided for @billingDetailsCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get billingDetailsCity;

  /// No description provided for @billingDetailsRegion.
  ///
  /// In en, this message translates to:
  /// **'Region code'**
  String get billingDetailsRegion;

  /// No description provided for @billingDetailsPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get billingDetailsPostalCode;

  /// No description provided for @billingDetailsCountry.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get billingDetailsCountry;

  /// No description provided for @billingDetailsTaxRegistration.
  ///
  /// In en, this message translates to:
  /// **'Tax registration'**
  String get billingDetailsTaxRegistration;

  /// No description provided for @billingDetailsSave.
  ///
  /// In en, this message translates to:
  /// **'Save billing details'**
  String get billingDetailsSave;

  /// No description provided for @billingDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Billing details saved.'**
  String get billingDetailsSaved;

  /// No description provided for @billingDetailsErrorLegalName.
  ///
  /// In en, this message translates to:
  /// **'Give the name the LMS bills under.'**
  String get billingDetailsErrorLegalName;

  /// No description provided for @billingDetailsErrorEmail.
  ///
  /// In en, this message translates to:
  /// **'Give an email address for invoices.'**
  String get billingDetailsErrorEmail;

  /// No description provided for @billingDetailsErrorAddress.
  ///
  /// In en, this message translates to:
  /// **'Give the street address.'**
  String get billingDetailsErrorAddress;

  /// No description provided for @billingDetailsErrorCity.
  ///
  /// In en, this message translates to:
  /// **'Give the city.'**
  String get billingDetailsErrorCity;

  /// No description provided for @billingDetailsErrorPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Give the postal code.'**
  String get billingDetailsErrorPostalCode;

  /// No description provided for @billingDetailsErrorCountry.
  ///
  /// In en, this message translates to:
  /// **'Choose the country by its two-letter code, e.g. IN.'**
  String get billingDetailsErrorCountry;

  /// No description provided for @billingDetailsErrorRegion.
  ///
  /// In en, this message translates to:
  /// **'A region is a short code, e.g. KA.'**
  String get billingDetailsErrorRegion;

  /// No description provided for @billingDetailsErrorTax.
  ///
  /// In en, this message translates to:
  /// **'A tax registration is 3–32 letters, digits or hyphens.'**
  String get billingDetailsErrorTax;

  /// No description provided for @billingDetailsNeeded.
  ///
  /// In en, this message translates to:
  /// **'This change is charged, and its tax depends on the LMS’s billing address. Add it first.'**
  String get billingDetailsNeeded;

  /// No description provided for @billingDetailsAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add billing details'**
  String get billingDetailsAddAction;

  /// No description provided for @planChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to {plan}'**
  String planChangeTitle(String plan);

  /// No description provided for @planChangeCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit for the time already paid'**
  String get planChangeCredit;

  /// No description provided for @planChangeNet.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get planChangeNet;

  /// No description provided for @planChangeTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get planChangeTax;

  /// No description provided for @planChangeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total to pay'**
  String get planChangeTotal;

  /// No description provided for @planChangeAppliesOnPayment.
  ///
  /// In en, this message translates to:
  /// **'It applies as soon as it is paid.'**
  String get planChangeAppliesOnPayment;

  /// No description provided for @planChangeAppliesOn.
  ///
  /// In en, this message translates to:
  /// **'It applies on {date}. Nothing is charged now.'**
  String planChangeAppliesOn(String date);

  /// No description provided for @planChangeConflictsTitle.
  ///
  /// In en, this message translates to:
  /// **'Already over the new plan’s limits'**
  String get planChangeConflictsTitle;

  /// No description provided for @planChangeConflict.
  ///
  /// In en, this message translates to:
  /// **'{limit}: you use {usage}, the new plan allows {allowed}'**
  String planChangeConflict(String limit, int usage, int allowed);

  /// No description provided for @planChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Ask for this change'**
  String get planChangeConfirm;

  /// No description provided for @planChangeContinueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get planChangeContinueToPayment;

  /// No description provided for @pastDueBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue'**
  String get pastDueBannerTitle;

  /// No description provided for @pastDueBannerBody.
  ///
  /// In en, this message translates to:
  /// **'A payment for your LMS plan didn’t go through.'**
  String get pastDueBannerBody;

  /// No description provided for @actionOpenBilling.
  ///
  /// In en, this message translates to:
  /// **'Open billing'**
  String get actionOpenBilling;

  /// No description provided for @moduleCoursesName.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get moduleCoursesName;

  /// No description provided for @moduleQuizzesName.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get moduleQuizzesName;

  /// No description provided for @moduleAssignmentsName.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get moduleAssignmentsName;

  /// No description provided for @moduleCertificatesName.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get moduleCertificatesName;

  /// No description provided for @moduleLiveName.
  ///
  /// In en, this message translates to:
  /// **'Live classes'**
  String get moduleLiveName;

  /// No description provided for @moduleReportsName.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moduleReportsName;

  /// No description provided for @moduleBrandingName.
  ///
  /// In en, this message translates to:
  /// **'Custom branding'**
  String get moduleBrandingName;

  /// No description provided for @moduleCoursesDescription.
  ///
  /// In en, this message translates to:
  /// **'Build courses with chapters and lessons, and publish them to your learners.'**
  String get moduleCoursesDescription;

  /// No description provided for @moduleQuizzesDescription.
  ///
  /// In en, this message translates to:
  /// **'Create quizzes and see how your learners score.'**
  String get moduleQuizzesDescription;

  /// No description provided for @moduleAssignmentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Set assignments and review and grade what learners hand in.'**
  String get moduleAssignmentsDescription;

  /// No description provided for @moduleCertificatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Issue, verify and manage the certificates your learners earn.'**
  String get moduleCertificatesDescription;

  /// No description provided for @moduleLiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Schedule live classes, send reminders and teach in real time.'**
  String get moduleLiveDescription;

  /// No description provided for @moduleReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'See how your courses, learners and enrolments are doing.'**
  String get moduleReportsDescription;

  /// No description provided for @moduleBrandingDescription.
  ///
  /// In en, this message translates to:
  /// **'Give your LMS its own look.'**
  String get moduleBrandingDescription;

  /// No description provided for @restrictedBannerBodyNew.
  ///
  /// In en, this message translates to:
  /// **'Start a free trial or choose a plan to open courses, classes and more.'**
  String get restrictedBannerBodyNew;

  /// No description provided for @actionChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get actionChoosePlan;

  /// No description provided for @actionSeePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get actionSeePlans;

  /// No description provided for @trialBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Free trial · ends today} =1{Free trial · 1 day left} other{Free trial · {days} days left}}'**
  String trialBannerTitle(int days);

  /// No description provided for @trialBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan before it ends to keep everything open.'**
  String get trialBannerBody;

  /// No description provided for @trialBannerBodyPlan.
  ///
  /// In en, this message translates to:
  /// **'You’re trying {plan}. Choose a plan before it ends.'**
  String trialBannerBodyPlan(String plan);

  /// No description provided for @readOnlyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'{module} is read-only'**
  String readOnlyBannerTitle(String module);

  /// No description provided for @readOnlyBannerBodyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Your plan no longer includes it. What you made stays readable; adding new needs a plan.'**
  String get readOnlyBannerBodyAdmin;

  /// No description provided for @readOnlyBannerBodyMember.
  ///
  /// In en, this message translates to:
  /// **'Your LMS plan no longer includes it. What you made stays readable; ask your admin to renew.'**
  String get readOnlyBannerBodyMember;

  /// No description provided for @readOnlyActionReason.
  ///
  /// In en, this message translates to:
  /// **'Adding to {module} needs an active plan.'**
  String readOnlyActionReason(String module);

  /// No description provided for @navLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Locked. Upgrade the plan to use it.'**
  String get navLockedHint;

  /// No description provided for @navReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get navReadOnlyHint;

  /// No description provided for @navUpgradeBadge.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get navUpgradeBadge;

  /// No description provided for @navReadOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get navReadOnlyBadge;

  /// No description provided for @academySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Your LMS is being set up'**
  String get academySetupTitle;

  /// No description provided for @academySetupBody.
  ///
  /// In en, this message translates to:
  /// **'Your admin is choosing a plan. {module} will open here as soon as they do.'**
  String academySetupBody(String module);

  /// No description provided for @limitLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get limitLearners;

  /// No description provided for @limitInstructors.
  ///
  /// In en, this message translates to:
  /// **'Instructors'**
  String get limitInstructors;

  /// No description provided for @limitCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get limitCourses;

  /// No description provided for @limitStorage.
  ///
  /// In en, this message translates to:
  /// **'Media storage'**
  String get limitStorage;

  /// No description provided for @limitLiveClasses.
  ///
  /// In en, this message translates to:
  /// **'Live classes a month'**
  String get limitLiveClasses;

  /// No description provided for @limitAdminAccounts.
  ///
  /// In en, this message translates to:
  /// **'Admin accounts'**
  String get limitAdminAccounts;

  /// No description provided for @limitStorageGb.
  ///
  /// In en, this message translates to:
  /// **'{size} GB'**
  String limitStorageGb(String size);

  /// No description provided for @limitStorageMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String limitStorageMb(String size);

  /// No description provided for @featureCoursesManage.
  ///
  /// In en, this message translates to:
  /// **'Course management'**
  String get featureCoursesManage;

  /// No description provided for @featureAssessmentsManage.
  ///
  /// In en, this message translates to:
  /// **'Quizzes and assignments'**
  String get featureAssessmentsManage;

  /// No description provided for @featureCertificatesManage.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get featureCertificatesManage;

  /// No description provided for @featureLiveClasses.
  ///
  /// In en, this message translates to:
  /// **'Live classes'**
  String get featureLiveClasses;

  /// No description provided for @featureReportsBasic.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get featureReportsBasic;

  /// No description provided for @featureReportsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced reports'**
  String get featureReportsAdvanced;

  /// No description provided for @featureAnalyticsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics'**
  String get featureAnalyticsAdvanced;

  /// No description provided for @featureCustomBranding.
  ///
  /// In en, this message translates to:
  /// **'Custom branding'**
  String get featureCustomBranding;

  /// No description provided for @featurePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get featurePrioritySupport;

  /// No description provided for @trialErrorPlanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This plan doesn’t offer a free trial any more. The plans have been refreshed.'**
  String get trialErrorPlanUnavailable;

  /// No description provided for @trialErrorAlreadySubscribed.
  ///
  /// In en, this message translates to:
  /// **'Your LMS already has a plan or has used its free trial. The plans have been refreshed.'**
  String get trialErrorAlreadySubscribed;

  /// No description provided for @onboardingAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingAppBarTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Choose a plan to get started'**
  String get onboardingTitle;

  /// No description provided for @onboardingTitleAcademy.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {academy}'**
  String onboardingTitleAcademy(String academy);

  /// No description provided for @onboardingBodyTrial.
  ///
  /// In en, this message translates to:
  /// **'Start a free trial to open courses, quizzes, live classes and more. No payment needed — choose a paid plan any time.'**
  String get onboardingBodyTrial;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan to open courses, quizzes, live classes and more.'**
  String get onboardingBody;

  /// No description provided for @onboardingNoBillingEdit.
  ///
  /// In en, this message translates to:
  /// **'Only an admin who can change billing can start a plan. Ask them to choose one.'**
  String get onboardingNoBillingEdit;

  /// No description provided for @onboardingTrialUsed.
  ///
  /// In en, this message translates to:
  /// **'Your LMS has already used its free trial.'**
  String get onboardingTrialUsed;

  /// No description provided for @onboardingNoPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'No plans on sale'**
  String get onboardingNoPlansTitle;

  /// No description provided for @onboardingCycleLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing cycle'**
  String get onboardingCycleLabel;

  /// No description provided for @onboardingCycleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get onboardingCycleMonthly;

  /// No description provided for @onboardingCycleAnnual.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get onboardingCycleAnnual;

  /// No description provided for @onboardingNotSoldMonthly.
  ///
  /// In en, this message translates to:
  /// **'Not sold monthly'**
  String get onboardingNotSoldMonthly;

  /// No description provided for @onboardingNotSoldAnnual.
  ///
  /// In en, this message translates to:
  /// **'Not sold yearly'**
  String get onboardingNotSoldAnnual;

  /// No description provided for @onboardingStartTrial.
  ///
  /// In en, this message translates to:
  /// **'Start {days}-day free trial'**
  String onboardingStartTrial(int days);

  /// No description provided for @onboardingBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy for {price}'**
  String onboardingBuy(String price);

  /// No description provided for @onboardingPaymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Paid plans can’t be bought in the app right now. You can still start a free trial.'**
  String get onboardingPaymentUnavailable;

  /// No description provided for @onboardingNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now — go to the dashboard'**
  String get onboardingNotNow;

  /// No description provided for @onboardingTrialStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your free trial has started'**
  String get onboardingTrialStartedTitle;

  /// No description provided for @onboardingTrialStartedBody.
  ///
  /// In en, this message translates to:
  /// **'Everything in the plan is open. Choose a paid plan any time before the trial ends.'**
  String get onboardingTrialStartedBody;

  /// No description provided for @onboardingTrialStartedUntil.
  ///
  /// In en, this message translates to:
  /// **'Everything in the plan is open until {date}. Choose a paid plan any time before then.'**
  String onboardingTrialStartedUntil(String date);

  /// No description provided for @onboardingGoToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to the dashboard'**
  String get onboardingGoToDashboard;

  /// No description provided for @onboardingAlreadyOnPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your LMS is on a plan'**
  String get onboardingAlreadyOnPlanTitle;

  /// No description provided for @trialOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Try a plan free for 1 day} other{Try a plan free for {days} days}}'**
  String trialOfferTitle(int days);

  /// No description provided for @trialOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Start a free trial to see everything your LMS can do. No payment needed.'**
  String get trialOfferBody;

  /// No description provided for @trialOfferDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss the free trial offer'**
  String get trialOfferDismiss;

  /// No description provided for @trialOfferAction.
  ///
  /// In en, this message translates to:
  /// **'See plans and start a trial'**
  String get trialOfferAction;

  /// No description provided for @planGateLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not included in your LMS plan'**
  String get planGateLockedTitle;

  /// No description provided for @planGateAskAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ask your admin to upgrade the plan.'**
  String get planGateAskAdmin;

  /// No description provided for @planGateNoPlanIncludes.
  ///
  /// In en, this message translates to:
  /// **'No plan on sale includes this yet.'**
  String get planGateNoPlanIncludes;

  /// No description provided for @planGateIncludedIn.
  ///
  /// In en, this message translates to:
  /// **'Included in'**
  String get planGateIncludedIn;

  /// No description provided for @planGatePlansUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The plans couldn’t be loaded.'**
  String get planGatePlansUnavailable;

  /// No description provided for @reportsSourcePurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get reportsSourcePurchase;

  /// No description provided for @coursePriceNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Not open yet'**
  String get coursePriceNotOpen;

  /// No description provided for @courseSaleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not open for enrolment yet'**
  String get courseSaleUnavailable;

  /// No description provided for @courseNotSoldInApp.
  ///
  /// In en, this message translates to:
  /// **'This course can’t be bought in the app.'**
  String get courseNotSoldInApp;

  /// No description provided for @actionBuyCourse.
  ///
  /// In en, this message translates to:
  /// **'Buy course · {price}'**
  String actionBuyCourse(String price);

  /// No description provided for @actionPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {price}'**
  String actionPayAmount(String price);

  /// No description provided for @purchaseSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get purchaseSummaryTitle;

  /// No description provided for @purchaseSummaryCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get purchaseSummaryCourse;

  /// No description provided for @purchaseSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get purchaseSummaryTotal;

  /// No description provided for @purchaseSummaryAllInclusive.
  ///
  /// In en, this message translates to:
  /// **'All-inclusive price'**
  String get purchaseSummaryAllInclusive;

  /// No description provided for @purchaseSummaryNote.
  ///
  /// In en, this message translates to:
  /// **'The course opens as soon as your payment is confirmed.'**
  String get purchaseSummaryNote;

  /// No description provided for @purchaseStarting.
  ///
  /// In en, this message translates to:
  /// **'Opening the payment…'**
  String get purchaseStarting;

  /// No description provided for @purchaseAtGateway.
  ///
  /// In en, this message translates to:
  /// **'Finish paying in the payment window.'**
  String get purchaseAtGateway;

  /// No description provided for @purchaseConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming your payment…'**
  String get purchaseConfirming;

  /// No description provided for @purchaseWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your payment is being confirmed. The course opens as soon as it is.'**
  String get purchaseWaiting;

  /// No description provided for @purchaseStillWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your payment is still being confirmed. The course opens as soon as it is, even if you leave this page.'**
  String get purchaseStillWaiting;

  /// No description provided for @purchaseAwayAtPage.
  ///
  /// In en, this message translates to:
  /// **'Finish paying on the payment page, then come back here.'**
  String get purchaseAwayAtPage;

  /// No description provided for @purchasePaid.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. The course is open.'**
  String get purchasePaid;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The payment didn’t go through, so the course wasn’t opened. You can try again.'**
  String get purchaseFailed;

  /// No description provided for @purchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled. You weren’t charged.'**
  String get purchaseCancelled;

  /// No description provided for @purchaseOffline.
  ///
  /// In en, this message translates to:
  /// **'We’ll confirm your payment when you’re back online.'**
  String get purchaseOffline;

  /// No description provided for @purchaseNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'This academy doesn’t take online payments yet.'**
  String get purchaseNotSetUp;

  /// No description provided for @purchaseNotForSale.
  ///
  /// In en, this message translates to:
  /// **'This course isn’t open for enrolment yet.'**
  String get purchaseNotForSale;

  /// No description provided for @purchaseAlreadyEnrolled.
  ///
  /// In en, this message translates to:
  /// **'You already have this course.'**
  String get purchaseAlreadyEnrolled;

  /// No description provided for @purchaseUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This payment can’t be completed in this version of the app.'**
  String get purchaseUnsupported;

  /// No description provided for @purchaseRefused.
  ///
  /// In en, this message translates to:
  /// **'The payment couldn’t be started.'**
  String get purchaseRefused;

  /// No description provided for @actionCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get actionCheckAgain;

  /// No description provided for @purchasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchasesTitle;

  /// No description provided for @purchasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Courses you’ve bought'**
  String get purchasesSubtitle;

  /// No description provided for @purchasesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet'**
  String get purchasesEmptyTitle;

  /// No description provided for @purchasesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Courses you buy are listed here.'**
  String get purchasesEmptyBody;

  /// No description provided for @purchaseNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'The academy is reviewing this payment.'**
  String get purchaseNeedsReview;

  /// No description provided for @quizTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mark} other{{count} marks}}'**
  String quizTotalPoints(int count);

  /// No description provided for @quizNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get quizNoTimeLimit;

  /// No description provided for @quizAttemptsUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {allowed} attempts used'**
  String quizAttemptsUsedOf(int used, int allowed);

  /// No description provided for @quizAttemptsUsedUnlimited.
  ///
  /// In en, this message translates to:
  /// **'{used, plural, =0{No attempts used} =1{1 attempt used} other{{used} attempts used}} · no limit'**
  String quizAttemptsUsedUnlimited(int used);

  /// No description provided for @quizOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens {time}'**
  String quizOpensAt(String time);

  /// No description provided for @quizClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes {time}'**
  String quizClosesAt(String time);

  /// No description provided for @quizClosedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed {time}'**
  String quizClosedAt(String time);

  /// No description provided for @quizNegativeMarkingNotice.
  ///
  /// In en, this message translates to:
  /// **'Wrong answers lose marks. Leaving a question blank costs nothing.'**
  String get quizNegativeMarkingNotice;

  /// No description provided for @quizResultsAfterClose.
  ///
  /// In en, this message translates to:
  /// **'Results are shown once the quiz closes.'**
  String get quizResultsAfterClose;

  /// No description provided for @quizPassedPractice.
  ///
  /// In en, this message translates to:
  /// **'You’ve passed. Further attempts are practice.'**
  String get quizPassedPractice;

  /// No description provided for @actionResumeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Resume the quiz'**
  String get actionResumeQuiz;

  /// No description provided for @quizAttemptUnderWay.
  ///
  /// In en, this message translates to:
  /// **'Attempt {number} is under way.'**
  String quizAttemptUnderWay(int number);

  /// No description provided for @quizStartTimedNotice.
  ///
  /// In en, this message translates to:
  /// **'The timer starts when you tap Start and keeps running if you leave the app.'**
  String get quizStartTimedNotice;

  /// No description provided for @quizStartUsesAttempt.
  ///
  /// In en, this message translates to:
  /// **'Starting uses one attempt.'**
  String get quizStartUsesAttempt;

  /// No description provided for @quizStandingFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t check your attempts.'**
  String get quizStandingFailed;

  /// No description provided for @quizNotOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'This quiz opens {time}.'**
  String quizNotOpenUntil(String time);

  /// No description provided for @quizNoLongerOpen.
  ///
  /// In en, this message translates to:
  /// **'This quiz is no longer open for attempts.'**
  String get quizNoLongerOpen;

  /// No description provided for @quizStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The quiz didn’t start. Check your connection and try again.'**
  String get quizStartFailed;

  /// No description provided for @quizTimerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Time left: {time}'**
  String quizTimerSemantics(String time);

  /// No description provided for @quizWarnFiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes left.'**
  String get quizWarnFiveMinutes;

  /// No description provided for @quizWarnOneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute left. Your saved answers are handed in when time runs out.'**
  String get quizWarnOneMinute;

  /// No description provided for @quizSaveUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get quizSaveUnsaved;

  /// No description provided for @quizSaveSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get quizSaveSaving;

  /// No description provided for @quizSaveSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get quizSaveSaved;

  /// No description provided for @quizSaveRetrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying…'**
  String get quizSaveRetrying;

  /// No description provided for @quizSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get quizSaveFailed;

  /// No description provided for @quizSaveUnsavedHint.
  ///
  /// In en, this message translates to:
  /// **'Answered on this phone, not saved yet.'**
  String get quizSaveUnsavedHint;

  /// No description provided for @quizSaveSavingHint.
  ///
  /// In en, this message translates to:
  /// **'Sending your answers to the server.'**
  String get quizSaveSavingHint;

  /// No description provided for @quizSaveSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved on the server.'**
  String get quizSaveSavedHint;

  /// No description provided for @quizSaveRetryingHint.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach the server. Trying again.'**
  String get quizSaveRetryingHint;

  /// No description provided for @quizSaveFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Your latest answers are not saved.'**
  String get quizSaveFailedHint;

  /// No description provided for @quizOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Your answers stay on this phone and are saved when you reconnect. The timer keeps running.'**
  String get quizOfflineBanner;

  /// No description provided for @quizPaletteItem.
  ///
  /// In en, this message translates to:
  /// **'Question {number}, {status}'**
  String quizPaletteItem(int number, String status);

  /// No description provided for @quizPaletteCurrent.
  ///
  /// In en, this message translates to:
  /// **'Question {number}, {status}, on screen'**
  String quizPaletteCurrent(int number, String status);

  /// No description provided for @quizQuestionMarks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mark} other{{count} marks}}'**
  String quizQuestionMarks(int count);

  /// No description provided for @quizQuestionNegative.
  ///
  /// In en, this message translates to:
  /// **'{marks} · a wrong answer costs {negative}'**
  String quizQuestionNegative(String marks, String negative);

  /// No description provided for @quizAnsweredNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Answered · not saved yet'**
  String get quizAnsweredNotSaved;

  /// No description provided for @actionBackToQuestions.
  ///
  /// In en, this message translates to:
  /// **'Back to questions'**
  String get actionBackToQuestions;

  /// No description provided for @quizSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t hand in your attempt. Your saved answers are safe — try again.'**
  String get quizSubmitFailed;

  /// No description provided for @quizHandingIn.
  ///
  /// In en, this message translates to:
  /// **'Handing in your attempt…'**
  String get quizHandingIn;

  /// No description provided for @quizHandInRetrying.
  ///
  /// In en, this message translates to:
  /// **'Still handing in — waiting for the connection.'**
  String get quizHandInRetrying;

  /// No description provided for @quizReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Attempt handed in'**
  String get quizReceivedTitle;

  /// No description provided for @quizResultPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String quizResultPercent(int percent);

  /// No description provided for @quizResultPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} of {max} marks'**
  String quizResultPoints(String points, String max);

  /// No description provided for @quizResultPassMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark {passMark}%'**
  String quizResultPassMark(int passMark);

  /// No description provided for @quizResultSemantics.
  ///
  /// In en, this message translates to:
  /// **'Score {percent} percent, {points} of {max} marks'**
  String quizResultSemantics(int percent, String points, String max);

  /// No description provided for @quizKeyWithheld.
  ///
  /// In en, this message translates to:
  /// **'Correct answers are shown once you pass or have no attempts left.'**
  String get quizKeyWithheld;

  /// No description provided for @quizResultsHeldUntil.
  ///
  /// In en, this message translates to:
  /// **'Your attempt is in. Results are shown on {time}.'**
  String quizResultsHeldUntil(String time);

  /// No description provided for @quizResultsHidden.
  ///
  /// In en, this message translates to:
  /// **'Your attempt is in. This quiz doesn’t show scores.'**
  String get quizResultsHidden;

  /// No description provided for @quizExpiredNotice.
  ///
  /// In en, this message translates to:
  /// **'Time ran out — your saved answers were marked.'**
  String get quizExpiredNotice;

  /// No description provided for @quizNegativeScoreNote.
  ///
  /// In en, this message translates to:
  /// **'Wrong answers cost marks, so a total can fall below zero.'**
  String get quizNegativeScoreNote;

  /// No description provided for @quizBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Question by question'**
  String get quizBreakdownTitle;

  /// No description provided for @quizAnswerCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get quizAnswerCorrect;

  /// No description provided for @quizAnswerIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get quizAnswerIncorrect;

  /// No description provided for @quizAnswerPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly right'**
  String get quizAnswerPartial;

  /// No description provided for @quizAnswerUnanswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get quizAnswerUnanswered;

  /// No description provided for @quizQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String quizQuestionNumber(int number);

  /// No description provided for @quizQuestionScored.
  ///
  /// In en, this message translates to:
  /// **'{marks} marks'**
  String quizQuestionScored(String marks);

  /// No description provided for @quizYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer: {answer}'**
  String quizYourAnswer(String answer);

  /// No description provided for @quizRightAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String quizRightAnswer(String answer);

  /// No description provided for @quizHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your attempts'**
  String get quizHistoryTitle;

  /// No description provided for @quizHistoryAttempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {number}'**
  String quizHistoryAttempt(int number);

  /// No description provided for @quizHistoryExpired.
  ///
  /// In en, this message translates to:
  /// **'Time ran out'**
  String get quizHistoryExpired;

  /// No description provided for @quizHistoryHeld.
  ///
  /// In en, this message translates to:
  /// **'Result after the quiz closes'**
  String get quizHistoryHeld;

  /// No description provided for @quizHistoryReceived.
  ///
  /// In en, this message translates to:
  /// **'Handed in'**
  String get quizHistoryReceived;

  /// No description provided for @quizResultUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your attempt was handed in. We couldn’t load the result.'**
  String get quizResultUnavailable;

  /// No description provided for @quizLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the quiz?'**
  String get quizLeaveTitle;

  /// No description provided for @quizLeaveBodyTimed.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved; the timer keeps running.'**
  String get quizLeaveBodyTimed;

  /// No description provided for @quizLeaveBodyUntimed.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved. You can come back and finish.'**
  String get quizLeaveBodyUntimed;

  /// No description provided for @quizLeaveUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Answers not saved yet are sent as you leave.'**
  String get quizLeaveUnsaved;

  /// No description provided for @quizLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get quizLeaveAction;

  /// No description provided for @assessmentInProgressDeadline.
  ///
  /// In en, this message translates to:
  /// **'Hand in by {time}'**
  String assessmentInProgressDeadline(String time);

  /// No description provided for @assessmentOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens {time}'**
  String assessmentOpensAt(String time);

  /// No description provided for @assessmentClosedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed {time}'**
  String assessmentClosedAt(String time);

  /// No description provided for @assessmentClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes {time}'**
  String assessmentClosesAt(String time);

  /// No description provided for @assessmentResultsHeld.
  ///
  /// In en, this message translates to:
  /// **'Score shown after the quiz closes'**
  String get assessmentResultsHeld;

  /// No description provided for @staffQuizStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get staffQuizStatusArchived;

  /// No description provided for @assessmentNegativeMarking.
  ///
  /// In en, this message translates to:
  /// **'Negative marking: wrong answers lose marks'**
  String get assessmentNegativeMarking;

  /// No description provided for @assessmentResultsHeldUntil.
  ///
  /// In en, this message translates to:
  /// **'Score shown {time}'**
  String assessmentResultsHeldUntil(String time);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
