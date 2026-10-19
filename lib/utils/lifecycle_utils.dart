import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/wishlist_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/search_controller.dart' as custom_search;
import '../utils/cache_manager.dart';

/// LifecycleUtils
/// Utility class for common lifecycle operations
class LifecycleUtils {
  
  /// Stop all background processes
  static Future<void> stopAllBackgroundProcesses() async {
    try {
      // Stop notification service
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = Get.find<NotificationService>();
        notificationService.stopRealTimeUpdates();
        debugPrint('[LifecycleUtils] Stopped notification service');
      }
      
      // Add other background processes here
      debugPrint('[LifecycleUtils] All background processes stopped');
    } catch (e) {
      debugPrint('[LifecycleUtils] Error stopping background processes: $e');
    }
  }
  
  /// Start all background processes (only if user is logged in)
  static Future<void> startAllBackgroundProcesses() async {
    try {
      // Only start processes if user is logged in
      if (!CacheManager.isLoggedIn()) {
        debugPrint('[LifecycleUtils] User not logged in, skipping background processes');
        return;
      }
      
      // Start notification service
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = Get.find<NotificationService>();
        notificationService.startRealTimeUpdates();
        debugPrint('[LifecycleUtils] Started notification service');
      }
      
      // Add other background processes here
      debugPrint('[LifecycleUtils] All background processes started');
    } catch (e) {
      debugPrint('[LifecycleUtils] Error starting background processes: $e');
    }
  }
  
  /// Clear all user-related data and controllers
  static Future<void> clearUserDataAndControllers() async {
    try {
      // Clear user data from cache
      await CacheManager.clearUserData();
      
      // Clear app state from Hive
      if (Hive.isBoxOpen('appState')) {
        final box = Hive.box('appState');
        await box.clear();
        debugPrint('[LifecycleUtils] Cleared app state');
      }
      
      // Stop background processes
      await stopAllBackgroundProcesses();
      
      // Clear controllers that might hold user data
      _clearController<CartController>('CartController');
      _clearController<WishlistController>('WishlistController');
      _clearController<CheckoutController>('CheckoutController');
      _clearController<ProfileController>('ProfileController');
      
      debugPrint('[LifecycleUtils] User data and controllers cleared');
    } catch (e) {
      debugPrint('[LifecycleUtils] Error clearing user data: $e');
    }
  }
  
  /// Perform complete app cleanup (for app termination)
  static Future<void> performAppCleanup() async {
    try {
      debugPrint('[LifecycleUtils] Starting app cleanup...');
      
      // Stop all background processes
      await stopAllBackgroundProcesses();
      
      // Clear all controllers
      _cleanupController<AuthController>('AuthController');
      _cleanupController<HomeController>('HomeController');
      _cleanupController<CartController>('CartController');
      _cleanupController<WishlistController>('WishlistController');
      _cleanupController<CheckoutController>('CheckoutController');
      _cleanupController<custom_search.SearchController>('SearchController');
      _cleanupController<ProductController>('ProductController');
      _cleanupController<ProfileController>('ProfileController');
      _cleanupController<NotificationService>('NotificationService');
      
      debugPrint('[LifecycleUtils] App cleanup completed');
    } catch (e) {
      debugPrint('[LifecycleUtils] Error during app cleanup: $e');
    }
  }
  
  /// Check if app should refresh data based on background duration
  static bool shouldRefreshData(Duration backgroundDuration) {
    // Refresh if app was in background for more than 5 minutes
    return backgroundDuration.inMinutes > 5;
  }
  
  /// Save critical app state before app goes to background
  static Future<void> saveCriticalState() async {
    try {
      if (!Hive.isBoxOpen('appState')) {
        await Hive.openBox('appState');
      }
      
      final box = Hive.box('appState');
      
      // Save timestamp
      await box.put('last_background_time', DateTime.now().millisecondsSinceEpoch);
      
      // Save current route if user is logged in
      if (CacheManager.isLoggedIn()) {
        try {
          final currentRoute = Get.currentRoute;
          await box.put('last_route', currentRoute);
          debugPrint('[LifecycleUtils] Saved current route: $currentRoute');
        } catch (e) {
          debugPrint('[LifecycleUtils] Error saving route: $e');
        }
      }
      
      debugPrint('[LifecycleUtils] Critical state saved');
    } catch (e) {
      debugPrint('[LifecycleUtils] Error saving critical state: $e');
    }
  }
  
  /// Validate app state on resume
  static Future<bool> validateAppState() async {
    try {
      // Check if user session is still valid
      if (CacheManager.isLoggedIn()) {
        final token = CacheManager.getUserToken();
        if (token == null || token.isEmpty) {
          debugPrint('[LifecycleUtils] Invalid token found, clearing user data');
          await clearUserDataAndControllers();
          return false;
        }
      }
      
      debugPrint('[LifecycleUtils] App state validation passed');
      return true;
    } catch (e) {
      debugPrint('[LifecycleUtils] Error validating app state: $e');
      return false;
    }
  }
  
  /// Helper method to clear a specific controller type
  static void _clearController<T>(String controllerName) {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>();
        debugPrint('[LifecycleUtils] Cleared controller: $controllerName');
      }
    } catch (e) {
      debugPrint('[LifecycleUtils] Error clearing controller $controllerName: $e');
    }
  }
  
  /// Helper method to cleanup a specific controller type
  static void _cleanupController<T>(String controllerName) {
    try {
      if (Get.isRegistered<T>()) {
        final controller = Get.find<T>();
        if (controller is GetxController) {
          controller.onClose();
        }
        Get.delete<T>();
        debugPrint('[LifecycleUtils] Cleaned up: $controllerName');
      }
    } catch (e) {
      debugPrint('[LifecycleUtils] Error cleaning up $controllerName: $e');
    }
  }
}
