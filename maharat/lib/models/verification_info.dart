import 'worker_model.dart';

/// The outcome of an identity check for a worker or a contractor.
class VerificationInfo {
  final VerificationStatus status;

  /// Face similarity between the CNIC photo and the selfie, 0-100.
  final double? score;

  /// Why it was rejected: face_mismatch, no_face_cnic, no_face_selfie,
  /// multiple_faces, or null for a manual decision.
  final String? code;
  final String? reason;

  const VerificationInfo({
    required this.status,
    this.score,
    this.code,
    this.reason,
  });

  factory VerificationInfo.fromJson(Map<String, dynamic> json) {
    return VerificationInfo(
      status: VerificationStatus.values.byName(json['status'] as String),
      score: (json['face_match_score'] as num?)?.toDouble(),
      code: json['rejection_code'] as String?,
      reason: json['rejection_reason'] as String?,
    );
  }

  bool get isApproved => status == VerificationStatus.approved;
  bool get isRejected => status == VerificationStatus.rejected;
  bool get isPending => status == VerificationStatus.pending;
}

/// What the face check returned right after a submission.
class FaceCheckResult {
  final VerificationStatus status;
  final double? score;

  /// For a pending result: not_configured (manual review) or temporary_error.
  final String? code;

  const FaceCheckResult({required this.status, this.score, this.code});
}
