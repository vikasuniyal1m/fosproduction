import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';
import '../utils/product_details_navigation.dart';

/// Cart Controller
/// Handles cart logic and API calls
class CartController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> cartItems = <Map<String, dynamic>>[].obs;
  final RxDouble subtotal = 0.0.obs;
  final RxInt totalItems = 0.obs;
  final ApiService _apiService = ApiService();
  final RxBool isRefreshing = false.obs;
  final RxString lastError = ''.obs;
  Timer? _refreshTimer;
  
  /// Calculate subtotal and totalItems from local cached items
  void _calculateCartSummaryFromCache() {
    double sub = 0.0;
    int total = 0;
    for (var item in cartItems) {
      sub += (item['item_total'] as num?)?.toDouble() ?? 0.0;
      total += (item['quantity'] as num?)?.toInt() ?? 0;
    }
    subtotal.value = sub;
    totalItems.value = total;
  }

  @override
  void onInit() {
    super.onInit();
    
    // Load cached cart items for instant smooth loading
    final cached = CacheManager.getCartItems();
    if (cached != null) {
      cartItems.value = cached;
      _calculateCartSummaryFromCache();
    }
    
    // Only load cart if user is logged in
    if (CacheManager.isLoggedIn()) {
      loadCart();
    } else {
      isLoading.value = false;
      cartItems.value = [];
      subtotal.value = 0.0;
      totalItems.value = 0;
    }
  }
  
  @override
  void onReady() {
    super.onReady();
    // Reload cart when screen becomes ready (in case data changed)
    loadCart();
    // Start periodic refresh for real-time updates
    _startPeriodicRefresh();
  }
  
  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
  
  /// Start periodic cart refresh for real-time updates
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (CacheManager.isLoggedIn() && !isLoading.value) {
        refreshCartSilently();
      }
    });
  }
  
  /// Refresh cart silently without loading indicators
  Future<void> refreshCartSilently() async {
    if (isRefreshing.value) return;
    
    isRefreshing.value = true;
    try {
      await _loadCartFromAPI();
      lastError.value = '';
    } catch (e) {
      print('[Cart] Silent refresh error: $e');
      lastError.value = e.toString();
    } finally {
      isRefreshing.value = false;
    }
  }
  
  /// Force refresh cart with loading indicator
  Future<void> forceRefreshCart() async {
    if (isLoading.value) return;
    
    await loadCart();
  }
  
  /// Load cart from API (extracted for reuse)
  Future<void> _loadCartFromAPI() async {
    // Check if user is logged in and has valid token
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Cart] _loadCartFromAPI auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      print('[Cart] User not authenticated, clearing cart');
      cartItems.value = [];
      subtotal.value = 0.0;
      totalItems.value = 0;
      return;
    }
    
    try {
      print('[Cart] Loading cart from API...');
      final response = await _apiService.get(ApiEndpoints.cartList);
      final data = ApiService.handleResponse(response);
      
      print('[Cart] API Response received. Items count: ${(data['items'] ?? []).length}');
      
      // Format cart items
      final items = data['items'] ?? [];
      print('[Cart] Processing ${items.length} items from API');
      
      cartItems.value = items.map<Map<String, dynamic>>((item) {
        // Get image from either 'image' or 'product_image' field
        final imagePath = item['image'] ?? item['product_image'] ?? '';
        print('[Cart] Item ${item['id']}: ${item['product_name']}, Image: $imagePath');
        
        return {
          'id': item['id'],
          'product_id': item['product_id'],
          'product_name': item['product_name'] ?? '',
          'product_slug': item['product_slug'] ?? '',
          'quantity': item['quantity'] ?? 1,
          'size': item['size'],
          'color': item['color'],
          'variant_id': item['variant_id'],
          'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          'item_total': double.tryParse(item['item_total']?.toString() ?? '0') ?? 0.0,
          'image': _getImageUrl(imagePath),
          'stock_quantity': item['stock_quantity'] ?? 0,
          'in_stock': item['in_stock'] ?? true,
        };
      }).toList();
      CacheManager.saveCartItems(cartItems.toList());
      
      print('[Cart] Formatted ${cartItems.length} items');
      
      // Update summary
      final summary = data['summary'] ?? {};
      subtotal.value = double.tryParse(summary['subtotal']?.toString() ?? '0') ?? 0.0;
      totalItems.value = int.tryParse(summary['total_items']?.toString() ?? '0') ?? 0;
      
      print('[Cart] Summary - Subtotal: ${subtotal.value}, Total Items: ${totalItems.value}');
    } catch (e) {
      print('[Cart] Error loading cart: $e');
      // Check if it's a 401 error (unauthorized)
      if (e is DioException && e.response?.statusCode == 401) {
        print('[Cart] 401 Unauthorized - clearing cart and redirecting to login');
        cartItems.value = [];
        subtotal.value = 0.0;
        totalItems.value = 0;
        // Clear invalid token and redirect to login
        CacheManager.clearUserData();
        Get.offAllNamed(AppRoutes.login);
      } else {
        // For other errors, keep existing cart data but show error message
        print('[Cart] Non-401 error, keeping existing cart data');
        rethrow; // Re-throw to handle in calling method
      }
    }
  }
  
  /// Load cart items
  Future<void> loadCart() async {
    if (isLoading.value) return;
    
    // Only show loading spinner if we don't have any cached items
    if (cartItems.isEmpty) {
      isLoading.value = true;
    }
    try {
      await _loadCartFromAPI();
      lastError.value = '';
    } catch (e) {
      print('[Cart] Error in loadCart: $e');
      lastError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Get full image URL
  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${ApiService.imageBaseUrl}$imagePath';
  }
  
  /// Add product to cart
  Future<bool> addToCart({
    required int productId,
    int quantity = 1,
    String? size,
    String? color,
    int? variantId,
  }) async {
    // Check if user is logged in and has valid token
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Cart] Auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      print('[Cart] User not authenticated, redirecting to login');
      // Get.snackbar(
      //   'Login Required',
      //   'Please login to add items to cart',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      // Navigate to login
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.toLogin();
      return false;
    }
    
    // Token validation removed - tokens should only expire on logout
    // Server-side issue: tokens expiring too quickly (15-30 min)
    // Let user continue using app until they manually logout
    print('[Cart] Proceeding with API call - token validation disabled');

    // Check if product is digital (category_id 15 for sticker packs)
    try {
      final productResponse = await _apiService.get(
        ApiEndpoints.productDetails,
        queryParameters: {'id': productId},
      );
      final productData = ApiService.handleResponse(productResponse);
      final categoryId = productData['category_id'];
      
      // Digital product categories: 15 (sticker packs)
      if (categoryId == 15) {
        // Get.snackbar(
        //   'Digital Product',
        //   'Digital products cannot be added to cart. Please purchase directly.',
        //   snackPosition: SnackPosition.BOTTOM,
        // );
        return false;
      }
    } catch (e) {
      print('[Cart] Error checking product category: $e');
      // Continue with add to cart if category check fails
    }
    
    try {
      print('[Cart] Adding to cart - Product ID: $productId, Quantity: $quantity, Size: $size, Color: $color');
      
      final response = await _apiService.post(
        ApiEndpoints.cartAdd,
        data: {
          'product_id': productId,
          'quantity': quantity,
          if (size != null && size.isNotEmpty) 'size': size,
          if (color != null && color.isNotEmpty) 'color': color,
          if (variantId != null && variantId > 0) 'variant_id': variantId,
        },
      );
      
      final data = ApiService.handleResponse(response);
      print('[Cart] Add to cart response: $data');
      
      // Always reload cart to get fresh data from database
      await loadCart();
      
      print('[Cart] Cart reloaded. Total items: ${totalItems.value}');
      
      Get.snackbar(
        'Success',
        'Product added to cart successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      return true;
    } catch (e) {
      print('[Cart] Error adding to cart: $e');
      // Use showErrorSnackbar which handles 401 redirects and hides server errors
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Update cart item quantity
  Future<bool> updateQuantity(int cartItemId, int quantity) async {
    // Check if user is logged in and has valid token
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Cart] UpdateQuantity auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      print('[Cart] User not authenticated, cannot update quantity');
      ApiService.showErrorSnackbar(Exception('Authentication required'));
      return false;
    }
    
    if (quantity <= 0) {
      return await removeFromCart(cartItemId);
    }
    
    // Optimistic update - update UI immediately
    final itemIndex = cartItems.indexWhere((item) => item['id'] == cartItemId);
    if (itemIndex == -1) {
      return false;
    }
    
    final oldQuantity = cartItems[itemIndex]['quantity'] as int;
    final price = (cartItems[itemIndex]['price'] as num).toDouble();
    final previousQuantity = oldQuantity; // Store for potential revert
    
    // Update quantity in local state immediately
    cartItems[itemIndex] = {
      ...cartItems[itemIndex],
      'quantity': quantity,
    };
    
    // Update subtotal immediately
    final quantityDiff = quantity - oldQuantity;
    subtotal.value = subtotal.value + (price * quantityDiff);
    totalItems.value = totalItems.value + quantityDiff;
    
    // Force reactive update
    cartItems.refresh();
    
    try {
      // Sync with server in background
      final response = await _apiService.put(
        ApiEndpoints.cartUpdate,
        data: {
          'cart_item_id': cartItemId,
          'quantity': quantity,
        },
      );
      
      ApiService.handleResponse(response);
      
      // Reload cart in background to sync any server-side changes (like price updates)
      loadCart().catchError((e) {
        print('[Cart] Error reloading cart after quantity update: $e');
        // Don't show error to user, optimistic update already applied
      });
      
      return true;
    } catch (e) {
      // Revert optimistic update on error
      cartItems[itemIndex] = {
        ...cartItems[itemIndex],
        'quantity': previousQuantity,
      };
      
      final revertDiff = previousQuantity - quantity;
      subtotal.value = subtotal.value + (price * revertDiff);
      totalItems.value = totalItems.value + revertDiff;
      cartItems.refresh();
      
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Remove item from cart
  Future<bool> removeFromCart(int cartItemId) async {
    // Check if user is logged in and has valid token
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Cart] RemoveFromCart auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      print('[Cart] User not authenticated, cannot remove from cart');
      ApiService.showErrorSnackbar(Exception('Authentication required'));
      return false;
    }
    
    try {
      final response = await _apiService.delete(
        ApiEndpoints.cartRemove,
        queryParameters: {'id': cartItemId.toString()},
      );
      
      ApiService.handleResponse(response);
      
      // Always reload cart to get fresh data
      await loadCart();
      
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Clear entire cart
  Future<bool> clearCart() async {
    try {
      final response = await _apiService.delete(ApiEndpoints.cartClear);
      ApiService.handleResponse(response);
      
      // Update count immediately
      totalItems.value = 0;
      cartItems.clear();
      subtotal.value = 0.0;
      CacheManager.saveCartItems([]);
      
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Increase quantity
  Future<void> increaseQuantity(int cartItemId, int currentQuantity, int stockQuantity) async {
    if (currentQuantity < stockQuantity) {
      await updateQuantity(cartItemId, currentQuantity + 1);
    } else {
      // Get.snackbar('Info', 'Maximum stock reached');
    }
  }
  
  /// Decrease quantity
  Future<void> decreaseQuantity(int cartItemId, int currentQuantity) async {
    if (currentQuantity > 1) {
      await updateQuantity(cartItemId, currentQuantity - 1);
    } else {
      await removeFromCart(cartItemId);
    }
  }
  
  /// Get cart item count (for badge)
  int get cartItemCount => totalItems.value;
  
  /// Check if cart is empty
  bool get isCartEmpty => cartItems.isEmpty;
  
  /// Navigate to product details
  void navigateToProductDetails(
    int productId, {
    Map<String, dynamic>? preview,
  }) {
    Map<String, dynamic>? item = preview;
    item ??= cartItems.firstWhereOrNull((i) => i['product_id'] == productId);
    if (item != null && !item.containsKey('name')) {
      item = {
        'id': productId,
        'name': item['product_name'] ?? '',
        'price': item['price'] ?? 0.0,
        'image': item['image'] ?? '',
      };
    }
    ProductDetailsNavigation.go(id: productId, preview: item);
  }
  
  /// Navigate to checkout
  void navigateToCheckout() {
    // Check if user is logged in
    if (!CacheManager.isLoggedIn()) {
      // Get.snackbar(
      //   'Login Required',
      //   'Please login to proceed with checkout',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      // Navigate to login
      Future.delayed(const Duration(milliseconds: 500), () {
        AppRoutes.toLogin();
      });
      return;
    }
    if (cartItems.isEmpty) {
      // Get.snackbar('Info', 'Your cart is empty');
      return;
    }
    Get.toNamed('/checkout');
  }
}

