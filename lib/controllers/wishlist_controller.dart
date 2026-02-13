import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';
import 'cart_controller.dart';

/// Wishlist Controller
/// Handles wishlist logic and API calls
class WishlistController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> wishlistItems = <Map<String, dynamic>>[].obs;
  final ApiService _apiService = ApiService();
  
  @override
  void onInit() {
    super.onInit();
    // Only load wishlist if user is logged in
    if (CacheManager.isLoggedIn()) {
      loadWishlist();
    } else {
      isLoading.value = false;
      wishlistItems.value = [];
    }
  }
  
  /// Load wishlist items
  Future<void> loadWishlist() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get(ApiEndpoints.wishlistList);
      final data = ApiService.handleResponse(response);
      
      // Format wishlist items
      final items = data['items'] ?? [];
      wishlistItems.value = items.map<Map<String, dynamic>>((item) {
        // Use product_id if available, otherwise use id
        final productId = item['product_id'] ?? item['id'];
        return {
          'id': productId, // Store product ID for checking
          'wishlist_id': item['wishlist_id'] ?? item['id'],
          'name': item['name'] ?? '',
          'slug': item['slug'] ?? '',
          'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          'originalPrice': item['originalPrice'] != null 
              ? double.tryParse(item['originalPrice']?.toString() ?? '0') 
              : null,
          'image': _getImageUrl(item['image'] ?? ''),
          'rating': double.tryParse(item['rating']?.toString() ?? '0') ?? 0.0,
          'review_count': int.tryParse(item['review_count']?.toString() ?? '0') ?? 0,
          'reviews': int.tryParse(item['reviews']?.toString() ?? item['review_count']?.toString() ?? '0') ?? 0,
          'inStock': item['inStock'] ?? true,
          'stock_quantity': int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0,
          'short_description': item['short_description'] ?? '',
          'is_featured': item['is_featured'] ?? false,
          'added_at': item['added_at'],
        };
      }).toList();
    } catch (e) {
      // Check if it's a 401 error (unauthorized) - don't show error
      if (e is DioException && e.response?.statusCode == 401) {
        // User not logged in, just clear wishlist
        wishlistItems.value = [];
      } else {
        ApiService.showErrorSnackbar(e);
        wishlistItems.value = [];
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
  
  /// Add product to wishlist
  Future<bool> addToWishlist(int productId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.wishlistAdd,
        data: {'product_id': productId},
      );
      
      ApiService.handleResponse(response);
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Remove item from wishlist
  Future<bool> removeFromWishlist(int productId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.wishlistRemove,
        data: {'product_id': productId},
      );
      
      ApiService.handleResponse(response);
      
      // Remove from local list
      wishlistItems.removeWhere((item) => item['id'] == productId);
      
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Check if product is in wishlist
  bool isInWishlist(int productId) {
    return wishlistItems.any((item) => item['id'] == productId);
  }
  
  /// Toggle wishlist (add if not present, remove if present) - Fast response with optimistic updates
  Future<bool> toggleWishlist(int productId) async {
    // Check if user is logged in
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar(
        'Login Required',
        'Please login to add items to wishlist',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Navigate to login
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.toLogin();
      return false;
    }
    
    // Quick check - don't wait for wishlist to load if empty
    final wasInWishlist = isInWishlist(productId);
    
    // Optimistically update local list immediately for instant UI response
    if (wasInWishlist) {
      wishlistItems.removeWhere((item) => item['id'] == productId);
    }
    
    try {
      bool success;
      if (wasInWishlist) {
        // Remove from wishlist
        success = await removeFromWishlist(productId);
        // Already removed from local list above, no need to reload
      } else {
        // Add to wishlist
        success = await addToWishlist(productId);
        if (success) {
          // Reload wishlist in background (non-blocking) to sync state
          loadWishlist(); // Don't await - let it run in background
        } else {
          // Revert on failure
          await loadWishlist();
        }
      }
      
      if (!success && wasInWishlist) {
        // Revert on failure - reload to restore state
        await loadWishlist();
      }
      
      return success;
    } catch (e) {
      // Revert on error
      if (wasInWishlist) {
        await loadWishlist();
      } else {
        wishlistItems.removeWhere((item) => item['id'] == productId);
      }
      rethrow;
    }
  }
  
  /// Navigate to product details
  void navigateToProductDetails(int productId) {
    Get.toNamed('/product-details', arguments: productId);
  }
  
  /// Add to cart
  Future<void> addToCart(int productId) async {
    // Get cart controller
    CartController cartController;
    if (Get.isRegistered<CartController>()) {
      cartController = Get.find<CartController>();
    } else {
      cartController = Get.put(CartController());
    }
    
    // Add to cart
    final success = await cartController.addToCart(productId: productId);
    
    if (success) {
      Get.snackbar('Success', 'Product added to cart');
    }
  }
  
  /// Clear wishlist
  Future<bool> clearWishlist() async {
    try {
      final response = await _apiService.post(ApiEndpoints.wishlistClear);
      ApiService.handleResponse(response);
      
      wishlistItems.clear();
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
}

