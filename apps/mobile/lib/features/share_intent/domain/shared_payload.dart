/// Payload extracted from an Android share intent. Pure Dart — no Flutter
/// or plugin types — so it can flow through the domain layer cleanly.
class SharedPayload {
  const SharedPayload(this.text);

  final String text;
}
