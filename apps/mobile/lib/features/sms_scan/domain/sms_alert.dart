class SmsAlert {
  const SmsAlert({
    required this.id,
    required this.senderMasked,
    required this.bodyExcerpt,
    required this.verdict,
    required this.detectedAt,
    required this.isRead,
  });

  final int id;
  final String senderMasked;
  final String bodyExcerpt;
  final String verdict; // 'scam' | 'suspicious'
  final DateTime detectedAt;
  final bool isRead;
}
