import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/location_service.dart';
import '../widgets/location_selection_dialog.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';
import 'wishlist_controller.dart';
import 'notification_controller.dart';

/// Home Controller
/// Handles home screen logic (categories, products, banners, etc.)
class HomeController extends GetxController {
  final RxInt currentBannerIndex = 0.obs;
  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final ApiService _apiService = ApiService();
  
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> banners = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> featuredProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> discountedProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topRatedProducts = <Map<String, dynamic>>[].obs;
  
  // Sort options
  final RxString featuredSortBy = 'default'.obs; // default, price_low, price_high, rating, newest
  final RxString discountedSortBy = 'popular'.obs; // popular, price_low, price_high, rating, discount_high
  final RxString topRatedSortBy = 'popular'.obs; // popular, price_low, price_high, rating, newest
  
  // Location/Address management
  final RxList<Map<String, dynamic>> addresses = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> selectedLocation = Rxn<Map<String, dynamic>>();
  
  @override
  void onInit() {
    super.onInit();
    loadHomeData();
    loadUserLocation();
    _requestNotificationPermissionIfNeeded();
  }
  
  /// Request notification permission if user is logged in and not already requested
  Future<void> _requestNotificationPermissionIfNeeded() async {
    // Only request if user is logged in
    if (!CacheManager.isLoggedIn()) {
      return;
    }
    
    // Check if permission was already requested (to avoid asking every time)
    final permissionRequested = CacheManager.getData('notification_permission_requested') ?? false;
    if (permissionRequested) {
      return;
    }
    
    // Wait a bit for the home screen to load
    await Future.delayed(const Duration(seconds: 2));
    
    // Check current permission status
    final status = await Permission.notification.status;
    
    // If not granted and not permanently denied, request it
    if (!status.isGranted && !status.isPermanentlyDenied) {
      // Initialize notification controller if not already initialized
      if (!Get.isRegistered<NotificationController>()) {
        Get.put(NotificationController());
      }
      
      final controller = Get.find<NotificationController>();
      
      // Request permission
      await controller.requestNotificationPermission();
      
      // Mark as requested
      await CacheManager.saveData('notification_permission_requested', true);
    }
  }
  
  /// Load all home screen data - OPTIMIZED: Load in parallel for faster performance
  Future<void> loadHomeData() async {
    isLoading.value = true;
    update(); // Update GetBuilder if used
    try {
      // Load all data in parallel instead of sequentially for much faster loading
      await Future.wait([
        loadCategories(),
        loadBanners(),
        loadFeaturedProducts(),
        loadDiscountedProducts(),
        loadTopRatedProducts(),
        // Load products last as it might be heavy
        loadProducts(),
      ], eagerError: false); // Don't stop on first error, continue loading others
    } catch (e) {
      // Log error but don't show snackbar immediately - let user see partial data
      print('Error loading home data: $e');
      // Only show error if critical data failed
      if (categories.isEmpty && banners.isEmpty) {
        ApiService.showErrorSnackbar(e);
      }
    } finally {
      isLoading.value = false;
      update(); // Update GetBuilder if used
      print('Home data loading completed. Categories: ${categories.length}, Banners: ${banners.length}, Products: ${products.length}');
    }
  }
  
  /// Load user location (default address)
  Future<void> loadUserLocation() async {
    try {
      final response = await _apiService.get(ApiEndpoints.addressesList);
      final data = ApiService.handleResponse(response);
      final addressesList = data['addresses'] ?? [];
      
      addresses.value = List<Map<String, dynamic>>.from(addressesList);
      
      // Select default address or first address
      if (addresses.isNotEmpty) {
        try {
          final defaultAddress = addresses.firstWhere((addr) => addr['is_default'] == true);
          selectedLocation.value = defaultAddress;
        } catch (e) {
          // No default address, use first one
          selectedLocation.value = addresses.first;
        }
      } else {
        selectedLocation.value = null;
        Get.snackbar(
          'No Address',
          'Please add a delivery address',
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      // If addresses fail, set to null (no location)
      addresses.value = [];
      selectedLocation.value = null;
    }
  }
  
  /// Select location/address
  void selectLocation(Map<String, dynamic> address) {
    selectedLocation.value = address;
  }
  
  /// Get location display text
  String get locationDisplayText {
    if (selectedLocation.value == null) {
      return 'Select Location';
    }
    
    final address = selectedLocation.value!;
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    
    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    } else if (city.isNotEmpty) {
      return city;
    } else if (state.isNotEmpty) {
      return state;
    } else {
      return 'Select Location';
    }
  }
  
  /// Get location label (Home, Work, etc.)
  String get locationLabel {
    if (selectedLocation.value == null) {
      return 'Home';
    }
    
    final address = selectedLocation.value!;
    final label = address['label'] ?? address['type'] ?? 'home';
    return label.toString().split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
  
  /// Show location selection dialog
  void showLocationSelectionDialog() {
    Get.dialog(
      LocationSelectionDialog(controller: this),
      barrierDismissible: true,
    );
  }
  
  /// Navigate to location selection (for backward compatibility)
  void navigateToLocationSelection() {
    showLocationSelectionDialog();
  }
  
  /// Use current location
  Future<void> useCurrentLocation() async {
    Get.back(); // Close dialog
    
    // Navigate to add address screen with current location option
    Get.toNamed('/add-address', arguments: {'use_current_location': true})?.then((_) {
      // Reload location after returning
      loadUserLocation();
    });
  }
  
  /// Get current location and set as selected
  Future<void> detectAndSetCurrentLocation() async {
    try {
      final locationService = LocationService();
      
      // Request permission first
      final permissionStatus = await locationService
          .requestLocationPermission();

      if (permissionStatus != PermissionStatus.granted) {
        return; // Permission denied, user will see snackbar
      }
      
      // Show loading
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      
      // Get current location
      final locationData = await locationService.getCurrentLocation();
      
      Get.back(); // Close loading dialog
      
      if (locationData != null) {
        // Set as selected location (temporary, not saved to database)
        selectedLocation.value = locationData;
        
        Get.snackbar(
          'Success',
          'Current location detected!',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog if still open
      Get.snackbar('Error', 'Failed to detect location: ${e.toString()}');
    }
  }
  
  /// Select saved address as location
  void selectSavedAddress(Map<String, dynamic> address) {
    selectLocation(address);
    Get.back(); // Close dialog
  }
  
  /// Load categories
  Future<void> loadCategories() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.categoriesList,
        queryParameters: {'status': 'active'},
      );
      final data = ApiService.handleResponse(response);
      final categoriesList = data['categories'] ?? [];
      
      // Add "All" category at the beginning
      final mappedCategories = (categoriesList as List).map((cat) {
        final catMap = Map<String, dynamic>.from(cat);
        return <String, dynamic>{
          'id': catMap['id'],
          'name': catMap['name'] ?? '',
          'icon': catMap['icon'] ?? '📦',
          'image': catMap['image'] ?? '',
        };
      }).toList();
      
      categories.value = [
        {'id': 0, 'name': 'All', 'icon': '🛍️'},
        ...mappedCategories,
      ];
    } catch (e) {
      // If categories fail, use default
      categories.value = [
        {'id': 0, 'name': 'All', 'icon': '🛍️'},
      ];
    }
  }
  
  /// Load banners
  Future<void> loadBanners() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.bannersList,
        queryParameters: {'position': 'top', 'status': 'active'},
      );
      final data = ApiService.handleResponse(response);
      final bannersList = data['banners'] ?? [];
      
      banners.value = bannersList.map((banner) => {
        'id': banner['id'],
        'image': _getBannerImageUrl(banner['image'] ?? ''),
        'title': banner['title'] ?? '',
        'description': banner['description'] ?? '',
        'link_url': banner['link_url'] ?? '',
        'link_text': banner['link_text'] ?? 'Shop Now',
      }).toList();
    } catch (e) {
      banners.value = [];
    }
  }
  
  /// Load featured products
  Future<void> loadFeaturedProducts() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.featuredProducts,
        queryParameters: {'limit': '6'},
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      featuredProducts.value = (productsList as List).map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
    } catch (e) {
      featuredProducts.value = [];
    }
  }
  
  /// Load discounted products
  Future<void> loadDiscountedProducts() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.discountedProducts,
        queryParameters: {'limit': '10', 'min_discount': '10'},
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      discountedProducts.value = (productsList as List).map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
    } catch (e) {
      discountedProducts.value = [];
    }
  }
  
  /// Load top-rated products
  Future<void> loadTopRatedProducts() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.topRatedProducts,
        queryParameters: {'limit': '10', 'min_rating': '4.0'},
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      topRatedProducts.value = (productsList as List).map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
    } catch (e) {
      topRatedProducts.value = [];
    }
  }
  
  /// Load all products
  Future<void> loadProducts() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.productsList,
        queryParameters: {'limit': '20'},
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      products.value = (productsList as List).map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
    } catch (e) {
      products.value = [];
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
    
    // Format image URL - API already returns full URL, but let's ensure it's correct
    if (imageUrl.isNotEmpty) {
      imageUrl = _getImageUrl(imageUrl);
      // Debug: Print image URL
      print('Product ${product['id']} Image URL: $imageUrl');
    } else {
      print('Product ${product['id']} has no image');
    }
    
    // Get price - API uses 'price' for regular price, 'sale_price' for discounted price
    final regularPrice = product['price'];
    final salePrice = product['sale_price'];
    
    final priceValue = double.tryParse(regularPrice?.toString() ?? '0') ?? 0.0;
    final salePriceValue = salePrice != null && salePrice.toString().isNotEmpty
        ? double.tryParse(salePrice.toString()) ?? 0.0
        : null;
    
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
      'isFavorite': _checkWishlistStatus(product['id']),
      'category': product['category'] ?? {},
      'discount_percent': product['discount_percent'] ?? null,
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
        .replaceAll('\\/', '/')  // Replace escaped slashes
        .trim();  // Remove leading/trailing whitespace
    
    // If already full URL, return cleaned version
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return cleanUrl;
    }
    
    // If relative path, add base URL
    // Remove leading slash if present
    final cleanPath = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
    
    // Check if path already includes 'products/' or 'uploads/'
    if (cleanPath.contains('products/') || cleanPath.contains('uploads/')) {
      return '${ApiService.imageBaseUrl}$cleanPath';
    }
    
    // Default to products folder
    return '${ApiService.imageBaseUrl}products/$cleanPath';
  }
  
  /// Get banner image URL
  String _getBannerImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      return '';
    }
    
    // If already full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // If relative path, add base URL
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    
    // Check if path already includes 'banners/' or 'uploads/'
    if (cleanPath.contains('banners/') || cleanPath.contains('uploads/')) {
      return '${ApiService.imageBaseUrl}$cleanPath';
    }
    
    // Default to banners folder
    return '${ApiService.imageBaseUrl}banners/$cleanPath';
  }
  
  /// Select category
  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
    if (index == 0) {
      // "All" selected - do nothing or show all products on home
      return;
    } else if (index < categories.length) {
      // Navigate to category products screen
      final categoryId = categories[index]['id'];
      final categoryName = categories[index]['name'] ?? 'Products';
      print('Navigating to category: $categoryName (ID: $categoryId)');
      
      try {
        print('About to navigate to /category-products');
        print('Arguments being passed: categoryId=$categoryId, categoryName=$categoryName');
        print('Current route: ${Get.currentRoute}');
        print('Available routes: ${Get.routing.current}');
        
        // Try navigation
        Get.toNamed(
          '/category-products',
          arguments: {
            'categoryId': categoryId,
            'categoryName': categoryName,
          },
        )?.then((value) {
          print('Navigation completed with result: $value');
        }).catchError((error) {
          print('Navigation error: $error');
          Get.snackbar('Error', 'Failed to open category: $error');
        });
        
        print('Navigation called successfully');
      } catch (e, stackTrace) {
        print('Navigation error: $e');
        print('Stack trace: $stackTrace');
        Get.snackbar('Error', 'Failed to open category: $e');
      }
    } else {
      print('Invalid category index: $index (categories length: ${categories.length})');
    }
  }
  
  /// Load products by category
  Future<void> loadProductsByCategory(int categoryId) async {
    isLoading.value = true;
    try {
      final response = await _apiService.get(
        ApiEndpoints.productsList,
        queryParameters: {
          'category_id': categoryId.toString(),
          'limit': '20',
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
  
  /// Toggle favorite (add/remove from wishlist)
  Future<void> toggleFavorite(int productId) async {
    try {
      // Get wishlist controller
      WishlistController wishlistController;
      if (Get.isRegistered<WishlistController>()) {
        wishlistController = Get.find<WishlistController>();
      } else {
        wishlistController = Get.put(WishlistController());
      }
      
      // Toggle wishlist
      // Check if product is in wishlist (for future use)
      // final wasInWishlist = wishlistController.isInWishlist(productId);
      final success = await wishlistController.toggleWishlist(productId);
      
      if (success) {
        final isNowInWishlist = wishlistController.isInWishlist(productId);
        
        // Update in featured products
        final featuredIndex = featuredProducts.indexWhere((p) => p['id'] == productId);
        if (featuredIndex != -1) {
          featuredProducts[featuredIndex]['isFavorite'] = isNowInWishlist;
          featuredProducts.refresh();
        }
        
        // Update in products
        final productIndex = products.indexWhere((p) => p['id'] == productId);
        if (productIndex != -1) {
          products[productIndex]['isFavorite'] = isNowInWishlist;
          products.refresh();
        }
        
        // Update in discounted products
        final discountedIndex = discountedProducts.indexWhere((p) => p['id'] == productId);
        if (discountedIndex != -1) {
          discountedProducts[discountedIndex]['isFavorite'] = isNowInWishlist;
          discountedProducts.refresh();
        }
        
        // Update in top rated products
        final topRatedIndex = topRatedProducts.indexWhere((p) => p['id'] == productId);
        if (topRatedIndex != -1) {
          topRatedProducts[topRatedIndex]['isFavorite'] = isNowInWishlist;
          topRatedProducts.refresh();
        }

        // Defer refresh calls to after the current build cycle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (featuredIndex != -1) featuredProducts.refresh();
          if (productIndex != -1) products.refresh();
          if (discountedIndex != -1) discountedProducts.refresh();
          if (topRatedIndex != -1) topRatedProducts.refresh();
        });

        // Show feedback
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
    // Ensure productId is an integer
    final id = productId is int ? productId : int.tryParse(productId.toString()) ?? 0;
    if (id > 0) {
      Get.toNamed('/product-details', arguments: id);
    } else {
      Get.snackbar('Error', 'Invalid product ID');
    }
  }
  
  /// Navigate to search
  void navigateToSearch() {
    Get.toNamed('/search');
  }
  
  /// Navigate to cart
  void navigateToCart() {
    // Check if user is logged in
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar(
        'Login Required',
        'Please login to view your cart',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Navigate to login
      Future.delayed(const Duration(milliseconds: 500), () {
        AppRoutes.toLogin();
      });
      return;
    }
    Get.toNamed('/cart');
  }
  
  /// Navigate to notifications
  void navigateToNotifications() {
    // TODO: Navigate to notifications screen
    Get.snackbar('Info', 'Notifications screen coming soon');
  }
  
  /// Show sort dialog for featured products
  void showSortDialog() {
    Get.bottomSheet(
      _SortBottomSheet(
        currentSort: featuredSortBy.value,
        onSortSelected: (sortOption) {
          featuredSortBy.value = sortOption;
          sortFeaturedProducts();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }
  
  /// Sort featured products based on selected option
  void sortFeaturedProducts() {
    final products = List<Map<String, dynamic>>.from(featuredProducts);
    
    switch (featuredSortBy.value) {
      case 'price_low':
        products.sort((a, b) {
          final priceA = (a['sale_price'] ?? a['price'] ?? 0.0) as double;
          final priceB = (b['sale_price'] ?? b['price'] ?? 0.0) as double;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high':
        products.sort((a, b) {
          final priceA = (a['sale_price'] ?? a['price'] ?? 0.0) as double;
          final priceB = (b['sale_price'] ?? b['price'] ?? 0.0) as double;
          return priceB.compareTo(priceA);
        });
        break;
      case 'rating':
        products.sort((a, b) {
          final ratingA = (a['rating'] ?? 0.0) as double;
          final ratingB = (b['rating'] ?? 0.0) as double;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'newest':
        // For newest, we'll keep original order (assuming API returns newest first)
        // If you have created_at field, sort by that
        break;
      case 'default':
      default:
        // Reload from API to get default order
        loadFeaturedProducts();
        return;
    }
    
    featuredProducts.value = products;
  }
  
  /// Show popular/sort dialog for discounted products
  void showDiscountedSortDialog() {
    Get.bottomSheet(
      _DiscountedSortBottomSheet(
        currentSort: discountedSortBy.value,
        onSortSelected: (sortOption) {
          discountedSortBy.value = sortOption;
          sortDiscountedProducts();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }
  
  /// Sort discounted products based on selected option
  void sortDiscountedProducts() {
    final products = List<Map<String, dynamic>>.from(discountedProducts);
    
    switch (discountedSortBy.value) {
      case 'popular':
        // Sort by rating * review_count (popularity score)
        products.sort((a, b) {
          final ratingA = (a['rating'] ?? 0.0) as double;
          final reviewsA = (a['review_count'] ?? a['reviews'] ?? 0) as int;
          final popularityA = ratingA * reviewsA;
          
          final ratingB = (b['rating'] ?? 0.0) as double;
          final reviewsB = (b['review_count'] ?? b['reviews'] ?? 0) as int;
          final popularityB = ratingB * reviewsB;
          
          return popularityB.compareTo(popularityA);
        });
        break;
      case 'price_low':
        products.sort((a, b) {
          final priceA = (a['sale_price'] ?? a['price'] ?? 0.0) as double;
          final priceB = (b['sale_price'] ?? b['price'] ?? 0.0) as double;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high':
        products.sort((a, b) {
          final priceA = (a['sale_price'] ?? a['price'] ?? 0.0) as double;
          final priceB = (b['sale_price'] ?? b['price'] ?? 0.0) as double;
          return priceB.compareTo(priceA);
        });
        break;
      case 'rating':
        products.sort((a, b) {
          final ratingA = (a['rating'] ?? 0.0) as double;
          final ratingB = (b['rating'] ?? 0.0) as double;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'discount_high':
        // Sort by discount percentage (highest discount first)
        products.sort((a, b) {
          final discountA = a['discount_percent'] ?? 
              _calculateDiscountPercent(a['price'], a['sale_price']);
          final discountB = b['discount_percent'] ?? 
              _calculateDiscountPercent(b['price'], b['sale_price']);
          return (discountB as num).compareTo(discountA as num);
        });
        break;
      default:
        // Reload from API to get default order
        loadDiscountedProducts();
        return;
    }
    
    discountedProducts.value = products;
  }

  /// Show popular/sort dialog for top rated products
  void showTopRatedSortDialog() {
    Get.bottomSheet(
      _DiscountedSortBottomSheet(
        currentSort: topRatedSortBy.value,
        onSortSelected: (sortOption) {
          topRatedSortBy.value = sortOption;
          sortTopRatedProducts();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }

  /// Sort top rated products based on selected option
  void sortTopRatedProducts() {
    final products = List<Map<String, dynamic>>.from(topRatedProducts);
    
    switch (topRatedSortBy.value) {
      case 'popular':
        // Sort by rating * review_count (popularity score)
        products.sort((a, b) {
          final ratingA = (a['rating'] ?? 0.0) as double;
          final reviewsA = (a['review_count'] ?? a['reviews'] ?? 0) as int;
          final popularityA = ratingA * reviewsA;
          
          final ratingB = (b['rating'] ?? 0.0) as double;
          final reviewsB = (b['review_count'] ?? b['reviews'] ?? 0) as int;
          final popularityB = ratingB * reviewsB;
          
          return popularityB.compareTo(popularityA);
        });
        break;
      case 'price_low':
        products.sort((a, b) {
          final priceA = (a['sale_price'] ?? a['price'] ?? 0.0) as double;
          final priceB = (b['sale_price'] ?? b['price'] ?? 0.0) as double;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high':
        products.sort((a, b) {
          final priceA = (a['sale_price'] ?? a['price'] ?? 0.0) as double;
          final priceB = (b['sale_price'] ?? b['price'] ?? 0.0) as double;
          return priceB.compareTo(priceA);
        });
        break;
      case 'rating':
        products.sort((a, b) {
          final ratingA = (a['rating'] ?? 0.0) as double;
          final ratingB = (b['rating'] ?? 0.0) as double;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'discount_high':
        // Sort by discount percentage (highest discount first)
        products.sort((a, b) {
          final discountA = a['discount_percent'] ?? 
              _calculateDiscountPercent(a['price'], a['sale_price']);
          final discountB = b['discount_percent'] ?? 
              _calculateDiscountPercent(b['price'], b['sale_price']);
          return (discountB as num).compareTo(discountA as num);
        });
        break;
      default:
        // Reload from API to get default order
        loadTopRatedProducts();
        return;
    }
    
    topRatedProducts.value = products;
  }
  
  /// Calculate discount percentage
  int _calculateDiscountPercent(dynamic regularPrice, dynamic salePrice) {
    final regPrice = double.tryParse(regularPrice?.toString() ?? '0') ?? 0.0;
    final sale = double.tryParse(salePrice?.toString() ?? '0') ?? 0.0;
    if (regPrice > 0 && sale > 0 && regPrice > sale) {
      return ((regPrice - sale) / regPrice * 100).round();
    }
    return 0;
  }
}

/// Discounted Products Sort Bottom Sheet Widget
class _DiscountedSortBottomSheet extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;
  
  const _DiscountedSortBottomSheet({
    required this.currentSort,
    required this.onSortSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ScreenSize.tileBorderRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: ScreenSize.spacingMedium),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: ScreenSize.headingMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingLarge),
                
                _SortOption(
                  title: 'Popular',
                  icon: Icons.trending_up,
                  isSelected: currentSort == 'popular',
                  onTap: () {
                    onSortSelected('popular');
                    Get.back();
                  },
                ),
                _SortOption(
                  title: 'Highest Discount',
                  icon: Icons.local_offer,
                  isSelected: currentSort == 'discount_high',
                  onTap: () {
                    onSortSelected('discount_high');
                    Get.back();
                  },
                ),
                _SortOption(
                  title: 'Price: Low to High',
                  icon: Icons.arrow_upward,
                  isSelected: currentSort == 'price_low',
                  onTap: () {
                    onSortSelected('price_low');
                    Get.back();
                  },
                ),
                _SortOption(
                  title: 'Price: High to Low',
                  icon: Icons.arrow_downward,
                  isSelected: currentSort == 'price_high',
                  onTap: () {
                    onSortSelected('price_high');
                    Get.back();
                  },
                ),
                _SortOption(
                  title: 'Highest Rated',
                  icon: Icons.star,
                  isSelected: currentSort == 'rating',
                  onTap: () {
                    onSortSelected('rating');
                    Get.back();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sort Bottom Sheet Widget
class _SortBottomSheet extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;
  
  const _SortBottomSheet({
    required this.currentSort,
    required this.onSortSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ScreenSize.tileBorderRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: ScreenSize.spacingMedium),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: ScreenSize.headingMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingLarge),
                
                _SortOption(
                  title: 'Default',
                  icon: Icons.sort,
                  isSelected: currentSort == 'default',
                  onTap: () {
                    onSortSelected('default');
                    Get.back();
                  },
                ),
                _SortOption(
                  title: 'Price: Low to High',
                  icon: Icons.arrow_upward,
                  isSelected: currentSort == 'price_low',
                  onTap: () {
                    onSortSelected('price_low');
                    Get.back();
                  },
                ),
                _SortOption(
                  title: 'Price: High to Low',
                  icon: Icons.arrow_downward,
                  isSelected: currentSort == 'price_high',
                  onTap: () {
                    onSortSelected('price_high');
                    Get.back();
                  },
                ),
                _SortOption(
                  title: 'Highest Rated',
                  icon: Icons.star,
                  isSelected: currentSort == 'rating',
                  onTap: () {
                    onSortSelected('rating');
                    Get.back();
                  },
                ),
                _SortOption(
                  title: 'Newest First',
                  icon: Icons.new_releases,
                  isSelected: currentSort == 'newest',
                  onTap: () {
                    onSortSelected('newest');
                    Get.back();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sort Option Widget
class _SortOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _SortOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: ScreenSize.iconMedium,
            ),
            SizedBox(width: ScreenSize.spacingMedium),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: AppColors.primary,
                size: ScreenSize.iconMedium,
              ),
          ],
        ),
      ),
    );
  }
}

