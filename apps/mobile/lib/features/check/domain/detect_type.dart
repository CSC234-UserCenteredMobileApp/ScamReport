/// Classifies a raw user-supplied string into a check `type`
/// (`'phone' | 'url' | 'text'`). Pure Dart with no dependencies, so it lives in
/// the domain layer and can be used from presentation without reaching into
/// the data layer.
///
/// The server re-normalises the payload (E.164 for phones, lowercased host for
/// URLs) before matching — this only picks the coarse `type`.
String detectType(String raw) {
  final trimmed = raw.trim();
  if (RegExp(r'^\+?[\d\s\-\(\)]{7,}$').hasMatch(trimmed)) return 'phone';
  if (RegExp(r'https?://|www\.').hasMatch(trimmed)) return 'url';
  return 'text';
}
