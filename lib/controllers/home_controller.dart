import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/location_service.dart';
import '../widgets/location_selection_dialog.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';
import '../utils/product_details_navigation.dart';
import 'wishlist_controller.dart';
import 'notification_controller.dart';

/// Home Controller
/// Handles home screen logic (categories, products, banners, etc.)
class HomeController extends GetxController {
  final RxInt currentBannerIndex = 0.obs;
  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool isLoading = false.obs;
  /// Set after first successful/cached load — avoids full-page spinner on return.
  final RxBool hasEverLoaded = false.obs;
  final ApiService _apiService = ApiService();
  
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> banners = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> featuredProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> discountedProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topRatedProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> digitalProducts = <Map<String, dynamic>>[].obs;

  // Category-specific product lists for home showcases
  final RxList<Map<String, dynamic>> homeDecorProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> healthProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> stationeryProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> collectiblesProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> cartoonLineProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> stickerProducts = <Map<String, dynamic>>[].obs;
  
  // New section lists for more content
  final RxList<Map<String, dynamic>> newArrivalsProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> budgetProducts = <Map<String, dynamic>>[].obs; // Under $50
  final RxList<Map<String, dynamic>> mediaShowcaseProducts = <Map<String, dynamic>>[].obs; // Audio/Video

  // Recently viewed products (local tracking)
  final RxList<Map<String, dynamic>> recentlyViewed = <Map<String, dynamic>>[].obs;
  
  // Real-time counts for UI
  final RxInt activeOrdersCount = 0.obs;
  final RxInt referralCount = 0.obs;

  // Sort options
  final RxString featuredSortBy = 'default'.obs;
  final RxString discountedSortBy = 'popular'.obs;
  final RxString topRatedSortBy = 'popular'.obs;
  
  // Location/Address management
  final RxList<Map<String, dynamic>> addresses = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> selectedLocation = Rxn<Map<String, dynamic>>();

  /// True when cached or loaded data can be shown (skip full-page spinner).
  bool get hasDisplayableContent =>
      categories.isNotEmpty ||
      banners.isNotEmpty ||
      featuredProducts.isNotEmpty ||
      products.isNotEmpty ||
      digitalProducts.isNotEmpty;
  
  void _markLoadedIfNeeded() {
    if (hasDisplayableContent) hasEverLoaded.value = true;
  }

  /// Load cached home page data to render instantly
  void loadCachedData() {
    try {
      final cachedCategories = CacheManager.getData<List>('home_categories');
      if (cachedCategories != null) {
        categories.value = List<Map<String, dynamic>>.from(cachedCategories);
      }

      final cachedBanners = CacheManager.getData<List>('home_banners');
      if (cachedBanners != null) {
        banners.value = List<Map<String, dynamic>>.from(cachedBanners);
      }

      final cachedFeatured = CacheManager.getData<List>('home_featured_products');
      if (cachedFeatured != null) {
        featuredProducts.value = _normalizeCachedProducts(cachedFeatured);
      }

      final cachedProducts = CacheManager.getData<List>('home_products');
      if (cachedProducts != null) {
        products.value = _normalizeCachedProducts(cachedProducts);
      }

      final cachedDiscounted = CacheManager.getData<List>('home_discounted_products');
      if (cachedDiscounted != null) {
        discountedProducts.value = _normalizeCachedProducts(cachedDiscounted);
      }

      final cachedTopRated = CacheManager.getData<List>('home_top_rated_products');
      if (cachedTopRated != null) {
        topRatedProducts.value = _normalizeCachedProducts(cachedTopRated);
      }

      final cachedDigital = CacheManager.getData<List>('home_digital_products');
      if (cachedDigital != null) {
        digitalProducts.value = _normalizeCachedProducts(cachedDigital);
      }

      final cachedDecor = CacheManager.getData<List>('home_decor_products');
      if (cachedDecor != null) {
        homeDecorProducts.value = _normalizeCachedProducts(cachedDecor);
      }

      final cachedHealth = CacheManager.getData<List>('home_health_products');
      if (cachedHealth != null) {
        healthProducts.value = _normalizeCachedProducts(cachedHealth);
      }

      final cachedStationery = CacheManager.getData<List>('home_stationery_products');
      if (cachedStationery != null) {
        stationeryProducts.value = _normalizeCachedProducts(cachedStationery);
      }

      final cachedCollectibles = CacheManager.getData<List>('home_collectibles_products');
      if (cachedCollectibles != null) {
        collectiblesProducts.value = _normalizeCachedProducts(cachedCollectibles);
      }

      final cachedCartoonLine = CacheManager.getData<List>('home_cartoon_line_products');
      if (cachedCartoonLine != null) {
        cartoonLineProducts.value = _normalizeCachedProducts(cachedCartoonLine);
      }

      final cachedStickers = CacheManager.getData<List>('home_sticker_products');
      if (cachedStickers != null) {
        stickerProducts.value = _normalizeCachedProducts(cachedStickers);
      }

      final cachedNewArrivals = CacheManager.getData<List>('home_new_arrivals_products');
      if (cachedNewArrivals != null) {
        newArrivalsProducts.value = _normalizeCachedProducts(cachedNewArrivals);
      }

      final cachedBudget = CacheManager.getData<List>('home_budget_products');
      if (cachedBudget != null) {
        budgetProducts.value = _normalizeCachedProducts(cachedBudget);
      }

      final cachedMedia = CacheManager.getData<List>('home_media_showcase_products');
      if (cachedMedia != null) {
        mediaShowcaseProducts.value = _normalizeCachedProducts(cachedMedia);
      }

      final cachedRecentlyViewed = CacheManager.getData<List>('home_recently_viewed');
      if (cachedRecentlyViewed != null) {
        recentlyViewed.value = List<Map<String, dynamic>>.from(cachedRecentlyViewed);
      }

      activeOrdersCount.value = CacheManager.getData<int>('home_active_orders_count') ?? 0;
      referralCount.value = CacheManager.getData<int>('home_referral_count') ?? 0;
      rebuildMediaShowcase();
      _markLoadedIfNeeded();
    } catch (e) {
      print('Error loading cached home data: $e');
    }
  }

  List<Map<String, dynamic>> _normalizeCachedProducts(List source) {
    return source.map<Map<String, dynamic>>((item) {
      final map = Map<String, dynamic>.from(item as Map);
      if (map['image'] is String) {
        map['image'] = _getImageUrl(map['image'].toString());
      }
      if (map['banner'] is String) {
        map['banner'] = _getImageUrl(map['banner'].toString());
      }
      return map;
    }).toList();
  }

  /// Save current home page lists to cache
  void saveAllToCache() {
    try {
      CacheManager.saveData('home_categories', categories.toList());
      CacheManager.saveData('home_banners', banners.toList());
      CacheManager.saveData('home_featured_products', featuredProducts.toList());
      CacheManager.saveData('home_products', products.toList());
      CacheManager.saveData('home_discounted_products', discountedProducts.toList());
      CacheManager.saveData('home_top_rated_products', topRatedProducts.toList());
      CacheManager.saveData('home_digital_products', digitalProducts.toList());
      CacheManager.saveData('home_decor_products', homeDecorProducts.toList());
      CacheManager.saveData('home_health_products', healthProducts.toList());
      CacheManager.saveData('home_stationery_products', stationeryProducts.toList());
      CacheManager.saveData('home_collectibles_products', collectiblesProducts.toList());
      CacheManager.saveData('home_cartoon_line_products', cartoonLineProducts.toList());
      CacheManager.saveData('home_sticker_products', stickerProducts.toList());
      CacheManager.saveData('home_new_arrivals_products', newArrivalsProducts.toList());
      CacheManager.saveData('home_budget_products', budgetProducts.toList());
      CacheManager.saveData('home_media_showcase_products', mediaShowcaseProducts.toList());
      CacheManager.saveData('home_recently_viewed', recentlyViewed.toList());
      CacheManager.saveData('home_active_orders_count', activeOrdersCount.value);
      CacheManager.saveData('home_referral_count', referralCount.value);
    } catch (e) {
      print('Error saving home data to cache: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // Initialize wishlist controller first to ensure isFavorite status is available
    if (CacheManager.isLoggedIn() && !Get.isRegistered<WishlistController>()) {
      Get.put(WishlistController());
    }
    
    // Load cache immediately for instant smooth rendering
    loadCachedData();
    
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
  Future<void> loadHomeData({bool silent = false}) async {
    if (!silent && !hasEverLoaded.value) {
      isLoading.value = true;
      update();
    }
    try {
      // Prepare list of futures
      List<Future> futures = [
        loadCategories(),
        loadBanners(),
        loadFeaturedProducts(),
        loadDiscountedProducts(),
        loadTopRatedProducts(),
        loadDigitalProducts(),
        loadProducts(),
        // Category-specific sections
        loadCategoryProducts(13, homeDecorProducts),   // Video
        loadCategoryProducts(12, healthProducts),      // Audio
        loadCategoryProducts(15, stationeryProducts),  // Sticker
        loadCategoryProducts(13, collectiblesProducts), // Video
        loadCategoryProducts(12, cartoonLineProducts),  // Audio
        loadCategoryProducts(15, stickerProducts),       // Sticker
        // New sections
        loadNewArrivals(),
        loadBudgetProducts(50.0),
        // Load real-time counts
        loadActiveOrdersCount(),
        loadReferralCount(),
      ];
      
      // Add wishlist loading if user is logged in
      if (CacheManager.isLoggedIn()) {
        if (Get.isRegistered<WishlistController>()) {
          final wishlistController = Get.find<WishlistController>();
          futures.add(wishlistController.loadWishlist());
        } else {
          final wishlistController = Get.put(WishlistController());
          futures.add(wishlistController.loadWishlist());
        }
      }
      
      // Load all data in parallel instead of sequentially for much faster loading
      await Future.wait(futures, eagerError: false);

      rebuildMediaShowcase();

      // Save loaded data to local cache
      saveAllToCache();
    } catch (e) {
      // Log error but don't show snackbar immediately - let user see partial data
      print('Error loading home data: $e');
      // Only show error if critical data failed
      if (categories.isEmpty && banners.isEmpty) {
        ApiService.showErrorSnackbar(e);
      }
    } finally {
      _markLoadedIfNeeded();
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
        // Get.snackbar(
        //   'No Address',
        //   'Please add a delivery address',
        //   duration: Duration(seconds: 2),
        // );
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
  
  /// Use current location (navigate to add-address so user can save it)
  Future<void> useCurrentLocation() async {
    Get.back(); // Close dialog
    final result = await Get.toNamed('/add-address', arguments: {'use_current_location': true});
    // Reload location so home page shows updated address
    await loadUserLocation();
    if (result == true) {
      // Get.snackbar('Done', 'Address saved. You can use it for delivery.', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    }
  }
  
  /// Get current location and set as selected (for home page display)
  Future<void> detectAndSetCurrentLocation() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final locationService = LocationService();
      final permission = await locationService.requestLocationPermission().timeout(
        const Duration(seconds: 60),
        onTimeout: () => LocationPermission.denied,
      );
      final isGranted = permission == LocationPermission.whileInUse || permission == LocationPermission.always;

      if (!isGranted) {
        Get.back(); // Close loading dialog
        return; // Snackbar already shown by LocationService
      }

      await Future.delayed(const Duration(milliseconds: 400));
      final locationData = await locationService.getCurrentLocation().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          // Get.snackbar('Location Timeout', 'Could not get location in time. Please try again.', snackPosition: SnackPosition.BOTTOM);
          return null;
        },
      );

      Get.back(); // Close loading dialog

      if (locationData != null) {
        selectedLocation.value = locationData;
        // Get.snackbar('Success', 'Current location detected!', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      // Get.snackbar('Error', 'Failed to detect location: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
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
  
  /// Load banners dynamically from backend (DB + uploads/banners/ folder scan)
  Future<void> loadBanners() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.bannersList,
        queryParameters: {'status': 'active'}, 
      );
      final data = ApiService.handleResponse(response);
      final bannersList = data['banners'] ?? [];
      
      print('[Banners] API returned ${(bannersList as List).length} banners');
      
      final List<Map<String, dynamic>> parsedBanners = [];
      for (final banner in bannersList) {
        final bannerMap = Map<String, dynamic>.from(banner);
        final imageUrl = bannerMap['image']?.toString() ?? '';
        print('[Banners] Banner id=${bannerMap['id']}, image=$imageUrl');
        
        parsedBanners.add(<String, dynamic>{
          'id': bannerMap['id'],
          'image': imageUrl, // Already full URL from backend
          'title': bannerMap['title']?.toString() ?? '',
          'description': bannerMap['description']?.toString() ?? '',
          'link_url': bannerMap['link_url']?.toString() ?? '',
          'link_text': bannerMap['link_text']?.toString() ?? 'Shop Now',
        });
      }
      
      banners.value = parsedBanners;
      print('[Banners] Successfully loaded ${banners.length} banners');
    } catch (e) {
      print('[Banners] Error loading banners: $e');
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
      
      var list = productsList as List;
      if (list.isEmpty) {
        final fallback = await _apiService.get(
          ApiEndpoints.productsList,
          queryParameters: {'limit': '6'},
        );
        final fallbackData = ApiService.handleResponse(fallback);
        list = fallbackData['products'] ?? [];
      }
      featuredProducts.value = list.map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
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
  
  /// Load digital products only (instant download after payment)
  Future<void> loadDigitalProducts() async {
    try {
      print('=== HomeController.loadDigitalProducts ===');
      
      // Use regular products API to get digital products
      print('Loading from regular products API...');
      final response = await _apiService.get(
        ApiEndpoints.productsList,
        queryParameters: {'limit': '50'}, // Load more products to find digital ones
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      print('Total products from API: ${productsList.length}');
      
      // Filter digital products
      final digitalProductsList = productsList.where((p) => 
        p['is_digital'] == true || p['is_digital'] == 1
      ).toList();
      
      print('Digital products found: ${digitalProductsList.length}');
      
      // Check for media types
      final videoProducts = digitalProductsList.where((p) => 
        p['media_type']?.toString().toLowerCase() == 'video'
      ).toList();
      final audioProducts = digitalProductsList.where((p) => 
        p['media_type']?.toString().toLowerCase() == 'audio'
      ).toList();
      print('Video products found: ${videoProducts.length}');
      print('Audio products found: ${audioProducts.length}');
      
      // Print first few digital products for debugging
      if (digitalProductsList.isNotEmpty) {
        print('First digital product details:');
        print('  ID: ${digitalProductsList.first['id']}');
        print('  Name: ${digitalProductsList.first['name']}');
        print('  is_digital: ${digitalProductsList.first['is_digital']}');
        print('  media_type: ${digitalProductsList.first['media_type']}');
        print('  category_id: ${digitalProductsList.first['category_id']}');
      }
      
      digitalProducts.value = (digitalProductsList as List).map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
      print('Formatted digital products: ${digitalProducts.length} items');
      print('====================================');
    } catch (e) {
      print('Error loading digital products: $e');
      if (digitalProducts.isEmpty) {
        digitalProducts.value = [];
      }
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
      
      print('Loading products: ${productsList.length} items found');
      products.value = (productsList as List).map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
      print('Formatted products: ${products.length} items loaded');
    } catch (e) {
      print('Error loading products: $e');
      products.value = [];
    }
  }
  
  /// Load products for a specific category (used for home screen showcases)
  Future<void> loadCategoryProducts(int categoryId, RxList<Map<String, dynamic>> targetList) async {
    try {
      print('=== HomeController.loadCategoryProducts ===');
      print('Loading category products for categoryId: $categoryId');
      
      final response = await _apiService.get(
        ApiEndpoints.productsList,
        queryParameters: {
          'category_id': categoryId.toString(),
          'limit': '10',
        },
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      print('Raw products from API: ${productsList.length} items');
      
      // Check if any digital products in this category
      final digitalProducts = productsList.where((p) => 
        p['is_digital'] == true || p['is_digital'] == 1
      ).toList();
      print('Digital products found in category: ${digitalProducts.length}');
      
      targetList.value = (productsList as List).map((product) => _formatProduct(Map<String, dynamic>.from(product))).toList();
      print('Formatted products in targetList: ${targetList.length} items');
      print('=====================================');
    } catch (e) {
      print('Error loading category products: $e');
      targetList.value = [];
    }
  }

  /// Add product to recently viewed (max 10, no duplicates)
  void addToRecentlyViewed(Map<String, dynamic> product) {
    recentlyViewed.removeWhere((p) => p['id'] == product['id']);
    recentlyViewed.insert(0, product);
    if (recentlyViewed.length > 10) {
      recentlyViewed.removeLast();
    }
    // Save to cache immediately
    CacheManager.saveData('home_recently_viewed', recentlyViewed.toList());
  }

  /// Load New Arrivals (sorted by newest first)
  Future<void> loadNewArrivals() async {
    try {
      final response = await _apiService.get(ApiEndpoints.productsList, queryParameters: {'sort': 'newest', 'limit': '10'});
      final data = ApiService.handleResponse(response);
      final list = data['products'] ?? [];
      newArrivalsProducts.value = (list as List).map((p) => _formatProduct(Map<String, dynamic>.from(p))).toList();
    } catch (e) {
      newArrivalsProducts.value = [];
    }
  }

  /// Load Budget Products (items under a certain price)
  Future<void> loadBudgetProducts(double maxPrice) async {
    try {
      final response = await _apiService.get(ApiEndpoints.productsList, queryParameters: {'limit': '50'});
      final data = ApiService.handleResponse(response);
      final list = data['products'] ?? [];
      final formatted = (list as List).map((p) => _formatProduct(Map<String, dynamic>.from(p))).toList();
      budgetProducts.value = formatted.where((p) {
        final price = p['sale_price'] ?? p['price'] ?? 0.0;
        final numericPrice = price is double ? price : double.tryParse(price.toString()) ?? 0.0;
        return numericPrice > 0 && numericPrice <= maxPrice;
      }).take(10).toList();
    } catch (e) {
      budgetProducts.value = [];
    }
  }

  /// Media Spotlight — interleave video, audio, stickers (no audio-only overwrite).
  void rebuildMediaShowcase({int maxTotal = 10}) {
    final merged = _interleaveProductLists(
      [
        homeDecorProducts,
        healthProducts,
        stickerProducts,
        collectiblesProducts,
        cartoonLineProducts,
      ],
      maxTotal: maxTotal,
    );
    if (merged.isNotEmpty) {
      mediaShowcaseProducts.value = merged;
    }
  }

  List<Map<String, dynamic>> _interleaveProductLists(
    List<RxList<Map<String, dynamic>>> sources, {
    int maxTotal = 10,
  }) {
    final seen = <dynamic>{};
    final result = <Map<String, dynamic>>[];
    final lists = sources.map((s) => s.toList()).toList();
    var round = 0;
    while (result.length < maxTotal) {
      var added = false;
      for (final list in lists) {
        if (round >= list.length) continue;
        final p = list[round];
        final id = p['id'];
        if (id == null || !seen.add(id)) continue;
        result.add(Map<String, dynamic>.from(p));
        added = true;
        if (result.length >= maxTotal) break;
      }
      if (!added) break;
      round++;
    }
    return result;
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
    }
    
    // Extract digital and media type information
    final bool isDigital = product['is_digital'] == true || product['is_digital'] == 1;
    String mediaType = product['media_type']?.toString() ?? '';
    
    // Extract banner URL for digital products
    String bannerUrl = '';
    if (isDigital && product['banner'] != null) {
      bannerUrl = product['banner'].toString();
      if (bannerUrl.isNotEmpty) {
        bannerUrl = _getImageUrl(bannerUrl);
      }
    }
    
    // Extract video URL for video products
    String videoUrl = '';
    if (isDigital && mediaType == 'video' && product['video_url'] != null) {
      videoUrl = product['video_url'].toString();
    }
    
    // If media_type is not set, try to detect from category name
    if (isDigital && mediaType.isEmpty) {
      final category = product['category'];
      if (category != null && category['name'] != null) {
        final categoryName = category['name'].toString().toLowerCase();
        if (categoryName.contains('video')) {
          mediaType = 'video';
        } else if (categoryName.contains('audio') || categoryName.contains('music')) {
          mediaType = 'audio';
        }
      }
    }
    
    // Debug print to check formatted data
    print('=== HomeController._formatProduct ===');
    print('Product ID: ${product['id']}');
    print('Original is_digital: ${product['is_digital']} (type: ${product['is_digital'].runtimeType})');
    print('Original media_type: ${product['media_type']} (type: ${product['media_type'].runtimeType})');
    print('Category name: ${product['category']?['name']}');
    print('Detected is_digital: $isDigital');
    print('Detected media_type: $mediaType');
    print('Banner URL: $bannerUrl');
    print('Video URL: $videoUrl');
    print('================================');
    
    final Map<String, dynamic> formattedProduct = {
      'id': product['id'],
      'name': product['name'] ?? '',
      'price': product['price'] ?? 0.0,
      'sale_price': product['sale_price'] ?? null,
      'originalPrice': product['sale_price'] != null ? product['price'] : null,
      'image': imageUrl,
      'banner': bannerUrl,  // Added banner URL
      'video_url': videoUrl,  // Added video URL
      'rating': double.tryParse(product['rating']?.toString() ?? '0') ?? 0.0,
      'reviews': int.tryParse(product['review_count']?.toString() ?? product['reviews_count']?.toString() ?? '0') ?? 0,
      'review_count': int.tryParse(product['review_count']?.toString() ?? product['reviews_count']?.toString() ?? '0') ?? 0,
      'isFavorite': _checkWishlistStatus(product['id']),
      'category': product['category'] ?? {},
      'category_id': product['category_id'] ??
          (product['category'] is Map ? product['category']['id'] : null),
      'discount_percent': product['discount_percent'] ?? null,
      'is_digital': isDigital,
      'media_type': mediaType,
    };
    
    return formattedProduct;
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

    cleanUrl = cleanUrl.replaceAll(
      'https://ecommercepanel.templateforwebsites.com/',
      'https://admin.fosproductions.org/',
    );
    
    // If already full URL, return cleaned version
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return cleanUrl;
    }
    
    // If relative path, add base URL
    // Remove leading slash if present
    final cleanPath = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
    
    // Check if path already includes 'banners/' or 'uploads/'
    if (cleanPath.contains('products/') || cleanPath.contains('uploads/')) {
      // If it already contains 'uploads/', don't double it if imageBaseUrl also has it
      if (cleanPath.startsWith('uploads/') && ApiService.imageBaseUrl.endsWith('uploads/')) {
        return '${ApiService.imageBaseUrl.replaceAll('uploads/', '')}$cleanPath';
      }
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
          // Get.snackbar('Error', 'Failed to open category: $error');
        });
        
        print('Navigation called successfully');
      } catch (e, stackTrace) {
        print('Navigation error: $e');
        print('Stack trace: $stackTrace');
        // Get.snackbar('Error', 'Failed to open category: $e');
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
      
      final wasInWishlist = wishlistController.isInWishlist(productId);
      final isNowInWishlist = !wasInWishlist;
      
      void updateLocalFavoriteState(bool state) =>
          _setFavoriteOnAllLists(productId, state);

      // 1. Optimistic Update immediately
      updateLocalFavoriteState(isNowInWishlist);
      
      // 2. Perform API call in background/async
      final success = await wishlistController.toggleWishlist(productId);
      
      if (success) {
        // Show feedback
        if (isNowInWishlist) {
          Get.snackbar('Success', 'Added to wishlist', duration: const Duration(seconds: 2));
        } else {
          Get.snackbar('Success', 'Removed from wishlist', duration: const Duration(seconds: 2));
        }
      } else {
        // 3. Revert on failure
        updateLocalFavoriteState(wasInWishlist);
      }
    } catch (e) {
      if (Get.isRegistered<WishlistController>()) {
        final originalState =
            Get.find<WishlistController>().isInWishlist(productId);
        _setFavoriteOnAllLists(productId, originalState);
      }
      Get.snackbar('Error', 'Failed to update wishlist: ${e.toString()}');
    }
  }

  void _setFavoriteOnAllLists(int productId, bool state) {
    final lists = [
      featuredProducts,
      products,
      discountedProducts,
      topRatedProducts,
      digitalProducts,
      homeDecorProducts,
      healthProducts,
      stationeryProducts,
      collectiblesProducts,
      cartoonLineProducts,
      stickerProducts,
      newArrivalsProducts,
      budgetProducts,
      mediaShowcaseProducts,
      recentlyViewed,
    ];
    for (final list in lists) {
      final i = list.indexWhere((p) => p['id'] == productId);
      if (i != -1) {
        list[i]['isFavorite'] = state;
        list.refresh();
      }
    }
  }
  
  /// Find a product across all home lists (for instant detail preview).
  Map<String, dynamic>? findProductById(int id) {
    final lists = [
      featuredProducts,
      products,
      digitalProducts,
      discountedProducts,
      topRatedProducts,
      homeDecorProducts,
      healthProducts,
      stationeryProducts,
      collectiblesProducts,
      cartoonLineProducts,
      stickerProducts,
      newArrivalsProducts,
      budgetProducts,
      mediaShowcaseProducts,
      recentlyViewed,
    ];
    for (final list in lists) {
      final found = list.firstWhereOrNull((p) => p['id'] == id);
      if (found != null) {
        return Map<String, dynamic>.from(found);
      }
    }
    return null;
  }

  /// Navigate to product details — preview first, no blocking spinner.
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
    final item = preview ?? findProductById(id);
    ProductDetailsNavigation.go(id: id, preview: item);
    if (item != null) {
      _prefetchProductImages(item);
    }
  }

  /// Prefetch product images for faster loading
  Future<void> _prefetchProductImages(Map<String, dynamic> product) async {
    try {
      final images = <String>[];

      // Add main image
      if (product['image'] != null && product['image'].toString().isNotEmpty) {
        images.add(_getImageUrl(product['image'].toString()));
      }

      // Add additional images from images array
      if (product['images'] != null && product['images'] is List) {
        for (var img in product['images']) {
          if (img != null && img.toString().isNotEmpty) {
            images.add(_getImageUrl(img.toString()));
          }
        }
      }

      // Prefetch all images using DefaultCacheManager
      for (var imageUrl in images) {
        try {
          await cache.DefaultCacheManager().getSingleFile(imageUrl);
        } catch (e) {
          print('[HomeController] Failed to prefetch image: $imageUrl, error: $e');
        }
      }
    } catch (e) {
      print('[HomeController] Error prefetching images: $e');
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
    Get.toNamed(AppRoutes.notifications);
  }
  
  /// Get notification count (for badge)
  RxInt get notificationCount {
    try {
      if (Get.isRegistered<NotificationController>()) {
        final notificationController = Get.find<NotificationController>();
        final count = notificationController.unreadCount;
        print('[HomeController] Notification count: ${count.value}');
        return count;
      }
    } catch (e) {
      print('[HomeController] Error getting notification count: $e');
    }
    return 0.obs; // Fallback to 0 if controller not available
  }
  
  int getNotificationCount() {
    return notificationCount.value;
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

  /// Load active orders count
  Future<void> loadActiveOrdersCount() async {
    try {
      if (!CacheManager.isLoggedIn()) {
        activeOrdersCount.value = 0;
        return;
      }
      
      final response = await _apiService.get(ApiEndpoints.ordersList);
      ApiService.handleResponse(response);
      
      if (response.data['success'] == true) {
        final orders = response.data['data'] as List? ?? [];
        // Count all orders (digital and physical)
        activeOrdersCount.value = orders.length;
      }
    } catch (e) {
      // Keep previous count on error
      print('Error loading orders count: $e');
    }
  }

  /// Load referral count
  Future<void> loadReferralCount() async {
    try {
      if (!CacheManager.isLoggedIn()) {
        referralCount.value = 0;
        return;
      }
      
      // Mock referral count for now - replace with actual API call
      // This could be from a referral endpoint or user profile data
      referralCount.value = 2; // Example: 2 active referrals
      
      // Future implementation:
      // final response = await _apiService.get(ApiEndpoints.referrals);
      // if (response.data['success'] == true) {
      //   referralCount.value = response.data['data']['active_referrals'] ?? 0;
      // }
    } catch (e) {
      // Keep previous count on error
      print('Error loading referral count: $e');
    }
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

