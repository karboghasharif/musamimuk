/// Google Maps / Places / Geocoding key used from Dart (search + reverse geocode).
///
/// Pass at build time: `--dart-define=GOOGLE_MAPS_API_KEY=…`
/// Native Android/iOS SDKs still read their own key from local.properties / xcconfig.
abstract final class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Bias autocomplete toward Saudi Arabia for Print KYC.
  static const String country = 'sa';
}
