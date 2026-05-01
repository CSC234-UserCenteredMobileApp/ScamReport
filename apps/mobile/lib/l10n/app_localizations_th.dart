// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get searchHint => 'วางหมายเลข ลิงก์ หรือข้อความ…';

  @override
  String get aiSearch => 'ถามกับ AI';

  @override
  String get sectionThisWeek => 'สัปดาห์นี้';

  @override
  String get sectionRecentAlerts => 'การแจ้งเตือนการฉ้อโกงล่าสุด';

  @override
  String get sectionRecentlyVerified => 'ตรวจสอบล่าสุด';

  @override
  String get seeAll => 'ดูทั้งหมด';

  @override
  String get loadFailedRetry => 'โหลดล้มเหลว — แตะเพื่อลองอีกครั้ง';

  @override
  String get greetingGuest => 'สวัสดี 👋';

  @override
  String greetingWithName(String name) {
    return 'สวัสดี, $name 👋';
  }

  @override
  String get tagline => 'ก้าวนำหน้าการฉ้อโกงหนึ่งก้าว';

  @override
  String get clipboardBannerTitle => 'เราพบบางอย่างในคลิปบอร์ดของคุณ';

  @override
  String get checkIt => 'ตรวจสอบ';

  @override
  String get reportAScam => 'รายงานการหลอกลวง';

  @override
  String get statVerifiedReports => 'รายงาน\nที่ยืนยันแล้ว';

  @override
  String get statNewThisWeek => 'ใหม่\nสัปดาห์นี้';

  @override
  String get statTopScamType => 'ประเภทหลอกลวง\nอันดับต้น';

  @override
  String get categoryFraudAlert => 'การแจ้งเตือนฉ้อโกง';

  @override
  String get categoryTips => 'เคล็ดลับ';

  @override
  String get categoryPlatformUpdate => 'อัปเดตแพลตฟอร์ม';

  @override
  String reportCountLabel(int count) {
    return '$count รายงาน';
  }

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsSectionNotifications => 'การแจ้งเตือน';

  @override
  String get settingsSectionPreferences => 'การตั้งค่าส่วนตัว';

  @override
  String get settingsSectionAccount => 'บัญชี';

  @override
  String get myReports => 'รายงานของฉัน';

  @override
  String get privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get termsOfService => 'ข้อกำหนดการให้บริการ';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get signOutDialogContent => 'ออกจากระบบ ScamReport?';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get languageLabel => 'ภาษา';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageThai => 'ภาษาไทย';

  @override
  String get themeLabel => 'ธีม';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get notifPhoneScam => 'การแจ้งเตือนการหลอกลวงทางโทรศัพท์';

  @override
  String get notifPhoneScamDesc =>
      'รับการแจ้งเตือนเกี่ยวกับการหลอกลวงทางโทรศัพท์ใหม่';

  @override
  String get notifSmsPhishing => 'การแจ้งเตือนฟิชชิง SMS';

  @override
  String get notifSmsPhishingDesc => 'รูปแบบการหลอกลวง SMS ที่กำลังเป็นที่นิยม';

  @override
  String get notifRegional => 'การแจ้งเตือนตามภูมิภาค';

  @override
  String get notifRegionalDesc => 'การหลอกลวงที่รายงานในจังหวัดของคุณ';

  @override
  String get navHome => 'หน้าแรก';

  @override
  String get navFeed => 'ฟีด';

  @override
  String get navReport => 'รายงาน';

  @override
  String get navModerate => 'กลั่นกรอง';

  @override
  String get navAlerts => 'แจ้งเตือน';

  @override
  String get navMe => 'ฉัน';
}
