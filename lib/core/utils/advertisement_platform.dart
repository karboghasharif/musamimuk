import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Maps the current runtime to the API `platform` query value.
String advertisementPlatformParam() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'all';
}
