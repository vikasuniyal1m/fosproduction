import 'package:get/get.dart';
import 'dart:async';
import '../controllers/cart_controller.dart';
import '../utils/cache_manager.dart';
import '../utils/app_lifecycle.dart';

/// Cart Sync Service
/// Manages real-time cart synchronization across the app
class CartSyncService extends GetxService {
  static CartSyncService get to => Get.find();
  
  Timer? _syncTimer;
  final RxInt cartBadgeCount = 0.obs;
  final RxBool isSyncing = false.obs;
  final RxString lastSyncError = ''.obs;
  int _lastKnownCount = 0;
  
  @override
  void onInit() {
    super.onInit();
    _startAutoSync();
    _listenToAppLifecycle();
  }
  
  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }
  
  /// Start automatic cart synchronization
  void _startAutoSync() {
    _syncTimer?.cancel();
    
    // Sync every 15 seconds when user is logged in
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (CacheManager.isLoggedIn()) {
        syncCartBadge();
      }
    });
    
    // Initial sync
    if (CacheManager.isLoggedIn()) {
      syncCartBadge();
    }
  }
  
  /// Sync cart badge count in background
  Future<void> syncCartBadge() async {
    if (isSyncing.value) return;
    
    isSyncing.value = true;
    try {
      if (!Get.isRegistered<CartController>()) {
        lastSyncError.value = '';
        return;
      }
      final cartController = Get.find<CartController>();
      
      // Only sync if cart is not currently being loaded
      if (!cartController.isLoading.value) {
        await cartController.refreshCartSilently();
        
        // Update badge count
        final newCount = cartController.totalItems.value;
        if (newCount != _lastKnownCount) {
          _lastKnownCount = newCount;
          cartBadgeCount.value = newCount;
          print('[CartSync] Badge count updated: $newCount');
        }
      }
      
      lastSyncError.value = '';
    } catch (e) {
      print('[CartSync] Sync error: $e');
      lastSyncError.value = e.toString();
    } finally {
      isSyncing.value = false;
    }
  }
  
  /// Force immediate sync
  Future<void> forceSync() async {
    await syncCartBadge();
  }
  
  /// Listen to app lifecycle events
  void _listenToAppLifecycle() {
    // Listen to app lifecycle changes
    ever(AppLifecycleManager.instance.isAppInForeground, (bool isInForeground) {
      if (isInForeground) {
        print('[CartSync] App resumed, resetting sync timer');
        // Reset sync timer when app comes to foreground
        _startAutoSync();
        // Force immediate sync
        Future.delayed(const Duration(milliseconds: 500), () {
          forceSync();
        });
      }
    });
  }
  
  /// Reset sync service (call after login/logout)
  void reset() {
    _lastKnownCount = 0;
    cartBadgeCount.value = 0;
    lastSyncError.value = '';
    _startAutoSync();
  }
  
  /// Get current cart count
  int get currentCartCount => cartBadgeCount.value;
  
  /// Check if cart has items
  bool get hasItems => cartBadgeCount.value > 0;
}
