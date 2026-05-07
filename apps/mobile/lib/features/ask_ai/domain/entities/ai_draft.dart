enum TargetIdentifierKind { phone, url, other }

class AiDraft {
  const AiDraft({
    required this.title,
    required this.description,
    required this.scamTypeCode,
    this.targetIdentifier,
    this.targetIdentifierKind,
  });

  final String title;
  final String description;
  final String scamTypeCode;
  final String? targetIdentifier;
  final TargetIdentifierKind? targetIdentifierKind;

  AiDraft copyWith({
    String? title,
    String? description,
    String? scamTypeCode,
    String? targetIdentifier,
    TargetIdentifierKind? targetIdentifierKind,
    bool clearTargetIdentifier = false,
  }) {
    return AiDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      scamTypeCode: scamTypeCode ?? this.scamTypeCode,
      targetIdentifier:
          clearTargetIdentifier ? null : (targetIdentifier ?? this.targetIdentifier),
      targetIdentifierKind: clearTargetIdentifier
          ? null
          : (targetIdentifierKind ?? this.targetIdentifierKind),
    );
  }
}
