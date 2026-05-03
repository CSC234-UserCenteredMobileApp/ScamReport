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
  String adminReviewSubmittedBy(String handle, String date) {
    return 'Submitted by $handle • $date';
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
  String get adminAuditSubmitted => 'Submitted';

  @override
  String adminAiScore(int score, String level) {
    return 'AI confidence: $score% ($level)';
  }
}
