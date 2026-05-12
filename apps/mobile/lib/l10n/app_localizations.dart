import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th')
  ];

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a number, link, or message…'**
  String get searchHint;

  /// No description provided for @aiSearch.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get aiSearch;

  /// No description provided for @sectionThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get sectionThisWeek;

  /// No description provided for @sectionRecentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent Fraud Alerts'**
  String get sectionRecentAlerts;

  /// No description provided for @sectionRecentlyVerified.
  ///
  /// In en, this message translates to:
  /// **'Recently Verified'**
  String get sectionRecentlyVerified;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @loadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to load — tap to retry'**
  String get loadFailedRetry;

  /// No description provided for @greetingGuest.
  ///
  /// In en, this message translates to:
  /// **'Hi 👋'**
  String get greetingGuest;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String greetingWithName(String name);

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Stay one step ahead of scams'**
  String get tagline;

  /// No description provided for @clipboardBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'We noticed something on your clipboard'**
  String get clipboardBannerTitle;

  /// No description provided for @checkIt.
  ///
  /// In en, this message translates to:
  /// **'Check it'**
  String get checkIt;

  /// No description provided for @reportAScam.
  ///
  /// In en, this message translates to:
  /// **'Report a scam'**
  String get reportAScam;

  /// No description provided for @statVerifiedReports.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED\nREPORTS'**
  String get statVerifiedReports;

  /// No description provided for @statNewThisWeek.
  ///
  /// In en, this message translates to:
  /// **'NEW THIS\nWEEK'**
  String get statNewThisWeek;

  /// No description provided for @statTopScamType.
  ///
  /// In en, this message translates to:
  /// **'TOP SCAM\nTYPE'**
  String get statTopScamType;

  /// No description provided for @categoryFraudAlert.
  ///
  /// In en, this message translates to:
  /// **'Fraud Alert'**
  String get categoryFraudAlert;

  /// No description provided for @categoryTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get categoryTips;

  /// No description provided for @categoryPlatformUpdate.
  ///
  /// In en, this message translates to:
  /// **'Platform Update'**
  String get categoryPlatformUpdate;

  /// No description provided for @categorySmsAlert.
  ///
  /// In en, this message translates to:
  /// **'SMS Scan'**
  String get categorySmsAlert;

  /// No description provided for @reportCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} reports'**
  String reportCountLabel(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settingsSectionAccount;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReports;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Sign out of ScamReport?'**
  String get signOutDialogContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageThai.
  ///
  /// In en, this message translates to:
  /// **'ภาษาไทย'**
  String get languageThai;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @notifPhoneScam.
  ///
  /// In en, this message translates to:
  /// **'Phone scam alerts'**
  String get notifPhoneScam;

  /// No description provided for @notifPhoneScamDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about new phone scams'**
  String get notifPhoneScamDesc;

  /// No description provided for @notifSmsPhishing.
  ///
  /// In en, this message translates to:
  /// **'SMS phishing alerts'**
  String get notifSmsPhishing;

  /// No description provided for @notifSmsPhishingDesc.
  ///
  /// In en, this message translates to:
  /// **'Trending SMS scam patterns'**
  String get notifSmsPhishingDesc;

  /// No description provided for @notifRegional.
  ///
  /// In en, this message translates to:
  /// **'Regional alerts'**
  String get notifRegional;

  /// No description provided for @notifRegionalDesc.
  ///
  /// In en, this message translates to:
  /// **'Scams reported in your province'**
  String get notifRegionalDesc;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get alertsTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @alertsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get alertsEmpty;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @postedByTeam.
  ///
  /// In en, this message translates to:
  /// **'Posted by ScamReport Team'**
  String get postedByTeam;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get navModerate;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified feed'**
  String get feedTitle;

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAll;

  /// No description provided for @feedNoReports.
  ///
  /// In en, this message translates to:
  /// **'No reports yet — be the first to submit one.'**
  String get feedNoReports;

  /// No description provided for @feedStatTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get feedStatTotal;

  /// No description provided for @feedStatThisWeek.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get feedStatThisWeek;

  /// No description provided for @feedStatTopType.
  ///
  /// In en, this message translates to:
  /// **'TOP TYPE'**
  String get feedStatTopType;

  /// No description provided for @modQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation queue'**
  String get modQueueTitle;

  /// No description provided for @modQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty — nice work!'**
  String get modQueueEmpty;

  /// No description provided for @modStatPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get modStatPending;

  /// No description provided for @modStatFlagged.
  ///
  /// In en, this message translates to:
  /// **'FLAGGED'**
  String get modStatFlagged;

  /// No description provided for @modStatAvgAge.
  ///
  /// In en, this message translates to:
  /// **'AVG AGE'**
  String get modStatAvgAge;

  /// No description provided for @modStatAvgAgeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String modStatAvgAgeHours(int hours);

  /// No description provided for @modSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get modSortOldestFirst;

  /// No description provided for @modSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get modSortNewestFirst;

  /// No description provided for @modFilterPriorityFlag.
  ///
  /// In en, this message translates to:
  /// **'Priority flag'**
  String get modFilterPriorityFlag;

  /// No description provided for @modEvidenceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} evidence'**
  String modEvidenceCount(int count);

  /// No description provided for @modReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get modReview;

  /// No description provided for @modTeamNote.
  ///
  /// In en, this message translates to:
  /// **'Team note: {note}'**
  String modTeamNote(String note);

  /// No description provided for @modAgeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String modAgeHours(int hours);

  /// No description provided for @modAgeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String modAgeMinutes(int minutes);

  /// No description provided for @adminReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review report'**
  String get adminReviewTitle;

  /// No description provided for @adminReviewApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminReviewApprove;

  /// No description provided for @adminReviewReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReviewReject;

  /// No description provided for @adminReviewFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get adminReviewFlag;

  /// No description provided for @adminReviewUnflag.
  ///
  /// In en, this message translates to:
  /// **'Unflag'**
  String get adminReviewUnflag;

  /// No description provided for @adminReviewRemark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get adminReviewRemark;

  /// No description provided for @adminReviewRemarkHint.
  ///
  /// In en, this message translates to:
  /// **'Required — will be visible in the audit trail'**
  String get adminReviewRemarkHint;

  /// No description provided for @adminReviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm {action}'**
  String adminReviewConfirm(String action);

  /// No description provided for @adminReviewApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved.'**
  String get adminReviewApproved;

  /// No description provided for @adminReviewRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected.'**
  String get adminReviewRejected;

  /// No description provided for @adminReviewFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged for discussion.'**
  String get adminReviewFlagged;

  /// No description provided for @adminReviewUnflagged.
  ///
  /// In en, this message translates to:
  /// **'Flag removed.'**
  String get adminReviewUnflagged;

  /// No description provided for @adminReviewSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String adminReviewSubmittedOn(String date);

  /// No description provided for @adminLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get adminLabelDescription;

  /// No description provided for @adminLabelTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET IDENTIFIER'**
  String get adminLabelTarget;

  /// No description provided for @adminLabelEvidence.
  ///
  /// In en, this message translates to:
  /// **'EVIDENCE'**
  String get adminLabelEvidence;

  /// No description provided for @adminLabelAuditTrail.
  ///
  /// In en, this message translates to:
  /// **'AUDIT TRAIL'**
  String get adminLabelAuditTrail;

  /// No description provided for @adminAiScore.
  ///
  /// In en, this message translates to:
  /// **'AI confidence: {score}% ({level})'**
  String adminAiScore(int score, String level);

  /// No description provided for @noEvidence.
  ///
  /// In en, this message translates to:
  /// **'No evidence files.'**
  String get noEvidence;

  /// No description provided for @auditTrailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No actions yet.'**
  String get auditTrailEmpty;

  /// No description provided for @smsSmishingDetectionLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS smishing detection'**
  String get smsSmishingDetectionLabel;

  /// No description provided for @smsSmishingDetectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan incoming messages for scams'**
  String get smsSmishingDetectionDesc;

  /// No description provided for @smsConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable SMS scanning?'**
  String get smsConsentTitle;

  /// No description provided for @smsConsentBody.
  ///
  /// In en, this message translates to:
  /// **'ScamReport will read incoming SMS and send the content to our servers to check for scams. No messages are stored on our servers. You can disable this at any time.'**
  String get smsConsentBody;

  /// No description provided for @smsConsentAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree & Continue'**
  String get smsConsentAgree;

  /// No description provided for @smsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'SMS permission is required to scan messages'**
  String get smsPermissionDenied;

  /// No description provided for @smsScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspicious SMS detected'**
  String get smsScanTitle;

  /// No description provided for @smsScanScamTitle.
  ///
  /// In en, this message translates to:
  /// **'Scam SMS detected'**
  String get smsScanScamTitle;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @verdictScam.
  ///
  /// In en, this message translates to:
  /// **'Scam'**
  String get verdictScam;

  /// No description provided for @verdictSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Suspicious'**
  String get verdictSuspicious;

  /// No description provided for @checkInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Check something'**
  String get checkInputTitle;

  /// No description provided for @checkInputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste or type a phone number, link, or message'**
  String get checkInputHint;

  /// No description provided for @checkInputPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'We never store what you check unless you choose to report it.'**
  String get checkInputPrivacyNote;

  /// No description provided for @checkInputRunCheck.
  ///
  /// In en, this message translates to:
  /// **'Run check'**
  String get checkInputRunCheck;

  /// No description provided for @checkInputSampleNumber.
  ///
  /// In en, this message translates to:
  /// **'Try a number'**
  String get checkInputSampleNumber;

  /// No description provided for @checkInputSampleLink.
  ///
  /// In en, this message translates to:
  /// **'Try a link'**
  String get checkInputSampleLink;

  /// No description provided for @verdictChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get verdictChecking;

  /// No description provided for @verdictCheckingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-checking verified reports…'**
  String get verdictCheckingSubtitle;

  /// No description provided for @verdictSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get verdictSafe;

  /// No description provided for @verdictUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get verdictUnknown;

  /// No description provided for @verdictSubtitleScam.
  ///
  /// In en, this message translates to:
  /// **'Multiple verified reports match this item.'**
  String get verdictSubtitleScam;

  /// No description provided for @verdictSubtitleSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Partial match — proceed with caution.'**
  String get verdictSubtitleSuspicious;

  /// No description provided for @verdictSubtitleSafe.
  ///
  /// In en, this message translates to:
  /// **'No verified scam reports for this item.'**
  String get verdictSubtitleSafe;

  /// No description provided for @verdictSubtitleUnknown.
  ///
  /// In en, this message translates to:
  /// **'We could not classify this item.'**
  String get verdictSubtitleUnknown;

  /// No description provided for @verdictYouChecked.
  ///
  /// In en, this message translates to:
  /// **'YOU CHECKED'**
  String get verdictYouChecked;

  /// No description provided for @verdictMatchedReports.
  ///
  /// In en, this message translates to:
  /// **'{count} verified reports matched'**
  String verdictMatchedReports(int count);

  /// No description provided for @verdictSeeReports.
  ///
  /// In en, this message translates to:
  /// **'See matched reports'**
  String get verdictSeeReports;

  /// No description provided for @verdictReportThis.
  ///
  /// In en, this message translates to:
  /// **'Report this'**
  String get verdictReportThis;

  /// No description provided for @verdictShareViaSms.
  ///
  /// In en, this message translates to:
  /// **'Share via SMS'**
  String get verdictShareViaSms;

  /// No description provided for @verdictCachedResult.
  ///
  /// In en, this message translates to:
  /// **'Cached result'**
  String get verdictCachedResult;

  /// No description provided for @reportDetailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get reportDetailVerified;

  /// No description provided for @reportDetailVerifiedOn.
  ///
  /// In en, this message translates to:
  /// **'Verified {date}'**
  String reportDetailVerifiedOn(String date);

  /// No description provided for @reportDetailIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'REPORTED IDENTIFIER'**
  String get reportDetailIdentifierLabel;

  /// No description provided for @reportDetailWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'WHAT HAPPENED'**
  String get reportDetailWhatHappened;

  /// No description provided for @reportDetailEvidence.
  ///
  /// In en, this message translates to:
  /// **'EVIDENCE'**
  String get reportDetailEvidence;

  /// No description provided for @reportDetailCta.
  ///
  /// In en, this message translates to:
  /// **'Report a similar scam'**
  String get reportDetailCta;

  /// No description provided for @reportDetailPrivacyFooter.
  ///
  /// In en, this message translates to:
  /// **'The reporter\'s identity is never shown publicly. Only the scam content above is shared.'**
  String get reportDetailPrivacyFooter;

  /// No description provided for @callScreeningTitle.
  ///
  /// In en, this message translates to:
  /// **'Call Screening'**
  String get callScreeningTitle;

  /// No description provided for @callScreeningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warn you about incoming calls from known scam numbers'**
  String get callScreeningSubtitle;

  /// No description provided for @callScreeningSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warn about known scam callers automatically'**
  String get callScreeningSettingsSubtitle;

  /// No description provided for @callScreeningUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Call screening requires Android 10 or later.'**
  String get callScreeningUnsupported;

  /// No description provided for @callScreeningNoBlocked.
  ///
  /// In en, this message translates to:
  /// **'No screened calls yet.'**
  String get callScreeningNoBlocked;

  /// No description provided for @callScreeningBlockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} call screened} other{{count} calls screened}}'**
  String callScreeningBlockedCount(int count);

  /// No description provided for @callScreeningSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup required'**
  String get callScreeningSetupTitle;

  /// No description provided for @callScreeningSetupBody.
  ///
  /// In en, this message translates to:
  /// **'ScamReport must be set as call screening app in your Phone app settings.'**
  String get callScreeningSetupBody;

  /// No description provided for @callScreeningSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Set as call screening app'**
  String get callScreeningSetupAction;

  /// No description provided for @callScreeningSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update phone list — cached data will be used'**
  String get callScreeningSyncFailed;

  /// No description provided for @askAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask ScamReport'**
  String get askAiTitle;

  /// No description provided for @askAiBeta.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get askAiBeta;

  /// No description provided for @askAiViewDraft.
  ///
  /// In en, this message translates to:
  /// **'View draft'**
  String get askAiViewDraft;

  /// No description provided for @askAiNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get askAiNewChat;

  /// No description provided for @askAiPastChats.
  ///
  /// In en, this message translates to:
  /// **'Past chats'**
  String get askAiPastChats;

  /// No description provided for @askAiRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get askAiRefresh;

  /// No description provided for @askAiNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No past chats yet. Send a message to start one.'**
  String get askAiNoConversations;

  /// No description provided for @askAiLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load conversations.'**
  String get askAiLoadFailed;

  /// No description provided for @askAiNoPreview.
  ///
  /// In en, this message translates to:
  /// **'(no preview)'**
  String get askAiNoPreview;

  /// No description provided for @askAiDeletePrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get askAiDeletePrompt;

  /// No description provided for @askAiDeleteIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get askAiDeleteIrreversible;

  /// No description provided for @askAiDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get askAiDelete;

  /// No description provided for @askAiCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get askAiCancel;

  /// No description provided for @askAiDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete conversation.'**
  String get askAiDeleteFailed;

  /// No description provided for @askAiWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m your scam radar.'**
  String get askAiWelcomeTitle;

  /// No description provided for @askAiWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Tell me what happened — a weird SMS, a suspicious call, a too-good offer — and I\'ll tell you if others have seen it.'**
  String get askAiWelcomeBody;

  /// No description provided for @askAiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI can make mistakes · check important info'**
  String get askAiDisclaimer;

  /// No description provided for @askAiThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get askAiThinking;

  /// No description provided for @askAiSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your message. Please try again.'**
  String get askAiSendFailed;

  /// No description provided for @askAiComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Tell me what happened…'**
  String get askAiComposerHint;

  /// No description provided for @askAiAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get askAiAttach;

  /// No description provided for @askAiAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get askAiAttachCamera;

  /// No description provided for @askAiAttachGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get askAiAttachGallery;

  /// No description provided for @askAiAttachUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type. Use JPEG, PNG, WebP, GIF, or PDF.'**
  String get askAiAttachUnsupported;

  /// No description provided for @askAiAttachTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large (max 10 MB).'**
  String get askAiAttachTooLarge;

  /// No description provided for @askAiConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit this report?'**
  String get askAiConsentTitle;

  /// No description provided for @askAiConsentEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit draft'**
  String get askAiConsentEdit;

  /// No description provided for @askAiConsentRedraft.
  ///
  /// In en, this message translates to:
  /// **'Ask AI to redraft'**
  String get askAiConsentRedraft;

  /// No description provided for @askAiConsentNotice.
  ///
  /// In en, this message translates to:
  /// **'By submitting, you agree that this report — but never your identity — may be published to the verified feed once approved.'**
  String get askAiConsentNotice;

  /// No description provided for @askAiConsentAgree.
  ///
  /// In en, this message translates to:
  /// **'I understand and agree.'**
  String get askAiConsentAgree;

  /// No description provided for @askAiSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get askAiSubmit;

  /// No description provided for @askAiSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get askAiSubmitting;

  /// No description provided for @askAiSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get askAiSubmittedTitle;

  /// No description provided for @askAiSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Track it in My Reports.'**
  String get askAiSubmittedBody;

  /// No description provided for @askAiOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get askAiOpen;

  /// No description provided for @askAiDraftSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit draft'**
  String get askAiDraftSheetTitle;

  /// No description provided for @askAiDraftFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get askAiDraftFieldTitle;

  /// No description provided for @askAiDraftFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get askAiDraftFieldDescription;

  /// No description provided for @askAiDraftFieldScamType.
  ///
  /// In en, this message translates to:
  /// **'Scam type'**
  String get askAiDraftFieldScamType;

  /// No description provided for @askAiDraftFieldIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Target identifier (phone / URL)'**
  String get askAiDraftFieldIdentifier;

  /// No description provided for @askAiDraftFieldKind.
  ///
  /// In en, this message translates to:
  /// **'Identifier kind'**
  String get askAiDraftFieldKind;

  /// No description provided for @askAiSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get askAiSave;

  /// No description provided for @askAiKindNone.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get askAiKindNone;

  /// No description provided for @askAiKindPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get askAiKindPhone;

  /// No description provided for @askAiKindUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get askAiKindUrl;

  /// No description provided for @askAiKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get askAiKindOther;

  /// No description provided for @askAiAskRedraftPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please redraft the report based on what we discussed.'**
  String get askAiAskRedraftPrompt;

  /// No description provided for @askAiSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use Ask AI'**
  String get askAiSignInTitle;

  /// No description provided for @askAiSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Ask AI helps you identify scams and get guidance on what to do next.'**
  String get askAiSignInBody;

  /// No description provided for @askAiSignInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in or register'**
  String get askAiSignInCta;

  /// No description provided for @askAiComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Ask AI — coming soon'**
  String get askAiComingSoon;

  /// No description provided for @askAiEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get askAiEvidenceTitle;

  /// No description provided for @askAiEvidenceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add evidence'**
  String get askAiEvidenceAdd;

  /// No description provided for @askAiEvidenceCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/5'**
  String askAiEvidenceCount(int count);

  /// No description provided for @askAiEvidenceCapReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 files.'**
  String get askAiEvidenceCapReached;

  /// No description provided for @askAiRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get askAiRetry;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchInputHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, scam type, or description…'**
  String get searchInputHint;

  /// No description provided for @searchEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type something to search verified reports.'**
  String get searchEmptyPrompt;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No reports matched your search.'**
  String get searchNoResults;

  /// No description provided for @searchFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get searchFilterTitle;

  /// No description provided for @searchFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get searchFilterReset;

  /// No description provided for @searchFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get searchFilterApply;

  /// No description provided for @searchFilterSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get searchFilterSortLabel;

  /// No description provided for @searchFilterSortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest verified'**
  String get searchFilterSortLatest;

  /// No description provided for @searchFilterSortReporters.
  ///
  /// In en, this message translates to:
  /// **'Most reported'**
  String get searchFilterSortReporters;

  /// No description provided for @searchFilterScamTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scam type'**
  String get searchFilterScamTypeLabel;

  /// No description provided for @manageAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Manage Announcements'**
  String get manageAnnouncements;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Your account will be permanently deleted after 7 days. All your reports and data will be lost.\n\nYou will be signed out immediately.'**
  String get deleteAccountDialogContent;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not request deletion. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @deletionRequests.
  ///
  /// In en, this message translates to:
  /// **'Deletion Requests'**
  String get deletionRequests;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
