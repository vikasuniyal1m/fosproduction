import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/app_colors.dart';
import 'wishlist_controller.dart';

/// Search Controller
/// Handles product search functionality
class SearchController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  final RxList<String> recentSearches = <String>[].obs;
  final RxList<String> popularSearches = <String>[].obs;
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasMore = false.obs;
  
  // Filters
  final Rxn<int> selectedCategoryId = Rxn<int>();
  final Rxn<double> minPrice = Rxn<double>();
  final Rxn<double> maxPrice = Rxn<double>();
  final Rxn<int> minRating = Rxn<int>();
  final RxBool inStockOnly = false.obs;
  final RxString sortBy = 'relevance'.obs; // relevance, price_low, price_high, newest, popular
  
  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
    loadCategories().then((_) {
      // Load popular searches after categories are loaded (in case we need category names as fallback)
      loadPopularSearches();
    });
  }
  
  /// Load recent searches from local storage
  void loadRecentSearches() {
    // TODO: Load from local storage (SharedPreferences)
    recentSearches.value = [];
  }
  
  /// Load popular searches from actual app data
  Future<void> loadPopularSearches() async {
    try {
      final List<String> trendingTerms = [];
      
      // Get popular products (featured, bestsellers, or top-rated)
      try {
        // Try to get featured products first
        final featuredResponse = await _apiService.get(
          ApiEndpoints.featuredProducts,
          queryParameters: {'limit': '5'},
        );
        final featuredData = ApiService.handleResponse(featuredResponse);
        final featuredProducts = featuredData['products'] ?? [];
        
        if (featuredProducts.isNotEmpty) {
          for (var product in featuredProducts) {
            final productName = product['name']?.toString() ?? '';
            if (productName.isNotEmpty && productName.length <= 30) {
              trendingTerms.add(productName);
            }
            if (trendingTerms.length >= 5) break;
          }
        }
      } catch (e) {
        // If featured products fail, try bestsellers
        try {
          final bestsellerResponse = await _apiService.get(
            ApiEndpoints.bestsellerProducts,
            queryParameters: {'limit': '5'},
          );
          final bestsellerData = ApiService.handleResponse(bestsellerResponse);
          final bestsellerProducts = bestsellerData['products'] ?? [];
          
          if (bestsellerProducts.isNotEmpty) {
            for (var product in bestsellerProducts) {
              final productName = product['name']?.toString() ?? '';
              if (productName.isNotEmpty && productName.length <= 30) {
                trendingTerms.add(productName);
              }
              if (trendingTerms.length >= 5) break;
            }
          }
        } catch (e2) {
          // If bestsellers also fail, try top-rated
          try {
            final topRatedResponse = await _apiService.get(
              ApiEndpoints.topRatedProducts,
              queryParameters: {'limit': '5'},
            );
            final topRatedData = ApiService.handleResponse(topRatedResponse);
            final topRatedProducts = topRatedData['products'] ?? [];
            
            if (topRatedProducts.isNotEmpty) {
              for (var product in topRatedProducts) {
                final productName = product['name']?.toString() ?? '';
                if (productName.isNotEmpty && productName.length <= 30) {
                  trendingTerms.add(productName);
                }
                if (trendingTerms.length >= 5) break;
              }
            }
          } catch (e3) {
            // If all fail, use category names
            if (categories.isNotEmpty) {
              for (var category in categories) {
                final categoryName = category['name']?.toString() ?? '';
                if (categoryName.isNotEmpty) {
                  trendingTerms.add(categoryName);
                }
                if (trendingTerms.length >= 5) break;
              }
            }
          }
        }
      }
      
      // If still empty, add category names
      if (trendingTerms.isEmpty && categories.isNotEmpty) {
        for (var category in categories.take(5)) {
          final categoryName = category['name']?.toString() ?? '';
          if (categoryName.isNotEmpty) {
            trendingTerms.add(categoryName);
          }
        }
      }
      
      // If still empty, use default fallback
      if (trendingTerms.isEmpty) {
        trendingTerms.addAll([
          'Electronics',
          'Fashion',
          'Home & Kitchen',
          'Sports',
          'Beauty',
        ]);
      }
      
      popularSearches.value = trendingTerms;
    } catch (e) {
      // Fallback to default if all fails
      popularSearches.value = [
        'Electronics',
        'Fashion',
        'Home & Kitchen',
        'Sports',
        'Beauty',
      ];
    }
  }
  
  /// Load categories from API
  Future<void> loadCategories() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.categoriesList,
        queryParameters: {'status': 'active'},
      );
      final data = ApiService.handleResponse(response);
      final categoriesList = data['categories'] ?? [];
      
      // Map categories with icons and colors
      final mappedCategories = (categoriesList as List).map((cat) {
        final catMap = Map<String, dynamic>.from(cat);
        final categoryName = (catMap['name'] ?? '').toLowerCase();
        
        // Assign icon and color based on category name
        IconData icon = Icons.category_rounded;
        Color color = AppColors.primary;
        
        if (categoryName.contains('electron')) {
          icon = Icons.devices_rounded;
          color = Colors.blue;
        } else if (categoryName.contains('fashion') || categoryName.contains('cloth')) {
          icon = Icons.checkroom_rounded;
          color = Colors.pink;
        } else if (categoryName.contains('home') || categoryName.contains('kitchen')) {
          icon = Icons.home_rounded;
          color = Colors.orange;
        } else if (categoryName.contains('sport')) {
          icon = Icons.sports_soccer_rounded;
          color = Colors.green;
        } else if (categoryName.contains('book')) {
          icon = Icons.menu_book_rounded;
          color = Colors.blue;
        } else if (categoryName.contains('beauty') || categoryName.contains('cosmetic')) {
          icon = Icons.face_rounded;
          color = Colors.purple;
        } else if (categoryName.contains('food') || categoryName.contains('grocery')) {
          icon = Icons.restaurant_rounded;
          color = Colors.red;
        } else if (categoryName.contains('health') || categoryName.contains('medical')) {
          icon = Icons.medical_services_rounded;
          color = Colors.teal;
        } else if (categoryName.contains('toy') || categoryName.contains('game')) {
          icon = Icons.toys_rounded;
          color = Colors.amber;
        }
        
        return <String, dynamic>{
          'id': catMap['id'],
          'name': catMap['name'] ?? '',
          'icon': icon,
          'color': color,
          'image': catMap['image'] ?? '',
        };
      }).toList();
      
      categories.value = mappedCategories;
    } catch (e) {
      // If categories fail, use empty list
      categories.value = [];
    }
  }
  
  /// Save search to recent searches
  void saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    
    final trimmedQuery = query.trim();
    if (!recentSearches.contains(trimmedQuery)) {
      recentSearches.insert(0, trimmedQuery);
      if (recentSearches.length > 10) {
        recentSearches.removeLast();
      }
      // TODO: Save to local storage
    }
  }
  
  /// Clear recent searches
  void clearRecentSearches() {
    recentSearches.clear();
    // TODO: Clear from local storage
  }
  
  /// Search products
  Future<void> searchProducts({String? query, bool loadMore = false}) async {
    final searchTerm = query ?? searchQuery.value;
    
    if (searchTerm.trim().isEmpty && selectedCategoryId.value == null) {
      searchResults.clear();
      return;
    }
    
    if (!loadMore) {
      isLoading.value = true;
      currentPage.value = 1;
    }
    
    try {
      final page = loadMore ? currentPage.value + 1 : 1;
      
      final queryParams = <String, String>{};
      if (searchTerm.trim().isNotEmpty) {
        queryParams['q'] = searchTerm.trim();
      }
      if (selectedCategoryId.value != null) {
        queryParams['category_id'] = selectedCategoryId.value!.toString();
      }
      if (minPrice.value != null) {
        queryParams['min_price'] = minPrice.value!.toString();
      }
      if (maxPrice.value != null) {
        queryParams['max_price'] = maxPrice.value!.toString();
      }
      if (minRating.value != null) {
        queryParams['rating'] = minRating.value!.toString();
      }
      if (inStockOnly.value) {
        queryParams['in_stock'] = 'true';
      }
      queryParams['sort'] = sortBy.value;
      queryParams['page'] = page.toString();
      queryParams['limit'] = '20';
      
      final response = await _apiService.get(
        ApiEndpoints.productSearch,
        queryParameters: queryParams,
      );
      
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      final pagination = data['pagination'] ?? {};
      
      final newProducts = (productsList as List).map((product) {
        return _formatProduct(Map<String, dynamic>.from(product));
      }).toList();
      
      if (loadMore) {
        searchResults.addAll(newProducts);
        currentPage.value = page;
      } else {
        searchResults.value = newProducts;
        currentPage.value = page;
        if (searchTerm.trim().isNotEmpty) {
          saveRecentSearch(searchTerm);
        }
      }
      
      final total = pagination['total'] ?? 0;
      final limit = pagination['limit'] ?? 20;
      totalPages.value = (total / limit).ceil();
      hasMore.value = currentPage.value < totalPages.value;
      
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      if (!loadMore) {
        searchResults.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Format product data
  Map<String, dynamic> _formatProduct(Map<String, dynamic> product) {
    String imageUrl = '';
    
    if (product['image'] != null) {
      final imageValue = product['image'];
      if (imageValue is String && imageValue.isNotEmpty) {
        imageUrl = _getImageUrl(imageValue);
      }
    }
    
    final regularPrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final salePrice = product['sale_price'] != null
        ? double.tryParse(product['sale_price'].toString()) ?? null
        : null;
    
    return {
      'id': product['id'],
      'name': product['name'] ?? '',
      'price': regularPrice,
      'sale_price': salePrice,
      'image': imageUrl,
      'rating': double.tryParse(product['rating']?.toString() ?? '0') ?? 0.0,
      'review_count': int.tryParse(product['review_count']?.toString() ?? '0') ?? 0,
      'isFavorite': _checkWishlistStatus(product['id']),
      'category': product['category'] ?? {},
      'in_stock': product['in_stock'] ?? false,
    };
  }
  
  /// Get full image URL
  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      return '';
    }
    
    String cleanUrl = imagePath.replaceAll('\\/', '/').trim();
    
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return cleanUrl;
    }
    
    final cleanPath = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
    
    if (cleanPath.contains('products/') || cleanPath.contains('uploads/')) {
      return '${ApiService.imageBaseUrl}$cleanPath';
    }
    
    return '${ApiService.imageBaseUrl}products/$cleanPath';
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
  
  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
  
  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    selectedCategoryId.value = null;
    minPrice.value = null;
    maxPrice.value = null;
    minRating.value = null;
    inStockOnly.value = false;
    sortBy.value = 'relevance';
    currentPage.value = 1;
  }
  
  /// Apply filter
  void applyFilter({
    int? categoryId,
    double? min,
    double? max,
    int? rating,
    bool? inStock,
    String? sort,
  }) {
    if (categoryId != null) {
      selectedCategoryId.value = categoryId;
    } else {
      selectedCategoryId.value = null;
    }
    if (min != null) {
      minPrice.value = min;
    } else {
      minPrice.value = null;
    }
    if (max != null) {
      maxPrice.value = max;
    } else {
      maxPrice.value = null;
    }
    if (rating != null) {
      minRating.value = rating;
    } else {
      minRating.value = null;
    }
    if (inStock != null) {
      inStockOnly.value = inStock;
    }
    if (sort != null) {
      sortBy.value = sort;
    }
    
    // Re-search with new filters
    searchProducts();
  }
  
  /// Clear filters
  void clearFilters() {
    selectedCategoryId.value = null;
    minPrice.value = null;
    maxPrice.value = null;
    minRating.value = null;
    inStockOnly.value = false;
    sortBy.value = 'relevance';
    searchProducts();
  }
  
  /// Toggle favorite
  Future<void> toggleFavorite(int productId) async {
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
        
        // Update in search results
        final index = searchResults.indexWhere((p) => p['id'] == productId);
        if (index != -1) {
          searchResults[index]['isFavorite'] = isNowInWishlist;
          searchResults.refresh();
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
  
  /// Load more results
  void loadMore() {
    if (!isLoading.value && hasMore.value) {
      searchProducts(loadMore: true);
    }
  }
}

