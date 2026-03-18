class HostProfile {
  HostProfile({
    required this.id,
    required this.displayName,
    required this.areaLabel,
    required this.selectedSectors,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String areaLabel;
  final List<int> selectedSectors;
  final DateTime createdAt;
}

