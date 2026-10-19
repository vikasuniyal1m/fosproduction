import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/cache_manager.dart';
import '../utils/data_cache.dart';
import '../routes/app_routes.dart';
import '../utils/product_details_navigation.dart';
import 'wishlist_controller.dart';

/// Category Products Controller
/// Handles category products listing logic
class CategoryProductsController extends GetxController {
  final RxBool isLoading = false.obs;
  final ApiService _apiService = ApiService();
  
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  String categoryName = '';
  int categoryId = 0;
  
  @override
  void onInit() {
    super.onInit();
    
    // Initialize wishlist controller to ensure isFavorite status is available
    if (CacheManager.isLoggedIn() && !Get.isRegistered<WishlistController>()) {
      Get.put(WishlistController());
    }
    
    // Get category info from arguments
    final args = Get.arguments;
    print('CategoryProductsController onInit - Arguments: $args');
    
    if (args is Map) {
      categoryId = args['categoryId'] ?? 0;
      categoryName = args['categoryName'] ?? 'Products';
      final seeded = args['products'];
      if (seeded is List && seeded.isNotEmpty) {
        products.value = seeded
            .whereType<Map>()
            .map((p) => Map<String, dynamic>.from(p))
            .toList();
      }
    } else if (args is int) {
      categoryId = args;
      categoryName = 'Products';
    }
    
    print('CategoryProductsController - categoryId: $categoryId, categoryName: $categoryName');
    
    if (categoryId > 0) {
      if (products.isEmpty) _loadCachedProducts();
      loadCategoryProducts();
    } else {
      print('CategoryProductsController - Invalid categoryId: $categoryId');
    }
  }
  
  void _loadCachedProducts() {
    final cached = DataCache.loadList(DataCache.categoryProducts(categoryId));
    if (cached != null && cached.isNotEmpty) {
      products.value = cached;
    }
  }

  /// Load products by category
  Future<void> loadCategoryProducts() async {
    final hadContent = products.isNotEmpty;
    if (!hadContent) {
      isLoading.value = true;
    }
    try {
      final response = await _apiService.get(
        ApiEndpoints.productsList,
        queryParameters: {
          'category_id': categoryId.toString(),
          'limit': '50',
        },
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      products.value = (productsList as List)
          .map((product) => _formatProduct(Map<String, dynamic>.from(product)))
          .toList();
      await DataCache.saveList(DataCache.categoryProducts(categoryId), products.toList());
    } catch (e) {
      if (!hadContent) {
        ApiService.showErrorSnackbar(e);
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Format product data
  Map<String, dynamic> _formatProduct(Map<String, dynamic> product) {
    // Get image - API returns full URL in 'image' field
    String imageUrl = '';
    
    // Check if image field exists and is not null
    if (product['image'] != null) {
      final imageValue = product['image'];
      if (imageValue is String && imageValue.isNotEmpty) {
        imageUrl = imageValue;
      } else if (imageValue != null) {
        imageUrl = imageValue.toString();
      }
    }
    
    // If image is empty, try main_image
    if (imageUrl.isEmpty && product['main_image'] != null) {
      final mainImage = product['main_image'];
      if (mainImage is String && mainImage.isNotEmpty) {
        imageUrl = mainImage;
      } else if (mainImage != null) {
        imageUrl = mainImage.toString();
      }
    }
    
    // If image is empty, try to get from images array
    if (imageUrl.isEmpty && product['images'] != null) {
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        if (images[0] is String) {
          imageUrl = images[0] as String;
        } else if (images[0] is Map) {
          final imgMap = images[0] as Map;
          imageUrl = imgMap['url']?.toString() ?? 
                     imgMap['image']?.toString() ?? 
                     imgMap['image_path']?.toString() ?? 
                     imgMap['image_url']?.toString() ?? '';
        }
      }
    }
    
    // Format image URL
    if (imageUrl.isNotEmpty) {
      imageUrl = _getImageUrl(imageUrl);
    }
    
    // Get price - API uses 'price' for regular price, 'sale_price' for discounted price
    final regularPrice = product['price'];
    final salePrice = product['sale_price'];
    
    final priceValue = double.tryParse(regularPrice?.toString() ?? '0') ?? 0.0;
    final salePriceValue = salePrice != null && salePrice.toString().isNotEmpty
        ? double.tryParse(salePrice.toString()) ?? 0.0
        : null;
    
    final bool isDigital =
        product['is_digital'] == true || product['is_digital'] == 1;
    String mediaType = product['media_type']?.toString() ?? '';
    String bannerUrl = '';
    if (isDigital && product['banner'] != null) {
      bannerUrl = _getImageUrl(product['banner'].toString());
    }
    if (isDigital && mediaType.isEmpty) {
      final category = product['category'];
      if (category is Map && category['name'] != null) {
        final categoryName = category['name'].toString().toLowerCase();
        if (categoryName.contains('video')) {
          mediaType = 'video';
        } else if (categoryName.contains('audio') ||
            categoryName.contains('music')) {
          mediaType = 'audio';
        }
      }
    }

    return {
      'id': product['id'],
      'name': product['name'] ?? '',
      'price': priceValue,
      'sale_price': salePriceValue,
      'originalPrice': salePriceValue != null ? priceValue : null,
      'image': imageUrl,
      'banner': bannerUrl,
      'rating': double.tryParse(product['rating']?.toString() ?? '0') ?? 0.0,
      'reviews': int.tryParse(product['review_count']?.toString() ??
              product['reviews_count']?.toString() ??
              '0') ??
          0,
      'review_count': int.tryParse(product['review_count']?.toString() ??
              product['reviews_count']?.toString() ??
              '0') ??
          0,
      'isFavorite': _checkWishlistStatus(product['id']),
      'category': product['category'] ?? {},
      'category_id': product['category_id'] ??
          (product['category'] is Map ? product['category']['id'] : null),
      'discount_percent': product['discount_percent'] ?? null,
      'is_digital': isDigital,
      'media_type': mediaType,
      'is_sticker_pack':
          product['is_sticker_pack'] == true || product['is_sticker_pack'] == 1,
    };
  }
  
  /// Check if product is in wishlist
  bool _checkWishlistStatus(int productId) {
    try {
      if (Get.isRegistered<WishlistController>()) {
        final wishlistController = Get.find<WishlistController>();
        return wishlistController.isInWishlist(productId);
      }
    } catch (e) {
      // If wishlist controller not available, return false
    }
    return false;
  }
  
  /// Get full image URL
  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      return '';
    }
    
    // Clean the URL: remove escaped slashes, trim whitespace
    String cleanUrl = imagePath
        .replaceAll('\\/', '/')
        .trim();

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
    
    // Default to products folder
    return '${ApiService.imageBaseUrl}products/$cleanPath';
  }
  
  /// Toggle favorite (add/remove from wishlist)
  Future<void> toggleFavorite(int productId) async {
    if (!CacheManager.isLoggedIn()) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Save to Wishlist?'),
          content: const Text(
              'Please log in to create a wishlist and save your favorite items for later.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                AppRoutes.toLogin();
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }
    try {
      WishlistController wishlistController;
      if (Get.isRegistered<WishlistController>()) {
        wishlistController = Get.find<WishlistController>();
      } else {
        wishlistController = Get.put(WishlistController());
      }
      
      final success = await wishlistController.toggleWishlist(productId);
      
      if (success) {
        final isNowInWishlist = wishlistController.isInWishlist(productId);
        
        final productIndex = products.indexWhere((p) => p['id'] == productId);
        if (productIndex != -1) {
          products[productIndex]['isFavorite'] = isNowInWishlist;
          products.refresh();
        }
        
        if (isNowInWishlist) {
          Get.snackbar('Success', 'Added to wishlist', duration: const Duration(seconds: 2));
        } else {
          Get.snackbar('Success', 'Removed from wishlist', duration: const Duration(seconds: 2));
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update wishlist: ${e.toString()}');
    }
  }
  
  /// Navigate to product details
  void navigateToProductDetails(
    dynamic productId, {
    Map<String, dynamic>? preview,
  }) {
    final id = productId is int
        ? productId
        : int.tryParse(productId.toString()) ?? 0;
    if (id <= 0) {
      Get.snackbar('Error', 'Invalid product ID');
      return;
    }
    final item = preview ??
        products.firstWhereOrNull((p) => p['id'] == id);
    ProductDetailsNavigation.go(
      id: id,
      preview: item != null ? Map<String, dynamic>.from(item) : null,
    );
  }
}
