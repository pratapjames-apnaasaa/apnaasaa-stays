import 'package:unite_india_app/core/domain/guest_listing.dart';
import 'package:unite_india_app/core/domain/host.dart';
import 'package:unite_india_app/core/domain/host_listing_snapshot.dart';
import 'package:unite_india_app/core/domain/user.dart';
import 'package:unite_india_app/core/domain/verification_status.dart';
import 'package:unite_india_app/core/repositories/auth_repository.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';
import 'package:unite_india_app/core/repositories/trust_repository.dart';

/// Single emission per [authStateChanges] (matches typical Firebase first snapshot).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialUser});

  final UniteUser? initialUser;

  @override
  Stream<UniteUser?> authStateChanges() => Stream.value(initialUser);

  @override
  Future<void> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {}

  @override
  Future<void> signInAnonymously() async {}

  @override
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(Exception error) onError,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class FakeHostRepository implements HostRepository {
  @override
  Future<GuestListingDetail?> getPublishedListingForGuest(String listingId) async =>
      null;

  @override
  Future<HostListingSnapshot?> getHostListingForUser(String userId) async => null;

  @override
  Future<List<GuestListingSummary>> listPublishedGuestListings() async => [];

  @override
  Future<List<HostProfile>> listHostProfiles() async => [];

  @override
  Future<void> saveHostProfile({
    required String userId,
    required String displayName,
    required String areaLabel,
    required List<int> selectedSectors,
    String? city,
    String? state,
    double? lat,
    double? lng,
    String? exactAddress,
    String? landmark,
    String? propertyType,
    int? maxGuests,
    int? bedrooms,
    int? beds,
    int? bathrooms,
    bool? ruleNoLateEntryAfter9,
    bool? ruleNoSmokingInside,
    bool? ruleNoCooking,
    bool? ruleNoOutsideGuests,
    bool? ruleNoPets,
    String? otherHouseRules,
    bool? safetyOnlyQueerOrAllies,
    bool? safetyNoOutingDiscretion,
    bool? safetyBuildingSecurity24x7,
    bool? safetySeparateEntry,
    String? safetyNotesForQueerGuests,
    int? minNightlyPriceInr,
    int? maxNightlyPriceInr,
    bool? longStayDiscountOffered,
    int? cleaningFeeInr,
    int? extraGuestFeeInr,
    String? otherChargesNote,
    bool? kycVerifiedPilot,
    int? kycFailedAttempts,
    bool? kycBlockedPilot,
    String? kycBlockReason,
    String? listingStatus,
  }) async {}
}

class FakeTrustRepository implements TrustRepository {
  @override
  Future<TrustProfile> getTrustProfile(String userId) async {
    return TrustProfile(
      userId: userId,
      trustLevel: TrustLevel.newAccount,
      verificationStatus: VerificationStatus(
        kycLevel: KycLevel.none,
        hasVerifiedPaymentMethod: false,
        lastKycAt: null,
        kycProvider: null,
        kycReferenceId: null,
      ),
      completedStays: 0,
      cancellations: 0,
      reportsCount: 0,
    );
  }

  @override
  Future<void> updateTrustProfile(TrustProfile profile) async {}
}
