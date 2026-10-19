import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';
import '../utils/product_details_navigation.dart';
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
    
    // Load cached items immediately for smooth UI rendering
    final cached = CacheManager.getWishlistItems();
    if (cached != null) {
      wishlistItems.value = cached
          .map((e) => _formatWishlistItem(Map<String, dynamic>.from(e)))
          .toList();
    }
    
    // Only load wishlist if user is logged in and has valid token
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Wishlist] Init auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (isLoggedIn && userToken != null && userToken.isNotEmpty) {
      loadWishlist();
    } else {
      print('[Wishlist] User not authenticated, skipping wishlist load');
      isLoading.value = false;
      wishlistItems.value = [];
    }
  }
  
  /// Load wishlist items
  Future<void> loadWishlist() async {
    // Check authentication before loading
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Wishlist] LoadWishlist auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      print('[Wishlist] User not authenticated, cannot load wishlist');
      isLoading.value = false;
      wishlistItems.value = [];
      return;
    }
    
    // Only show loading spinner if we don't have any cached items
    if (wishlistItems.isEmpty) {
      isLoading.value = true;
    }
    try {
      final response = await _apiService.get(ApiEndpoints.wishlistList);
      final data = ApiService.handleResponse(response);
      
      final items = data['items'] ?? [];
      wishlistItems.value = items
          .map<Map<String, dynamic>>(
            (item) => _formatWishlistItem(Map<String, dynamic>.from(item)),
          )
          .toList();
      CacheManager.saveWishlistItems(wishlistItems.toList());
    } catch (e) {
      // Check if it's a 401 error (unauthorized) - don't show error
      if (e is DioException && e.response?.statusCode == 401) {
        // User not logged in, just clear wishlist
        wishlistItems.value = [];
      } else if (e.toString().contains('Unknown column')) {
        // Database column error - handle gracefully
        print('Wishlist API Error: Database schema issue - $e');
        wishlistItems.value = [];
        // Don't show error to user for backend issues
      } else {
        ApiService.showErrorSnackbar(e);
        wishlistItems.value = [];
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  Map<String, dynamic> _formatWishlistItem(Map<String, dynamic> item) {
    final productId = item['product_id'] ?? item['id'];

    String imageUrl = '';
    for (final key in ['image', 'product_image', 'main_image']) {
      final v = item[key];
      if (v != null && v.toString().isNotEmpty) {
        imageUrl = _getImageUrl(v.toString());
        break;
      }
    }
    if (imageUrl.isEmpty && item['images'] is List) {
      final images = item['images'] as List;
      if (images.isNotEmpty) {
        final first = images.first;
        if (first is String) {
          imageUrl = _getImageUrl(first);
        } else if (first is Map) {
          imageUrl = _getImageUrl(
            first['url']?.toString() ??
                first['image']?.toString() ??
                first['image_url']?.toString() ??
                '',
          );
        }
      }
    }

    var isDigital = item['is_digital'] == true ||
        item['is_digital'] == 1 ||
        item['is_digital'] == '1' ||
        item['is_digital']?.toString() == 'true';

    String bannerUrl = '';
    if (item['banner'] != null && item['banner'].toString().isNotEmpty) {
      bannerUrl = _getImageUrl(item['banner'].toString());
    }

    String mediaType = item['media_type']?.toString() ?? '';
    final categoryId = item['category_id'] ??
        (item['category'] is Map ? item['category']['id'] : null);

    final cid = categoryId != null
        ? int.tryParse(categoryId.toString()) ?? 0
        : 0;
    if (mediaType.isEmpty && cid > 0) {
      if (cid == 12) mediaType = 'audio';
      if (cid == 13) mediaType = 'video';
      if (cid == 15) mediaType = 'sticker';
    }
    if (!isDigital && (cid == 12 || cid == 13 || cid == 15)) {
      isDigital = true;
    }
    if (!isDigital &&
        (mediaType == 'audio' ||
            mediaType == 'video' ||
            mediaType == 'sticker' ||
            mediaType == 'sticker_pack')) {
      isDigital = true;
    }

    return {
      'id': productId,
      'wishlist_id': item['wishlist_id'] ?? item['id'],
      'name': item['name'] ?? '',
      'slug': item['slug'] ?? '',
      'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
      'originalPrice': item['originalPrice'] != null
          ? double.tryParse(item['originalPrice']?.toString() ?? '0')
          : null,
      'image': imageUrl,
      'banner': bannerUrl,
      'rating': double.tryParse(item['rating']?.toString() ?? '0') ?? 0.0,
      'review_count':
          int.tryParse(item['review_count']?.toString() ?? '0') ?? 0,
      'reviews': int.tryParse(
            item['reviews']?.toString() ??
                item['review_count']?.toString() ??
                '0',
          ) ??
          0,
      'inStock': item['inStock'] ?? true,
      'stock_quantity':
          int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0,
      'short_description': item['short_description'] ?? '',
      'is_featured': item['is_featured'] ?? false,
      'is_digital': isDigital,
      'is_sticker_pack':
          item['is_sticker_pack'] == true || item['is_sticker_pack'] == 1,
      'product_type': item['product_type']?.toString() ?? '',
      'media_type': mediaType,
      'category_id': categoryId,
      'added_at': item['added_at'],
    };
  }

  /// Get full image URL
  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    String cleanUrl = imagePath.replaceAll('\\/', '/').trim();
    cleanUrl = cleanUrl.replaceAll(
      'https://ecommercepanel.templateforwebsites.com/',
      'https://admin.fosproductions.org/',
    );

    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return cleanUrl;
    }

    final cleanPath =
        cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;

    if (cleanPath.contains('products/') || cleanPath.contains('uploads/')) {
      if (cleanPath.startsWith('uploads/') &&
          ApiService.imageBaseUrl.endsWith('uploads/')) {
        return '${ApiService.imageBaseUrl.replaceAll('uploads/', '')}$cleanPath';
      }
      return '${ApiService.imageBaseUrl}$cleanPath';
    }

    return '${ApiService.imageBaseUrl}products/$cleanPath';
  }
  
  /// Add product to wishlist
  Future<bool> addToWishlist(int productId) async {
    // Check authentication before adding
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Wishlist] AddToWishlist auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      print('[Wishlist] User not authenticated, cannot add to wishlist');
      ApiService.showErrorSnackbar(Exception('Authentication required'));
      return false;
    }
    
    try {
      final response = await _apiService.post(
        ApiEndpoints.wishlistAdd,
        data: {'product_id': productId},
      );
      
      ApiService.handleResponse(response);
      CacheManager.saveWishlistItems(wishlistItems.toList());
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Remove item from wishlist
  Future<bool> removeFromWishlist(int productId) async {
    // Check authentication before removing
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Wishlist] RemoveFromWishlist auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      print('[Wishlist] User not authenticated, cannot remove from wishlist');
      ApiService.showErrorSnackbar(Exception('Authentication required'));
      return false;
    }
    
    try {
      final response = await _apiService.post(
        ApiEndpoints.wishlistRemove,
        data: {'product_id': productId},
      );
      
      ApiService.handleResponse(response);
      
      // Remove from local list
      wishlistItems.removeWhere((item) => item['id'] == productId);
      CacheManager.saveWishlistItems(wishlistItems.toList());
      
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Check if product is in wishlist
  bool isInWishlist(int productId) {
    return wishlistItems.any((item) {
      final id = item['id'];
      if (id is int) return id == productId;
      return int.tryParse(id?.toString() ?? '') == productId;
    });
  }
  
  /// Toggle wishlist (add if not present, remove if present) - Fast response with optimistic updates
  Future<bool> toggleWishlist(int productId) async {
    // Check if user is logged in and has valid token
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Wishlist] ToggleWishlist auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      print('[Wishlist] User not authenticated, cannot toggle wishlist');
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
    } else {
      wishlistItems.add({
        'id': productId,
        'name': '',
        'price': 0.0,
        'image': '',
        'is_digital': false,
      });
    }
    CacheManager.saveWishlistItems(wishlistItems.toList());

    try {
      bool success;
      if (wasInWishlist) {
        // Remove from wishlist
        success = await removeFromWishlist(productId);
        // Already removed from local list above, no need to reload
      } else {
        success = await addToWishlist(productId);
        if (success) {
          await loadWishlist();
        }
      }
      
      if (!success) {
        // Revert on failure - reload to restore state
        await loadWishlist();
      }
      
      return success;
    } catch (e) {
      // Revert on error
      await loadWishlist();
      rethrow;
    }
  }
  
  /// Navigate to product details
  void navigateToProductDetails(
    int productId, {
    Map<String, dynamic>? preview,
  }) {
    final item = preview ??
        wishlistItems.firstWhereOrNull((p) => p['id'] == productId);
    ProductDetailsNavigation.go(
      id: productId,
      preview: item != null ? Map<String, dynamic>.from(item) : null,
    );
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
    await cartController.addToCart(productId: productId);
  }
  
  /// Clear wishlist
  Future<bool> clearWishlist() async {
    try {
      final response = await _apiService.post(ApiEndpoints.wishlistClear);
      ApiService.handleResponse(response);
      
      wishlistItems.clear();
      CacheManager.saveWishlistItems([]);
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
}

