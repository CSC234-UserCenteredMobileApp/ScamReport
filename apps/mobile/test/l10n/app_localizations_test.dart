import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/l10n/app_localizations_en.dart';
import 'package:mobile/l10n/app_localizations_th.dart';

void main() {
  group('AppLocalizationsEn', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('searchHint returns English string', () {
      expect(l10n.searchHint, 'Paste a number, link, or message…');
    });

    test('aiSearch returns English string', () {
      expect(l10n.aiSearch, 'AI search');
    });

    test('section headers', () {
      expect(l10n.sectionThisWeek, 'This Week');
      expect(l10n.sectionRecentAlerts, 'Recent Fraud Alerts');
      expect(l10n.sectionRecentlyVerified, 'Recently Verified');
      expect(l10n.seeAll, 'See all');
    });

    test('loadFailedRetry', () {
      expect(l10n.loadFailedRetry, 'Failed to load — tap to retry');
    });

    test('greetings', () {
      expect(l10n.greetingGuest, 'Hi 👋');
      expect(l10n.greetingWithName('Alice'), 'Hi, Alice 👋');
    });

    test('tagline', () {
      expect(l10n.tagline, 'Stay one step ahead of scams');
    });

    test('clipboard', () {
      expect(l10n.clipboardBannerTitle,
          'We noticed something on your clipboard');
      expect(l10n.checkIt, 'Check it');
    });

    test('stat labels', () {
      expect(l10n.statVerifiedReports, 'VERIFIED\nREPORTS');
      expect(l10n.statNewThisWeek, 'NEW THIS\nWEEK');
      expect(l10n.statTopScamType, 'TOP SCAM\nTYPE');
    });

    test('categories', () {
      expect(l10n.categoryFraudAlert, 'Fraud Alert');
      expect(l10n.categoryTips, 'Tips');
      expect(l10n.categoryPlatformUpdate, 'Platform Update');
    });

    test('reportCountLabel', () {
      expect(l10n.reportCountLabel(5), '5 reports');
      expect(l10n.reportCountLabel(0), '0 reports');
    });

    test('settings strings', () {
      expect(l10n.settingsTitle, 'Settings');
      expect(l10n.settingsSectionNotifications, 'NOTIFICATIONS');
      expect(l10n.settingsSectionPreferences, 'PREFERENCES');
      expect(l10n.settingsSectionAccount, 'ACCOUNT');
    });

    test('account strings', () {
      expect(l10n.myReports, 'My reports');
      expect(l10n.privacyPolicy, 'Privacy policy');
      expect(l10n.termsOfService, 'Terms of service');
      expect(l10n.signOut, 'Sign out');
      expect(l10n.signOutDialogContent, 'Sign out of ScamReport?');
      expect(l10n.cancel, 'Cancel');
    });

    test('preference strings', () {
      expect(l10n.languageLabel, 'Language');
      expect(l10n.languageEnglish, 'English');
      expect(l10n.languageThai, 'ภาษาไทย');
      expect(l10n.themeLabel, 'Theme');
      expect(l10n.themeLight, 'Light');
      expect(l10n.themeDark, 'Dark');
    });

    test('notification strings', () {
      expect(l10n.notifPhoneScam, 'Phone scam alerts');
      expect(l10n.notifPhoneScamDesc, 'Get notified about new phone scams');
      expect(l10n.notifSmsPhishing, 'SMS phishing alerts');
      expect(l10n.notifSmsPhishingDesc, 'Trending SMS scam patterns');
      expect(l10n.notifRegional, 'Regional alerts');
      expect(l10n.notifRegionalDesc, 'Scams reported in your province');
    });

    test('navigation labels', () {
      expect(l10n.navHome, 'Home');
      expect(l10n.navFeed, 'Feed');
      expect(l10n.navReport, 'Report');
      expect(l10n.navModerate, 'Moderate');
      expect(l10n.navAlerts, 'Alerts');
      expect(l10n.navMe, 'Me');
    });
  });

  group('AppLocalizationsTh', () {
    late AppLocalizationsTh l10n;

    setUp(() {
      l10n = AppLocalizationsTh();
    });

    test('searchHint returns Thai string', () {
      expect(l10n.searchHint, 'วางหมายเลข ลิงก์ หรือข้อความ…');
    });

    test('aiSearch', () {
      expect(l10n.aiSearch, 'ค้นหาด้วย AI');
    });

    test('section headers', () {
      expect(l10n.sectionThisWeek, 'สัปดาห์นี้');
      expect(l10n.sectionRecentAlerts, 'การแจ้งเตือนการฉ้อโกงล่าสุด');
      expect(l10n.sectionRecentlyVerified, 'ตรวจสอบล่าสุด');
      expect(l10n.seeAll, 'ดูทั้งหมด');
    });

    test('loadFailedRetry', () {
      expect(l10n.loadFailedRetry, 'โหลดล้มเหลว — แตะเพื่อลองอีกครั้ง');
    });

    test('greetings', () {
      expect(l10n.greetingGuest, 'สวัสดี 👋');
      expect(l10n.greetingWithName('Alice'), 'สวัสดี, Alice 👋');
    });

    test('tagline', () {
      expect(l10n.tagline, 'ก้าวนำหน้าการฉ้อโกงหนึ่งก้าว');
    });

    test('clipboard', () {
      expect(l10n.clipboardBannerTitle, 'เราพบบางอย่างในคลิปบอร์ดของคุณ');
      expect(l10n.checkIt, 'ตรวจสอบ');
    });

    test('stat labels', () {
      expect(l10n.statVerifiedReports, 'รายงาน\nที่ยืนยันแล้ว');
      expect(l10n.statNewThisWeek, 'ใหม่\nสัปดาห์นี้');
      expect(l10n.statTopScamType, 'ประเภทหลอกลวง\nอันดับต้น');
    });

    test('categories', () {
      expect(l10n.categoryFraudAlert, 'การแจ้งเตือนฉ้อโกง');
      expect(l10n.categoryTips, 'เคล็ดลับ');
      expect(l10n.categoryPlatformUpdate, 'อัปเดตแพลตฟอร์ม');
    });

    test('reportCountLabel', () {
      expect(l10n.reportCountLabel(5), '5 รายงาน');
      expect(l10n.reportCountLabel(0), '0 รายงาน');
    });

    test('settings strings', () {
      expect(l10n.settingsTitle, 'การตั้งค่า');
      expect(l10n.settingsSectionNotifications, 'การแจ้งเตือน');
      expect(l10n.settingsSectionPreferences, 'การตั้งค่าส่วนตัว');
      expect(l10n.settingsSectionAccount, 'บัญชี');
    });

    test('account strings', () {
      expect(l10n.myReports, 'รายงานของฉัน');
      expect(l10n.privacyPolicy, 'นโยบายความเป็นส่วนตัว');
      expect(l10n.termsOfService, 'ข้อกำหนดการให้บริการ');
      expect(l10n.signOut, 'ออกจากระบบ');
      expect(l10n.signOutDialogContent, 'ออกจากระบบ ScamReport?');
      expect(l10n.cancel, 'ยกเลิก');
    });

    test('preference strings', () {
      expect(l10n.languageLabel, 'ภาษา');
      expect(l10n.languageEnglish, 'English');
      expect(l10n.languageThai, 'ภาษาไทย');
      expect(l10n.themeLabel, 'ธีม');
      expect(l10n.themeLight, 'สว่าง');
      expect(l10n.themeDark, 'มืด');
    });

    test('notification strings', () {
      expect(l10n.notifPhoneScam, 'การแจ้งเตือนการหลอกลวงทางโทรศัพท์');
      expect(l10n.notifPhoneScamDesc,
          'รับการแจ้งเตือนเกี่ยวกับการหลอกลวงทางโทรศัพท์ใหม่');
      expect(l10n.notifSmsPhishing, 'การแจ้งเตือนฟิชชิง SMS');
      expect(l10n.notifSmsPhishingDesc,
          'รูปแบบการหลอกลวง SMS ที่กำลังเป็นที่นิยม');
      expect(l10n.notifRegional, 'การแจ้งเตือนตามภูมิภาค');
      expect(l10n.notifRegionalDesc, 'การหลอกลวงที่รายงานในจังหวัดของคุณ');
    });

    test('navigation labels', () {
      expect(l10n.navHome, 'หน้าแรก');
      expect(l10n.navFeed, 'ฟีด');
      expect(l10n.navReport, 'รายงาน');
      expect(l10n.navModerate, 'กลั่นกรอง');
      expect(l10n.navAlerts, 'แจ้งเตือน');
      expect(l10n.navMe, 'ฉัน');
    });
  });

  group('lookupAppLocalizations', () {
    test('returns English for en locale', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(l10n, isA<AppLocalizationsEn>());
    });

    test('returns Thai for th locale', () {
      final l10n = lookupAppLocalizations(const Locale('th'));
      expect(l10n, isA<AppLocalizationsTh>());
    });

    test('throws for unsupported locale', () {
      expect(
        () => lookupAppLocalizations(const Locale('fr')),
        throwsFlutterError,
      );
    });
  });

  group('_AppLocalizationsDelegate', () {
    test('isSupported returns true for en and th', () {
      const delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('th')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);
    });

    test('load returns AppLocalizations for supported locale', () async {
      const delegate = AppLocalizations.delegate;
      final result = await delegate.load(const Locale('en'));
      expect(result, isA<AppLocalizationsEn>());
    });
  });
}
