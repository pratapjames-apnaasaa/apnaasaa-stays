// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:js' as js;

import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<LatLng?> webGeocodeAddressImpl(String query) async {
  try {
    final google = js.context['google'];
    if (google == null) return null;
    final maps = google['maps'];
    if (maps == null) return null;
    final geocoderCtor = maps['Geocoder'];
    if (geocoderCtor == null) return null;

    final geocoder = js.JsObject(geocoderCtor);
    final completer = Completer<LatLng?>();

    geocoder.callMethod('geocode', [
      js.JsObject.jsify({'address': query}),
      (results, status) {
        try {
          final statusStr = status?.toString() ?? '';
          if (statusStr != 'OK' || results == null || results.length == 0) {
            completer.complete(null);
            return;
          }
          final first = results[0];
          final geometry = first['geometry'];
          final location = geometry?['location'];
          final lat = location?.callMethod('lat') as num?;
          final lng = location?.callMethod('lng') as num?;
          if (lat == null || lng == null) {
            completer.complete(null);
            return;
          }
          completer.complete(LatLng(lat.toDouble(), lng.toDouble()));
        } catch (_) {
          completer.complete(null);
        }
      },
    ]);

    return await completer.future.timeout(const Duration(seconds: 5));
  } catch (_) {
    return null;
  }
}

