/// Public listing card + detail for guest browse (published only in UI).
class GuestListingSummary {
  GuestListingSummary({
    required this.id,
    required this.displayName,
    required this.areaLabel,
    this.city,
    this.state,
    this.minNightlyPriceInr,
    this.maxNightlyPriceInr,
    this.propertyType,
    this.lat,
    this.lng,
  });

  final String id;
  final String displayName;
  final String areaLabel;
  final String? city;
  final String? state;
  final int? minNightlyPriceInr;
  final int? maxNightlyPriceInr;
  final String? propertyType;
  final double? lat;
  final double? lng;

  String get locationLine {
    final parts = <String>[
      areaLabel,
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
    ];
    return parts.join(', ');
  }
}

/// Full read model for listing detail screen (published docs only).
class GuestListingDetail {
  GuestListingDetail({
    required this.id,
    required this.displayName,
    required this.areaLabel,
    this.city,
    this.state,
    this.lat,
    this.lng,
    this.exactAddress,
    this.landmark,
    this.propertyType,
    this.maxGuests,
    this.bedrooms,
    this.beds,
    this.bathrooms,
    this.sectors,
    this.minNightlyPriceInr,
    this.maxNightlyPriceInr,
    this.longStayDiscountOffered,
    this.cleaningFeeInr,
    this.extraGuestFeeInr,
    this.otherChargesNote,
    this.ruleNoLateEntryAfter9,
    this.ruleNoSmokingInside,
    this.ruleNoCooking,
    this.ruleNoOutsideGuests,
    this.ruleNoPets,
    this.otherHouseRules,
    this.safetyOnlyQueerOrAllies,
    this.safetyNoOutingDiscretion,
    this.safetyBuildingSecurity24x7,
    this.safetySeparateEntry,
    this.safetyNotesForQueerGuests,
  });

  final String id;
  final String displayName;
  final String areaLabel;
  final String? city;
  final String? state;
  final double? lat;
  final double? lng;
  final String? exactAddress;
  final String? landmark;
  final String? propertyType;
  final int? maxGuests;
  final int? bedrooms;
  final int? beds;
  final int? bathrooms;
  final List<int>? sectors;
  final int? minNightlyPriceInr;
  final int? maxNightlyPriceInr;
  final bool? longStayDiscountOffered;
  final int? cleaningFeeInr;
  final int? extraGuestFeeInr;
  final String? otherChargesNote;
  final bool? ruleNoLateEntryAfter9;
  final bool? ruleNoSmokingInside;
  final bool? ruleNoCooking;
  final bool? ruleNoOutsideGuests;
  final bool? ruleNoPets;
  final String? otherHouseRules;
  final bool? safetyOnlyQueerOrAllies;
  final bool? safetyNoOutingDiscretion;
  final bool? safetyBuildingSecurity24x7;
  final bool? safetySeparateEntry;
  final String? safetyNotesForQueerGuests;

  static GuestListingDetail fromFirestore(String id, Map<String, dynamic> d) {
    int? readInt(String key) {
      final v = d[key];
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    return GuestListingDetail(
      id: id,
      displayName: (d['displayName'] ?? '') as String,
      areaLabel: (d['areaLabel'] ?? '') as String,
      city: d['city'] as String?,
      state: d['state'] as String?,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      exactAddress: d['exactAddress'] as String?,
      landmark: d['landmark'] as String?,
      propertyType: d['propertyType'] as String?,
      maxGuests: readInt('maxGuests'),
      bedrooms: readInt('bedrooms'),
      beds: readInt('beds'),
      bathrooms: readInt('bathrooms'),
      sectors: (d['sectors'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      minNightlyPriceInr: readInt('minNightlyPriceInr'),
      maxNightlyPriceInr: readInt('maxNightlyPriceInr'),
      longStayDiscountOffered: d['longStayDiscountOffered'] as bool?,
      cleaningFeeInr: readInt('cleaningFeeInr'),
      extraGuestFeeInr: readInt('extraGuestFeeInr'),
      otherChargesNote: d['otherChargesNote'] as String?,
      ruleNoLateEntryAfter9: d['ruleNoLateEntryAfter9'] as bool?,
      ruleNoSmokingInside: d['ruleNoSmokingInside'] as bool?,
      ruleNoCooking: d['ruleNoCooking'] as bool?,
      ruleNoOutsideGuests: d['ruleNoOutsideGuests'] as bool?,
      ruleNoPets: d['ruleNoPets'] as bool?,
      otherHouseRules: d['otherHouseRules'] as String?,
      safetyOnlyQueerOrAllies: d['safetyOnlyQueerOrAllies'] as bool?,
      safetyNoOutingDiscretion: d['safetyNoOutingDiscretion'] as bool?,
      safetyBuildingSecurity24x7: d['safetyBuildingSecurity24x7'] as bool?,
      safetySeparateEntry: d['safetySeparateEntry'] as bool?,
      safetyNotesForQueerGuests: d['safetyNotesForQueerGuests'] as String?,
    );
  }
}
