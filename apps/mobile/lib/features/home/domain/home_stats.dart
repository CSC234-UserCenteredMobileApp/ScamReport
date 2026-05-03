class HomeStats {
  const HomeStats({
    required this.verifiedTotal,
    required this.newThisWeek,
    required this.topScamTypeLabelEn,
    required this.topScamTypeLabelTh,
  });
  final int verifiedTotal;
  final int newThisWeek;
  final String topScamTypeLabelEn;
  final String topScamTypeLabelTh;
}
