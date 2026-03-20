import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unite_india_app/core/domain/guest_listing.dart';
import 'package:unite_india_app/core/domain/host.dart';
import 'package:unite_india_app/core/domain/host_listing_snapshot.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';

class FirebaseHostRepository implements HostRepository {
  FirebaseHostRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('hosts');

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
  }) async {
    await _collection.doc(userId).set(
      {
        'userId': userId,
        'displayName': displayName,
        'areaLabel': areaLabel,
        'city': city,
        'state': state,
        'lat': lat,
        'lng': lng,
        'exactAddress': exactAddress,
        'landmark': landmark,
        'propertyType': propertyType,
        'maxGuests': maxGuests,
        'bedrooms': bedrooms,
        'beds': beds,
        'bathrooms': bathrooms,
        'sectors': selectedSectors,
        'ruleNoLateEntryAfter9': ruleNoLateEntryAfter9,
        'ruleNoSmokingInside': ruleNoSmokingInside,
        'ruleNoCooking': ruleNoCooking,
        'ruleNoOutsideGuests': ruleNoOutsideGuests,
        'ruleNoPets': ruleNoPets,
        'otherHouseRules': otherHouseRules,
        'safetyOnlyQueerOrAllies': safetyOnlyQueerOrAllies,
        'safetyNoOutingDiscretion': safetyNoOutingDiscretion,
        'safetyBuildingSecurity24x7': safetyBuildingSecurity24x7,
        'safetySeparateEntry': safetySeparateEntry,
        'safetyNotesForQueerGuests': safetyNotesForQueerGuests,
        'minNightlyPriceInr': minNightlyPriceInr,
        'maxNightlyPriceInr': maxNightlyPriceInr,
        'longStayDiscountOffered': longStayDiscountOffered,
        'cleaningFeeInr': cleaningFeeInr,
        'extraGuestFeeInr': extraGuestFeeInr,
        'otherChargesNote': otherChargesNote,
        'kycVerifiedPilot': kycVerifiedPilot,
        'kycFailedAttempts': kycFailedAttempts,
        'kycBlockedPilot': kycBlockedPilot,
        'kycBlockReason': kycBlockReason,
        'listingStatus': listingStatus ?? 'published',
        'timestamp': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<List<HostProfile>> listHostProfiles() async {
    final snapshot =
        await _collection.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['timestamp'];
      return HostProfile(
        id: doc.id,
        displayName: (data['displayName'] ?? '') as String,
        areaLabel: (data['areaLabel'] ?? '') as String,
        selectedSectors:
            List<int>.from((data['sectors'] as List<dynamic>? ?? <dynamic>[])
                .map((e) => e as int)),
        createdAt: timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  @override
  Future<List<GuestListingSummary>> listPublishedGuestListings() async {
    final snapshot = await _collection
        .where('listingStatus', isEqualTo: 'published')
        .get();
    final list = snapshot.docs.map((doc) {
      final d = doc.data();
      int? readInt(String key) {
        final v = d[key];
        if (v == null) return null;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return null;
      }

      return GuestListingSummary(
        id: doc.id,
        displayName: (d['displayName'] ?? '') as String,
        areaLabel: (d['areaLabel'] ?? '') as String,
        city: d['city'] as String?,
        state: d['state'] as String?,
        minNightlyPriceInr: readInt('minNightlyPriceInr'),
        maxNightlyPriceInr: readInt('maxNightlyPriceInr'),
        propertyType: d['propertyType'] as String?,
        lat: (d['lat'] as num?)?.toDouble(),
        lng: (d['lng'] as num?)?.toDouble(),
      );
    }).toList();
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  @override
  Future<GuestListingDetail?> getPublishedListingForGuest(
    String listingId,
  ) async {
    final doc = await _collection.doc(listingId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    if (data['listingStatus'] != 'published') return null;
    return GuestListingDetail.fromFirestore(doc.id, data);
  }

  @override
  Future<HostListingSnapshot?> getHostListingForUser(String userId) async {
    final doc = await _collection.doc(userId).get();
    if (!doc.exists) return null;
    return HostListingSnapshot.fromFirestoreDoc(doc);
  }
}
