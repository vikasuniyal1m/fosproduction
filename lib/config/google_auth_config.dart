/// Google Sign-In — Google Cloud Console project 312606208197.
/// https://console.cloud.google.com/apis/credentials?project=312606208197
class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// Android OAuth — release keystore (Android client 2).
  static const String androidReleaseClientId =
      '312606208197-fb05c8kpmnoeijmblv40nhac9fdsqoc6.apps.googleusercontent.com';

  /// Android OAuth — debug keystore (`flutter run`).
  static const String androidDebugClientId =
      '312606208197-jj89cr5qoh9htinrhb42nll6mlcaqgi7.apps.googleusercontent.com';

  /// iOS OAuth client (iOS client 1) — bundle com.fruitsofspirit.ecommerce.
  static const String iosClientId =
      '312606208197-gcvr4m6qt5r6mklb6b1serhpblnkbem8.apps.googleusercontent.com';

  /// Web OAuth client — [GoogleSignIn.serverClientId] on Android (id token for backend).
  static const String webClientId =
      '312606208197-k2tqmk7j9be767lk629kl25usp0noo35.apps.googleusercontent.com';

  static const String androidPackageName = 'com.fosproduction.ecommerceapp';

  /// Release SHA-1 — Android client 2.
  static const String androidReleaseSha1 =
      '07:A6:3F:90:65:37:AA:09:DC:3C:15:B5:63:66:E2:14:AD:F2:AA:0E';

  /// Debug SHA-1 — Android client (jj89cr5q…).
  static const String androidDebugSha1 =
      'E8:B6:19:CC:80:FE:EA:A3:22:19:0E:F5:BC:19:57:43:C1:E0:3B:21';
}
