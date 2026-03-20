import 'package:unite_india_app/core/domain/host.dart';

abstract class HostRepository {
  Future<void> saveHostProfile({
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
  });

  Future<List<HostProfile>> listHostProfiles();
}

