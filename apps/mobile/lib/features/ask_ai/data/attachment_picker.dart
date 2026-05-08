import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../domain/failures.dart';

const allowedAttachmentMime = <String>{
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'application/pdf',
};

const maxAttachmentBytes = 10 * 1024 * 1024;
const maxAttachmentsPerMessage = 3;

class StagedAttachment {
  StagedAttachment({
    required this.bytes,
    required this.mimeType,
    required this.filename,
  });
  final Uint8List bytes;
  final String mimeType;
  final String filename;
  int get sizeBytes => bytes.lengthInBytes;
}

/// Wraps image_picker for the chat composer. v1 supports image attachments
/// only; PDF support arrives once we add a file_picker dep (out of scope
/// for PR-5b).
class AttachmentPicker {
  AttachmentPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<StagedAttachment?> pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return _stageOrThrow(file);
  }

  Future<StagedAttachment?> pickFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    return _stageOrThrow(file);
  }

  Future<StagedAttachment> _stageOrThrow(XFile file) async {
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? _inferMime(file.path);
    if (!allowedAttachmentMime.contains(mime)) {
      throw const AskAiValidationFailure(
        'Unsupported file type. Use JPEG, PNG, WebP, GIF, or PDF.',
      );
    }
    if (bytes.lengthInBytes > maxAttachmentBytes) {
      throw const AskAiValidationFailure('File is too large (max 10 MB).');
    }
    return StagedAttachment(
      bytes: bytes,
      mimeType: mime,
      filename: file.name,
    );
  }

  String _inferMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
