/// Map each watch face id → your backend **digital product** id.
/// Create one digital product per fruit face in admin, then paste ids here
/// (or set `productId` directly in assets/watch_faces/catalog/watch_faces.json).
class WatchFaceProductIds {
  WatchFaceProductIds._();

  static const Map<String, int> overrides = {
    'ios-photos-00': 212,
    'ios-photos-01': 212,
    'ios-photos-02': 212,
    'ios-photos-03': 212,
    'ios-photos-04': 212,
    'ios-photos-05': 212,
    'ios-photos-06': 212,
    'ios-photos-07': 212,
    'ios-photos-08': 212,
    'ios-photos-09': 212,
    'ios-photos-10': 212,
    'ios-photos-11': 212,
    'ios-photos-12': 212,
    'android-apple': 212,
    'android-banana': 213,
    'android-grapes': 212,
    'android-juicy-melon': 212,
    'android-kiwi': 212,
    'android-lemon': 212,
    'android-mango': 212,
    'android-orange': 212,
    'android-pineapple': 212,
    'android-watermelon': 212,
  };

  static Set<int> get knownProductIds =>
      overrides.values.toSet();

  static bool isWatchFaceProduct(int? productId) =>
      productId != null && productId > 0 && knownProductIds.contains(productId);

  static int? resolve(String faceId, int? fromCatalog) {
    if (overrides.containsKey(faceId)) return overrides[faceId];
    if (fromCatalog != null && fromCatalog > 0) return fromCatalog;
    
    // Dynamic fallback for any watch face that is not explicitly mapped
    if (faceId.contains('banana')) return 213;
    if (faceId.startsWith('android-')) return 212;
    return 212; // Apple as default fallback
  }
}
