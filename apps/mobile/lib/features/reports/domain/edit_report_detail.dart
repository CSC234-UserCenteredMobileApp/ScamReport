import 'dart:typed_data';

class ExistingEvidenceFile {
  const ExistingEvidenceFile({
    required this.id,
    required this.storagePath,
    this.signedUrl,
    required this.kind,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String id;
  final String storagePath;
  final String? signedUrl;
  final String kind; // 'image' | 'pdf'
  final String mimeType;
  final int sizeBytes;
}

class EditReportDetail {
  const EditReportDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.scamTypeCode,
    required this.scamTypeLabelEn,
    required this.scamTypeLabelTh,
    required this.status,
    this.targetIdentifier,
    this.targetIdentifierKind,
    required this.evidenceFiles,
  });

  final String id;
  final String title;
  final String description;
  final String scamTypeCode;
  final String scamTypeLabelEn;
  final String scamTypeLabelTh;
  final String status;
  final String? targetIdentifier;
  final String? targetIdentifierKind;
  final List<ExistingEvidenceFile> evidenceFiles;

  factory EditReportDetail.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['evidenceFiles'] as List<dynamic>;
    return EditReportDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      scamTypeCode: json['scamTypeCode'] as String,
      scamTypeLabelEn: json['scamTypeLabelEn'] as String,
      scamTypeLabelTh: json['scamTypeLabelTh'] as String,
      status: json['status'] as String,
      targetIdentifier: json['targetIdentifier'] as String?,
      targetIdentifierKind: json['targetIdentifierKind'] as String?,
      evidenceFiles: rawFiles.map((f) {
        final file = f as Map<String, dynamic>;
        return ExistingEvidenceFile(
          id: file['id'] as String,
          storagePath: file['storagePath'] as String,
          signedUrl: file['signedUrl'] as String?,
          kind: file['kind'] as String,
          mimeType: file['mimeType'] as String,
          sizeBytes: (file['sizeBytes'] as num).toInt(),
        );
      }).toList(),
    );
  }
}

/// Unified evidence item for the edit form.
/// Either an existing file (loaded from API) or a newly picked file.
sealed class EditStagedFile {
  const EditStagedFile();
}

class ExistingFile extends EditStagedFile {
  const ExistingFile({
    required this.id,
    required this.storagePath,
    this.signedUrl,
    required this.kind,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String id;
  final String storagePath;
  final String? signedUrl;
  final String kind;
  final String mimeType;
  final int sizeBytes;

  static ExistingFile fromEvidence(ExistingEvidenceFile f) => ExistingFile(
        id: f.id,
        storagePath: f.storagePath,
        signedUrl: f.signedUrl,
        kind: f.kind,
        mimeType: f.mimeType,
        sizeBytes: f.sizeBytes,
      );
}

class NewFile extends EditStagedFile {
  const NewFile({
    required this.bytes,
    required this.mimeType,
    required this.filename,
  });

  final Uint8List bytes;
  final String mimeType;
  final String filename;
}
