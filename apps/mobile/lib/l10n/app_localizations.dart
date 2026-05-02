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
