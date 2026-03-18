import 'package:unite_india_app/core/domain/host.dart';

abstract class HostRepository {
  Future<void> saveHostProfile({
    required String displayName,
    required String areaLabel,
    required List<int> selectedSectors,
  });

  Future<List<HostProfile>> listHostProfiles();
}

