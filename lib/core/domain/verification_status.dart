enum KycLevel {
  none,
  basic,
  strong,
}

enum TrustLevel {
  newAccount,
  basic,
  verified,
  trusted,
}

class VerificationStatus {
  VerificationStatus({
    required this.kycLevel,
    required this.hasVerifiedPaymentMethod,
    required this.lastKycAt,
    required this.kycProvider,
    required this.kycReferenceId,
  });

  final KycLevel kycLevel;
  final bool hasVerifiedPaymentMethod;
  final DateTime? lastKycAt;
  final String? kycProvider;
  final String? kycReferenceId;
}

class TrustProfile {
  TrustProfile({
    required this.userId,
    required this.trustLevel,
    required this.verificationStatus,
    required this.completedStays,
    required this.cancellations,
    required this.reportsCount,
  });

  final String userId;
  final TrustLevel trustLevel;
  final VerificationStatus verificationStatus;
  final int completedStays;
  final int cancellations;
  final int reportsCount;
}

