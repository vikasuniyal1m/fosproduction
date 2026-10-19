import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Watch faces feature flags — flip here while testing.
class WatchFacesConfig {
  WatchFacesConfig._();

  // ---------------------------------------------------------------------------
  // PLATFORM VISIBILITY
  // ---------------------------------------------------------------------------
  // `false` = hide watch faces on Android (home banner, navigation, screen).
  static const bool enableOnAndroid = true;
  static const bool enableOnIos = true;

  /// Whether watch faces should be shown on the current device.
  static bool get isFeatureEnabled {
    if (kIsWeb) return enableOnIos || enableOnAndroid;
    if (Platform.isAndroid) return enableOnAndroid;
    if (Platform.isIOS) return enableOnIos;
    return false;
  }

  // ---------------------------------------------------------------------------
  // PAY MODEL (enable / disable for testing Install)
  // ---------------------------------------------------------------------------
  // `true`  = skip Pay — all faces show Install (no login / Stripe / API check).
  // `false` = production — Pay required before Install.
  static const bool bypassPurchaseForTesting = false;

  static bool get isPayEnabled => !bypassPurchaseForTesting;

  static const double defaultPrice = 1.99;
}
