enum DeletionRequestStatus { pending, approved, rejected }

class DeletionRequest {
  const DeletionRequest({
    required this.id,
    required this.userHandle,
    required this.requestedAt,
    required this.purgeDueAt,
    required this.status,
    this.rejectionReason,
    this.reviewedAt,
  });

  final String id;
  final String userHandle;
  final DateTime requestedAt;
  final DateTime purgeDueAt;
  final DeletionRequestStatus status;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  factory DeletionRequest.fromJson(Map<String, dynamic> m) {
    return DeletionRequest(
      id: m['id'] as String,
      userHandle: m['userHandle'] as String,
      requestedAt: DateTime.parse(m['requestedAt'] as String),
      purgeDueAt: DateTime.parse(m['purgeDueAt'] as String),
      status: _parseStatus(m['status'] as String),
      rejectionReason: m['rejectionReason'] as String?,
      reviewedAt: m['reviewedAt'] != null
          ? DateTime.parse(m['reviewedAt'] as String)
          : null,
    );
  }
}

DeletionRequestStatus _parseStatus(String s) => switch (s) {
      'approved' => DeletionRequestStatus.approved,
      'rejected' => DeletionRequestStatus.rejected,
      _ => DeletionRequestStatus.pending,
    };
