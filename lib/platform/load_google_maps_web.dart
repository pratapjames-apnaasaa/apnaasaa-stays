// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:unite_india_app/config/maps_config.dart';

/// Injects the Maps JavaScript API using [MapsConfig.googleMapsApiKey].
Future<void> loadGoogleMapsScript() async {
  final key = MapsConfig.googleMapsApiKey;
  if (key.isEmpty) {
    // ignore: avoid_print
    print(
      'GOOGLE_MAPS_API_KEY is not set. Maps and web geocoding will be limited. '
      'Use: flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY',
    );
    return;
  }

  if (html.document.querySelector('script[data-apnaasaa-maps]') != null) {
    return;
  }

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$key'
    ..setAttribute('data-apnaasaa-maps', 'true');

  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });

  html.document.head!.append(script);
  await completer.future;
}
