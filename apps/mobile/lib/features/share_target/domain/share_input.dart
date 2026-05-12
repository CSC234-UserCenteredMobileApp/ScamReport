class ShareInput {
  const ShareInput({required this.text, required this.kind});

  final String text;
  final String kind; // 'phone' | 'url' | 'text'

  static String detectKind(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'text';
    if (RegExp(r'^\+?[\d\s\-\(\)]{7,}$').hasMatch(t)) return 'phone';
    if (RegExp(r'https?://|www\.').hasMatch(t)) return 'url';
    return 'text';
  }
}
