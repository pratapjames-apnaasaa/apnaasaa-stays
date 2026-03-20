import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'web_geocoder_stub.dart'
    if (dart.library.js) 'web_geocoder_web.dart';

/// Geocode using the Google Maps JS API when running on web.
/// Returns null when unavailable.
Future<LatLng?> webGeocodeAddress(String query) => webGeocodeAddressImpl(query);

