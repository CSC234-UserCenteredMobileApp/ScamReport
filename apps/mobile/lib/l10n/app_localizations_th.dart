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
  String get settingsSectionAppearance => 'การแสดงผล';

  @override
  String get settingsSectionProtection => 'การแจ้งเตือนและการป้องกัน';

  @override
  String get settingsSectionAdminTools => 'เครื่องมือผู้ดูแล';

  @override
  String get settingsDangerZone => 'โซนอันตราย';

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
  String modAgeHours(int hours) {
    return '$hours ชม.';
  }

  @override
  String modAgeMinutes(int minutes) {
    return '$minutes นาที';
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
  String get modErrorUnauthorized => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';

  @override
  String get modErrorForbidden =>
      'บัญชีนี้ไม่มีสิทธิ์ผู้ดูแลระบบ กรุณาแจ้งหัวหน้าทีมเพื่อยกระดับสิทธิ์';

  @override
  String get modErrorNotFound => 'รายงานนี้ถูกลบหรือดำเนินการไปแล้ว';

  @override
  String get modErrorInvalidRemark => 'ต้องระบุเหตุผล';

  @override
  String modErrorGeneric(int code, String message) {
    return 'ข้อผิดพลาดเซิร์ฟเวอร์ ($code): $message';
  }

  @override
  String get aiScorePending => 'กำลังประมวลผลคะแนน AI';

  @override
  String adminReviewSubmittedOn(String date) {
    return 'ส่งเมื่อ $date';
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
  String adminAiScore(int score, String level) {
    return 'ความเชื่อมั่น AI: $score% ($level)';
  }

  @override
  String get aiScoreBadgeLabel => 'AI';

  @override
  String get aiScoreRiskLabel => 'ความเสี่ยง';

  @override
  String get aiScoreVerdictLabel => 'ผลตรวจ AI';

  @override
  String get aiVerdictHigh => 'น่าจะเป็นสแกม';

  @override
  String get aiVerdictMedium => 'ต้องตรวจสอบ';

  @override
  String get aiVerdictLow => 'น่าจะปฏิเสธ';

  @override
  String get aiVerdictUnknown => 'สรุปไม่ได้';

  @override
  String aiScoreA11yLabel(String confidence, int score) {
    return 'ความเชื่อมั่น AI $confidence คะแนน $score จาก 100';
  }

  @override
  String get noEvidence => 'ไม่มีไฟล์หลักฐาน';

  @override
  String get auditTrailEmpty => 'ยังไม่มีการดำเนินการ';

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

  @override
  String get checkInputTitle => 'ตรวจสอบบางอย่าง';

  @override
  String get checkInputHint => 'วางหรือพิมพ์หมายเลขโทรศัพท์ ลิงก์ หรือข้อความ';

  @override
  String get checkInputPrivacyNote =>
      'เราไม่เก็บข้อมูลที่คุณตรวจสอบ เว้นแต่คุณเลือกรายงาน';

  @override
  String get checkInputRunCheck => 'เริ่มตรวจสอบ';

  @override
  String get checkInputSampleNumber => 'ลองด้วยหมายเลข';

  @override
  String get checkInputSampleLink => 'ลองด้วยลิงก์';

  @override
  String get verdictChecking => 'กำลังตรวจสอบ…';

  @override
  String get verdictCheckingSubtitle => 'กำลังตรวจสอบรายงานที่ยืนยันแล้ว…';

  @override
  String get verdictSafe => 'ปลอดภัย';

  @override
  String get verdictUnknown => 'ไม่ทราบ';

  @override
  String get verdictSubtitleScam =>
      'มีรายงานที่ยืนยันแล้วหลายรายการตรงกับรายการนี้';

  @override
  String get verdictSubtitleSuspicious => 'ตรงกันบางส่วน — โปรดระมัดระวัง';

  @override
  String get verdictSubtitleSafe =>
      'ไม่มีรายงานการหลอกลวงที่ยืนยันแล้วสำหรับรายการนี้';

  @override
  String get verdictSubtitleUnknown => 'เราไม่สามารถจัดประเภทรายการนี้ได้';

  @override
  String get verdictYouChecked => 'คุณตรวจสอบ';

  @override
  String verdictMatchedReports(int count) {
    return 'พบรายงานที่ยืนยันแล้ว $count รายการ';
  }

  @override
  String get verdictSeeReports => 'ดูรายงานที่ตรงกัน';

  @override
  String get verdictReportThis => 'รายงานสิ่งนี้';

  @override
  String get verdictCachedResult => 'ผลลัพธ์ที่แคชไว้';

  @override
  String get reportDetailVerified => 'ตรวจสอบแล้ว';

  @override
  String reportDetailVerifiedOn(String date) {
    return 'ตรวจสอบเมื่อ $date';
  }

  @override
  String get reportDetailIdentifierLabel => 'ตัวระบุที่รายงาน';

  @override
  String get reportDetailWhatHappened => 'สิ่งที่เกิดขึ้น';

  @override
  String get reportDetailEvidence => 'หลักฐาน';

  @override
  String get reportDetailCta => 'รายงานการหลอกลวงที่คล้ายกัน';

  @override
  String get reportDetailPrivacyFooter =>
      'ตัวตนของผู้รายงานจะไม่ถูกเปิดเผยต่อสาธารณะ มีเพียงเนื้อหาการหลอกลวงข้างต้นที่จะถูกแชร์';

  @override
  String get callScreeningTitle => 'กรองสายเรียกเข้า';

  @override
  String get callScreeningSubtitle =>
      'แจ้งเตือนเมื่อมีสายจากหมายเลขมิจฉาชีพที่รู้จัก';

  @override
  String get callScreeningSettingsSubtitle =>
      'แจ้งเตือนสายมิจฉาชีพที่รู้จักโดยอัตโนมัติ';

  @override
  String get callScreeningUnsupported =>
      'การกรองสายเรียกเข้าต้องใช้ Android 10 ขึ้นไป';

  @override
  String get callScreeningNoBlocked => 'ยังไม่มีสายที่ถูกกรอง';

  @override
  String callScreeningBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'กรอง $count สาย',
      one: 'กรอง $count สาย',
    );
    return '$_temp0';
  }

  @override
  String get callScreeningSetupTitle => 'ต้องตั้งค่าก่อน';

  @override
  String get callScreeningSetupBody =>
      'ต้องตั้ง ScamReport เป็นแอปกรองสายในการตั้งค่าแอปโทรศัพท์ของคุณ';

  @override
  String get callScreeningSetupAction => 'ตั้งเป็นแอปกรองสาย';

  @override
  String get callScreeningSyncFailed =>
      'ไม่สามารถอัปเดตรายการโทรศัพท์ — จะใช้ข้อมูลที่แคชไว้';

  @override
  String get askAiTitle => 'ถาม ScamReport';

  @override
  String get askAiBeta => 'BETA';

  @override
  String get askAiViewDraft => 'ดูร่างรายงาน';

  @override
  String get askAiNewChat => 'แชทใหม่';

  @override
  String get askAiReportSeed =>
      'ฉันต้องการรายงานกิจกรรมที่น่าสงสัย ช่วยฉันได้ไหม';

  @override
  String get askAiSimilarReportsLabel => 'รายงานที่ตรวจสอบแล้วที่ตรงกัน';

  @override
  String get askAiPastChats => 'แชทที่ผ่านมา';

  @override
  String get askAiRefresh => 'รีเฟรช';

  @override
  String get askAiNoConversations =>
      'ยังไม่มีแชทเก่า ส่งข้อความเพื่อเริ่มแชทแรก';

  @override
  String get askAiLoadFailed => 'โหลดบทสนทนาไม่สำเร็จ';

  @override
  String get askAiNoPreview => '(ไม่มีตัวอย่าง)';

  @override
  String get askAiDeletePrompt => 'ลบบทสนทนานี้ใช่ไหม?';

  @override
  String get askAiDeleteIrreversible => 'การลบไม่สามารถย้อนกลับได้';

  @override
  String get askAiDelete => 'ลบ';

  @override
  String get askAiCancel => 'ยกเลิก';

  @override
  String get askAiDeleteFailed => 'ลบบทสนทนาไม่สำเร็จ';

  @override
  String get askAiWelcomeTitle => 'สวัสดี ฉันคือผู้ช่วยตรวจจับมิจฉาชีพของคุณ';

  @override
  String get askAiWelcomeBody =>
      'เล่าให้ฉันฟังว่าเกิดอะไรขึ้น — SMS แปลก ๆ การโทรน่าสงสัย ข้อเสนอที่ดีเกินจริง — แล้วฉันจะดูให้ว่าคนอื่นเคยเจอแบบนี้ไหม';

  @override
  String get askAiDisclaimer =>
      'AI อาจผิดพลาดได้ · ตรวจสอบข้อมูลสำคัญด้วยตนเอง';

  @override
  String get askAiThinking => 'กำลังคิด…';

  @override
  String get askAiSendFailed => 'ส่งข้อความไม่สำเร็จ กรุณาลองใหม่';

  @override
  String get askAiComposerHint => 'เล่าให้ฉันฟัง…';

  @override
  String get askAiAttach => 'แนบไฟล์';

  @override
  String get askAiAttachCamera => 'ถ่ายรูป';

  @override
  String get askAiAttachGallery => 'เลือกจากแกลเลอรี';

  @override
  String get askAiAttachUnsupported =>
      'ไฟล์ประเภทนี้ไม่รองรับ ใช้ JPEG, PNG, WebP, GIF หรือ PDF';

  @override
  String get askAiAttachTooLarge => 'ไฟล์ใหญ่เกินไป (สูงสุด 10 MB)';

  @override
  String get askAiConsentTitle => 'ส่งรายงานนี้ใช่ไหม?';

  @override
  String get askAiConsentEdit => 'แก้ไขร่าง';

  @override
  String get askAiConsentRedraft => 'ให้ AI ร่างใหม่';

  @override
  String get askAiConsentNotice =>
      'เมื่อส่ง คุณยินยอมให้รายงานนี้ — แต่ไม่รวมตัวตนของคุณ — เผยแพร่ในฟีดที่ตรวจสอบแล้วเมื่อได้รับการอนุมัติ';

  @override
  String get askAiConsentAgree => 'ฉันเข้าใจและยินยอม';

  @override
  String get askAiSubmit => 'ส่งรายงาน';

  @override
  String get askAiSubmitting => 'กำลังส่ง…';

  @override
  String get askAiSubmittedTitle => 'ส่งรายงานแล้ว';

  @override
  String get askAiSubmittedBody => 'ติดตามได้ที่หน้ารายงานของฉัน';

  @override
  String get askAiOpen => 'เปิด';

  @override
  String get askAiDraftSheetTitle => 'แก้ไขร่าง';

  @override
  String get askAiDraftFieldTitle => 'หัวข้อ';

  @override
  String get askAiDraftFieldDescription => 'รายละเอียด';

  @override
  String get askAiDraftFieldScamType => 'ประเภทการหลอกลวง';

  @override
  String get askAiDraftFieldIdentifier => 'ตัวระบุเป้าหมาย (เบอร์โทร / URL)';

  @override
  String get askAiDraftFieldKind => 'ประเภทตัวระบุ';

  @override
  String get askAiSave => 'บันทึก';

  @override
  String get askAiKindNone => '—';

  @override
  String get askAiKindPhone => 'เบอร์โทร';

  @override
  String get askAiKindUrl => 'URL';

  @override
  String get askAiKindOther => 'อื่น ๆ';

  @override
  String get askAiAskRedraftPrompt => 'ช่วยร่างรายงานใหม่จากที่เราคุยกัน';

  @override
  String get askAiSignInTitle => 'เข้าสู่ระบบเพื่อใช้ Ask AI';

  @override
  String get askAiSignInBody =>
      'Ask AI ช่วยให้คุณระบุการหลอกลวงและคำแนะนำในการดำเนินการต่อ';

  @override
  String get askAiSignInCta => 'เข้าสู่ระบบหรือสมัครสมาชิก';

  @override
  String get askAiComingSoon => 'Ask AI — เร็ว ๆ นี้';

  @override
  String get askAiEvidenceTitle => 'หลักฐาน';

  @override
  String get askAiEvidenceAdd => 'เพิ่มหลักฐาน';

  @override
  String askAiEvidenceCount(int count) {
    return '$count/5';
  }

  @override
  String get askAiEvidenceCapReached => 'แนบได้สูงสุด 5 ไฟล์';

  @override
  String get askAiRetry => 'ลองอีกครั้ง';

  @override
  String get searchTitle => 'ค้นหา';

  @override
  String get searchInputHint =>
      'ค้นหาด้วยชื่อเรื่อง ประเภทหลอกลวง หรือรายละเอียด…';

  @override
  String get searchEmptyPrompt => 'พิมพ์บางอย่างเพื่อค้นหารายงานที่ยืนยันแล้ว';

  @override
  String get searchNoResults => 'ไม่พบรายงานที่ตรงกับการค้นหาของคุณ';

  @override
  String get searchFilterTitle => 'กรอง & จัดเรียง';

  @override
  String get searchFilterReset => 'รีเซ็ต';

  @override
  String get searchFilterApply => 'นำไปใช้';

  @override
  String get searchFilterSortLabel => 'จัดเรียงตาม';

  @override
  String get searchFilterSortLatest => 'ยืนยันล่าสุด';

  @override
  String get searchFilterSortReporters => 'ผู้รายงานมากที่สุด';

  @override
  String get searchFilterScamTypeLabel => 'ประเภทหลอกลวง';

  @override
  String get myReportsTitle => 'รายงานของฉัน';

  @override
  String get myReportsEmpty => 'คุณยังไม่ได้ส่งรายงานใดๆ';

  @override
  String get myReportsEmptyAction => 'ส่งรายงาน';

  @override
  String get myReportsFilterAll => 'ทั้งหมด';

  @override
  String myReportsFilterPending(int n) {
    return 'รอดำเนินการ ($n)';
  }

  @override
  String myReportsFilterVerified(int n) {
    return 'ยืนยันแล้ว ($n)';
  }

  @override
  String myReportsFilterRejected(int n) {
    return 'ถูกปฏิเสธ ($n)';
  }

  @override
  String get myReportsStatusPending => 'รอดำเนินการ';

  @override
  String get myReportsStatusVerified => 'ยืนยันแล้ว';

  @override
  String get myReportsStatusRejected => 'ถูกปฏิเสธ';

  @override
  String get myReportsEdit => 'แก้ไข';

  @override
  String get myReportsWithdraw => 'ถอนรายงาน';

  @override
  String get myReportsWithdrawTitle => 'ถอนรายงาน?';

  @override
  String get myReportsWithdrawBody =>
      'รายงานนี้จะถูกลบออกจากคิวและไม่สามารถส่งใหม่ได้';

  @override
  String get myReportsWithdrawConfirm => 'ถอน';

  @override
  String myReportsModeratorNote(String note) {
    return 'หมายเหตุผู้ดูแล: $note';
  }

  @override
  String get myReportsUnderReview =>
      'อยู่ระหว่างการพิจารณาของทีม เราจะแจ้งให้คุณทราบเมื่อมีการตัดสินใจ';

  @override
  String get myReportsWithdrawFailed =>
      'ไม่สามารถถอนรายงานได้ กรุณาลองอีกครั้ง';

  @override
  String get submitReportTitle => 'รายงานการหลอกลวง';

  @override
  String get submitReportEditTitle => 'แก้ไขรายงาน';

  @override
  String get submitReportStep1of2 => 'ขั้นตอนที่ 1 จาก 2';

  @override
  String get submitReportStep2of2 => 'ขั้นตอนที่ 2 จาก 2';

  @override
  String get submitReportConfirmTitle => 'ยืนยันและส่ง';

  @override
  String get submitReportFieldTitle => 'หัวข้อ';

  @override
  String get submitReportFieldTitleHint => 'เช่น สายโทรปลอมธนาคารขอ OTP';

  @override
  String get submitReportFieldDescription => 'รายละเอียด';

  @override
  String get submitReportFieldDescriptionHint => 'อธิบายสิ่งที่เกิดขึ้น…';

  @override
  String submitReportCharCount(int count) {
    return '$count/500';
  }

  @override
  String get submitReportFieldScamType => 'ประเภทการหลอกลวง';

  @override
  String get submitReportFieldTarget => 'ตัวระบุเป้าหมาย';

  @override
  String get submitReportFieldTargetHint =>
      'ไม่บังคับ — หมายเลข ลิงก์ หรือบัญชีของมิจฉาชีพ';

  @override
  String get submitReportFieldEvidence => 'หลักฐาน (ไม่บังคับ)';

  @override
  String get submitReportEvidenceHint => 'เพิ่มได้สูงสุด 5 รูปภาพหรือ PDF';

  @override
  String get submitReportAddEvidence => 'เพิ่มไฟล์';

  @override
  String get submitReportEvidenceCapReached => 'สูงสุด 5 ไฟล์';

  @override
  String get submitReportContinue => 'ถัดไป';

  @override
  String get submitReportSubmit => 'ส่งรายงาน';

  @override
  String get submitReportUpdate => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get submitReportSubmitting => 'กำลังส่ง…';

  @override
  String get submitReportConsent =>
      'ด้วยการส่งรายงาน คุณยินยอมให้เผยแพร่เนื้อหารายงาน — แต่ไม่ใช่ตัวตนของคุณ — ในฟีดที่ยืนยันแล้วเมื่อได้รับการอนุมัติ';

  @override
  String get submitReportConsentCheck => 'ฉันเข้าใจและยินยอม';

  @override
  String get submitReportSuccess =>
      'ส่งรายงานแล้ว — เราจะแจ้งให้คุณทราบเมื่อตรวจสอบเสร็จ';

  @override
  String get submitReportUpdateSuccess => 'อัปเดตรายงานแล้ว';

  @override
  String get submitReportFailed => 'ไม่สามารถส่งรายงานได้ กรุณาลองอีกครั้ง';

  @override
  String get submitReportRequiredField => 'จำเป็นต้องกรอกข้อมูลนี้';

  @override
  String get submitReportTitleTooShort => 'หัวข้อต้องมีอย่างน้อย 3 ตัวอักษร';

  @override
  String get submitReportDescriptionTooShort =>
      'รายละเอียดต้องมีอย่างน้อย 10 ตัวอักษร';

  @override
  String get submitReportSelectScamType => 'กรุณาเลือกประเภทการหลอกลวง';

  @override
  String get scamTypePhoneImpersonation => 'แอบอ้างทางโทรศัพท์';

  @override
  String get scamTypePhishingSms => 'SMS ฟิชชิ่ง';

  @override
  String get scamTypeFakeQr => 'QR Code ปลอม';

  @override
  String get scamTypeEcommerce => 'ฉ้อโกงอีคอมเมิร์ซ';

  @override
  String get scamTypeInvestment => 'ฉ้อโกงการลงทุน';

  @override
  String get scamTypeRomance => 'หลอกรัก';

  @override
  String get manageAnnouncements => 'จัดการประกาศ';

  @override
  String get deleteAccount => 'ลบบัญชี';

  @override
  String get deleteAccountDialogTitle => 'ลบบัญชีใช่ไหม?';

  @override
  String get deleteAccountDialogContent =>
      'บัญชีของคุณจะถูกลบถาวรภายใน 7 วัน ข้อมูลและรายงานทั้งหมดจะสูญหาย\n\nคุณจะถูกออกจากระบบทันที';

  @override
  String get deleteAccountFailed => 'ไม่สามารถส่งคำขอลบบัญชีได้ กรุณาลองใหม่';

  @override
  String get deletionRequests => 'คำขอลบบัญชี';

  @override
  String get editReportTitle => 'แก้ไขรายงาน';

  @override
  String get editReportSectionDetails => 'รายละเอียด';

  @override
  String get editReportSectionTarget => 'เป้าหมาย';

  @override
  String get editReportSave => 'บันทึก';

  @override
  String get editReportSaving => 'กำลังบันทึก…';

  @override
  String editReportUploading(int current, int total) {
    return 'กำลังอัปโหลด $current/$total…';
  }

  @override
  String get editReportSaved => 'อัปเดตรายงานแล้ว';

  @override
  String get editReportSaveFailed =>
      'ไม่สามารถอัปเดตรายงานได้ กรุณาลองอีกครั้ง';

  @override
  String get editReportUploadFailed =>
      'ไม่สามารถอัปโหลดรูปภาพได้ กรุณาลองอีกครั้ง';

  @override
  String get editReportUploadSuccess => 'อัปโหลดรูปภาพแล้ว';

  @override
  String get editReportLoadFailed => 'ไม่สามารถโหลดรายงานได้';
}
