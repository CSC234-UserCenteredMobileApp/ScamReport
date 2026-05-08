// Pure Dart — no Flutter imports. dart:typed_data is allowed in domain.
import 'dart:typed_data';

class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.mimeType,
    required this.sizeBytes,
    this.signedUrl,
    this.localBytes,
  });

  final String id;
  final String mimeType;
  final int sizeBytes;
  final String? signedUrl;
  // Set on optimistic user messages so the bubble can render the image
  // before the server-returned signed URL is available. Cleared once the
  // server response replaces the optimistic message.
  final Uint8List? localBytes;
}
