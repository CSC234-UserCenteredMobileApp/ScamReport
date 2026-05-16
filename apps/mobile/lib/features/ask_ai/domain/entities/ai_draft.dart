enum TargetIdentifierKind { phone, url, other }

class AiDraft {
  const AiDraft({
    required this.title,
    required this.description,
    required this.scamTypeCode,
    this.targetIdentifier,
    this.targetIdentifierKind,
    this.suspectedScammerName,
  });

  final String title;
  final String description;
  final String scamTypeCode;
  final String? targetIdentifier;
  final TargetIdentifierKind? targetIdentifierKind;
  final String? suspectedScammerName;

  AiDraft copyWith({
    String? title,
    String? description,
    String? scamTypeCode,
    String? targetIdentifier,
    TargetIdentifierKind? targetIdentifierKind,
    String? suspectedScammerName,
    bool clearTargetIdentifier = false,
    bool clearSuspectedScammerName = false,
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
      suspectedScammerName: clearSuspectedScammerName
          ? null
          : (suspectedScammerName ?? this.suspectedScammerName),
    );
  }
}
