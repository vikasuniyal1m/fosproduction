import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';
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
    // Get category info from arguments
    final args = Get.arguments;
    print('CategoryProductsController onInit - Arguments: $args');
    
    if (args is Map) {
      categoryId = args['categoryId'] ?? 0;
      categoryName = args['categoryName'] ?? 'Products';
    } else if (args is int) {
      categoryId = args;
      categoryName = 'Products';
    }
    
    print('CategoryProductsController - categoryId: $categoryId, categoryName: $categoryName');
    
    if (categoryId > 0) {
      loadCategoryProducts();
    } else {
      print('CategoryProductsController - Invalid categoryId: $categoryId');
    }
  }
  
  /// Load products by category
  Future<void> loadCategoryProducts() async {
    isLoading.value = true;
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
      
      products.value = (productsList as List).map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      products.value = [];
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
    
    print('Formatting product ${product['id']}: imageUrl = $imageUrl');
    
    return {
      'id': product['id'],
      'name': product['name'] ?? '',
      'price': priceValue, // Regular price
      'sale_price': salePriceValue, // Sale price (if exists)
      'originalPrice': salePriceValue != null ? priceValue : null, // Original price when on sale
      'image': imageUrl,
      'rating': double.tryParse(product['rating']?.toString() ?? '0') ?? 0.0,
      'reviews': int.tryParse(product['review_count']?.toString() ?? product['reviews_count']?.toString() ?? '0') ?? 0,
      'review_count': int.tryParse(product['review_count']?.toString() ?? product['reviews_count']?.toString() ?? '0') ?? 0,
      'isFavorite': false,
      'category': product['category'] ?? {},
      'discount_percent': product['discount_percent'] ?? null,
    };
  }
  
  /// Get full image URL
  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      return '';
    }
    
    // Clean the URL: remove escaped slashes, trim whitespace
    String cleanUrl = imagePath
        .replaceAll('\\/', '/')  // Replace escaped slashes
        .trim();  // Remove leading/trailing whitespace
    
    // If already full URL, return cleaned version
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return cleanUrl;
    }
    
    // If relative path, add base URL
    final cleanPath = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
    
    // Check if path already includes 'products/' or 'uploads/'
    if (cleanPath.contains('products/') || cleanPath.contains('uploads/')) {
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
  void navigateToProductDetails(dynamic productId) {
    final id = productId is int ? productId : int.tryParse(productId.toString()) ?? 0;
    if (id > 0) {
      Get.toNamed('/product-details', arguments: id);
    } else {
      Get.snackbar('Error', 'Invalid product ID');
    }
  }
}
