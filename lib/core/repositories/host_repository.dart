import 'package:unite_india_app/core/domain/guest_listing.dart';
import 'package:unite_india_app/core/domain/host.dart';
import 'package:unite_india_app/core/domain/host_listing_snapshot.dart';

abstract class HostRepository {
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
    // Step 4 — house rules
    bool? ruleNoLateEntryAfter9,
    bool? ruleNoSmokingInside,
    bool? ruleNoCooking,
    bool? ruleNoOutsideGuests,
    bool? ruleNoPets,
    String? otherHouseRules,
    // Step 5 — safety
    bool? safetyOnlyQueerOrAllies,
    bool? safetyNoOutingDiscretion,
    bool? safetyBuildingSecurity24x7,
    bool? safetySeparateEntry,
    String? safetyNotesForQueerGuests,
    // Step 6 — pricing
    int? minNightlyPriceInr,
    int? maxNightlyPriceInr,
    bool? longStayDiscountOffered,
    int? cleaningFeeInr,
    int? extraGuestFeeInr,
    String? otherChargesNote,
    // Step 7 — KYC (pilot / mock)
    bool? kycVerifiedPilot,
    int? kycFailedAttempts,
    bool? kycBlockedPilot,
    String? kycBlockReason,
    // Status
    String? listingStatus,
  });

  /// All host docs (newest first). May include drafts; use for admin/debug.
  Future<List<HostProfile>> listHostProfiles();

  /// Published listings for guest browse.
  Future<List<GuestListingSummary>> listPublishedGuestListings();

  /// Single published listing for guest detail, or null if missing / not published.
  Future<GuestListingDetail?> getPublishedListingForGuest(String listingId);

  /// Current user's listing (any status), keyed by [userId] document id.
  Future<HostListingSnapshot?> getHostListingForUser(String userId);
}
