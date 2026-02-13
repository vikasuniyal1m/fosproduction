import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';

/// Cart Controller
/// Handles cart logic and API calls
class CartController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> cartItems = <Map<String, dynamic>>[].obs;
  final RxDouble subtotal = 0.0.obs;
  final RxInt totalItems = 0.obs;
  final ApiService _apiService = ApiService();
  
  @override
  void onInit() {
    super.onInit();
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
  }
  
  /// Load cart items
  Future<void> loadCart() async {
    isLoading.value = true;
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
        // Don't show error, just clear cart (user not logged in)
        cartItems.value = [];
        subtotal.value = 0.0;
        totalItems.value = 0;
      } else {
        // Only show error for non-401 errors
        final errorMessage = ApiService.handleError(e);
        // Don't show server errors (500+) as snackbar
        if (e is DioException && e.response?.statusCode != null && e.response!.statusCode! < 500) {
          Get.snackbar('Error', errorMessage);
        }
      }
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
    // Check if user is logged in
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar(
        'Login Required',
        'Please login to add items to cart',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Navigate to login
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.toLogin();
      return false;
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
      Get.snackbar('Info', 'Maximum stock reached');
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
  void navigateToProductDetails(int productId) {
    Get.toNamed('/product-details', arguments: productId);
  }
  
  /// Navigate to checkout
  void navigateToCheckout() {
    // Check if user is logged in
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar(
        'Login Required',
        'Please login to proceed with checkout',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Navigate to login
      Future.delayed(const Duration(milliseconds: 500), () {
        AppRoutes.toLogin();
      });
      return;
    }
    if (cartItems.isEmpty) {
      Get.snackbar('Info', 'Your cart is empty');
      return;
    }
    Get.toNamed('/checkout');
  }
}

