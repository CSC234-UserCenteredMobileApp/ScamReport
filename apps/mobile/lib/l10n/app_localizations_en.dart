// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchHint => 'Paste a number, link, or message…';

  @override
  String get aiSearch => 'Ask AI';

  @override
  String get sectionThisWeek => 'This Week';

  @override
  String get sectionRecentAlerts => 'Recent Fraud Alerts';

  @override
  String get sectionRecentlyVerified => 'Recently Verified';

  @override
  String get seeAll => 'See all';

  @override
  String get loadFailedRetry => 'Failed to load — tap to retry';

  @override
  String get greetingGuest => 'Hi 👋';

  @override
  String greetingWithName(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get tagline => 'Stay one step ahead of scams';

  @override
  String get clipboardBannerTitle => 'We noticed something on your clipboard';

  @override
  String get checkIt => 'Check it';

  @override
  String get reportAScam => 'Report a scam';

  @override
  String get statVerifiedReports => 'VERIFIED\nREPORTS';

  @override
  String get statNewThisWeek => 'NEW THIS\nWEEK';

  @override
  String get statTopScamType => 'TOP SCAM\nTYPE';

  @override
  String get categoryFraudAlert => 'Fraud Alert';

  @override
  String get categoryTips => 'Tips';

  @override
  String get categoryPlatformUpdate => 'Platform Update';

  @override
  String get categorySmsAlert => 'SMS Scan';

  @override
  String reportCountLabel(int count) {
    return '$count reports';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionNotifications => 'NOTIFICATIONS';

  @override
  String get settingsSectionPreferences => 'PREFERENCES';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get myReports => 'My reports';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutDialogContent => 'Sign out of ScamReport?';

  @override
  String get cancel => 'Cancel';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageThai => 'ภาษาไทย';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get notifPhoneScam => 'Phone scam alerts';

  @override
  String get notifPhoneScamDesc => 'Get notified about new phone scams';

  @override
  String get notifSmsPhishing => 'SMS phishing alerts';

  @override
  String get notifSmsPhishingDesc => 'Trending SMS scam patterns';

  @override
  String get notifRegional => 'Regional alerts';

  @override
  String get notifRegionalDesc => 'Scams reported in your province';

  @override
  String get alertsTitle => 'Announcements';

  @override
  String get filterAll => 'All';

  @override
  String get alertsEmpty => 'No announcements yet.';

  @override
  String get retry => 'Retry';

  @override
  String get shareLink => 'Share';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get postedByTeam => 'Posted by ScamReport Team';

  @override
  String get navHome => 'Home';

  @override
  String get navFeed => 'Feed';

  @override
  String get navReport => 'Report';

  @override
  String get navModerate => 'Moderate';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navMe => 'Me';

  @override
  String get feedTitle => 'Verified feed';

  @override
  String get feedFilterAll => 'All';

  @override
  String get feedNoReports => 'No reports yet — be the first to submit one.';

  @override
  String get feedStatTotal => 'TOTAL';

  @override
  String get feedStatThisWeek => 'THIS WEEK';

  @override
  String get feedStatTopType => 'TOP TYPE';

  @override
  String get modQueueTitle => 'Moderation queue';

  @override
  String get modQueueEmpty => 'Queue is empty — nice work!';

  @override
  String get modStatPending => 'PENDING';

  @override
  String get modStatFlagged => 'FLAGGED';

  @override
  String get modStatAvgAge => 'AVG AGE';

  @override
  String modStatAvgAgeHours(int hours) {
    return '${hours}h';
  }

  @override
  String get modSortOldestFirst => 'Oldest first';

  @override
  String get modSortNewestFirst => 'Newest first';

  @override
  String get modFilterPriorityFlag => 'Priority flag';

  @override
  String modEvidenceCount(int count) {
    return '$count evidence';
  }

  @override
  String get modReview => 'Review';

  @override
  String modTeamNote(String note) {
    return 'Team note: $note';
  }

  @override
  String modAgeHours(int hours) {
    return '${hours}h';
  }

  @override
  String modAgeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get adminReviewTitle => 'Review report';

  @override
  String get adminReviewApprove => 'Approve';

  @override
  String get adminReviewReject => 'Reject';

  @override
  String get adminReviewFlag => 'Flag';

  @override
  String get adminReviewUnflag => 'Unflag';

  @override
  String get adminReviewRemark => 'Remark';

  @override
  String get adminReviewRemarkHint =>
      'Required — will be visible in the audit trail';

  @override
  String adminReviewConfirm(String action) {
    return 'Confirm $action';
  }

  @override
  String get adminReviewApproved => 'Approved.';

  @override
  String get adminReviewRejected => 'Rejected.';

  @override
  String get adminReviewFlagged => 'Flagged for discussion.';

  @override
  String get adminReviewUnflagged => 'Flag removed.';

  @override
  String adminReviewSubmittedOn(String date) {
    return 'Submitted $date';
  }

  @override
  String get adminLabelDescription => 'DESCRIPTION';

  @override
  String get adminLabelTarget => 'TARGET IDENTIFIER';

  @override
  String get adminLabelEvidence => 'EVIDENCE';

  @override
  String get adminLabelAuditTrail => 'AUDIT TRAIL';

  @override
  String adminAiScore(int score, String level) {
    return 'AI confidence: $score% ($level)';
  }

  @override
  String get noEvidence => 'No evidence files.';

  @override
  String get auditTrailEmpty => 'No actions yet.';

  @override
  String get smsSmishingDetectionLabel => 'SMS smishing detection';

  @override
  String get smsSmishingDetectionDesc => 'Scan incoming messages for scams';

  @override
  String get smsConsentTitle => 'Enable SMS scanning?';

  @override
  String get smsConsentBody =>
      'ScamReport will read incoming SMS and send the content to our servers to check for scams. No messages are stored on our servers. You can disable this at any time.';

  @override
  String get smsConsentAgree => 'Agree & Continue';

  @override
  String get smsPermissionDenied =>
      'SMS permission is required to scan messages';

  @override
  String get smsScanTitle => 'Suspicious SMS detected';

  @override
  String get smsScanScamTitle => 'Scam SMS detected';

  @override
  String get view => 'View';

  @override
  String get verdictScam => 'Scam';

  @override
  String get verdictSuspicious => 'Suspicious';

  @override
  String get checkInputTitle => 'Check something';

  @override
  String get checkInputHint => 'Paste or type a phone number, link, or message';

  @override
  String get checkInputPrivacyNote =>
      'We never store what you check unless you choose to report it.';

  @override
  String get checkInputRunCheck => 'Run check';

  @override
  String get checkInputSampleNumber => 'Try a number';

  @override
  String get checkInputSampleLink => 'Try a link';

  @override
  String get verdictChecking => 'Checking…';

  @override
  String get verdictCheckingSubtitle => 'Cross-checking verified reports…';

  @override
  String get verdictSafe => 'Safe';

  @override
  String get verdictUnknown => 'Unknown';

  @override
  String get verdictSubtitleScam =>
      'Multiple verified reports match this item.';

  @override
  String get verdictSubtitleSuspicious =>
      'Partial match — proceed with caution.';

  @override
  String get verdictSubtitleSafe => 'No verified scam reports for this item.';

  @override
  String get verdictSubtitleUnknown => 'We could not classify this item.';

  @override
  String get verdictYouChecked => 'YOU CHECKED';

  @override
  String verdictMatchedReports(int count) {
    return '$count verified reports matched';
  }

  @override
  String get verdictSeeReports => 'See matched reports';

  @override
  String get verdictReportThis => 'Report this';

  @override
  String get verdictCachedResult => 'Cached result';

  @override
  String get reportDetailVerified => 'Verified';

  @override
  String reportDetailVerifiedOn(String date) {
    return 'Verified $date';
  }

  @override
  String get reportDetailIdentifierLabel => 'REPORTED IDENTIFIER';

  @override
  String get reportDetailWhatHappened => 'WHAT HAPPENED';

  @override
  String get reportDetailEvidence => 'EVIDENCE';

  @override
  String get reportDetailCta => 'Report a similar scam';

  @override
  String get reportDetailPrivacyFooter =>
      'The reporter\'s identity is never shown publicly. Only the scam content above is shared.';

  @override
  String get callScreeningTitle => 'Call Screening';

  @override
  String get callScreeningSubtitle =>
      'Warn you about incoming calls from known scam numbers';

  @override
  String get callScreeningSettingsSubtitle =>
      'Warn about known scam callers automatically';

  @override
  String get callScreeningUnsupported =>
      'Call screening requires Android 10 or later.';

  @override
  String get callScreeningNoBlocked => 'No screened calls yet.';

  @override
  String callScreeningBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calls screened',
      one: '$count call screened',
    );
    return '$_temp0';
  }

  @override
  String get callScreeningSetupTitle => 'Setup required';

  @override
  String get callScreeningSetupBody =>
      'ScamReport must be set as call screening app in your Phone app settings.';

  @override
  String get callScreeningSetupAction => 'Set as call screening app';

  @override
  String get callScreeningSyncFailed =>
      'Could not update phone list — cached data will be used';

  @override
  String get askAiTitle => 'Ask ScamReport';

  @override
  String get askAiBeta => 'BETA';

  @override
  String get askAiViewDraft => 'View draft';

  @override
  String get askAiNewChat => 'New chat';

  @override
  String get askAiPastChats => 'Past chats';

  @override
  String get askAiRefresh => 'Refresh';

  @override
  String get askAiNoConversations =>
      'No past chats yet. Send a message to start one.';

  @override
  String get askAiLoadFailed => 'Could not load conversations.';

  @override
  String get askAiNoPreview => '(no preview)';

  @override
  String get askAiDeletePrompt => 'Delete conversation?';

  @override
  String get askAiDeleteIrreversible => 'This cannot be undone.';

  @override
  String get askAiDelete => 'Delete';

  @override
  String get askAiCancel => 'Cancel';

  @override
  String get askAiDeleteFailed => 'Failed to delete conversation.';

  @override
  String get askAiWelcomeTitle => 'Hi, I\'m your scam radar.';

  @override
  String get askAiWelcomeBody =>
      'Tell me what happened — a weird SMS, a suspicious call, a too-good offer — and I\'ll tell you if others have seen it.';

  @override
  String get askAiDisclaimer => 'AI can make mistakes · check important info';

  @override
  String get askAiThinking => 'Thinking…';

  @override
  String get askAiSendFailed =>
      'Couldn\'t send your message. Please try again.';

  @override
  String get askAiComposerHint => 'Tell me what happened…';

  @override
  String get askAiAttach => 'Attach a file';

  @override
  String get askAiAttachCamera => 'Take photo';

  @override
  String get askAiAttachGallery => 'Choose from gallery';

  @override
  String get askAiAttachUnsupported =>
      'Unsupported file type. Use JPEG, PNG, WebP, GIF, or PDF.';

  @override
  String get askAiAttachTooLarge => 'File is too large (max 10 MB).';

  @override
  String get askAiConsentTitle => 'Submit this report?';

  @override
  String get askAiConsentEdit => 'Edit draft';

  @override
  String get askAiConsentRedraft => 'Ask AI to redraft';

  @override
  String get askAiConsentNotice =>
      'By submitting, you agree that this report — but never your identity — may be published to the verified feed once approved.';

  @override
  String get askAiConsentAgree => 'I understand and agree.';

  @override
  String get askAiSubmit => 'Submit report';

  @override
  String get askAiSubmitting => 'Submitting…';

  @override
  String get askAiSubmittedTitle => 'Report submitted';

  @override
  String get askAiSubmittedBody => 'Track it in My Reports.';

  @override
  String get askAiOpen => 'Open';

  @override
  String get askAiDraftSheetTitle => 'Edit draft';

  @override
  String get askAiDraftFieldTitle => 'Title';

  @override
  String get askAiDraftFieldDescription => 'Description';

  @override
  String get askAiDraftFieldScamType => 'Scam type';

  @override
  String get askAiDraftFieldIdentifier => 'Target identifier (phone / URL)';

  @override
  String get askAiDraftFieldKind => 'Identifier kind';

  @override
  String get askAiSave => 'Save';

  @override
  String get askAiKindNone => '—';

  @override
  String get askAiKindPhone => 'Phone';

  @override
  String get askAiKindUrl => 'URL';

  @override
  String get askAiKindOther => 'Other';

  @override
  String get askAiAskRedraftPrompt =>
      'Please redraft the report based on what we discussed.';

  @override
  String get askAiSignInTitle => 'Sign in to use Ask AI';

  @override
  String get askAiSignInBody =>
      'Ask AI helps you identify scams and get guidance on what to do next.';

  @override
  String get askAiSignInCta => 'Sign in or register';

  @override
  String get askAiComingSoon => 'Ask AI — coming soon';

  @override
  String get askAiEvidenceTitle => 'Evidence';

  @override
  String get askAiEvidenceAdd => 'Add evidence';

  @override
  String askAiEvidenceCount(int count) {
    return '$count/5';
  }

  @override
  String get askAiEvidenceCapReached => 'Maximum 5 files.';

  @override
  String get askAiRetry => 'Retry';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchInputHint => 'Search by title, scam type, or description…';

  @override
  String get searchEmptyPrompt => 'Type something to search verified reports.';

  @override
  String get searchNoResults => 'No reports matched your search.';

  @override
  String get searchFilterTitle => 'Filter & Sort';

  @override
  String get searchFilterReset => 'Reset';

  @override
  String get searchFilterApply => 'Apply';

  @override
  String get searchFilterSortLabel => 'Sort by';

  @override
  String get searchFilterSortLatest => 'Latest verified';

  @override
  String get searchFilterSortReporters => 'Most reported';

  @override
  String get searchFilterScamTypeLabel => 'Scam type';
}
