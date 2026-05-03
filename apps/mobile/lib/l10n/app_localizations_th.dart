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
  String get categorySmsAlert => 'สแกน SMS';

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
  String get alertsTitle => 'ประกาศ';

  @override
  String get filterAll => 'ทั้งหมด';

  @override
  String get alertsEmpty => 'ยังไม่มีประกาศ';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get shareLink => 'แชร์';

  @override
  String get linkCopied => 'คัดลอกลิงก์แล้ว';

  @override
  String get postedByTeam => 'โพสต์โดย ScamReport Team';

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

  @override
  String get feedTitle => 'ฟีดที่ตรวจสอบแล้ว';

  @override
  String get feedFilterAll => 'ทั้งหมด';

  @override
  String get feedNoReports => 'ยังไม่มีรายงาน — เป็นคนแรกที่ส่ง';

  @override
  String get feedStatTotal => 'ยอดรวม';

  @override
  String get feedStatThisWeek => 'สัปดาห์นี้';

  @override
  String get feedStatTopType => 'ประเภทหลัก';

  @override
  String get modQueueTitle => 'คิวตรวจสอบ';

  @override
  String get modQueueEmpty => 'คิวว่างเปล่า — ดีมาก!';

  @override
  String get modStatPending => 'รอดำเนินการ';

  @override
  String get modStatFlagged => 'ถูกตั้งสถานะ';

  @override
  String get modStatAvgAge => 'อายุเฉลี่ย';

  @override
  String modStatAvgAgeHours(int hours) {
    return '$hours ชม.';
  }

  @override
  String get modSortOldestFirst => 'เก่าที่สุดก่อน';

  @override
  String get modSortNewestFirst => 'ใหม่ที่สุดก่อน';

  @override
  String get modFilterPriorityFlag => 'ธงลำดับความสำคัญ';

  @override
  String modEvidenceCount(int count) {
    return '$count หลักฐาน';
  }

  @override
  String get modReview => 'ตรวจสอบ';

  @override
  String modTeamNote(String note) {
    return 'บันทึกทีม: $note';
  }

  @override
  String get adminReviewTitle => 'ตรวจสอบรายงาน';

  @override
  String get adminReviewApprove => 'อนุมัติ';

  @override
  String get adminReviewReject => 'ปฏิเสธ';

  @override
  String get adminReviewFlag => 'ตั้งสถานะ';

  @override
  String get adminReviewUnflag => 'ยกเลิกสถานะ';

  @override
  String get adminReviewRemark => 'หมายเหตุ';

  @override
  String get adminReviewRemarkHint => 'จำเป็น — จะปรากฏในบันทึกการตรวจสอบ';

  @override
  String adminReviewConfirm(String action) {
    return 'ยืนยัน$action';
  }

  @override
  String get adminReviewApproved => 'อนุมัติแล้ว';

  @override
  String get adminReviewRejected => 'ปฏิเสธแล้ว';

  @override
  String get adminReviewFlagged => 'ตั้งสถานะเพื่อหารือแล้ว';

  @override
  String get adminReviewUnflagged => 'ยกเลิกสถานะแล้ว';

  @override
  String adminReviewSubmittedBy(String handle, String date) {
    return 'ส่งโดย $handle • $date';
  }

  @override
  String get adminLabelDescription => 'คำอธิบาย';

  @override
  String get adminLabelTarget => 'ตัวระบุเป้าหมาย';

  @override
  String get adminLabelEvidence => 'หลักฐาน';

  @override
  String get adminLabelAuditTrail => 'บันทึกการตรวจสอบ';

  @override
  String get adminAuditSubmitted => 'ส่งแล้ว';

  @override
  String adminAiScore(int score, String level) {
    return 'ความเชื่อมั่น AI: $score% ($level)';
  }

  @override
  String get smsSmishingDetectionLabel => 'ตรวจจับ SMS หลอกลวง';

  @override
  String get smsSmishingDetectionDesc =>
      'ตรวจสอบข้อความขาเข้าเพื่อหาการหลอกลวง';

  @override
  String get smsConsentTitle => 'เปิดใช้การสแกน SMS?';

  @override
  String get smsConsentBody =>
      'ScamReport จะอ่าน SMS ขาเข้าและส่งเนื้อหาไปยังเซิร์ฟเวอร์เพื่อตรวจสอบการหลอกลวง ข้อความของคุณจะไม่ถูกจัดเก็บบนเซิร์ฟเวอร์ คุณสามารถปิดใช้งานได้ทุกเมื่อ';

  @override
  String get smsConsentAgree => 'ยอมรับและดำเนินการต่อ';

  @override
  String get smsPermissionDenied => 'ต้องการสิทธิ์ SMS เพื่อสแกนข้อความ';

  @override
  String get smsScanTitle => 'พบ SMS น่าสงสัย';

  @override
  String get smsScanScamTitle => 'พบ SMS หลอกลวง';

  @override
  String get view => 'ดู';

  @override
  String get verdictScam => 'หลอกลวง';

  @override
  String get verdictSuspicious => 'น่าสงสัย';
}
