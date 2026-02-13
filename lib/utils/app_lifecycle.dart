import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../controllers/cart_controller.dart';
import '../controllers/wishlist_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/search_controller.dart' as search_ctrl;
import 'cache_manager.dart';
import '../routes/app_routes.dart';

/// App Lifecycle Manager
/// Handles app lifecycle events like Play Store apps
/// Manages app state, background/foreground transitions, etc.
class AppLifecycleManager extends GetxController with WidgetsBindingObserver {
  static final AppLifecycleManager instance = AppLifecycleManager._internal();
  
  AppLifecycleManager._internal();
  
  // Observable states
  final Rx<AppLifecycleState> currentState = AppLifecycleState.resumed.obs;
  final RxBool isAppInForeground = true.obs;
  final RxBool isAppInBackground = false.obs;
  final RxBool isAppPaused = false.obs;
  
  // Timestamps
  DateTime? _lastPausedTime;
  DateTime? _lastResumedTime;
  
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }
  
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
  
  /// Initialize app lifecycle
  void _initializeApp() {
    currentState.value = AppLifecycleState.resumed;
    isAppInForeground.value = true;
    isAppInBackground.value = false;
    isAppPaused.value = false;
    
    // Restore app state on startup (in case of process death)
    _restoreAppState();
  }
  
  /// Restore app state on startup
  /// 
  /// This method is called when the app initializes. It restores any saved state
  /// that was persisted before the app was killed by the OS (process death).
  Future<void> _restoreAppState() async {
    try {
      final box = Hive.box('appState');
      
      // TEMPORARILY DISABLED: State restoration to prevent old UI from showing
      // Clear any saved state to ensure fresh start
      await _clearSavedState();
      return; // Skip state restoration for now
      
      // Check if there's saved state (only restore if app was killed, not on normal startup)
      final hasSavedState = box.get('has_saved_state', defaultValue: false) as bool;
      if (!hasSavedState) {
        return; // No saved state, normal app startup
      }
      
      // Check if saved state is too old (more than 24 hours)
      final savedTimestamp = box.get('saved_timestamp') as int?;
      if (savedTimestamp != null) {
        final savedTime = DateTime.fromMillisecondsSinceEpoch(savedTimestamp);
        final now = DateTime.now();
        if (now.difference(savedTime).inHours > 24) {
          // State is too old, clear it
          await _clearSavedState();
          return;
        }
      }
      
      debugPrint('[AppLifecycle] Restoring app state from process death...');
      
      // Restore navigation state (do this last, after controllers are ready)
      await Future.delayed(const Duration(milliseconds: 800), () async {
        await _restoreNavigationState();
      });
      
      // Restore cart state
      await _restoreCartState();
      
      // Restore wishlist state
      await _restoreWishlistState();
      
      // Restore checkout state
      await _restoreCheckoutState();
      
      // Restore search state
      await _restoreSearchState();
      
      debugPrint('[AppLifecycle] App state restored successfully');
    } catch (e) {
      debugPrint('[AppLifecycle] Error restoring app state: $e');
    }
  }
  
  /// Restore navigation state
  Future<void> _restoreNavigationState() async {
    try {
      final box = Hive.box('appState');
      final lastRoute = box.get('last_route') as String?;
      
      if (lastRoute != null && lastRoute.isNotEmpty) {
        // Don't restore to splash or login if user is logged in
        if (lastRoute == AppRoutes.splash || lastRoute == AppRoutes.onboarding) {
          return;
        }
        
        // Don't restore to login if user is already logged in
        if (lastRoute == AppRoutes.login && CacheManager.isLoggedIn()) {
          // Restore to home instead
          Future.delayed(const Duration(milliseconds: 300), () {
            Get.offAllNamed(AppRoutes.home);
          });
          return;
        }
        
        debugPrint('[AppLifecycle] Restoring navigation to: $lastRoute');
        
        // Navigate to last route after ensuring app is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAllNamed(lastRoute);
        });
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error restoring navigation state: $e');
    }
  }
  
  /// Restore cart state
  Future<void> _restoreCartState() async {
    try {
      final box = Hive.box('appState');
      final cartData = box.get('cart_data');
      
      if (cartData != null && cartData is List) {
        // Cart will be loaded from API when CartController initializes
        // We just mark that we need to restore it
        debugPrint('[AppLifecycle] Cart state found, will be restored by CartController');
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error restoring cart state: $e');
    }
  }
  
  /// Restore wishlist state
  Future<void> _restoreWishlistState() async {
    try {
      final box = Hive.box('appState');
      final wishlistData = box.get('wishlist_data');
      
      if (wishlistData != null && wishlistData is List) {
        // Wishlist will be loaded from API when WishlistController initializes
        debugPrint('[AppLifecycle] Wishlist state found, will be restored by WishlistController');
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error restoring wishlist state: $e');
    }
  }
  
  /// Restore checkout state
  Future<void> _restoreCheckoutState() async {
    try {
      final box = Hive.box('appState');
      final checkoutData = box.get('checkout_data');
      
      if (checkoutData != null && checkoutData is Map) {
        // Restore checkout state if CheckoutController is registered
        if (Get.isRegistered<CheckoutController>()) {
          final checkoutController = Get.find<CheckoutController>();
          final selectedAddressId = checkoutData['selected_address_id'] as int?;
          final selectedPaymentMethodId = checkoutData['selected_payment_method_id'] as int?;
          final couponCode = checkoutData['coupon_code'] as String?;
          final notes = checkoutData['notes'] as String?;
          
          if (selectedAddressId != null && selectedAddressId > 0) {
            checkoutController.selectedAddressId.value = selectedAddressId;
          }
          if (selectedPaymentMethodId != null && selectedPaymentMethodId > 0) {
            checkoutController.selectedPaymentMethodId.value = selectedPaymentMethodId;
          }
          if (couponCode != null && couponCode.isNotEmpty) {
            checkoutController.couponCode.value = couponCode;
            // Re-apply coupon
            await checkoutController.applyCoupon(couponCode);
          }
          if (notes != null && notes.isNotEmpty) {
            checkoutController.notes.value = notes;
          }
          
          debugPrint('[AppLifecycle] Checkout state restored');
        }
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error restoring checkout state: $e');
    }
  }
  
  /// Restore search state
  Future<void> _restoreSearchState() async {
    try {
      final box = Hive.box('appState');
      final searchQuery = box.get('search_query') as String?;
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Restore search query if SearchController is registered
        if (Get.isRegistered<search_ctrl.SearchController>()) {
          final searchController = Get.find<search_ctrl.SearchController>();
          searchController.searchQuery.value = searchQuery;
          debugPrint('[AppLifecycle] Search state restored: $searchQuery');
        }
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error restoring search state: $e');
    }
  }
  
  /// Clear saved state
  Future<void> _clearSavedState() async {
    try {
      final box = Hive.box('appState');
      await box.delete('has_saved_state');
      await box.delete('saved_timestamp');
      await box.delete('last_route');
      await box.delete('cart_data');
      await box.delete('wishlist_data');
      await box.delete('checkout_data');
      await box.delete('search_query');
      debugPrint('[AppLifecycle] Cleared old saved state');
    } catch (e) {
      debugPrint('[AppLifecycle] Error clearing saved state: $e');
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    currentState.value = state;
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }
  
  /// App resumed (came to foreground)
  void _onAppResumed() {
    isAppInForeground.value = true;
    isAppInBackground.value = false;
    isAppPaused.value = false;
    _lastResumedTime = DateTime.now();
    
    // Calculate time spent in background
    if (_lastPausedTime != null) {
      final duration = _lastResumedTime!.difference(_lastPausedTime!);
      _handleBackgroundDuration(duration);
    }
    
    // Refresh data if needed
    _refreshAppData();
  }
  
  /// App inactive (transitioning)
  void _onAppInactive() {
    // App is transitioning between states
  }
  
  /// App paused (went to background)
  void _onAppPaused() {
    isAppInForeground.value = false;
    isAppInBackground.value = true;
    isAppPaused.value = true;
    _lastPausedTime = DateTime.now();
    
    // Save important data
    _saveAppState();
  }
  
  /// App detached (terminated)
  void _onAppDetached() {
    isAppInForeground.value = false;
    isAppInBackground.value = true;
    _saveAppState();
  }
  
  /// App hidden (iOS specific)
  void _onAppHidden() {
    isAppInForeground.value = false;
    isAppInBackground.value = true;
    _saveAppState();
  }
  
  /// Handle duration spent in background
  void _handleBackgroundDuration(Duration duration) {
    // If app was in background for more than 5 minutes, refresh data
    if (duration.inMinutes > 5) {
      _refreshAppData();
    }
  }
  
  /// Refresh app data when coming back to foreground
  void _refreshAppData() {
    // Override this in your controllers to refresh data
    // Example: CartController.instance.refreshCart();
  }
  
  /// Save app state before going to background
  /// 
  /// This method is called when the app enters the paused state (e.g., user presses home button).
  /// This is the critical hook where state persistence logic prevents data loss if the OS
  /// kills the app process due to memory constraints.
  void _saveAppState() {
    // Run asynchronously to avoid blocking
    Future.microtask(() async {
      try {
        final box = Hive.box('appState');
        
        debugPrint('[AppLifecycle] Saving app state...');
        
        // Save timestamp
        await box.put('saved_timestamp', DateTime.now().millisecondsSinceEpoch);
        await box.put('has_saved_state', true);
        
        // Save navigation state
        await _saveNavigationState();
        
        // Save cart state
        await _saveCartState();
        
        // Save wishlist state
        await _saveWishlistState();
        
        // Save checkout state
        await _saveCheckoutState();
        
        // Save search state
        await _saveSearchState();
        
        debugPrint('[AppLifecycle] App state saved successfully');
      } catch (e) {
        debugPrint('[AppLifecycle] Error saving app state: $e');
      }
    });
  }
  
  /// Save navigation state
  Future<void> _saveNavigationState() async {
    try {
      final box = Hive.box('appState');
      final currentRoute = Get.currentRoute;
      
      // Don't save splash or onboarding routes
      if (currentRoute != AppRoutes.splash && currentRoute != AppRoutes.onboarding) {
        await box.put('last_route', currentRoute);
        debugPrint('[AppLifecycle] Saved navigation state: $currentRoute');
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error saving navigation state: $e');
    }
  }
  
  /// Save cart state
  Future<void> _saveCartState() async {
    try {
      if (Get.isRegistered<CartController>()) {
        final cartController = Get.find<CartController>();
        final box = Hive.box('appState');
        
        // Save cart items
        final cartData = cartController.cartItems.map((item) => {
          'id': item['id'],
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'size': item['size'],
          'color': item['color'],
          'variant_id': item['variant_id'],
        }).toList();
        
        await box.put('cart_data', cartData);
        debugPrint('[AppLifecycle] Saved cart state: ${cartData.length} items');
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error saving cart state: $e');
    }
  }
  
  /// Save wishlist state
  Future<void> _saveWishlistState() async {
    try {
      if (Get.isRegistered<WishlistController>()) {
        final wishlistController = Get.find<WishlistController>();
        final box = Hive.box('appState');
        
        // Save wishlist items (just product IDs for efficiency)
        final wishlistData = wishlistController.wishlistItems.map((item) => {
          'id': item['id'],
          'product_id': item['id'], // product_id is same as id in wishlist
        }).toList();
        
        await box.put('wishlist_data', wishlistData);
        debugPrint('[AppLifecycle] Saved wishlist state: ${wishlistData.length} items');
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error saving wishlist state: $e');
    }
  }
  
  /// Save checkout state
  Future<void> _saveCheckoutState() async {
    try {
      if (Get.isRegistered<CheckoutController>()) {
        final checkoutController = Get.find<CheckoutController>();
        final box = Hive.box('appState');
        
        // Save checkout form state
        final checkoutData = {
          'selected_address_id': checkoutController.selectedAddressId.value,
          'selected_payment_method_id': checkoutController.selectedPaymentMethodId.value,
          'coupon_code': checkoutController.couponCode.value,
          'notes': checkoutController.notes.value,
        };
        
        await box.put('checkout_data', checkoutData);
        debugPrint('[AppLifecycle] Saved checkout state');
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error saving checkout state: $e');
    }
  }
  
  /// Save search state
  Future<void> _saveSearchState() async {
    try {
      if (Get.isRegistered<search_ctrl.SearchController>()) {
        final searchController = Get.find<search_ctrl.SearchController>();
        final box = Hive.box('appState');
        
        // Save search query
        if (searchController.searchQuery.value.isNotEmpty) {
          await box.put('search_query', searchController.searchQuery.value);
          debugPrint('[AppLifecycle] Saved search state: ${searchController.searchQuery.value}');
        }
      }
    } catch (e) {
      debugPrint('[AppLifecycle] Error saving search state: $e');
    }
  }
  
  /// Check if app is currently in foreground
  bool get isForeground => isAppInForeground.value;
  
  /// Check if app is currently in background
  bool get isBackground => isAppInBackground.value;
  
  /// Get time spent in background (if available)
  Duration? get backgroundDuration {
    if (_lastPausedTime != null && _lastResumedTime != null) {
      return _lastResumedTime!.difference(_lastPausedTime!);
    }
    return null;
  }
}

