import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/app_colors.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';
import '../widgets/add_to_cart_success_sheet.dart';
import '../widgets/review_dialog.dart';
import 'cart_controller.dart';
import 'wishlist_controller.dart';

/// Product Controller
/// Handles product details logic
class ProductController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxInt selectedImageIndex = 0.obs;
  final RxInt quantity = 1.obs;
  final RxBool isFavorite = false.obs;
  final RxInt selectedSizeIndex = 0.obs;
  final RxInt selectedColorIndex = 0.obs;
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? product;
  final RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> relatedProducts = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // Get product ID from arguments
    final productIdArg = Get.arguments;
    int? productId;
    
    if (productIdArg is int) {
      productId = productIdArg;
    } else if (productIdArg is String) {
      productId = int.tryParse(productIdArg);
    } else if (productIdArg != null) {
      productId = int.tryParse(productIdArg.toString());
    }
    
    if (productId != null && productId > 0) {
      loadProductDetails(productId);
    } else {
      // Defer snackbar and navigation until after build phase completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'Invalid product ID');
        Get.back();
      });
    }
  }
  
  /// Load product details
  Future<void> loadProductDetails(int productId) async {
    isLoading.value = true;
    try {
      // Load product details
      final response = await _apiService.get(
        ApiEndpoints.productDetails,
        queryParameters: {'id': productId.toString()},
      );
      final data = ApiService.handleResponse(response);
      
      // Format product data
      // Handle images - API returns array of objects with 'url' key
      List<String> imageUrls = [];
      if (data['images'] != null && data['images'] is List) {
        for (var img in data['images']) {
          if (img is Map && img['url'] != null) {
            imageUrls.add(_getImageUrl(img['url'].toString()));
          } else if (img is String) {
            imageUrls.add(_getImageUrl(img));
          }
        }
      }
      // If no images from images array, use main image
      if (imageUrls.isEmpty && data['image'] != null) {
        imageUrls.add(_getImageUrl(data['image'].toString()));
      }
      
      // Handle variants - API returns variants as object with 'size', 'color', etc.
      List<String> sizes = [];
      List<Map<String, dynamic>> colors = [];
      if (data['variants'] != null && data['variants'] is Map) {
        final variants = data['variants'] as Map;
        if (variants['size'] != null && variants['size'] is List) {
          sizes = (variants['size'] as List).map((v) {
            if (v is Map) return v['value']?.toString() ?? '';
            return v.toString();
          }).where((s) => s.isNotEmpty).toList();
        }
        if (variants['color'] != null && variants['color'] is List) {
          colors = (variants['color'] as List).map((v) {
            if (v is Map) {
              return {
                'name': v['value']?.toString() ?? '',
                'code': v['value']?.toString() ?? '#000000',
              };
            }
            return {
              'name': v.toString(),
              'code': '#000000',
            };
          }).toList();
        }
      }
      
      product = {
        'id': data['id'],
        'name': data['name'] ?? '',
        'price': double.tryParse((data['sale_price'] ?? data['price'] ?? '0').toString()) ?? 0.0,
        'originalPrice': data['sale_price'] != null 
            ? double.tryParse(data['price']?.toString() ?? '0') ?? 0.0 
            : null,
        'rating': double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
        'reviews': int.tryParse(data['review_count']?.toString() ?? '0') ?? 0,
        'description': data['description'] ?? data['short_description'] ?? '',
        'images': imageUrls.isNotEmpty ? imageUrls : [data['image'] != null ? _getImageUrl(data['image'].toString()) : ''],
        'sizes': sizes,
        'colors': colors,
        'inStock': data['in_stock'] ?? (data['stock_quantity'] != null && (int.tryParse(data['stock_quantity'].toString()) ?? 0) > 0),
        'stock': int.tryParse(data['stock_quantity']?.toString() ?? '0') ?? 0,
        'category_id': data['category'] != null && data['category'] is Map 
            ? data['category']['id'] 
            : data['category_id'],
      };
      
      // Check if product is in wishlist
      _checkWishlistStatus(product!['id']);
      
      // Load reviews
      await loadReviews(productId);
      
      // Load related products (same category)
      if (data['category_id'] != null) {
        await loadRelatedProducts(data['category_id'], productId);
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
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
  
  /// Load reviews
  Future<void> loadReviews(int productId) async {
    try {
      // Check if user is logged in
      final token = CacheManager.getUserToken();
      print('[LoadReviews] User token: ${token != null && token.isNotEmpty ? "Present" : "Missing"}');
      print('[LoadReviews] Loading reviews for product ID: $productId');
      
      final response = await _apiService.get(
        ApiEndpoints.reviewsList,
        queryParameters: {
          'product_id': productId.toString(),
          'limit': '20',
        },
      );
      
      print('[LoadReviews] API Response status: ${response.statusCode}');
      print('[LoadReviews] API Response data type: ${response.data.runtimeType}');
      
      final data = ApiService.handleResponse(response);
      final reviewsList = data['reviews'];
      
      print('[LoadReviews] Raw API response: ${reviewsList?.length ?? 0} reviews');
      if (reviewsList != null && reviewsList is List) {
        print('[LoadReviews] Reviews list content: $reviewsList');
      }
      
      if (reviewsList == null || reviewsList is! List) {
        print('[LoadReviews] No reviews found or invalid format');
        reviews.value = [];
        reviews.refresh();
        return;
      }
      
      // Convert List<dynamic> to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> formattedReviews = [];
      
      for (var review in reviewsList) {
        if (review is! Map) {
          print('[LoadReviews] Skipping invalid review: $review');
          continue;
        }
        
        final reviewMap = Map<String, dynamic>.from(review);
        print('[LoadReviews] Processing review ID: ${reviewMap['id']}, User: ${reviewMap['user_name']}, Status: ${reviewMap['status']}');
        
        // Format date
        String formattedDate = '';
        if (reviewMap['created_at'] != null) {
          try {
            final date = DateTime.parse(reviewMap['created_at'].toString());
            final now = DateTime.now();
            final difference = now.difference(date);
            
            if (difference.inDays == 0) {
              if (difference.inHours == 0) {
                formattedDate = '${difference.inMinutes} minutes ago';
              } else {
                formattedDate = '${difference.inHours} hours ago';
              }
            } else if (difference.inDays < 7) {
              formattedDate = '${difference.inDays} days ago';
            } else if (difference.inDays < 30) {
              formattedDate = '${(difference.inDays / 7).floor()} weeks ago';
            } else {
              formattedDate = '${date.day}/${date.month}/${date.year}';
            }
          } catch (e) {
            formattedDate = reviewMap['created_at']?.toString() ?? '';
          }
        }
        
        formattedReviews.add({
          'id': reviewMap['id'],
          'userName': reviewMap['user_name'] ?? reviewMap['name'] ?? 'Anonymous',
          'rating': double.tryParse(reviewMap['rating']?.toString() ?? '0') ?? 0.0,
          'comment': reviewMap['comment'] ?? reviewMap['review'] ?? reviewMap['title'] ?? '',
          'date': formattedDate,
          'images': reviewMap['images'] is List ? reviewMap['images'] : [],
          'title': reviewMap['title'] ?? '',
          'status': reviewMap['status'] ?? 'approved', // Include status for pending reviews
          'like_count': reviewMap['like_count'] ?? 0,
          'is_liked': reviewMap['is_liked'] ?? false,
        });
      }
      
      // Update reviews list and trigger UI refresh
      print('[LoadReviews] Formatted ${formattedReviews.length} reviews');
      print('[LoadReviews] Before update: ${reviews.length} reviews in list');
      
      // Update reviews list - use assignment to trigger Obx
      reviews.value = formattedReviews;
      // Force refresh to ensure UI updates
      reviews.refresh();
      
      print('[LoadReviews] After update: ${reviews.length} reviews in list');
      for (var i = 0; i < reviews.length; i++) {
        print('[LoadReviews] Review $i: ID=${reviews[i]['id']}, User=${reviews[i]['userName']}, Status=${reviews[i]['status']}');
      }
      
      // Force controller update to trigger UI rebuild
      update();
    } catch (e) {
      print('Error loading reviews: $e');
      reviews.value = [];
      reviews.refresh(); // Force UI update even on error
    }
  }
  
  /// Like/Unlike review
  Future<void> toggleReviewLike(int reviewId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.reviewLike,
        data: {'review_id': reviewId},
      );
      final data = ApiService.handleResponse(response);
      
      // Update review in list
      final reviewIndex = reviews.indexWhere((r) => r['id'] == reviewId);
      if (reviewIndex != -1) {
        reviews[reviewIndex]['is_liked'] = data['is_liked'] ?? false;
        reviews[reviewIndex]['like_count'] = data['like_count'] ?? 0;
        reviews.refresh();
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Report review
  Future<void> reportReview(int reviewId, String reason, {String? description}) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.reviewReport,
        data: {
          'review_id': reviewId,
          'reason': reason,
          if (description != null) 'description': description,
        },
      );
      ApiService.handleResponse(response);
      
      Get.snackbar(
        'Success',
        'Review reported. Our team will review it.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.9),
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Load related products
  Future<void> loadRelatedProducts(int categoryId, int excludeProductId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.productsList,
        queryParameters: {
          'category_id': categoryId.toString(),
          'limit': '4',
          'exclude_id': excludeProductId.toString(),
        },
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      relatedProducts.value = productsList.map((p) => {
        'id': p['id'],
        'name': p['name'] ?? '',
        'price': double.tryParse(p['price']?.toString() ?? '0') ?? 0.0,
        'image': _getImageUrl(p['image'] ?? p['main_image'] ?? ''),
        'rating': double.tryParse(p['rating']?.toString() ?? '0') ?? 0.0,
      }).toList();
    } catch (e) {
      relatedProducts.value = [];
    }
  }
  
  /// Increase quantity
  void increaseQuantity() {
    if (product != null && quantity.value < (product!['stock'] ?? 99)) {
      quantity.value++;
    }
  }
  
  /// Decrease quantity
  void decreaseQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }
  
  /// Check wishlist status for product
  void _checkWishlistStatus(int productId) {
    try {
      if (Get.isRegistered<WishlistController>()) {
        final wishlistController = Get.find<WishlistController>();
        isFavorite.value = wishlistController.isInWishlist(productId);
      }
    } catch (e) {
      // If wishlist controller not available, default to false
      isFavorite.value = false;
    }
  }
  
  /// Toggle favorite (add/remove from wishlist) - Optimistic update for instant response
  Future<void> toggleFavorite() async {
    if (product == null) return;
    
    // Optimistic update - change UI immediately
    final previousState = isFavorite.value;
    isFavorite.value = !isFavorite.value;
    
    try {
      // Get wishlist controller
      WishlistController wishlistController;
      if (Get.isRegistered<WishlistController>()) {
        wishlistController = Get.find<WishlistController>();
      } else {
        wishlistController = Get.put(WishlistController());
      }
      
      // Make API call in background
      final success = await wishlistController.toggleWishlist(product!['id']);
      
      if (!success) {
        // Revert if API call failed
        isFavorite.value = previousState;
        Get.snackbar('Error', 'Failed to update wishlist. Please try again.');
      } else {
        // Sync with actual state
        isFavorite.value = wishlistController.isInWishlist(product!['id']);
        
        // Show brief feedback (shorter duration for better UX)
        if (isFavorite.value) {
          Get.snackbar('', 'Added to wishlist', 
            duration: const Duration(milliseconds: 1500),
            snackPosition: SnackPosition.BOTTOM,
            margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
            backgroundColor: AppColors.success.withOpacity(0.9),
            colorText: AppColors.textWhite,
          );
        } else {
          Get.snackbar('', 'Removed from wishlist',
            duration: const Duration(milliseconds: 1500),
            snackPosition: SnackPosition.BOTTOM,
            margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
            backgroundColor: AppColors.textSecondary.withOpacity(0.9),
            colorText: AppColors.textWhite,
          );
        }
      }
    } catch (e) {
      // Revert on error
      isFavorite.value = previousState;
      Get.snackbar('Error', 'Failed to update wishlist. Please try again.');
    }
  }
  
  /// Select size
  void selectSize(int index) {
    selectedSizeIndex.value = index;
  }
  
  /// Select color
  void selectColor(int index) {
    selectedColorIndex.value = index;
  }
  
  // Loading state for add to cart
  final RxBool isAddingToCart = false.obs;
  
  /// Add to cart
  Future<void> addToCart() async {
    if (product == null) return;
    
    // Show loading state
    isAddingToCart.value = true;
    
    try {
      // Get cart controller
      CartController cartController;
      if (Get.isRegistered<CartController>()) {
        cartController = Get.find<CartController>();
      } else {
        cartController = Get.put(CartController());
      }
      
      // Get selected size and color
      String? size;
      String? color;
      if (product!['sizes'] != null && product!['sizes'] is List) {
        final sizes = product!['sizes'] as List;
        if (selectedSizeIndex.value < sizes.length) {
          size = sizes[selectedSizeIndex.value]?.toString();
        }
      }
      if (product!['colors'] != null && product!['colors'] is List) {
        final colors = product!['colors'] as List;
        if (selectedColorIndex.value < colors.length) {
          final colorData = colors[selectedColorIndex.value];
          if (colorData is Map) {
            color = colorData['name']?.toString();
          } else {
            color = colorData?.toString();
          }
        }
      }
      
      // Add to cart
      final success = await cartController.addToCart(
        productId: product!['id'],
        quantity: quantity.value,
        size: size,
        color: color,
      );
      
      if (success) {
        // Get formatted image URL
        String imageUrl = '';
        if (product!['images'] != null && (product!['images'] as List).isNotEmpty) {
          imageUrl = (product!['images'] as List)[0] ?? '';
        } else if (product!['image'] != null) {
          imageUrl = _getImageUrl(product!['image'].toString());
        }
        
        // Show beautiful success bottom sheet
        Get.bottomSheet(
          AddToCartSuccessSheet(
            product: {
              'id': product!['id'],
              'name': product!['name'] ?? 'Product',
              'image': imageUrl,
              'price': product!['price'] ?? 0,
              'sale_price': product!['sale_price'] ?? product!['price'] ?? 0,
            },
            quantity: quantity.value,
          ),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          enableDrag: true,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add product to cart. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: AppColors.textWhite,
      );
    } finally {
      isAddingToCart.value = false;
    }
  }
  
  /// Buy now
  Future<void> buyNow() async {
    if (product == null) return;
    
    // Check if user is logged in
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar(
        'Login Required',
        'Please login to proceed with checkout',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Navigate to login
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.toLogin();
      return;
    }
    
    // Get cart controller
    CartController cartController;
    if (Get.isRegistered<CartController>()) {
      cartController = Get.find<CartController>();
    } else {
      cartController = Get.put(CartController());
    }
    
    // Get selected size and color
    String? size;
    String? color;
    if (product!['sizes'] != null && product!['sizes'] is List) {
      final sizes = product!['sizes'] as List;
      if (selectedSizeIndex.value < sizes.length) {
        size = sizes[selectedSizeIndex.value]?.toString();
      }
    }
    if (product!['colors'] != null && product!['colors'] is List) {
      final colors = product!['colors'] as List;
      if (selectedColorIndex.value < colors.length) {
        final colorData = colors[selectedColorIndex.value];
        if (colorData is Map) {
          color = colorData['name']?.toString();
        } else {
          color = colorData?.toString();
        }
      }
    }
    
    // Add to cart first
    final success = await cartController.addToCart(
      productId: product!['id'],
      quantity: quantity.value,
      size: size,
      color: color,
    );
    
    if (success) {
      // Navigate to checkout
      cartController.navigateToCheckout();
    }
  }
  
  /// Write review - Shows review dialog
  void writeReview() {
    if (product == null) {
      Get.snackbar('Error', 'Product information not available');
      return;
    }
    
    // Check if user is logged in
    // Note: You may need to import CacheManager to check login status
    // For now, we'll let the API handle authentication
    
    Get.dialog(
      ReviewDialogWithCallback(
        productId: product!['id'] as int,
        productName: product!['name'] ?? 'Product',
        onSubmit: (rating, title, comment) async {
          return await submitReview(
            product!['id'] as int,
            rating,
            title,
            comment,
          );
        },
      ),
    );
  }
  
  /// Submit review to API
  Future<bool> submitReview(int productId, int rating, String title, String comment) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createReview,
        data: {
          'product_id': productId,
          'rating': rating,
          'title': title,
          'comment': comment,
        },
      );
      
      // Get message from response before handleResponse (which only returns data)
      String successMessage = 'Review submitted successfully. It will be published after approval.';
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        successMessage = responseData['message'] ?? successMessage;
      }
      
      // Process response (data not needed, only message is used)
      ApiService.handleResponse(response);
      
      // Show success message
      Get.snackbar(
        'Success',
        successMessage,
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        duration: const Duration(seconds: 3),
      );
      
      // Reload reviews to show the updated/new review immediately
      if (product != null) {
        // Reload reviews immediately - don't wait for dialog to close
        // The dialog will close on its own
        try {
          print('[SubmitReview] Reloading reviews immediately...');
          await loadReviews(productId);
          print('[SubmitReview] Reviews reloaded successfully, count: ${reviews.length}');
          // Print all review IDs to debug
          for (var review in reviews) {
            print('[SubmitReview] Review ID: ${review['id']}, User: ${review['userName']}, Status: ${review['status']}');
          }
        } catch (e) {
          print('[SubmitReview] Error reloading reviews: $e');
          // Don't show error to user, just log it
        }
      }
      
      return true;
    } catch (e) {
      final errorMessage = ApiService.handleError(e);
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }
}

