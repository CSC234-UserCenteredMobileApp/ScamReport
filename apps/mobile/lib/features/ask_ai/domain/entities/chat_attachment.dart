// Pure Dart — no Flutter imports.
class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.mimeType,
    required this.sizeBytes,
    this.signedUrl,
  });

  final String id;
  final String mimeType;
  final int sizeBytes;
  final String? signedUrl;
}
