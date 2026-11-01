/// Google Maps / Places / Geocoding key used from Dart (search + reverse geocode).
///
/// TEMP testing key — replace before production and rotate in Google Cloud Console.
/// Native Android/iOS SDKs still read their own key from local.properties / xcconfig.
abstract final class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDciNqktI9_WsAT2Wzfwf_r56tUCxzLexk',
  );

  /// Bias autocomplete toward Saudi Arabia for Print KYC.
  static const String country = 'sa';
}
