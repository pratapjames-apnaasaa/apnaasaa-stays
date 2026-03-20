/// Google Maps / Geocoding API key.
///
/// Pass at build/run time:
/// `flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=your_key`
/// `flutter build web --dart-define=GOOGLE_MAPS_API_KEY=your_key`
class MapsConfig {
  MapsConfig._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasGoogleMapsApiKey => googleMapsApiKey.isNotEmpty;
}
