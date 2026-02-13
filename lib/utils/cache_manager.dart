import 'package:get_storage/get_storage.dart';

/// Cache Manager
/// Handles all local storage and caching operations
/// Lightweight and fast storage solution
class CacheManager {
  static final GetStorage _storage = GetStorage();
  
  /// Initialize cache - Call this in main.dart
  static Future<void> init() async {
    await GetStorage.init();
  }
  
  // ========== User Data ==========
  static const String _keyUserId = 'user_id';
  static const String _keyUserToken = 'user_token';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  
  // ========== App Settings ==========
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyNotifications = 'notifications_enabled';
  
  // ========== Cart & Wishlist ==========
  static const String _keyCartItems = 'cart_items';
  static const String _keyWishlistItems = 'wishlist_items';
  
  // ========== User Data Methods ==========
  static Future<void> saveUserId(String userId) => _storage.write(_keyUserId, userId);
  static String? getUserId() => _storage.read(_keyUserId);
  
  static Future<void> saveUserToken(String token) => _storage.write(_keyUserToken, token);
  static String? getUserToken() => _storage.read(_keyUserToken);
  
  static Future<void> saveUserEmail(String email) => _storage.write(_keyUserEmail, email);
  static String? getUserEmail() => _storage.read(_keyUserEmail);
  
  static Future<void> saveUserName(String name) => _storage.write(_keyUserName, name);
  static String? getUserName() => _storage.read(_keyUserName);
  
  static Future<void> saveUserPhone(String phone) => _storage.write(_keyUserPhone, phone);
  static String? getUserPhone() => _storage.read(_keyUserPhone);
  
  static Future<void> setLoggedIn(bool value) => _storage.write(_keyIsLoggedIn, value);
  static bool isLoggedIn() => _storage.read(_keyIsLoggedIn) ?? false;
  
  static Future<void> setOnboardingCompleted(bool value) => _storage.write(_keyOnboardingCompleted, value);
  static bool isOnboardingCompleted() => _storage.read(_keyOnboardingCompleted) ?? false;
  
  /// Reset onboarding status (for testing)
  static Future<void> resetOnboarding() => _storage.remove(_keyOnboardingCompleted);
  
  // ========== App Settings Methods ==========
  static Future<void> saveThemeMode(String mode) => _storage.write(_keyThemeMode, mode);
  static String? getThemeMode() => _storage.read(_keyThemeMode);
  
  static Future<void> saveLanguage(String language) => _storage.write(_keyLanguage, language);
  static String? getLanguage() => _storage.read(_keyLanguage);
  
  static Future<void> setNotificationsEnabled(bool value) => _storage.write(_keyNotifications, value);
  static bool isNotificationsEnabled() => _storage.read(_keyNotifications) ?? true;
  
  // ========== Cart & Wishlist Methods ==========
  static Future<void> saveCartItems(List<Map<String, dynamic>> items) => _storage.write(_keyCartItems, items);
  static List<Map<String, dynamic>>? getCartItems() {
    final data = _storage.read(_keyCartItems);
    if (data != null && data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }
  
  static Future<void> saveWishlistItems(List<Map<String, dynamic>> items) => _storage.write(_keyWishlistItems, items);
  static List<Map<String, dynamic>>? getWishlistItems() {
    final data = _storage.read(_keyWishlistItems);
    if (data != null && data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }
  
  // ========== Generic Methods ==========
  static Future<void> saveData(String key, dynamic value) => _storage.write(key, value);
  static T? getData<T>(String key) => _storage.read<T>(key);
  
  static Future<void> removeData(String key) => _storage.remove(key);
  
  static Future<void> clearAll() => _storage.erase();
  
  static Future<void> clearUserData() async {
    await _storage.remove(_keyUserId);
    await _storage.remove(_keyUserToken);
    await _storage.remove(_keyUserEmail);
    await _storage.remove(_keyUserName);
    await _storage.remove(_keyUserPhone);
    await _storage.remove(_keyIsLoggedIn);
  }
  
  // ========== Check if key exists ==========
  static bool hasData(String key) => _storage.hasData(key);
}

