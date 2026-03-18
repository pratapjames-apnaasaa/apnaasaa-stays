import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unite_india_app/core/domain/verification_status.dart';
import 'package:unite_india_app/core/repositories/trust_repository.dart';

class FirebaseTrustRepository implements TrustRepository {
  FirebaseTrustRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('trust_profiles');

  @override
  Future<TrustProfile> getTrustProfile(String userId) async {
    final doc = await _collection.doc(userId).get();
    if (!doc.exists) {
      throw StateError('Trust profile not found for user $userId');
    }
    final data = doc.data()!;
    final verification = VerificationStatus(
      kycLevel: KycLevel.values[data['kycLevel'] as int? ?? 0],
      hasVerifiedPaymentMethod:
          (data['hasVerifiedPaymentMethod'] as bool?) ?? false,
      lastKycAt: (data['lastKycAt'] as Timestamp?)?.toDate(),
      kycProvider: data['kycProvider'] as String?,
      kycReferenceId: data['kycReferenceId'] as String?,
    );
    return TrustProfile(
      userId: userId,
      trustLevel: TrustLevel.values[data['trustLevel'] as int? ?? 0],
      verificationStatus: verification,
      completedStays: (data['completedStays'] as int?) ?? 0,
      cancellations: (data['cancellations'] as int?) ?? 0,
      reportsCount: (data['reportsCount'] as int?) ?? 0,
    );
  }

  @override
  Future<void> updateTrustProfile(TrustProfile profile) async {
    await _collection.doc(profile.userId).set({
      'trustLevel': profile.trustLevel.index,
      'kycLevel': profile.verificationStatus.kycLevel.index,
      'hasVerifiedPaymentMethod':
          profile.verificationStatus.hasVerifiedPaymentMethod,
      'lastKycAt': profile.verificationStatus.lastKycAt != null
          ? Timestamp.fromDate(profile.verificationStatus.lastKycAt!)
          : null,
      'kycProvider': profile.verificationStatus.kycProvider,
      'kycReferenceId': profile.verificationStatus.kycReferenceId,
      'completedStays': profile.completedStays,
      'cancellations': profile.cancellations,
      'reportsCount': profile.reportsCount,
    });
  }
}

