import 'cache_manager.dart';

/// Typed cache helpers for API list/map data (GetStorage via CacheManager).
class DataCache {
  static String categoryProducts(int categoryId) => 'category_products_$categoryId';
  static String productDetail(int productId) => 'product_detail_$productId';
  static String orderDetail(int orderId) => 'order_detail_$orderId';
  static const orders = 'cache_orders';
  static const addresses = 'cache_addresses';
  static const coupons = 'cache_coupons';
  static const profile = 'cache_profile';
  static const notifications = 'cache_notifications';
  static const loyalty = 'cache_loyalty';
  static const referral = 'cache_referral';
  static const digitalPurchased = 'digital_purchased_map';

  /// Instant owned-state lookup (no preview URL required — works for stickers).
  static ({bool purchased, int? orderItemId}) purchaseStatus(int productId) {
    final map = CacheManager.getData<Map>(digitalPurchased);
    if (map == null || !map.containsKey(productId.toString())) {
      return (purchased: false, orderItemId: null);
    }
    final raw = map[productId.toString()];
    if (raw == null) return (purchased: true, orderItemId: null);
    if (raw is int) return (purchased: true, orderItemId: raw);
    return (
      purchased: true,
      orderItemId: int.tryParse(raw.toString()),
    );
  }

  static Future<void> markDigitalPurchased(
    int productId, {
    int? orderItemId,
  }) async {
    final existing = CacheManager.getData<Map>(digitalPurchased);
    final map = existing != null
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};
    map[productId.toString()] = orderItemId ?? true;
    await CacheManager.saveData(digitalPurchased, map);
  }

  static List<Map<String, dynamic>>? loadList(String key) {
    final raw = CacheManager.getData<List>(key);
    if (raw == null) return null;
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> saveList(
    String key,
    List<Map<String, dynamic>> data,
  ) =>
      CacheManager.saveData(key, data);

  static Map<String, dynamic>? loadMap(String key) {
    final raw = CacheManager.getData<Map>(key);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> saveMap(String key, Map<String, dynamic> data) =>
      CacheManager.saveData(key, data);

  static Future<void> clearUserCaches() => CacheManager.clearUserSessionData();
}
