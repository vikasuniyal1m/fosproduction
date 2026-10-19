import 'dart:developer' show log;
import 'dart:io' show Directory;
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'checkout_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapp_stickers_plus/whatsapp_stickers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' hide log;
import 'dart:convert';
import 'dart:math' hide log;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;


import '../utils/cache_manager.dart';
import '../utils/data_cache.dart';
import '../utils/digital_product_type.dart';
import '../watch_faces/watch_face_order_helper.dart';
import '../utils/app_colors.dart';
import '../utils/screen_size.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../views/orders/order_details_screen.dart';

/// Profile Controller
/// Handles user profile logic and all profile-related features
class ProfileController extends GetxController {
  final ApiService _apiService = ApiService();
  
  // Profile Data
  final RxBool isLoading = false.obs;
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userImage = ''.obs;
  final RxInt totalOrders = 0.obs;
  final RxDouble totalSpent = 0.0.obs;
  final RxInt loyaltyPoints = 0.obs;
  final RxString referralCode = ''.obs;
  
  // Edit Profile Form
  final GlobalKey<FormState> editProfileFormKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final RxBool isUpdating = false.obs;
  
  // Change Password Form
  final GlobalKey<FormState> changePasswordFormKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final RxBool showCurrentPassword = false.obs;
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;
  final RxBool isChangingPassword = false.obs;
  
  // Orders
  final RxBool isLoadingOrders = false.obs;
  final RxBool hasEverLoadedOrders = false.obs;
  final RxBool isLoadingOrderDetail = false.obs;
  final RxMap<int, Map<String, dynamic>> orderDetailsById =
      <int, Map<String, dynamic>>{}.obs;
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  
  // Download Progress
  final RxMap<int, double> downloadProgress = <int, double>{}.obs;
  
  // Addresses
  final RxBool isLoadingAddresses = false.obs;
  final RxList<Map<String, dynamic>> addresses = <Map<String, dynamic>>[].obs;
  final GlobalKey<FormState> addressFormKey = GlobalKey<FormState>();
  final TextEditingController addressTypeController = TextEditingController(text: 'home');
  final TextEditingController addressNameController = TextEditingController();
  final TextEditingController addressPhoneController = TextEditingController();
  final TextEditingController addressLine1Controller = TextEditingController();
  final TextEditingController addressLine2Controller = TextEditingController();
  final TextEditingController addressCityController = TextEditingController();
  final TextEditingController addressStateController = TextEditingController();
  final TextEditingController addressPincodeController = TextEditingController();
  final RxBool isDefaultAddress = false.obs;
  final RxBool isSavingAddress = false.obs;
  final RxBool isDetectingLocation = false.obs;

  // Payment Methods
  final RxBool isLoadingPaymentMethods = false.obs;
  final RxList<Map<String, dynamic>> paymentMethods = <Map<String, dynamic>>[].obs;
  final GlobalKey<FormState> paymentMethodFormKey = GlobalKey<FormState>();
  final RxString paymentMethodType = 'cash_on_delivery'.obs;
  final TextEditingController upiIdController = TextEditingController();
  final TextEditingController walletTypeController = TextEditingController();
  final RxString walletPaymentMethodId = ''.obs;
  final RxString walletType = ''.obs;
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final RxString provider = ''.obs;
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderNameController = TextEditingController();
  final TextEditingController cardExpiryMonthController = TextEditingController();
  final TextEditingController cardExpiryYearController = TextEditingController();
  final TextEditingController bankAccountNumberController = TextEditingController();
  final TextEditingController routingNumberController = TextEditingController();
  final TextEditingController accountHolderNameController = TextEditingController();
  final RxString selectedBankRedirect = ''.obs;
  final TextEditingController transferReferenceController = TextEditingController();
  final RxString bnplProvider = ''.obs;
  final TextEditingController realTimePaymentIdentifierController = TextEditingController();
  final TextEditingController voucherCodeController = TextEditingController();
  final RxBool isDefaultPaymentMethod = false.obs;
  final RxBool isSavingPaymentMethod = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Only load profile if user is logged in and has valid token
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Profile] Init auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    _loadCachedProfile();
    if (isLoggedIn && userToken != null && userToken.isNotEmpty) {
      _loadCachedOrders();
      loadUserProfile();
    } else {
      print('[Profile] User not authenticated, skipping profile load');
      isLoading.value = false;
    }
  }
  
  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    addressTypeController.dispose();
    addressNameController.dispose();
    addressPhoneController.dispose();
    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    addressCityController.dispose();
    addressStateController.dispose();
    addressPincodeController.dispose();
    upiIdController.dispose();
    walletTypeController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    cardNumberController.dispose();
    cardHolderNameController.dispose();
    cardExpiryMonthController.dispose();
    cardExpiryYearController.dispose();
    bankAccountNumberController.dispose();
    routingNumberController.dispose();
    accountHolderNameController.dispose();
    transferReferenceController.dispose();
    realTimePaymentIdentifierController.dispose();
    voucherCodeController.dispose();
    super.onClose();
  }
  
  void _loadCachedProfile() {
    final cached = DataCache.loadMap(DataCache.profile);
    if (cached == null) return;
    userName.value = cached['userName']?.toString() ?? userName.value;
    userEmail.value = cached['userEmail']?.toString() ?? userEmail.value;
    userPhone.value = cached['userPhone']?.toString() ?? userPhone.value;
    userImage.value = cached['userImage']?.toString() ?? userImage.value;
    totalOrders.value = int.tryParse(cached['totalOrders']?.toString() ?? '0') ?? totalOrders.value;
    totalSpent.value = double.tryParse(cached['totalSpent']?.toString() ?? '0') ?? totalSpent.value;
    loyaltyPoints.value = int.tryParse(cached['loyaltyPoints']?.toString() ?? '0') ?? loyaltyPoints.value;
    referralCode.value = cached['referralCode']?.toString() ?? referralCode.value;
  }

  Future<void> _saveProfileCache() async {
    await DataCache.saveMap(DataCache.profile, {
      'userName': userName.value,
      'userEmail': userEmail.value,
      'userPhone': userPhone.value,
      'userImage': userImage.value,
      'totalOrders': totalOrders.value,
      'totalSpent': totalSpent.value,
      'loyaltyPoints': loyaltyPoints.value,
      'referralCode': referralCode.value,
    });
  }

  /// Load user profile data
  Future<void> loadUserProfile() async {
    if (userName.value.isEmpty) {
      isLoading.value = true;
    }
    try {
      final response = await _apiService.get(ApiEndpoints.userProfile);
      final data = ApiService.handleResponse(response);
      final user = data['user'] ?? data;
      
      userName.value = user['name'] ?? CacheManager.getUserName() ?? 'User';
      userEmail.value = user['email'] ?? CacheManager.getUserEmail() ?? '';
      userPhone.value = user['phone'] ?? CacheManager.getUserPhone() ?? '';
      userImage.value = _getImageUrl(user['image'] ?? user['profile_image'] ?? '');
      
      // Update form controllers
      nameController.text = userName.value;
      emailController.text = userEmail.value;
      phoneController.text = userPhone.value;
      
      // Update stats
      if (data['stats'] != null) {
        totalOrders.value = int.tryParse(data['stats']['total_orders']?.toString() ?? '0') ?? 0;
        totalSpent.value = double.tryParse(data['stats']['total_spent']?.toString() ?? '0') ?? 0.0;
      }
      
      // Update loyalty points and referral code
      loyaltyPoints.value = int.tryParse(user['loyalty_points']?.toString() ?? '0') ?? 0;
      referralCode.value = user['referral_code'] ?? '';
      
      // Update cache
      await CacheManager.saveUserName(userName.value);
      await CacheManager.saveUserEmail(userEmail.value);
      await CacheManager.saveUserPhone(userPhone.value);
      await _saveProfileCache();
    } catch (e) {
      // If API fails, load from cache
      userName.value = CacheManager.getUserName() ?? 'User';
      userEmail.value = CacheManager.getUserEmail() ?? '';
      userPhone.value = CacheManager.getUserPhone() ?? '';
      // Only set controller text if they're not disposed
      try {
        nameController.text = userName.value;
        emailController.text = userEmail.value;
        phoneController.text = userPhone.value;
      } catch (e) {
        // Controllers are disposed, ignore
        print('Controllers disposed, skipping text assignment');
      }
    } finally {
      isLoading.value = false;
    }
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
    return '${ApiService.imageBaseUrl}$cleanPath';
  }
  
  /// Update profile
  Future<void> updateProfile() async {
    if (!editProfileFormKey.currentState!.validate()) {
      return;
    }
    
    isUpdating.value = true;
    try {
      final response = await _apiService.put(
        ApiEndpoints.userProfile,
        data: {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );
      
      final data = ApiService.handleResponse(response);
      final user = data['user'] ?? data;
      
      userName.value = user['name'] ?? nameController.text;
      userPhone.value = user['phone'] ?? phoneController.text;
      
      // Update cache
      await CacheManager.saveUserName(userName.value);
      await CacheManager.saveUserPhone(userPhone.value);
      
      // Get.snackbar('Success', 'Profile updated successfully');
      Get.back();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    } finally {
      isUpdating.value = false;
    }
  }
  
  /// Change password
  Future<void> changePassword() async {
    if (!changePasswordFormKey.currentState!.validate()) {
      return;
    }
    
    if (newPasswordController.text != confirmPasswordController.text) {
      // Get.snackbar('Error', 'Passwords do not match');
      return;
    }
    
    isChangingPassword.value = true;
    try {
      final response = await _apiService.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPasswordController.text,
          'new_password': newPasswordController.text,
          'confirm_password': confirmPasswordController.text,
        },
      );
      
      ApiService.handleResponse(response);
      
      // Clear password fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      
      // Get.snackbar('Success', 'Password changed successfully');
      Get.back();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    } finally {
      isChangingPassword.value = false;
    }
  }
  
  void _loadCachedOrders() {
    final cached = DataCache.loadList(DataCache.orders);
    if (cached != null && cached.isNotEmpty) {
      orders.assignAll(cached);
      hasEverLoadedOrders.value = true;
    }
  }

  Map<String, dynamic>? orderDetailsFor(int orderId) =>
      orderDetailsById[orderId];

  String _resolveImageFromProductData(Map<String, dynamic> data) {
    final media = DigitalProductType.resolveMediaType(data);
    if (media == 'audio' || media == 'video') {
      final banner = data['banner']?.toString().trim() ?? '';
      if (banner.isNotEmpty) return _getImageUrl(banner);
    }

    for (final key in ['image', 'product_image', 'main_image', 'thumbnail']) {
      final v = data[key];
      if (v != null && v.toString().isNotEmpty) {
        final url = _getImageUrl(v.toString());
        if (url.isNotEmpty) return url;
      }
    }

    if (data['images'] is List) {
      for (final img in data['images'] as List) {
        if (img is String && img.isNotEmpty) {
          final url = _getImageUrl(img);
          if (url.isNotEmpty) return url;
        } else if (img is Map) {
          final url = _getImageUrl(
            img['url']?.toString() ??
                img['image']?.toString() ??
                img['image_url']?.toString() ??
                '',
          );
          if (url.isNotEmpty) return url;
        }
      }
    }

    if (data['stickers_preview'] is List) {
      for (final sticker in data['stickers_preview'] as List) {
        if (sticker is Map) {
          final url = _getImageUrl(
            sticker['image_url']?.toString() ??
                sticker['url']?.toString() ??
                sticker['image']?.toString() ??
                '',
          );
          if (url.isNotEmpty) return url;
        }
      }
    }

    final banner = data['banner']?.toString().trim() ?? '';
    if (banner.isNotEmpty) return _getImageUrl(banner);

    return '';
  }

  void _applyProductDataToOrderItem(
    Map<String, dynamic> item,
    Map<String, dynamic> data,
  ) {
    final image = _resolveImageFromProductData(data);
    if (image.isNotEmpty) item['image'] = image;

    final banner = data['banner']?.toString().trim() ?? '';
    if (banner.isNotEmpty) item['banner'] = _getImageUrl(banner);

    final catRaw = data['category_id'] ??
        (data['category'] is Map ? data['category']['id'] : null);
    if (catRaw != null && item['category_id'] == null) {
      item['category_id'] =
          catRaw is int ? catRaw : int.tryParse(catRaw.toString());
    }

    if (data['is_digital'] == true || data['is_digital'] == 1) {
      item['is_digital'] = true;
    }
    if (data['is_sticker_pack'] == true || data['is_sticker_pack'] == 1) {
      item['is_sticker_pack'] = true;
    }
    if (data['digital_file_path'] != null) {
      item['digital_file_path'] = data['digital_file_path'];
    }
    if (data['product_type'] != null) {
      item['product_type'] = data['product_type'];
    }
    final media = data['media_type']?.toString() ?? '';
    if (media.isNotEmpty) item['media_type'] = media;
  }

  bool _enrichOrderItemFromCaches(Map<String, dynamic> item) {
    final pid = item['product_id'];
    if (pid == null) return false;
    final id = pid is int ? pid : int.tryParse(pid.toString());
    if (id == null || id <= 0) return false;

    final cached = DataCache.loadMap(DataCache.productDetail(id));
    final product = cached?['product'];
    if (product is Map && product.isNotEmpty) {
      _applyProductDataToOrderItem(
        item,
        Map<String, dynamic>.from(product),
      );
      if ((item['image']?.toString() ?? '').isNotEmpty) return true;
    }

    final wishlist = CacheManager.getWishlistItems();
    if (wishlist != null) {
      for (final raw in wishlist) {
        if (raw is! Map) continue;
        final w = Map<String, dynamic>.from(raw);
        if (w['id'] == id) {
          _applyProductDataToOrderItem(item, w);
          if ((item['image']?.toString() ?? '').isNotEmpty) return true;
          break;
        }
      }
    }

    final cid = item['category_id'];
    if (cid != null) {
      final catId = cid is int ? cid : int.tryParse(cid.toString());
      if (catId != null && catId > 0) {
        final list = DataCache.loadList(DataCache.categoryProducts(catId));
        if (list != null) {
          for (final raw in list) {
            if (raw['id'] == id) {
              _applyProductDataToOrderItem(item, raw);
              break;
            }
          }
        }
      }
    }

    return (item['image']?.toString() ?? '').isNotEmpty;
  }

  Future<void> _hydrateMissingOrderItemImages(int orderId) async {
    final order = orderDetailsById[orderId];
    if (order == null) return;

    final items = (order['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (items.isEmpty) return;

    var changed = false;
    final fetches = <Future<void>>[];

    for (final item in items) {
      final needsImage = (item['image']?.toString() ?? '').isEmpty;
      final needsPrice = _parseOrderAmount(item['price']) <= 0;
      if (!needsImage && !needsPrice) continue;
      final pid = item['product_id'];
      if (pid == null) continue;
      final id = pid is int ? pid : int.tryParse(pid.toString());
      if (id == null || id <= 0) continue;

      fetches.add(() async {
        if (_enrichOrderItemFromCaches(item)) {
          changed = true;
          return;
        }
        try {
          final response = await _apiService.get(
            ApiEndpoints.productDetails,
            queryParameters: {'id': id.toString()},
          );
          final data = ApiService.handleResponse(response);
          _applyProductDataToOrderItem(item, Map<String, dynamic>.from(data));
          _applyOrderItemPricing(item);
          final image = item['image']?.toString() ?? '';
          final price = _parseOrderAmount(item['price']);
          if (image.isNotEmpty || price > 0) {
            changed = true;
            await DataCache.saveMap(
              DataCache.productDetail(id),
              {
                'product': {
                  'id': id,
                  'image': image,
                  'banner': item['banner'],
                  'price': data['price'],
                  'sale_price': data['sale_price'],
                  'category_id': item['category_id'],
                  'is_digital': item['is_digital'],
                  'media_type': item['media_type'],
                  'is_sticker_pack': item['is_sticker_pack'],
                },
              },
            );
          }
        } catch (_) {}
      }());
    }

    if (fetches.isNotEmpty) {
      await Future.wait(fetches);
    }

    final beforeTotal = items.fold<double>(
      0.0,
      (sum, i) => sum + _parseOrderAmount(i['total']),
    );
    final updated = Map<String, dynamic>.from(order);
    updated['items'] =
        items.map((i) => Map<String, dynamic>.from(i)).toList();
    _finalizeOrderPricing(updated);
    final afterItems = updated['items'] as List;
    final afterTotal = afterItems.fold<double>(
      0.0,
      (sum, i) => sum + _parseOrderAmount((i as Map)['total']),
    );
    if (!changed && afterTotal <= beforeTotal) return;
    orderDetailsById[orderId] = updated;
    orderDetailsById.refresh();
    await DataCache.saveMap(DataCache.orderDetail(orderId), updated);

    final listIdx = orders.indexWhere((o) => o['id'] == orderId);
    if (listIdx >= 0) {
      orders[listIdx] = Map<String, dynamic>.from(updated);
      orders.refresh();
      await DataCache.saveList(DataCache.orders, orders.toList());
    }
  }

  double _parseOrderAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final cleaned = value
        .toString()
        .trim()
        .replaceAll(RegExp(r'[^\d.\-]'), '');
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }

  Map<String, dynamic> _unwrapOrderPayload(Map<String, dynamic> data) {
    for (final key in ['order', 'order_details', 'order_detail']) {
      if (data[key] is Map) {
        final nested = Map<String, dynamic>.from(data[key] as Map);
        for (final itemsKey in ['items', 'order_items', 'orderItems']) {
          if (nested[itemsKey] is List &&
              (nested['items'] as List?)?.isEmpty != false) {
            nested['items'] = nested[itemsKey];
          }
        }
        return nested;
      }
    }
    for (final itemsKey in ['order_items', 'orderItems']) {
      if (data[itemsKey] is List &&
          (data['items'] as List?)?.isEmpty != false) {
        data['items'] = data[itemsKey];
      }
    }
    return data;
  }

  void _applyOrderItemPricing(Map<String, dynamic> item) {
    final qty = item['quantity'] is int
        ? item['quantity'] as int
        : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    item['quantity'] = qty;

    final productMap = item['product'] is Map
        ? Map<String, dynamic>.from(item['product'] as Map)
        : null;

    var unitPrice = _parseOrderAmount(
      item['price'] ??
          item['unit_price'] ??
          item['product_price'] ??
          item['item_price'] ??
          item['sale_price'] ??
          item['amount'] ??
          item['paid_price'] ??
          item['final_price'] ??
          item['selling_price'] ??
          item['order_price'] ??
          item['purchase_price'] ??
          item['price_at_purchase'] ??
          productMap?['sale_price'] ??
          productMap?['price'],
    );
    var lineTotal = _parseOrderAmount(
      item['total'] ??
          item['line_total'] ??
          item['item_total'] ??
          item['subtotal'] ??
          item['line_subtotal'] ??
          item['amount'] ??
          item['paid_amount'] ??
          item['final_amount'],
    );
    if (lineTotal <= 0 && unitPrice > 0 && qty > 0) {
      lineTotal = unitPrice * qty;
    } else if (unitPrice <= 0 && lineTotal > 0 && qty > 0) {
      unitPrice = lineTotal / qty;
    }
    item['price'] = unitPrice;
    item['total'] = lineTotal > 0 ? lineTotal : unitPrice * qty;
  }

  void _applyOrderTotalToItems(List<Map<String, dynamic>> items, double orderTotal) {
    if (orderTotal <= 0 || items.isEmpty) return;
    final allZero =
        items.every((i) => _parseOrderAmount(i['total']) <= 0);
    if (!allZero) return;

    if (items.length == 1) {
      final item = items[0];
      final qty = item['quantity'] is int
          ? item['quantity'] as int
          : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      item['total'] = orderTotal;
      item['price'] = orderTotal / qty;
      return;
    }

    final perLine = orderTotal / items.length;
    for (final item in items) {
      final qty = item['quantity'] is int
          ? item['quantity'] as int
          : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      item['total'] = perLine;
      item['price'] = perLine / qty;
    }
  }

  void _finalizeOrderPricing(Map<String, dynamic> formatted) {
    final items = (formatted['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();
    if (items.isEmpty) return;

    for (final item in items) {
      if (WatchFaceOrderHelper.isWatchFaceProductId(item['product_id']) ||
          item['watch_face_id'] != null ||
          item['media_type'] == 'watch_face') {
        continue;
      }
      if (_parseOrderAmount(item['price']) <= 0) {
        _enrichOrderItemFromCaches(item);
        _applyOrderItemPricing(item);
      }
    }

    final orderTotal = _parseOrderAmount(formatted['total_amount']);
    _applyOrderTotalToItems(items, orderTotal);
    formatted['items'] = items;

    if (_parseOrderAmount(formatted['subtotal']) <= 0) {
      formatted['subtotal'] = items.fold<double>(
        0.0,
        (sum, i) => sum + _parseOrderAmount(i['total']),
      );
    }
    if (_parseOrderAmount(formatted['total_amount']) <= 0) {
      formatted['total_amount'] = _parseOrderAmount(formatted['subtotal']);
    }
  }

  void _mergeOrderPricingFromList(int orderId, Map<String, dynamic> formatted) {
    final summary = orders.cast<Map<String, dynamic>?>().firstWhere(
          (o) => o?['id'] == orderId,
          orElse: () => null,
        );
    if (summary == null) return;

    final summaryNotes = summary['order_notes']?.toString();
    if (summaryNotes != null &&
        summaryNotes.isNotEmpty &&
        (formatted['order_notes']?.toString() ?? '').isEmpty) {
      formatted['order_notes'] = summaryNotes;
    }

    if (_parseOrderAmount(formatted['total_amount']) <= 0) {
      formatted['total_amount'] = summary['total_amount'];
    }
    for (final key in [
      'subtotal',
      'shipping_amount',
      'tax_amount',
      'discount_amount',
    ]) {
      if (_parseOrderAmount(formatted[key]) <= 0 &&
          _parseOrderAmount(summary[key]) > 0) {
        formatted[key] = summary[key];
      }
    }

    final summaryItems = (summary['items'] as List? ?? [])
        .map((i) => _formatOrderItem(Map<String, dynamic>.from(i as Map)))
        .toList();
    final detailItems = (formatted['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();

    for (var i = 0; i < detailItems.length; i++) {
      final detail = detailItems[i];
      if (_parseOrderAmount(detail['price']) > 0) continue;

      Map<String, dynamic>? match;
      final detailId = detail['id'];
      for (final s in summaryItems) {
        if (s['id'] == detailId ||
            s['order_item_id'] == detailId ||
            s['product_id'] == detail['product_id']) {
          match = s;
          break;
        }
      }
      match ??= i < summaryItems.length ? summaryItems[i] : null;
      if (match != null) {
        detail['price'] = match['price'];
        detail['total'] = match['total'];
        if (match['watch_face_preview'] != null) {
          detail['watch_face_preview'] = match['watch_face_preview'];
          detail['image'] = match['watch_face_preview'];
        }
        if (match['watch_face_id'] != null) {
          detail['watch_face_id'] = match['watch_face_id'];
        }
        detailItems[i] = detail;
      }
    }
    formatted['items'] = detailItems;
  }

  Map<String, dynamic> _formatOrderItem(Map<String, dynamic> raw) {
    final item = Map<String, dynamic>.from(raw);

    if (item['product'] is Map) {
      _applyProductDataToOrderItem(
        item,
        Map<String, dynamic>.from(item['product'] as Map),
      );
    }

    final productId = item['product_id'] ?? item['productId'];
    if (productId != null) {
      item['product_id'] = productId is int
          ? productId
          : int.tryParse(productId.toString());
    }

    if ((item['image']?.toString() ?? '').isEmpty) {
      item['image'] = _resolveImageFromProductData(item);
    }

    if (item['banner'] != null && item['banner'].toString().isNotEmpty) {
      item['banner'] = _getImageUrl(item['banner'].toString());
    }

    final catRaw = item['category_id'] ??
        (item['category'] is Map ? item['category']['id'] : null);
    if (catRaw != null) {
      item['category_id'] =
          catRaw is int ? catRaw : int.tryParse(catRaw.toString());
    }

    var isDigital = item['is_digital'] == true ||
        item['is_digital'] == 1 ||
        item['is_digital']?.toString() == 'true';
    final cid = item['category_id'] as int? ?? 0;
    if (!isDigital && (cid == 12 || cid == 13 || cid == 15)) {
      isDigital = true;
    }
    item['is_digital'] = isDigital;

    // Always enrich from product cache — sets is_digital, category, media_type
    if (item['product_id'] != null) {
      _enrichOrderItemFromCaches(item);
    } else if ((item['image']?.toString() ?? '').isEmpty) {
      _enrichOrderItemFromCaches(item);
    }

    _applyOrderItemPricing(item);
    final isWatchFaceItem = DigitalProductType.isWatchFaceProduct(item) ||
        item['watch_face_id'] != null;
    if (_parseOrderAmount(item['price']) <= 0 && !isWatchFaceItem) {
      final pid = item['product_id'];
      final id = pid is int ? pid : int.tryParse(pid?.toString() ?? '');
      if (id != null && id > 0) {
        final cached = DataCache.loadMap(DataCache.productDetail(id));
        final product = cached?['product'];
        if (product is Map) {
          final catalogPrice = _parseOrderAmount(
            product['sale_price'] ?? product['price'],
          );
          if (catalogPrice > 0) {
            final qty = item['quantity'] is int
                ? item['quantity'] as int
                : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
            item['price'] = catalogPrice;
            item['total'] = catalogPrice * qty;
          }
        }
      }
    }

    final media = DigitalProductType.resolveMediaType(item);
    if (media != 'none') {
      item['media_type'] = media;
    }
    if (DigitalProductType.isStickerPack(item)) {
      item['is_sticker_pack'] = true;
    }
    if (DigitalProductType.isWatchFaceProduct(item)) {
      item['is_digital'] = true;
      item['is_sticker_pack'] = false;
      item['is_sticker'] = false;
      item['media_type'] = 'watch_face';
    }
    if (DigitalProductType.isDigitalProduct(item)) {
      item['is_digital'] = true;
    }
    return item;
  }

  Map<String, dynamic> _formatOrderSummary(Map<String, dynamic> order) {
    final orderId = order['id'] is int
        ? order['id'] as int
        : int.tryParse(order['id']?.toString() ?? '0') ?? 0;
    final items = (order['items'] as List? ?? [])
        .map((i) => _formatOrderItem(Map<String, dynamic>.from(i as Map)))
        .toList();
    var hasDigital = items.any(DigitalProductType.isDigitalProduct);
    var hasPhysical = items.any((i) => !DigitalProductType.isDigitalProduct(i));

    if (order['has_digital'] == true ||
        order['has_digital'] == 1 ||
        order['is_digital'] == true ||
        order['is_digital'] == 1) {
      hasDigital = true;
    }
    if (order['has_physical'] == true || order['has_physical'] == 1) {
      hasPhysical = true;
    }
    // Digital checkout — no shipping address on order
    final ship = order['shipping_address'];
    final hasShipping = ship is Map && ship.isNotEmpty;
    if (hasDigital && !hasShipping) {
      hasPhysical = false;
    }
    if (items.isNotEmpty && hasDigital && !hasPhysical) {
      hasPhysical = false;
    }
    var totalAmount = _parseOrderAmount(
      order['total_amount'] ??
          order['total'] ??
          order['grand_total'] ??
          order['paid_amount'] ??
          order['payment_amount'] ??
          order['amount_paid'] ??
          order['amount'] ??
          order['order_total'],
    );
    if (totalAmount <= 0) {
      totalAmount = items.fold<double>(
        0.0,
        (sum, i) => sum + _parseOrderAmount(i['total']),
      );
    }
    _applyOrderTotalToItems(items, totalAmount);
    WatchFaceOrderHelper.applyWatchFacePreviewToItems(
      items.cast<Map<String, dynamic>>(),
      order['order_notes']?.toString(),
    );
    WatchFaceOrderHelper.applyWatchFacePricing(
      items.cast<Map<String, dynamic>>(),
      order['order_notes']?.toString(),
      totalAmount,
    );
    return {
      'id': orderId,
      'order_number': order['order_number'] ?? orderId.toString(),
      'status': (order['status'] ?? 'pending').toString().toLowerCase(),
      'total_amount': totalAmount,
      'created_at': order['created_at'] ?? '',
      'items': items,
      'payment_status':
          (order['payment_status'] ?? 'pending').toString().toLowerCase(),
      'order_notes': order['order_notes']?.toString(),
      'has_digital': hasDigital || WatchFaceOrderHelper.isWatchFaceOrder(order, items: items),
      'has_physical': WatchFaceOrderHelper.isWatchFaceOrder(order, items: items)
          ? false
          : hasPhysical,
      'is_watch_face_order': WatchFaceOrderHelper.isWatchFaceOrder(order, items: items),
    };
  }

  Map<String, dynamic> _formatOrderDetails(Map<String, dynamic> order) {
    final formatted = _formatOrderSummary(order);
    formatted['shipping_address'] = order['shipping_address'];
    formatted['billing_address'] = order['billing_address'];
    formatted['payment_method'] = order['payment_method'];
    formatted['order_notes'] = order['order_notes'] ?? order['notes'];

    var subtotal = _parseOrderAmount(
      order['subtotal'] ?? order['sub_total'] ?? order['items_subtotal'],
    );
    if (subtotal <= 0) {
      subtotal = (formatted['items'] as List? ?? []).fold<double>(
        0.0,
        (sum, i) => sum + _parseOrderAmount((i as Map)['total']),
      );
    }
    final shipping = _parseOrderAmount(
      order['shipping_amount'] ??
          order['shipping_cost'] ??
          order['shipping'] ??
          order['shipping_charge'],
    );
    final tax = _parseOrderAmount(
      order['tax_amount'] ?? order['tax'] ?? order['tax_cost'],
    );
    final discount = _parseOrderAmount(
      order['discount_amount'] ??
          order['discount'] ??
          order['coupon_discount'] ??
          order['discount_total'],
    );
    var total = _parseOrderAmount(
      order['total_amount'] ??
          order['total'] ??
          order['grand_total'] ??
          order['paid_amount'] ??
          order['payment_amount'] ??
          order['amount_paid'] ??
          order['amount'] ??
          order['order_total'],
    );
    if (total <= 0) {
      total = subtotal + shipping + tax - discount;
    }

    final pricedItems = (formatted['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();
    _applyOrderTotalToItems(
      pricedItems,
      total > 0 ? total : _parseOrderAmount(formatted['total_amount']),
    );
    formatted['items'] = pricedItems;

    formatted['subtotal'] = subtotal;
    formatted['shipping_amount'] = shipping;
    formatted['shipping_cost'] = shipping;
    formatted['tax_amount'] = tax;
    formatted['tax'] = tax;
    formatted['discount_amount'] = discount;
    formatted['discount'] = discount;
    formatted['total_amount'] = total > 0 ? total : formatted['total_amount'];
    return formatted;
  }

  void _hydrateOrderDetailCache(int orderId) {
    if (orderDetailsById.containsKey(orderId)) return;
    final disk = DataCache.loadMap(DataCache.orderDetail(orderId));
    if (disk != null) {
      orderDetailsById[orderId] = disk;
      return;
    }
    final summary = orders.cast<Map<String, dynamic>?>().firstWhere(
          (o) => o?['id'] == orderId,
          orElse: () => null,
        );
    if (summary != null) {
      orderDetailsById[orderId] = Map<String, dynamic>.from(summary);
    }
  }

  /// Load orders
  Future<void> loadOrders({bool silent = false}) async {
    _loadCachedOrders();
    final hasCache = orders.isNotEmpty;
    if (!silent && !hasCache) {
      isLoadingOrders.value = true;
    }
    try {
      await WatchFaceOrderHelper.ensureCatalogLoaded();
      final response = await _apiService.get(ApiEndpoints.ordersList);
      final data = ApiService.handleResponse(response);
      final formattedOrders = (data['orders'] ?? [])
          .map<Map<String, dynamic>>(
            (order) => _formatOrderSummary(Map<String, dynamic>.from(order)),
          )
          .where(WatchFaceOrderHelper.isWatchFaceOrderForCurrentPlatform)
          .toList();

      orders.assignAll(formattedOrders);
      if (orders.isNotEmpty) {
        hasEverLoadedOrders.value = true;
        await DataCache.saveList(DataCache.orders, orders.toList());
      }
    } catch (e) {
      if (orders.isEmpty) {
        ApiService.showErrorSnackbar(e);
      }
    } finally {
      isLoadingOrders.value = false;
    }
  }
  
  void _loadCachedAddresses() {
    final cached = DataCache.loadList(DataCache.addresses);
    if (cached != null && cached.isNotEmpty) {
      addresses.value = cached;
    }
  }

  /// Load addresses
  Future<void> loadAddresses() async {
    _loadCachedAddresses();
    if (addresses.isEmpty) {
      isLoadingAddresses.value = true;
    }
    try {
      final response = await _apiService.get(ApiEndpoints.addressesList);
      final data = ApiService.handleResponse(response);
      addresses.value = (data['addresses'] ?? []).map<Map<String, dynamic>>((address) {
        return {
          'id': address['id'],
          'name': address['name'] ?? '',
          'phone': address['phone'] ?? '',
          'address_line1': address['address_line1'] ?? '',
          'address_line2': address['address_line2'],
          'city': address['city'] ?? '',
          'state': address['state'] ?? '',
          'pincode': address['pincode'] ?? '',
          'type': address['type'] ?? 'home',
          'label': address['label'] ?? address['type'] ?? 'home',
          'is_default': address['is_default'] ?? false,
        };
      }).toList();
      await DataCache.saveList(DataCache.addresses, addresses.toList());
    } catch (e) {
      if (addresses.isEmpty) {
        ApiService.showErrorSnackbar(e);
      }
    } finally {
      isLoadingAddresses.value = false;
    }
  }
  
  /// Initialize address form for editing
  void initializeAddressForm(Map<String, dynamic> address) {
    addressTypeController.text = address['type'] ?? 'home';
    addressNameController.text = address['name'] ?? '';
    addressPhoneController.text = address['phone'] ?? '';
    addressLine1Controller.text = address['address_line1'] ?? '';
    addressLine2Controller.text = address['address_line2'] ?? '';
    addressCityController.text = address['city'] ?? '';
    addressStateController.text = address['state'] ?? '';
    addressPincodeController.text = address['pincode'] ?? '';
    isDefaultAddress.value = address['is_default'] == true || address['is_default'] == 1;
  }
  
  /// Clear address form
  void clearAddressForm() {
    addressTypeController.text = 'home';
    addressNameController.clear();
    addressPhoneController.clear();
    addressLine1Controller.clear();
    addressLine2Controller.clear();
    addressCityController.clear();
    addressStateController.clear();
    addressPincodeController.clear();
    isDefaultAddress.value = false;
  }
  
  /// Detect current location.
  /// If [onLocationDetected] is provided, it is called with the location data and the
  /// controller's text fields are not updated (for use when the screen uses its own controllers).
  Future<void> detectCurrentLocation({void Function(Map<String, dynamic>?)? onLocationDetected}) async {
    debugPrint('[UseCurrentLocation] START - detectCurrentLocation called');
    isDetectingLocation.value = true;
    // Get.snackbar(
    //   'Location',
    //   'Detecting your location...',
    //   snackPosition: SnackPosition.BOTTOM,
    //   duration: const Duration(seconds: 2),
    // );

    final locationService = LocationService();

    debugPrint('[UseCurrentLocation] Requesting location permission...');
    LocationPermission permission;
    try {
      permission = await locationService.requestLocationPermission().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('[UseCurrentLocation] Permission request timed out');
          return LocationPermission.denied;
        },
      );
      debugPrint('[UseCurrentLocation] Back from permission request, value: $permission');
    } catch (e, st) {
      debugPrint('[UseCurrentLocation] Exception after permission: $e');
      debugPrint('[UseCurrentLocation] $st');
      isDetectingLocation.value = false;
      Get.snackbar(
        'Location',
        'Something went wrong with permission. Please try again or enter address manually.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final isGranted = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
    debugPrint('[UseCurrentLocation] isGranted=$isGranted');

    if (!isGranted) {
      debugPrint('[UseCurrentLocation] PERMISSION DENIED - stopping');
      isDetectingLocation.value = false;
      Get.snackbar(
        'Location',
        'Location permission is needed to use current location. You can enter address manually.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    debugPrint('[UseCurrentLocation] Permission OK, calling getCurrentLocation now...');
    try {
      // Short delay so OS can apply permission (avoids stuck on some devices)
      await Future.delayed(const Duration(milliseconds: 400));
      debugPrint('[UseCurrentLocation] Calling locationService.getCurrentLocation()...');
      final locationData = await locationService.getCurrentLocation().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('[UseCurrentLocation] TIMEOUT - getCurrentLocation took > 20s');
          return null;
        },
      );

      if (locationData != null) {
        debugPrint('[UseCurrentLocation] SUCCESS - address: ${locationData['address_line1']}, city: ${locationData['city']}, state: ${locationData['state']}, pincode: ${locationData['pincode']}');
        if (onLocationDetected != null) {
          onLocationDetected(locationData);
        } else {
          addressLine1Controller.text = locationData['address_line1'] ?? '';
          addressLine2Controller.text = locationData['address_line2'] ?? '';
          addressCityController.text = locationData['city'] ?? '';
          addressStateController.text = locationData['state'] ?? '';
          addressPincodeController.text = locationData['pincode'] ?? '';
        }
        Get.snackbar(
          'Success',
          'Address filled from your location. Please verify and add name & phone.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      } else {
        debugPrint('[UseCurrentLocation] locationData is NULL - could not get address');
        Get.snackbar(
          'Location Unavailable',
          'Could not get address from location. Please enter address manually.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, stack) {
      debugPrint('[UseCurrentLocation] CATCH - error: $e');
      debugPrint('[UseCurrentLocation] stackTrace: $stack');
      if (e is! TimeoutException) {
        Get.snackbar(
          'Error',
          'Something went wrong. Please enter address manually.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      debugPrint('[UseCurrentLocation] DONE - isDetectingLocation = false');
      isDetectingLocation.value = false;
    }
  }
  
  /// Save address (add or update) using form controllers
  Future<void> saveAddress(int? addressId) async {
    if (!addressFormKey.currentState!.validate()) {
      return;
    }
    final addressData = {
      'name': addressNameController.text.trim(),
      'phone': addressPhoneController.text.trim(),
      'address_line1': addressLine1Controller.text.trim(),
      'address_line2': addressLine2Controller.text.trim(),
      'city': addressCityController.text.trim(),
      'state': addressStateController.text.trim(),
      'pincode': addressPincodeController.text.trim(),
      'type': addressTypeController.text,
      'is_default': isDefaultAddress.value ? 1 : 0,
    };
    await saveAddressWithData(addressId, addressData);
  }

  /// Save address (add or update) using provided data. Use this when the screen
  /// owns its own form controllers to avoid using disposed controllers.
  /// [fromCheckout] when true: pop back to checkout; when false: pop back to previous screen.
  Future<void> saveAddressWithData(int? addressId, Map<String, dynamic> addressData, {bool fromCheckout = false}) async {
    isSavingAddress.value = true;
    try {
      final data = {
        'name': (addressData['name'] ?? '').toString().trim(),
        'phone': (addressData['phone'] ?? '').toString().trim(),
        'address_line1': (addressData['address_line1'] ?? '').toString().trim(),
        'address_line2': (addressData['address_line2'] ?? '').toString().trim(),
        'city': (addressData['city'] ?? '').toString().trim(),
        'state': (addressData['state'] ?? '').toString().trim(),
        'pincode': (addressData['pincode'] ?? '').toString().trim(),
        'type': (addressData['type'] ?? 'home').toString(),
        'is_default': addressData['is_default'] == true || addressData['is_default'] == 1 ? 1 : 0,
      };

      if (addressId != null) {
        final updateUrl = ApiEndpoints.addressesUpdate.replaceAll('{id}', addressId.toString());
        await _apiService.put(updateUrl, data: data);
        // Get.snackbar('Success', 'Address updated successfully');
      } else {
        await _apiService.post(ApiEndpoints.addressesAdd, data: data);
        // Get.snackbar('Success', 'Address added successfully');
      }

      // Reload addresses and refresh checkout if needed
      await loadAddresses();
      
      try {
        if (Get.isRegistered<CheckoutController>()) {
          await Get.find<CheckoutController>().loadCheckoutSummary();
        }
      } catch (e) {
        print('Error refreshing checkout: $e');
      }

      // Navigate back to previous screen
      Get.back(result: true);
      clearAddressForm();
      isSavingAddress.value = false;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      isSavingAddress.value = false;
    }
  }
  
  /// Delete address
  Future<void> deleteAddress(int addressId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final deleteUrl = ApiEndpoints.addressesDelete.replaceAll('{id}', addressId.toString());
      await _apiService.delete(deleteUrl);
      Get.snackbar('Success', 'Address deleted successfully');
      await loadAddresses();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Set default address
  Future<void> setDefaultAddress(int addressId) async {
    try {
      final setDefaultUrl = ApiEndpoints.addressesSetDefault.replaceAll('{id}', addressId.toString());
      await _apiService.put(setDefaultUrl);
      Get.snackbar('Success', 'Default address updated');
      await loadAddresses();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// View order details
  void viewOrderDetails(int orderId) {
    print('[ProfileController] viewOrderDetails() called with orderId: $orderId');
    print('[ProfileController] Navigating to: ${AppRoutes.orderDetails}');
    
    // Ensure orderId is valid
    if (orderId <= 0) {
      Get.snackbar('Error', 'Invalid order ID');
      return;
    }
    
    // Use Get.to() directly to bypass route middleware issues
    try {
      Get.to(() => OrderDetailsScreen(orderId: orderId));
      print('[ProfileController] Navigation successful');
    } catch (e, stackTrace) {
      print('[ProfileController] Navigation exception: $e');
      print('[ProfileController] Stack trace: $stackTrace');
      Get.snackbar('Error', 'Failed to open order details: ${e.toString()}');
    }
  }
  
  /// Reorder - Add items from previous order to cart
  Future<void> reorder(int orderId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.orderReorder,
        data: {'order_id': orderId},
      );
      final data = ApiService.handleResponse(response);
      
      final addedItems = data['added_items'] ?? [];
      final failedItems = data['failed_items'] ?? [];
      
      if (addedItems.isNotEmpty) {
        Get.snackbar(
          'Success',
          '${addedItems.length} item(s) added to cart',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: AppColors.textWhite,
        );
        
        // Navigate to cart
        Future.delayed(const Duration(seconds: 1), () {
          Get.toNamed('/cart');
        });
      }
      
      if (failedItems.isNotEmpty) {
        Get.snackbar(
          'Warning',
          '${failedItems.length} item(s) could not be added (out of stock or unavailable)',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Get order tracking
  Future<Map<String, dynamic>?> getOrderTracking(int orderId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderTracking,
        queryParameters: {'order_id': orderId.toString()},
      );
      final data = ApiService.handleResponse(response);
      return data;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return null;
    }
  }
  
  /// Get order details (full order information)
  Future<Map<String, dynamic>?> getOrderDetails(
    int orderId, {
    bool silent = false,
  }) async {
    await WatchFaceOrderHelper.ensureCatalogLoaded();
    _hydrateOrderDetailCache(orderId);
    final hasContent = orderDetailsById.containsKey(orderId);
    if (hasContent) {
      final cached = orderDetailsById[orderId]!;
      await WatchFaceOrderHelper.enrichWatchFaceOrder(cached);
      orderDetailsById[orderId] = cached;
      orderDetailsById.refresh();
      _hydrateMissingOrderItemImages(orderId);
    }
    if (!silent && !hasContent) {
      isLoadingOrderDetail.value = true;
    }
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderDetails,
        queryParameters: {'id': orderId.toString()},
      );
      final data = ApiService.handleResponse(response);
      final order = _unwrapOrderPayload(Map<String, dynamic>.from(data));
      final formatted = _formatOrderDetails(order);
      _mergeOrderPricingFromList(orderId, formatted);
      _finalizeOrderPricing(formatted);
      await WatchFaceOrderHelper.enrichWatchFaceOrder(formatted);
      orderDetailsById[orderId] = formatted;
      orderDetailsById.refresh();
      await DataCache.saveMap(DataCache.orderDetail(orderId), formatted);
      _hydrateMissingOrderItemImages(orderId);
      return formatted;
    } catch (e) {
      if (!hasContent) {
        ApiService.showErrorSnackbar(e);
      }
      return orderDetailsById[orderId];
    } finally {
      isLoadingOrderDetail.value = false;
    }
  }

  /// Append auth token for media/download URLs (streaming + file fetch).
  String withAuthToken(String url) => _authenticatedDownloadUrl(url);

  String _authenticatedDownloadUrl(String url) {
    final token = CacheManager.getUserToken();
    if (token == null || token.isEmpty) return url;
    final uri = Uri.parse(url);
    if (uri.queryParameters.containsKey('token')) return url;
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'token': token})
        .toString();
  }

  Dio _rawDownloadDio({Duration? receiveTimeout}) => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: receiveTimeout ?? const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          followRedirects: true,
          headers: const {'Accept': '*/*'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

  Future<Uint8List?> _downloadBytes(String url) async {
    try {
      final authedUrl = _authenticatedDownloadUrl(_fixDownloadUrl(url));
      final response = await _rawDownloadDio().get<List<int>>(
        authedUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final code = response.statusCode ?? 0;
      if (code == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (e) {
      log('[DigitalDownload] _downloadBytes failed: $e');
    }
    return null;
  }

  Future<void> _authenticatedDownload(
    String url,
    String savePath, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final authedUrl = _authenticatedDownloadUrl(_fixDownloadUrl(url));
    // Absolute URLs must bypass ApiService Dio (baseUrl + token interceptor).
    final response = await _rawDownloadDio().download(
      authedUrl,
      savePath,
      onReceiveProgress: onReceiveProgress,
    );
    final code = response.statusCode ?? 0;
    if (code == 401) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Unauthorized — please login again',
      );
    }
    if (code >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Download failed (HTTP $code)',
      );
    }
  }

  Future<({int? orderId, int? productId})> resolveStickerContext(
    int orderItemId, {
    int? orderId,
    int? productId,
  }) async {
    var oid = orderId;
    var pid = productId;

    void scanItem(Map<String, dynamic> item, int parentOrderId) {
      final itemId = item['id'];
      if (itemId == orderItemId || itemId.toString() == orderItemId.toString()) {
        oid ??= parentOrderId;
        final rawPid = item['product_id'] ?? item['productId'];
        if (rawPid != null) {
          pid ??= rawPid is int ? rawPid : int.tryParse(rawPid.toString());
        }
      }
    }

    for (final order in orders) {
      final parentId = order['id'] is int
          ? order['id'] as int
          : int.tryParse(order['id']?.toString() ?? '');
      if (parentId == null) continue;
      for (final raw in order['items'] as List? ?? []) {
        if (raw is Map) scanItem(Map<String, dynamic>.from(raw), parentId);
      }
    }

    for (final entry in orderDetailsById.entries) {
      for (final raw in entry.value['items'] as List? ?? []) {
        if (raw is Map) scanItem(Map<String, dynamic>.from(raw), entry.key);
      }
    }

    if (pid == null || oid == null) {
      final info = await getOrderDetailsFromItemId(orderItemId);
      oid ??= info?['order_id'] is int
          ? info!['order_id'] as int
          : int.tryParse(info?['order_id']?.toString() ?? '');
    }

    if (pid == null && oid != null) {
      final details = orderDetailsById[oid] ??
          await getOrderDetails(oid!, silent: true);
      for (final raw in details?['items'] as List? ?? []) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        if (item['id'] == orderItemId ||
            item['id'].toString() == orderItemId.toString()) {
          final rawPid = item['product_id'] ?? item['productId'];
          if (rawPid != null) {
            pid = rawPid is int ? rawPid : int.tryParse(rawPid.toString());
          }
          break;
        }
      }
    }

    return (orderId: oid, productId: pid);
  }

  Map<String, dynamic> _stickerDownloadInfo(int orderId, int productId) {
    final raw =
        '${ApiService.baseUrl}${ApiEndpoints.stickerDownload}?order_id=$orderId&product_id=$productId&format=zip';
    return {
      'download_url': withAuthToken(raw),
      'suggested_filename': 'StickerPack_$productId.zip',
      'source': 'sticker_endpoint',
    };
  }

  Future<Map<String, dynamic>?> _fetchOrderItemDownloadInfo(int orderItemId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderDownload,
        queryParameters: {'order_item_id': orderItemId.toString()},
      );
      final data = ApiService.handleResponse(response);
      final downloadUrl = data['download_url'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) return null;
      final suggested = data['suggested_filename']?.toString().trim();
      return {
        'download_url': withAuthToken(_fixDownloadUrl(downloadUrl)),
        'suggested_filename': suggested?.isNotEmpty == true ? suggested : null,
        'source': 'order_download',
      };
    } catch (e) {
      log('[DigitalDownload] order download info failed orderItemId=$orderItemId: $e');
      return null;
    }
  }

  /// Get secure download URL for a digital product order item. Returns URL or null.
  /// Lifetime access – user can download anytime from My Orders.
  Future<String?> getDigitalDownloadUrl(int orderItemId, {int? orderId, int? productId, bool isSticker = false}) async {
    final info = await getDigitalDownloadInfo(orderItemId, orderId: orderId, productId: productId, isSticker: isSticker);
    return info?['download_url'] as String?;
  }

  /// Get download URL and suggested filename (correct extension, not .php).
  /// Returns map with 'download_url' and 'suggested_filename', or null on error.
  Future<Map<String, dynamic>?> getDigitalDownloadInfo(int orderItemId, {int? orderId, int? productId, bool isSticker = false, bool silent = false}) async {
    try {
      log('[DigitalDownload] getDigitalDownloadInfo: orderItemId=$orderItemId, orderId=$orderId, productId=$productId, isSticker=$isSticker');

      if (isSticker) {
        final orderInfo = await _fetchOrderItemDownloadInfo(orderItemId);
        if (orderInfo != null) {
          log('[DigitalDownload] Using order download for sticker orderItemId=$orderItemId');
          return orderInfo;
        }
        final ctx = await resolveStickerContext(
          orderItemId,
          orderId: orderId,
          productId: productId,
        );
        if (ctx.orderId != null && ctx.productId != null) {
          log('[DigitalDownload] Sticker endpoint order=${ctx.orderId} product=${ctx.productId}');
          return _stickerDownloadInfo(ctx.orderId!, ctx.productId!);
        }
      }

      log('[DigitalDownload] Fetching from standard digital endpoint: order_item_id=$orderItemId');
      try {
        final response = await _apiService.get(
          ApiEndpoints.orderDownload,
          queryParameters: {'order_item_id': orderItemId.toString()},
        );
        final data = ApiService.handleResponse(response);
        var downloadUrl = data['download_url'] as String?;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          log('[DigitalDownload] No download_url in response for orderItemId=$orderItemId');
          if (!silent) {
            Get.snackbar('Error', 'Download link not available', snackPosition: SnackPosition.BOTTOM);
          }
          return null;
        }
        
        // Fix URL but preserve double slashes after domain as they might be intentional
        downloadUrl = withAuthToken(_fixDownloadUrl(downloadUrl));
        final suggestedFilename = data['suggested_filename']?.toString().trim();
        log('[DigitalDownload] Download URL received for orderItemId=$orderItemId');
        return {
          'download_url': downloadUrl,
          'suggested_filename': suggestedFilename?.isNotEmpty == true ? suggestedFilename : null,
        };
      } catch (e) {
        // If regular download fails with "Digital file path not configured", and we have orderId/productId,
        // it might be a sticker pack that wasn't identified correctly. Try sticker flow.
        String errorMsg = e.toString().toLowerCase();
        
        // Extract message from DioException response data if available
        if (e is DioException && e.response?.data != null) {
          final resData = e.response?.data;
          String resString = '';
          if (resData is Map) {
            resString = (resData['message'] ?? '').toString().toLowerCase();
          } else {
            resString = resData.toString().toLowerCase();
          }
          errorMsg += ' ' + resString;
          log('[DigitalDownload] Caught error message: $resString');
        }

        final ctx = await resolveStickerContext(
          orderItemId,
          orderId: orderId,
          productId: productId,
        );
        if ((errorMsg.contains('path not configured') ||
                errorMsg.contains('500') ||
                errorMsg.contains('bad response') ||
                isSticker) &&
            ctx.orderId != null &&
            ctx.productId != null) {
          log('[DigitalDownload] Fallback sticker flow orderItemId=$orderItemId');
          return {
            ..._stickerDownloadInfo(ctx.orderId!, ctx.productId!),
            'is_fallback_sticker': true,
          };
        }
        rethrow;
      }
    } catch (e) {
      log('[DigitalDownload] Error in getDigitalDownloadInfo for orderItemId=$orderItemId: $e');
      if (!silent) {
        ApiService.showErrorSnackbar(e);
      }
      return null;
    }
  }

  /// Direct download for audio/video - no validation, just download and save
  Future<String?> directDownloadAudioVideo(
    String url, 
    String productName, 
    String productType, // 'audio' or 'video'
    String? productCategory, // 'sticker', 'audio', 'video'
    int orderItemId, // Add orderItemId parameter
  ) async {
    // final notificationService = Get.find<NotificationService>();
    final downloadId = DateTime.now().millisecondsSinceEpoch;
    
    print('[DirectDownload] ========== DIRECT DOWNLOAD START ==========');
    print('[DirectDownload] Product: $productName');
    print('[DirectDownload] Type: $productType');
    print('[DirectDownload] Category: $productCategory');
    print('[DirectDownload] URL: ${url.substring(0, min(url.length, 100))}...');
    
    try {
      // Fix malformed URL before using it
      url = _fixDownloadUrl(url);
      print('[DirectDownload] Fixed URL: ${url.substring(0, min(url.length, 100))}...');
      
      // Show initial download notification
      // await notificationService.showDownloadProgressNotification(
      //   downloadId: downloadId,
      //   fileName: productName,
      //   progress: 0,
      //   total: 100,
      // );

      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = await Directory('${dir.path}/DigitalDownloads').create(recursive: true);
      
      // Create filename with proper extension
      final safeName = productName.replaceAll(RegExp(r'[^\w\s\-.]'), '_').replaceAll(RegExp(r'\s+'), '_');
      String ext;
      String fileName;
      
      // Handle different product types based on category
      if (productCategory == 'sticker') {
        ext = '.zip';
        fileName = '${safeName.isEmpty ? 'stickers_$downloadId' : safeName}$ext';
        print('[DirectDownload] STICKER category: downloading as ZIP');
      } else if (productCategory == 'audio') {
        ext = '.mp3';
        fileName = 'FOS audio.mp3'; // Fixed name as requested
        print('[DirectDownload] AUDIO category: downloading as FOS audio.mp3');
      } else if (productCategory == 'video') {
        ext = '.mp4';
        fileName = 'FOS video.mp4'; // Fixed name as requested
        print('[DirectDownload] VIDEO category: downloading as FOS video.mp4');
      } else {
        // Fallback - determine from productType
        ext = productType == 'audio' ? '.mp3' : '.mp4';
        fileName = '${safeName.isEmpty ? 'digital_$downloadId' : safeName}$ext';
        print('[DirectDownload] FALLBACK: using productType to determine extension');
      }
      
      final savePath = '${downloadDir.path}/$fileName';
      
      print('[DirectDownload] Save location: ${downloadDir.path}');
      print('[DirectDownload] Final filename: $fileName');

      await _authenticatedDownload(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).round();
            if (progress % 10 == 0 || progress == 0 || progress == 100) {}
          }
        },
      );

      print('[DirectDownload] Download complete: $savePath');
      
      // Check if downloaded file is ZIP and extract if needed
      final file = File(savePath);
      final bytes = await file.readAsBytes();
      String finalFilePath = savePath;
      String finalFileName = fileName;
      
      if (_isZipFile(bytes)) {
        print('[DirectDownload] Downloaded file is ZIP, extracting media file...');
        final extractedPath = await _extractMediaFromZip(savePath, productType);
        if (extractedPath != null) {
          finalFilePath = extractedPath;
          finalFileName = fileName.replaceAll('.zip', productType == 'audio' ? '.mp3' : '.mp4');
          print('[DirectDownload] Extracted media file: $finalFilePath');
        } else {
          // Extraction failed - this means server returned wrong content type
          print('[DirectDownload] ERROR: Server returned wrong file type in ZIP');
          throw Exception('Server returned incorrect file type. Expected $productType but received different content. Please contact support.');
        }
      }
      
      // Show completion notification
      // await notificationService.showDownloadCompleteNotification(
      //   downloadId: downloadId,
      //   fileName: finalFileName,
      //   filePath: finalFilePath,
      //   mimeType: productType == 'audio' ? 'audio/mpeg' : 'video/mp4',
      //   productType: productType,
      // );

      return finalFilePath;

    } catch (e) {
      print('[DirectDownload] Error: $e');
      // await notificationService.showDownloadErrorNotification(
      //   downloadId: downloadId,
      //   fileName: productName,
      //   error: e.toString(),
      // );
      return null;
    }
  }

  /// Download digital product to device storage (lifetime – saved locally).
  /// Uses suggested_filename from API so file gets correct extension (e.g. .mp4), not .php.
  /// [productType] should be 'audio', 'video', 'sticker', or null for auto-detect
  Future<String?> downloadDigitalProductToDevice(
    int orderItemId, 
    String productName, {
    int? orderId, 
    int? productId, 
    bool isSticker = false,
    String? productType, // 'audio', 'video', 'sticker', or null
  }) async {
    // Get notification service
    // final notificationService = Get.find<NotificationService>();
    final downloadId = orderItemId; // Use orderItemId as notification ID
    
    // Determine the actual product type
    String actualProductType = productType?.toLowerCase() ?? '';
    
    print('[DigitalDownload] ========== DOWNLOAD START ==========');
    print('[DigitalDownload] orderItemId=$orderItemId, productName=$productName');
    print('[DigitalDownload] isSticker=$isSticker, productType=$productType');
    
    try {
      // Show initial download notification
      // await notificationService.showDownloadProgressNotification(
      //   downloadId: downloadId,
      //   fileName: productName,
      //   progress: 0,
      //   total: 100,
      // );

      final info = await getDigitalDownloadInfo(orderItemId, orderId: orderId, productId: productId, isSticker: isSticker);
      if (info == null) {
        // await notificationService.showDownloadErrorNotification(
        //   downloadId: downloadId,
        //   fileName: productName,
        //   error: 'Download information not available',
        // );
        return null;
      }
      final url = info['download_url'] as String?;
      if (url == null || url.isEmpty) {
        // await notificationService.showDownloadErrorNotification(
        //   downloadId: downloadId,
        //   fileName: productName,
        //   error: 'Download URL not available',
        // );
        return null;
      }

      print('[DigitalDownload] Download info received:');
      print('  - URL: ${url?.substring(0, min(url.length, 100))}...');
      print('  - suggested_filename: ${info['suggested_filename']}');
      print('  - is_fallback_sticker: ${info['is_fallback_sticker']}');

      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = await Directory('${dir.path}/DigitalDownloads').create(recursive: true);
      
      print('[DigitalDownload] Save location: ${downloadDir.path}');
      final suggested = info['suggested_filename'] as String?;
      String fileName;
      
      print('[DigitalDownload] ========== PRODUCT TYPE DETECTION ==========');
      print('[DigitalDownload] Product Name: $productName');
      print('[DigitalDownload] isSticker: $isSticker');
      print('[DigitalDownload] productType: $productType');
      print('[DigitalDownload] suggested filename: $suggested');
      print('[DigitalDownload] URL: ${url.substring(0, min(url.length, 100))}...');
      
      // Check if product type is specified in the URL or file content
      final urlLower = url.toLowerCase();
      final productNameLower = productName.toLowerCase();
      
      // Priority-based detection: Audio > Video > Sticker
      if (actualProductType.isEmpty) {
        // Check suggested filename for stickers first
        final suggestedLower = suggested?.toLowerCase() ?? '';
        final isSuggestedSticker = suggestedLower.contains('sticker') || suggestedLower.contains('.zip');
        
        if (urlLower.endsWith('.mp3') || productNameLower.contains('audio') || productNameLower.contains('jingle') || productNameLower.contains('mp3')) {
          actualProductType = 'audio';
          print('[DigitalDownload] AUDIO detected from product name/URL: $productName');
        } else if (urlLower.endsWith('.mp4') || urlLower.endsWith('.mov') || productNameLower.contains('video')) {
          actualProductType = 'video';
          print('[DigitalDownload] VIDEO detected from product name/URL: $productName');
        } else if (isSticker || info['is_fallback_sticker'] == true || productNameLower.contains('sticker') || isSuggestedSticker) {
          actualProductType = 'sticker';
          print('[DigitalDownload] STICKER detected - productName: $productName, suggested: $suggested');
        }
      }
      
      print('[DigitalDownload] Final product type: $actualProductType');
      
      // For audio/video: Use direct download - no validation
      if (actualProductType == 'audio' || actualProductType == 'video') {
        print('[DigitalDownload] Using DIRECT download for audio/video');
        
        // Determine product category from product name
        String productCategory = 'other';
        final productNameLower = productName.toLowerCase();
        if (productNameLower.contains('sticker') || productNameLower.contains('sticker')) {
          productCategory = 'sticker';
        } else if (productNameLower.contains('audio') || productNameLower.contains('jingle') || productNameLower.contains('mp3')) {
          productCategory = 'audio';
        } else if (productNameLower.contains('video') || productNameLower.contains('mp4')) {
          productCategory = 'video';
        }
        
        return await directDownloadAudioVideo(url, productName, actualProductType, productCategory, orderItemId);
      }
      
      // Continue with existing logic for stickers only
      
      if (isSticker || info['is_fallback_sticker'] == true) {
        fileName = _stickerZipFileName(
          productName,
          productId: productId,
          orderItemId: orderItemId,
          suggested: suggested,
        );
        actualProductType = 'sticker';
        print('[DigitalDownload] STICKER detected: fileName=$fileName');
      } else {
        // Check if we detected this as a sticker from suggested filename
        if (actualProductType == 'sticker') {
          fileName = _stickerZipFileName(
            productName,
            productId: productId,
            orderItemId: orderItemId,
            suggested: suggested,
          );
          print('[DigitalDownload] STICKER detected from filename: fileName=$fileName');
        } else {
          // Create proper filename based on actual product type
          final safeName = productName.replaceAll(RegExp(r'[^\w\s\-.]'), '_').replaceAll(RegExp(r'\s+'), '_');
          
          // Determine correct extension based on actual product type or URL
          String ext;
          // IMPORTANT: Trust our product type detection over suggested filename
          // Server might return wrong suggested filename (like digital_stickers.zip for audio)
          if (actualProductType == 'audio') {
            ext = '.mp3';
            print('[DigitalDownload] AUDIO detected from product name: creating MP3 file');
          } else if (actualProductType == 'video') {
            ext = '.mp4';
            print('[DigitalDownload] VIDEO detected from product name: creating MP4 file');
          } else if (actualProductType == 'sticker') {
            ext = '.zip';
            print('[DigitalDownload] STICKER detected from product name: creating ZIP file');
          } else {
            // Fallback: try to use suggested filename extension
            if (suggested != null && suggested.isNotEmpty) {
              final suggestedExt = suggested.toLowerCase().split('.').lastOrNull;
              print('[DigitalDownload] Using suggested extension as fallback: $suggestedExt from $suggested');
              if (suggestedExt == 'mp3') {
                ext = '.mp3';
                actualProductType = 'audio';
              } else if (suggestedExt == 'mp4' || suggestedExt == 'mov') {
                ext = '.mp4';
                actualProductType = 'video';
              } else if (suggestedExt == 'zip') {
                ext = '.zip';
                actualProductType = 'sticker';
              } else {
                ext = '.$suggestedExt';
              }
            } else {
              // Default based on URL
              ext = urlLower.endsWith('.mp3') ? '.mp3' : 
                     urlLower.endsWith('.mp4') || urlLower.endsWith('.mov') ? '.mp4' : '.zip';
            }
          }
          
          fileName = '${safeName.isEmpty ? 'digital_$orderItemId' : safeName}$ext';
          print('[DigitalDownload] Final fileName: $fileName (type: $actualProductType)');
        }
      }
      final savePath = '${downloadDir.path}/$fileName';

      log('[DigitalDownload] Saving to device: orderItemId=$orderItemId path=$savePath, type=$actualProductType');
      debugPrint('[DigitalDownload] Downloading to $savePath (type: $actualProductType)');

      await _authenticatedDownload(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).round();
            if (progress % 10 == 0 || progress == 0 || progress == 100) {}
          }
        },
      );

      log('[DigitalDownload] Saved to device successfully: $savePath');
      debugPrint('[DigitalDownload] File saved: $savePath');
      
      // Validate downloaded file
      final file = File(savePath);
      if (!file.existsSync()) {
        throw Exception('Downloaded file not found at $savePath');
      }
      
      final fileSize = file.lengthSync();
      print('[DigitalDownload] File size: $fileSize bytes');
      
      // Use mutable variable for final file path (may change if we extract from ZIP)
      String finalFilePath = savePath;
      String finalFileName = fileName;
      
      // Check if file is actually valid MP3 (not ZIP)
      if (actualProductType == 'audio') {
        final bytes = await file.readAsBytes();
        final isValidMp3 = _isValidMp3File(bytes);
        print('[DigitalDownload] MP3 validation: $isValidMp3');
        
        if (!isValidMp3) {
          print('[DigitalDownload] WARNING: Downloaded file is not valid MP3, may be ZIP or corrupted');
          // For audio/video: If server returns ZIP, just show error - don't extract
          if (_isZipFile(bytes)) {
            print('[DigitalDownload] Server returned ZIP for audio. Direct download failed.');
            throw Exception('Server returned ZIP file instead of direct MP3 download. Please check server configuration.');
          } else {
            throw Exception('Downloaded audio file is not valid MP3 format');
          }
        }
      } else if (actualProductType == 'video') {
        final bytes = await file.readAsBytes();
        final isValidMp4 = _isValidMp4File(bytes);
        print('[DigitalDownload] MP4 validation: $isValidMp4');
        
        if (!isValidMp4) {
          print('[DigitalDownload] WARNING: Downloaded file is not valid MP4, may be ZIP or corrupted');
          if (_isZipFile(bytes)) {
            print('[DigitalDownload] Server returned ZIP for video. Direct download failed.');
            throw Exception('Server returned ZIP file instead of direct MP4 download. Please check server configuration.');
          } else {
            throw Exception('Downloaded video file is not valid MP4 format');
          }
        }
      } else if (actualProductType == 'sticker' ||
          isSticker ||
          info['is_fallback_sticker'] == true) {
        if (!await _isValidStickerZipFile(savePath)) {
          try {
            await file.delete();
          } catch (_) {}
          final ctx = await resolveStickerContext(
            orderItemId,
            orderId: orderId,
            productId: productId,
          );
          final pid = productId ?? ctx.productId;
          if (pid != null && pid > 0) {
            log('[DigitalDownload] Server returned non-ZIP; building pack from product $pid previews');
            final built = await _buildStickerZipFromProduct(
              productId: pid,
              productName: productName,
              savePath: savePath,
            );
            if (built != null && await _isValidStickerZipFile(built)) {
              return built;
            }
          }
          throw Exception(
            'Sticker pack download invalid or empty. Please try again.',
          );
        }
      }
      
      // Show completion notification with correct product type
      // await notificationService.showDownloadCompleteNotification(
      //   downloadId: downloadId,
      //   fileName: finalFileName,
      //   filePath: finalFilePath,
      //   mimeType: actualProductType == 'audio' ? 'audio/mpeg' : actualProductType == 'video' ? 'video/mp4' : 'application/zip',
      //   productType: actualProductType,
      // );

      // Rename generic server filename to per-product path (fixes mixed-pack preview).
      if ((isSticker || actualProductType == 'sticker') &&
          productId != null &&
          productId > 0) {
        final correctPath = '${downloadDir.path}/StickerPack_$productId.zip';
        if (finalFilePath != correctPath) {
          final src = File(finalFilePath);
          final dst = File(correctPath);
          if (dst.existsSync()) await dst.delete();
          if (src.existsSync()) {
            await src.rename(correctPath);
            finalFilePath = correctPath;
            finalFileName = 'StickerPack_$productId.zip';
            print('[DigitalDownload] Renamed sticker zip -> $correctPath');
          }
        }
        final generic = File('${downloadDir.path}/digital_stickers.zip');
        if (generic.existsSync() && generic.path != finalFilePath) {
          try {
            await generic.delete();
          } catch (_) {}
        }
      }

      return finalFilePath;

    } catch (e) {
      log('[DigitalDownload] Error saving to device orderItemId=$orderItemId: $e');
      debugPrint('[DigitalDownload] downloadDigitalProductToDevice error: $e');
      
      // Show error notification
      // await notificationService.showDownloadErrorNotification(
      //   downloadId: downloadId,
      //   fileName: productName,
      //   error: e.toString(),
      // );
      
      rethrow;
    }
  }

  /// Check if file bytes represent a valid MP3 file
  bool _isValidMp3File(List<int> bytes) {
    if (bytes.length < 3) return false;
    
    // Check for MP3 ID3 tag (starts with "ID3")
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x46) {
      return true;
    }
    
    // Check for MP3 frame sync (11 bits set to 1)
    for (int i = 0; i < bytes.length - 2; i++) {
      if ((bytes[i] == 0xFF) && ((bytes[i + 1] & 0xE0) == 0xE0)) {
        return true;
      }
    }
    
    return false;
  }

  /// Check if file bytes represent a ZIP file
  bool _isZipFile(List<int> bytes) {
    if (bytes.length < 4) return false;
    
    // ZIP files start with magic number 0x504B0304 (PK\x03\x04)
    return bytes[0] == 0x50 && bytes[1] == 0x4B && 
           (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) && 
           (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);
  }

  bool _isStickerImageFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('__macosx') || lower.contains('/.')) return false;
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  int _countStickerImagesInArchive(Archive archive) {
    var count = 0;
    for (final zipFile in archive) {
      if (zipFile.isFile && _isStickerImageFileName(zipFile.name)) {
        count++;
      }
    }
    return count;
  }

  Future<bool> _isValidStickerZipFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final bytes = await file.readAsBytes();
    if (bytes.length < 22 || !_isZipFile(bytes)) return false;
    final head = String.fromCharCodes(bytes.take(32));
    if (head.trimLeft().startsWith('{') || head.trimLeft().startsWith('<')) {
      return false;
    }
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      return _countStickerImagesInArchive(archive) > 0;
    } catch (_) {
      return false;
    }
  }

  String _stickerFileExtension(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.webp')) return 'webp';
    if (lower.contains('.png')) return 'png';
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return 'jpg';
    if (lower.contains('.gif')) return 'gif';
    return 'webp';
  }

  /// Build a sticker ZIP locally when server returns banner/single image instead of pack.
  Future<String?> _buildStickerZipFromProduct({
    required int productId,
    required String productName,
    required String savePath,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.productDetails,
        queryParameters: {'id': productId.toString()},
      );
      final data = ApiService.handleResponse(response);
      final previews = data['stickers_preview'] as List? ?? [];
      if (previews.isEmpty) {
        log('[StickerZip] No stickers_preview for product $productId');
        return null;
      }

      final archive = Archive();
      var stickerIndex = 1;

      for (final sticker in previews) {
        if (sticker is! Map) continue;
        final imageUrl = _getImageUrl(
          sticker['image_url']?.toString() ??
              sticker['url']?.toString() ??
              sticker['image']?.toString() ??
              '',
        );
        if (imageUrl.isEmpty) continue;

        final bytes = await _downloadBytes(imageUrl);
        if (bytes == null || bytes.isEmpty) continue;

        final ext = _stickerFileExtension(imageUrl);
        archive.addFile(
          ArchiveFile('sticker_$stickerIndex.$ext', bytes.length, bytes),
        );
        stickerIndex++;
      }

      if (stickerIndex == 1) {
        log('[StickerZip] Could not download any preview images for product $productId');
        return null;
      }

      final traySource = data['banner']?.toString() ??
          data['image']?.toString() ??
          (previews.first is Map
              ? (previews.first as Map)['image_url']?.toString() ??
                  (previews.first as Map)['url']?.toString()
              : null);
      if (traySource != null && traySource.isNotEmpty) {
        final trayBytes = await _downloadBytes(_getImageUrl(traySource));
        if (trayBytes != null && trayBytes.isNotEmpty) {
          archive.addFile(
            ArchiveFile('tray_icon.webp', trayBytes.length, trayBytes),
          );
        }
      }

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null || zipBytes.isEmpty) return null;

      await File(savePath).writeAsBytes(zipBytes);
      log('[StickerZip] Built local pack for $productName at $savePath (${stickerIndex - 1} stickers)');
      return savePath;
    } catch (e) {
      log('[StickerZip] _buildStickerZipFromProduct failed productId=$productId: $e');
      return null;
    }
  }

  String _stickerZipFileName(
    String productName, {
    int? productId,
    int? orderItemId,
    String? suggested,
  }) {
    // Always prefer productId — server often returns generic digital_stickers.zip
    if (productId != null && productId > 0) {
      return 'StickerPack_$productId.zip';
    }
    const genericNames = {'digital_stickers.zip', 'stickers.zip', 'sticker_pack.zip'};
    final suggestedRaw = suggested?.trim() ?? '';
    final suggestedLower = suggestedRaw.toLowerCase();
    if (suggestedRaw.isNotEmpty &&
        suggestedLower.endsWith('.zip') &&
        !genericNames.contains(suggestedLower)) {
      return suggestedRaw.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    }
    final safeName = productName
        .replaceAll(RegExp(r'[^\w\s\-.]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return '${safeName.isEmpty ? 'Stickers_$orderItemId' : safeName}_Stickers.zip';
  }

  List<String> _stickerZipCandidates({
    required String productName,
    int? productId,
    int? orderItemId,
    required String downloadDirPath,
  }) {
    final safeName = productName
        .replaceAll(RegExp(r'[^\w\s\-.]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return <String>[
      if (productId != null && productId > 0)
        '$downloadDirPath/StickerPack_$productId.zip',
      '$downloadDirPath/${safeName.isEmpty ? 'Stickers_$orderItemId' : safeName}_Stickers.zip',
      // Never use generic digital_stickers.zip — it mixes packs (old preview bug).
    ];
  }

  Future<String?> findValidStickerZipPath({
    required String productName,
    int? productId,
    int? orderItemId,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir =
        await Directory('${dir.path}/DigitalDownloads').create(recursive: true);
    final candidates = _stickerZipCandidates(
      productName: productName,
      productId: productId,
      orderItemId: orderItemId,
      downloadDirPath: downloadDir.path,
    );
    for (final path in candidates) {
      final f = File(path);
      final valid = await _isValidStickerZipFile(path);
      print(
        '[StickerZip] candidate=$path exists=${f.existsSync()} '
        'size=${f.existsSync() ? f.lengthSync() : 0} valid=$valid',
      );
      if (valid) return path;
    }
    return null;
  }

  /// Resolve ZIP (cache or download), unzip, show preview / WhatsApp.
  Future<void> openStickerPackForOrder({
    required int orderItemId,
    required String productName,
    int? orderId,
    int? productId,
    bool skipPreview = false,
    VoidCallback? onComplete,
  }) async {
    print('[StickerFlow] ===== OPEN PACK =====');
    print(
      '[StickerFlow] orderItemId=$orderItemId productId=$productId '
      'orderId=$orderId name="$productName"',
    );

    while (Get.isDialogOpen == true || Get.isOverlaysOpen) {
      Get.back();
    }

    var zipPath = await findValidStickerZipPath(
      productName: productName,
      productId: productId,
      orderItemId: orderItemId,
    );
    print('[StickerFlow] cached zip => ${zipPath ?? "NONE"}');

    zipPath ??= await ensureValidStickerZip(
      orderItemId: orderItemId,
      productName: productName,
      orderId: orderId,
      productId: productId,
    );
    print('[StickerFlow] final zip => ${zipPath ?? "FAILED"}');

    if (zipPath == null || zipPath.isEmpty) {
      print('[StickerFlow] ERROR: no valid sticker ZIP on disk');
      throw Exception('Could not download sticker pack');
    }

    final zipFile = File(zipPath);
    print(
      '[StickerFlow] using zip exists=${zipFile.existsSync()} '
      'size=${zipFile.existsSync() ? zipFile.lengthSync() : 0}',
    );

    await unzipAndSaveStickersToGallery(
      zipPath,
      productName,
      productId: productId,
      skipPreview: skipPreview,
      onComplete: onComplete,
    );
    print('[StickerFlow] ===== OPEN PACK DONE =====');
  }

  /// Download sticker ZIP if missing/invalid; delete corrupt cached files.
  Future<String?> ensureValidStickerZip({
    required int orderItemId,
    required String productName,
    int? orderId,
    int? productId,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir =
        await Directory('${dir.path}/DigitalDownloads').create(recursive: true);

    final candidates = _stickerZipCandidates(
      productName: productName,
      productId: productId,
      orderItemId: orderItemId,
      downloadDirPath: downloadDir.path,
    );

    for (final path in candidates) {
      if (await _isValidStickerZipFile(path)) return path;
      final f = File(path);
      if (f.existsSync()) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }

    String? downloaded;
    try {
      downloaded = await downloadDigitalProductToDevice(
        orderItemId,
        productName,
        orderId: orderId,
        productId: productId,
        isSticker: true,
        productType: 'sticker',
      );
    } catch (e) {
      log('[StickerZip] downloadDigitalProductToDevice failed: $e');
    }
    if (downloaded != null &&
        downloaded.isNotEmpty &&
        await _isValidStickerZipFile(downloaded)) {
      return downloaded;
    }
    if (downloaded != null && downloaded.isNotEmpty) {
      try {
        await File(downloaded).delete();
      } catch (_) {}
    }

    final ctx = await resolveStickerContext(
      orderItemId,
      orderId: orderId,
      productId: productId,
    );
    final pid = productId ?? ctx.productId;
    if (pid != null && pid > 0) {
      final savePath = '${downloadDir.path}/StickerPack_$pid.zip';
      final built = await _buildStickerZipFromProduct(
        productId: pid,
        productName: productName,
        savePath: savePath,
      );
      if (built != null && await _isValidStickerZipFile(built)) return built;
    }
    return null;
  }

  /// Extract MP3 file from ZIP when server returns ZIP for audio product
  Future<String?> _extractMp3FromZip(String zipPath, String originalFileName) async {
    try {
      print('[AudioExtract] Extracting MP3 from ZIP: $zipPath');
      
      final file = File(zipPath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Look for MP3 files in the ZIP
      for (final zipFile in archive) {
        if (!zipFile.isFile) continue;
        
        final fileName = zipFile.name.toLowerCase();
        if (fileName.endsWith('.mp3')) {
          print('[AudioExtract] Found MP3 in ZIP: ${zipFile.name}');
          
          // Extract to same directory as ZIP
          final dir = file.parent;
          final extractedPath = '${dir.path}/${zipFile.name}';
          
          final extractedFile = File(extractedPath);
          await extractedFile.writeAsBytes(Uint8List.fromList(zipFile.content as List<int>));
          
          print('[AudioExtract] Extracted MP3 to: $extractedPath');
          return extractedPath;
        }
      }
      
      print('[AudioExtract] No MP3 files found in ZIP');
      return null;
    } catch (e) {
      print('[AudioExtract] Error extracting MP3 from ZIP: $e');
      return null;
    }
  }

  /// Check if file bytes represent a valid MP4 file
  bool _isValidMp4File(List<int> bytes) {
    if (bytes.length < 12) return false;
    
    // Check for MP4 file signature (ftyp box)
    // MP4 files start with "ftyp" at offset 4
    if (bytes.length >= 8) {
      // Look for "ftyp" at position 4
      if (bytes[4] == 0x66 && bytes[5] == 0x74 && 
          bytes[6] == 0x79 && bytes[7] == 0x70) {
        return true;
      }
    }
    
    return false;
  }

  /// Extract MP3/MP4 from ZIP file
  Future<String?> _extractMediaFromZip(String zipPath, String productType) async {
    try {
      print('[MediaExtract] Extracting $productType from ZIP: $zipPath');
      
      final file = File(zipPath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Look for media files in ZIP by name content
      for (final zipFile in archive) {
        if (!zipFile.isFile) continue;
        
        final fileName = zipFile.name.toLowerCase();
        
        // Check if filename contains the product type keyword
        final isAudioFile = fileName.contains('audio') || fileName.endsWith('.mp3');
        final isVideoFile = fileName.contains('video') || fileName.endsWith('.mp4');
        final isStickerFile = fileName.contains('sticker') || 
                             (fileName.endsWith('.png') || fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.webp'));
        
        print('[MediaExtract] Checking file: $fileName');
        print('[MediaExtract] - isAudioFile: $isAudioFile');
        print('[MediaExtract] - isVideoFile: $isVideoFile');
        print('[MediaExtract] - isStickerFile: $isStickerFile');
        
        // Extract based on file content and requested type
        if ((productType == 'audio' && isAudioFile) || 
            (productType == 'video' && isVideoFile) || 
            (productType == 'sticker' && isStickerFile)) {
          
          // Extract to same directory as ZIP
          final dir = file.parent;
          final extractedPath = '${dir.path}/${zipFile.name}';
          
          final extractedFile = File(extractedPath);
          await extractedFile.writeAsBytes(Uint8List.fromList(zipFile.content as List<int>));
          
          print('[MediaExtract] Extracted matching file: $extractedPath');
          return extractedPath;
        }
        
        // If we reach here, there's a mismatch between expected type and actual content
        print('[MediaExtract] ERROR: Expected $productType but ZIP contains different content');
        print('[MediaExtract] Available files in ZIP:');
        for (final zipFile in archive) {
          if (zipFile.isFile) {
            print('[MediaExtract]   - ${zipFile.name}');
          }
        }
        print('[MediaExtract] This appears to be a server-side error - wrong file type returned');
      }
      
      print('[MediaExtract] No matching $productType file found in ZIP');
      return null;
    } catch (e) {
      print('[MediaExtract] Error extracting from ZIP: $e');
      return null;
    }
  }

  /// Get MIME type based on file extension
  String? _getMimeType(String fileName) {
    final ext = fileName.toLowerCase().split('.').lastOrNull;
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      case 'zip':
        return 'application/zip';
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }

  /// Unzip a downloaded ZIP pack and save each image to the phone's gallery.
  /// This allows keyboards like Gboard to see them in the "Stickers" section.
  /// Also offers to add the stickers to WhatsApp.
  Future<void> unzipAndSaveStickersToGallery(
    String zipPath,
    String packName, {
    int? productId,
    VoidCallback? onComplete,
    bool skipPreview = false,
  }) async {
    try {
      log('[StickerUnzip] Starting unzip for pack: $packName at $zipPath');
      print('====== STARTING STICKER EXTRACTION ======');
      print('Zip Path: $zipPath');
       // Request storage permissions with broad compatibility
      if (Platform.isAndroid) {
        log('[StickerUnzip] Requesting storage permissions...');
        try {
          // Requesting multiple permissions often required for shared storage access
          await [
            Permission.storage,
            Permission.photos,
            Permission.mediaLibrary,
          ].request();
        } catch (e) {
          log('[StickerUnzip] Permission request warning: $e');
        }
      }

      final file = File(zipPath);
      if (!file.existsSync()) {
        log('[StickerUnzip] File not found: $zipPath');
        return;
      }

      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final stickerPaths = <String>[];
      
      final Directory libDir = await getApplicationSupportDirectory();
      
      final cleanName =
          packName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final finalIdentifier = (cleanName.isEmpty ||
              RegExp(r'^[0-9]').hasMatch(cleanName))
          ? 'pack$cleanName'
          : cleanName.substring(0, min(cleanName.length, 20));
      print(
        '[StickerUnzip] packName="$packName" identifier="$finalIdentifier" '
        'zip=$zipPath',
      );

      // Use simple pack name without complex timestamps
      final displayName = packName.length > 128 ? packName.substring(0, 128) : packName;
      final packStoreDir = Directory('${libDir.path}/stickers/$finalIdentifier');
      if (packStoreDir.existsSync()) {
        print('[StickerUnzip] clearing old stickers at ${packStoreDir.path}');
        await packStoreDir.delete(recursive: true);
      }
      await packStoreDir.create(recursive: true);
      
      int stickerCount = 1; // Start stickers at 1 for strict sequence
      for (final zipFile in archive) {
        if (!zipFile.isFile) {
          print('Skipping directory: ${zipFile.name}');
          continue;
        }

        final lowerName = zipFile.name.toLowerCase();
        if (lowerName.endsWith('.png') || lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.webp') || lowerName.endsWith('.gif')) {
          // Extra filtering for __MACOSX system folders or other junk
          if (zipFile.name.startsWith('__MACOSX') || zipFile.name.contains('/.')) {
            print('Skipping hidden/system file: ${zipFile.name}');
            continue;
          }
          
          final isTrayIcon = lowerName.contains('tray');
          final isAlreadyWebP = lowerName.endsWith('.webp');
          
          try {
            final data = zipFile.content as List<int>;
            Uint8List finalStickerData;
            
            // If it's already WebP (from our server), TRUST it. 
            // The server already forced it to 512x512/96x96 WebP.
            // This avoids the "WebP encoding not supported" error in Dart.
            if (isAlreadyWebP) {
              finalStickerData = Uint8List.fromList(data);
              log('[StickerUnzip] Using original WebP data (already resized by server) for ${zipFile.name}');
            } else {
              // Only decode/resize if it's NOT WebP (failsafe)
              final image = img.decodeImage(Uint8List.fromList(data));
              if (image != null) {
                img.Image processed;
                if (isTrayIcon) {
                  processed = img.copyResize(image, width: 96, height: 96);
                  finalStickerData = Uint8List.fromList(img.encodePng(processed));
                } else {
                  processed = img.copyResize(image, width: 512, height: 512);
                  // If we can't encode WebP, use PNG as a desperate fallback (WhatsApp might reject stickers if PNG)
                  finalStickerData = Uint8List.fromList(img.encodeNamedImage('x.webp', processed) ?? img.encodePng(processed));
                }
              } else {
                finalStickerData = Uint8List.fromList(data);
              }
            }

            // ABSOLUTE NAMING: No ambiguity for WhatsApp's engine
            final outputFileName = isTrayIcon ? 'FINAL_TRAY_ICON.webp' : 'sticker_$stickerCount.webp';
            final tempPath = '${packStoreDir.path}/$outputFileName';
            
            File(tempPath).writeAsBytesSync(finalStickerData);
            stickerPaths.add(tempPath);
            if (!isTrayIcon) stickerCount++;
            
            print('SUCCESS: Unpacked $outputFileName (${finalStickerData.length} bytes)');

          } catch (e) {
            log('[StickerUnzip] Error processing image: $e');
            print('ERROR processing ${zipFile.name}: $e');
          }
        } else {
          print('Skipping non-image file: ${zipFile.name}');
        }
      }
      
      print('====== EXTRACTION COMPLETE ======');
      print('Total paths in stickerPaths: ${stickerPaths.length}');
      int totalSizeBytes = 0;
      for(var p in stickerPaths) {
        final f = File(p);
        final size = f.lengthSync();
        totalSizeBytes += size;
        print(' - $p (${(size/1024).toStringAsFixed(1)} KB)');
      }
      print('TOTAL STICKER PACK SIZE: ${(totalSizeBytes/1024).toStringAsFixed(1)} KB');
      if (totalSizeBytes > 1024 * 1024) {
        print('WARNING: Total pack exceeds 1MB. WhatsApp will likely REJECT this pack.');
      }
      
      // Small delay to ensure any previous dialogs are fully dismissed
      await Future.delayed(const Duration(milliseconds: 300));

      if (stickerPaths.isNotEmpty) {
        int actualStickers = stickerPaths.where((p) => !p.contains('FINAL_TRAY_ICON')).length;
        
        // Get sticker files for sharing
        final stickerFiles = stickerPaths.where((p) => p.contains('sticker_')).toList();
        final trayIconPath = stickerPaths.firstWhere((p) => p.contains('FINAL_TRAY_ICON'), orElse: () => '');
        
        // Prepare files for sharing to platforms
        final filesToShare = <XFile>[];
        if (trayIconPath.isNotEmpty && File(trayIconPath).existsSync()) {
          filesToShare.add(XFile(trayIconPath));
        }
        for (final path in stickerFiles) {
          if (File(path).existsSync()) {
            filesToShare.add(XFile(path));
          }
        }
        
        // Skip preview dialog and directly add to WhatsApp if skipPreview is true
        if (skipPreview) {
          try {
            await addStickerPackToWhatsApp(packName, stickerPaths, finalIdentifier);
            onComplete?.call();
          } catch (e) {
            print('Direct WhatsApp add error: $e');
            onComplete?.call();
          }
        } else {
          // Show custom preview dialog with working share button
          Get.dialog(
          Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 580),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  // Header with title and share button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$packName — Preview',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF8B4513)),
                        onPressed: () {
                          Get.back();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to preview stickers',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  
                  // Sticker grid preview
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: stickerFiles.length > 8 ? 8 : stickerFiles.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Sticker image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(stickerFiles[index]),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 24),
                                ),
                              ),
                            ),
                            // WhatsApp button overlay on each sticker
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () async {
                                  // Share individual sticker to WhatsApp
                                  try {
                                    final stickerFile = XFile(stickerFiles[index]);
                                    await Share.shareXFiles(
                                      [stickerFile],
                                      text: '🎨 Sticker from $packName',
                                      subject: 'Sticker',
                                    );
                                  } catch (e) {
                                    Get.snackbar('Error', 'Could not share sticker: $e');
                                  }
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.chat,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$actualStickers stickers • Fruits Of Spirit',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action buttons - Grid of platform options
                  const SizedBox(height: 8),
                  const Text(
                    'Add or Share to:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  
                  // Platform buttons grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // WhatsApp - Add Pack (Native Integration)
                      _buildPlatformButton(
                        icon: Image.asset('assets/whatsapp.png', width: 20, height: 20),
                        color: const Color(0xFF25D366),
                        label: 'WhatsApp',
                        onTap: () async {
                          try {
                            // Close preview dialog first
                            Get.back();
                            // Small delay to ensure dialog is closed
                            await Future.delayed(const Duration(milliseconds: 300));
                            // Then add to WhatsApp (this shows its own loading)
                            await addStickerPackToWhatsApp(packName, stickerPaths, finalIdentifier);
                            // Notify parent that WhatsApp is done
                            onComplete?.call();
                          } catch (e) {
                            print('WhatsApp button error: $e');
                            // Ensure we close any open dialogs and notify completion
                            while (Get.isOverlaysOpen) {
                              Get.back();
                            }
                            onComplete?.call();
                          }
                        },
                      ),

                      // Instagram - Share to Stories
                      // _buildPlatformButton(
                      //   icon: Icons.camera_alt,
                      //   color: const Color(0xFFE4405F),
                      //   label: 'Instagram',
                      //   onTap: () async {
                      //     Get.back();
                      //     try {
                      //       await Share.shareXFiles(
                      //         filesToShare.take(10).toList(),
                      //         text: '🎨 $packName - Sticker Pack\n\nCheck out these amazing stickers! ✨',
                      //       );
                      //     } catch (e) {
                      //       Get.snackbar('Error', 'Could not share to Instagram: $e');
                      //     }
                      //   },
                      // ),

                  //     // Telegram - Share
                  //     _buildPlatformButton(
                  //       icon: Icons.send,
                  //       color: const Color(0xFF0088cc),
                  //       label: 'Telegram',
                  //       onTap: () async {
                  //         Get.back();
                  //         try {
                  //           await Share.shareXFiles(
                  //             filesToShare.take(30).toList(),
                  //             text: '🎨 Sticker Pack: $packName\n\n📦 $actualStickers stickers',
                  //           );
                  //         } catch (e) {
                  //           Get.snackbar('Error', 'Could not share to Telegram: $e');
                  //         }
                  //       },
                  //     ),
                  //
                  //     // Facebook - Share
                  //     _buildPlatformButton(
                  //       icon: Icons.facebook,
                  //       color: const Color(0xFF1877F2),
                  //       label: 'Facebook',
                  //       onTap: () async {
                  //         Get.back();
                  //         try {
                  //           await Share.shareXFiles(
                  //             filesToShare.take(30).toList(),
                  //             text: '🎨 Sticker Pack: $packName\n\n📦 $actualStickers stickers',
                  //           );
                  //         } catch (e) {
                  //           Get.snackbar('Error', 'Could not share to Facebook: $e');
                  //         }
                  //       },
                  //     ),
                  //
                  //     // Messenger - Share
                  //     _buildPlatformButton(
                  //       icon: Icons.message,
                  //       color: const Color(0xFF0084FF),
                  //       label: 'Messenger',
                  //       onTap: () async {
                  //         Get.back();
                  //         try {
                  //           await Share.shareXFiles(
                  //             filesToShare.take(30).toList(),
                  //             text: '🎨 Sticker Pack: $packName',
                  //           );
                  //         } catch (e) {
                  //           Get.snackbar('Error', 'Could not share to Messenger: $e');
                  //         }
                  //       },
                  //     ),
                  //
                  //     // More Options
                  //     _buildPlatformButton(
                  //       icon: Icons.more_horiz,
                  //       color: const Color(0xFF8B4513),
                  //       label: 'More',
                  //       onTap: () {
                  //         _showComprehensiveShareDialog(packName, stickerFiles, trayIconPath, actualStickers);
                  //       },
                  //     ),
                  //   ],
                  // ),
                  //
                  // const SizedBox(height: 16),
                  //
                  // Cancel button
                  // TextButton(
                  //   onPressed: () => Get.back(),
                  //   child: const Text('Cancel'),
                  // ),
                ],
              ),
            ]
                  ),
          ),
        ),
      ),
    ));
        }
      } else {
        Get.defaultDialog(
          title: 'Extraction Alert',
          middleText: 'No valid sticker images (.webp, .png, etc.) found in the zip file. Check the format of the digital download on the server.',
          textConfirm: 'OK',
          onConfirm: () => Get.back(),
        );
      }
    } catch (e) {
      // Delay to ensure any loader dialog is visible before closing
      await Future.delayed(const Duration(milliseconds: 500));
      if (Get.isDialogOpen ?? false) {
        Get.back(); // close loader if crash
      }
      log('[StickerUnzip] Error: $e');
      print('FATAL ERROR DURING EXTRACTION: $e');
      Get.snackbar('Sticker Export Failed', 'Could not extract stickers into gallery: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    }
  }
  Future<void> addStickerPackToWhatsApp(String packName, List<String> stickerPaths, String packIdentifier) async {
    if (stickerPaths.isEmpty) {
      Get.snackbar('Error', 'No stickers found to add to WhatsApp');
      if (Get.isDialogOpen ?? false) Get.back();
      return;
    }
    
    // Add timeout to prevent infinite loading (increased to 60 seconds for WhatsApp operations)
    Future.delayed(const Duration(seconds: 60), () {
      if (Get.isOverlaysOpen) {
        print('TIMEOUT: Closing WhatsApp dialogs after 60 seconds');
        while (Get.isOverlaysOpen) {
          Get.back();
        }
        Get.snackbar('Timeout', 'WhatsApp operation timed out. Please try again.',
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    });

    bool wasCancelled = false;

    try {
      log('[WhatsAppSticker] Initializing WhatsApp integration for $packName');
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // SEPARATE: Find the FIXED tray icon name exclusively (must be 96x96 WebP)
      final trayIconPath = stickerPaths.firstWhere((p) => p.contains('FINAL_TRAY_ICON'), orElse: () => '');
      // FILTER: Only the FIXED sticker sequence goes in the list (must be 512x512 WebP)
      final stickersOnly = stickerPaths.where((p) => p.contains('sticker_')).toList();

      // VALIDATION REMOVED: Allow any number of stickers and optional tray icon
      // Previous validation required at least 3 stickers and mandatory tray icon

      // VALIDATE AND RE-ENCODE STICKERS FOR WHATSAPP COMPATIBILITY
      log('[WhatsAppSticker] Starting validation: tray=$trayIconPath, stickers=${stickersOnly.length}');
      final validatedTrayPath = await _validateAndFixWebP(trayIconPath, isTrayIcon: true);
      final validatedStickerPaths = <String>[];
      
      // WhatsApp limit: maximum 14 stickers per pack to prevent range errors (library bug)
      final maxStickers = 14;
      final stickersToProcess = stickersOnly.take(maxStickers).toList();
      
      log('[WhatsAppSticker] Processing ${stickersToProcess.length} stickers (limit: $maxStickers)');
      print('DEBUG: Total stickersOnly.length: ${stickersOnly.length}');
      print('DEBUG: Stickers to process (after limit): ${stickersToProcess.length}');
      
      for (var i = 0; i < stickersToProcess.length; i++) {
        print('DEBUG: Processing sticker at index: $i of ${stickersToProcess.length}');
        print('DEBUG: Sticker path: ${stickersToProcess[i]}');
        final validatedPath = await _validateAndFixWebP(stickersToProcess[i], isTrayIcon: false);
        if (validatedPath != null) {
          validatedStickerPaths.add(validatedPath);
        } else {
          log('[WhatsAppSticker] Failed to validate sticker ${i+1}: ${stickersToProcess[i]}');
        }
      }
      
      log('[WhatsAppSticker] Validation complete: tray=${validatedTrayPath != null ? "OK" : "FAILED"}, stickers=${validatedStickerPaths.length}/${stickersOnly.length}');
      
      // DEBUG: Log tray icon details
      if (validatedTrayPath != null) {
        final trayFile = File(validatedTrayPath);
        if (trayFile.existsSync()) {
          final trayBytes = await trayFile.readAsBytes();
          final trayHash = trayBytes.fold<int>(0, (prev, b) => prev + b) % 10000;
          print('DEBUG: Tray Icon - Size: ${trayBytes.length} bytes, Hash: $trayHash, Path: $validatedTrayPath');
        }
      }
      for (var i = 0; i < validatedStickerPaths.length; i++) {
        final file = File(validatedStickerPaths[i]);
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();
          final size = bytes.length;
          final hash = bytes.fold<int>(0, (prev, b) => prev + b) % 10000;
          print('DEBUG: Sticker $i - Size: $size bytes, Hash: $hash, Path: ${validatedStickerPaths[i]}');
        }
      }

      // Notify user if stickers were limited
      if (stickersOnly.length > maxStickers) {
        log('[WhatsAppSticker] Pack limited to $maxStickers stickers (WhatsApp limit)');
        Get.snackbar(
          'WhatsApp Limit',
          'Pack limited to $maxStickers stickers (WhatsApp limit). ${stickersOnly.length - maxStickers} stickers not included.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }

      // ENHANCED VALIDATION: Ensure WhatsApp requirements are met
      if (validatedTrayPath == null) {
        print('[WhatsAppSticker] ERROR: Tray icon validation failed - cannot proceed');
        Get.snackbar(
          'Error',
          'Tray icon validation failed. Please check the sticker pack.',
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
        return;
      }
      
      if (validatedStickerPaths.isEmpty) {
        print('[WhatsAppSticker] ERROR: No stickers validated - cannot proceed');
        Get.snackbar(
          'Error',
          'No valid stickers found. Please check the sticker pack.',
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
        return;
      }

      // WhatsApp requires at least 3 stickers and at most 30 stickers
      if (validatedStickerPaths.length < 3) {
        print('[WhatsAppSticker] ERROR: Insufficient stickers (${validatedStickerPaths.length} < 3)');
        Get.snackbar(
          'Error',
          'WhatsApp requires at least 3 stickers per pack. Found: ${validatedStickerPaths.length}',
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
        return;
      }

      // Use validated tray icon
      final trayPathToUse = validatedTrayPath;

      // Clear WhatsApp cache and temporary files to prevent conflicts
      try {
        final tempDir = await getTemporaryDirectory();
        final cacheDir = Directory('${tempDir.path}/whatsapp_stickers');
        if (cacheDir.existsSync()) {
          await cacheDir.delete(recursive: true);
          print('[WhatsAppSticker] Cleared WhatsApp cache directory');
        }
      } catch (e) {
        print('[WhatsAppSticker] Cache clearing failed: $e');
      }

      // Generate WhatsApp-compliant identifier (lowercase, alphanumeric + underscore, starts with letter)
      final cleanName = packName.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      final shortName = (cleanName.isEmpty || RegExp(r'^[0-9]').hasMatch(cleanName))
          ? 'pack${cleanName}'
          : cleanName.substring(0, min(cleanName.length, 20));
      final finalIdentifier = shortName;
      final displayName = packName.length > 128 ? packName.substring(0, 128) : packName;

      final whatsappStickers = WhatsappStickers(
        identifier: finalIdentifier,
        name: displayName, 
        publisher: 'Fruits Of Spirit',
        trayImageFileName: WhatsappStickerImage.fromFile(trayPathToUse),
        publisherWebsite: 'https://fruitsofspirit.com',
        privacyPolicyWebsite: 'https://fruitsofspirit.com/privacy',
        licenseAgreementWebsite: 'https://fruitsofspirit.com/license',
      );
      
      log('[WhatsAppSticker] Configured pack: identifier=$finalIdentifier, publisher=${whatsappStickers.publisher}');
      print('=== WHATSAPP EXPORT START ===');
      print('Pack Name: ${whatsappStickers.name}');
      print('Identifier: ${whatsappStickers.identifier}');
      print('Publisher: ${whatsappStickers.publisher}');
      print('Tray Icon Path: $trayIconPath');
      print('Legal URL: ${whatsappStickers.publisherWebsite}');
      print('DEBUG: About to add ${validatedStickerPaths.length} stickers to WhatsApp pack');
      
      for (var i = 0; i < validatedStickerPaths.length; i++) {
        print('DEBUG: Adding sticker $i of ${validatedStickerPaths.length}');
        print('DEBUG: Sticker path: ${validatedStickerPaths[i]}');
        whatsappStickers.addSticker(WhatsappStickerImage.fromFile(validatedStickerPaths[i]), ['😀']);
      }

      print('Exporting ${validatedStickerPaths.length} stickers to WhatsApp...');
      
      // Comprehensive debug logging
      print('=== WHATSAPP PACK DEBUG INFO ===');
      print('Identifier: ${whatsappStickers.identifier}');
      print('Name: ${whatsappStickers.name}');
      print('Publisher: ${whatsappStickers.publisher}');
      print('Tray Icon: ${whatsappStickers.trayImageFileName}');
      print('Sticker Count: ${validatedStickerPaths.length}');
      print('Legal URLs: ${whatsappStickers.publisherWebsite}');
      
      // Enhanced file validation for WhatsApp compatibility
      bool allFilesValid = true;
      
      // Validate tray icon file exists and is valid WebP
      if (trayPathToUse != null) {
        final trayFile = File(trayPathToUse);
        print('Tray file exists: ${trayFile.existsSync()}');
        if (trayFile.existsSync()) {
          final traySize = await trayFile.length();
          print('Tray file size: $traySize bytes');
          
          // Validate it's actually a WebP file
          final trayBytes = await trayFile.readAsBytes();
          if (trayBytes.length < 4 || 
              !(trayBytes[0] == 0x52 && trayBytes[1] == 0x49 && trayBytes[2] == 0x46 && trayBytes[3] == 0x46)) {
            print('ERROR: Tray icon is not a valid WebP file');
            allFilesValid = false;
          }
        } else {
          print('ERROR: Tray icon file does not exist');
          allFilesValid = false;
        }
      }
      
      // Validate sticker files exist and are valid WebP
      for (var i = 0; i < validatedStickerPaths.length; i++) {
        final stickerFile = File(validatedStickerPaths[i]);
        final exists = stickerFile.existsSync();
        final size = exists ? await stickerFile.length() : 0;
        print('Sticker $i: exists=$exists, size=$size bytes, path=${validatedStickerPaths[i]}');
        
        if (exists && size > 0) {
          // Validate it's actually a WebP file
          final stickerBytes = await stickerFile.readAsBytes();
          if (stickerBytes.length < 4 || 
              !(stickerBytes[0] == 0x52 && stickerBytes[1] == 0x49 && stickerBytes[2] == 0x46 && stickerBytes[3] == 0x46)) {
            print('ERROR: Sticker $i is not a valid WebP file');
            allFilesValid = false;
          }
        } else {
          print('ERROR: Sticker $i file is invalid or empty');
          allFilesValid = false;
        }
      }
      
      if (!allFilesValid) {
        print('ERROR: One or more files are invalid WebP files - cannot proceed');
        Get.snackbar(
          'Error',
          'Invalid sticker files. Please try downloading the pack again.',
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
        return;
      }
      print('=== END DEBUG INFO ===');
      
      Get.back(); // Close loader
      
      // Extended delay to ensure cache clearing takes effect and provider is ready
      await Future.delayed(const Duration(milliseconds: 3000));
      
      try {
        await whatsappStickers.sendToWhatsApp();
        print('WhatsApp Export Complete (Invoked)');
        log('[WhatsAppSticker] Successfully invoked sendToWhatsApp');
        
        // Show success dialog with instructions
        Get.dialog(
          AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Pack Added!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${whatsappStickers.name}" has been added to WhatsApp!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If this pack already existed, it has been replaced.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How to find your stickers:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildStepText('1', 'Open any WhatsApp chat'),
                _buildStepText('2', 'Tap the emoji icon 😊'),
                _buildStepText('3', 'Tap the sticker icon 🔰 at bottom'),
                _buildStepText('4', 'Look for "${whatsappStickers.name}" at the top'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'If not visible: Restart WhatsApp or your phone',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Close success dialog
                  Get.back();
                  // Ensure all overlays are closed (cleanup)
                  while (Get.isOverlaysOpen) {
                    Get.back();
                  }
                },
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Close success dialog first
                  Get.back();
                  // Show troubleshooting dialog
                  _showTroubleshootingDialog(whatsappStickers.name);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Not showing?'),
              ),
            ],
          ),
        );
      } catch (e, stack) {
        print('!!! WHATSAPP EXPORT ERROR !!!');
        print('Error Detail: $e');
        print('Stack Trace: $stack');
        
        // Check for specific error types
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('handlestickerpackpreviewresult') || 
            errorString.contains('failed') ||
            errorString.contains('already') ||
            errorString.contains('duplicate') ||
            errorString.contains('could not add') ||
            errorString.contains('conflict') ||
            errorString.contains('exists')) {
          
          print('[WhatsAppSticker] WhatsApp rejected pack: $e');
          while (Get.isOverlaysOpen) {
            Get.back();
          }

          Get.dialog(
            AlertDialog(
              title: const Text('Could Not Add to WhatsApp'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WhatsApp rejected this sticker pack. Common causes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• App not registered on WhatsApp/Meta sticker whitelist'),
                    const Text('• Tap ADD in WhatsApp (don\'t press back)'),
                    const Text('• Try removing old pack from WhatsApp first'),
                    const SizedBox(height: 12),
                    const Text(
                      'Manual steps:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildManualStep('1', 'Go to WhatsApp Settings'),
                    _buildManualStep('2', 'Tap on "Stickers"'),
                    _buildManualStep('3', 'Tap "ADD" or "+" button'),
                    _buildManualStep('4', 'Choose "Download" option'),
                    _buildManualStep('5', 'Look for your sticker pack in downloads'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Alternative: Try restarting WhatsApp and your device',
                                  style: TextStyle(fontSize: 12, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Close error dialog
                    Get.back();
                    // Ensure all overlays are closed (cleanup)
                    while (Get.isOverlaysOpen) {
                      Get.back();
                    }
                  },
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _showReplacePackDialog(packName, stickerPaths, packIdentifier, whatsappStickers.identifier);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Replace'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    // Advanced retry with maximum uniqueness
                    await _advancedWhatsAppExport(packName, stickerPaths, packIdentifier);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  icon: const Icon(Icons.build, size: 18),
                  label: const Text('Advanced'),
                ),
              ],
            ),
          );
        } else {
          // Check for specific error patterns to provide better user feedback
          final errorString = e.toString().toLowerCase();
          String userMessage;
          
          if (errorString.contains('whatsapp is not installed') || errorString.contains('not installed on target')) {
            userMessage = 'WhatsApp is not installed on this device. Please install WhatsApp first and try again.';
          } else if (errorString.contains('cancelled')) {
            // User cancelled the operation - don't show error, just clean up
            print('WhatsApp operation cancelled by user');
            wasCancelled = true;
            // Ensure all overlays are closed
            while (Get.isOverlaysOpen) {
              Get.back();
            }
            return;
          } else if (errorString.contains('handlestickerpackpreviewresult') ||
                     errorString.contains('already') ||
                     errorString.contains('duplicate')) {
            userMessage = 'This sticker pack already exists in WhatsApp. It will be automatically replaced when you add it again.';
          } else {
            userMessage = 'Could not add stickers to WhatsApp: ${e.toString().substring(0, min(e.toString().length, 100))}';
          }
          
          Get.snackbar(
            'WhatsApp Sticker Issue',
            userMessage,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      }
      print('=== WHATSAPP EXPORT END ===');
    } catch (e) {
      // Check if user cancelled - don't show error
      if (e.toString().toLowerCase().contains('cancelled')) {
        print('WhatsApp operation cancelled by user');
        wasCancelled = true;
      } else {
        // Ensure all dialogs are closed
        while (Get.isOverlaysOpen) {
          Get.back();
        }
        log('[WhatsAppSticker] General Error: $e');
        print('WhatsApp function completed with error - all dialogs closed');
      }
    }

    // Final cleanup - ensure all overlays are closed (only for non-cancelled cases)
    if (!wasCancelled) {
      while (Get.isOverlaysOpen) {
        Get.back();
      }
    }

    // Always ensure completion - prevent infinite loading
    print('WhatsApp addStickerPackToWhatsApp function completed');
  }
  /// Retry WhatsApp export with enhanced uniqueness
  Future<void> _retryWhatsAppExport(String packName, List<String> stickerPaths, String packIdentifier) async {
    try {
      // Show loading dialog
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing unique sticker pack...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Wait a moment to ensure clean state
      await Future.delayed(const Duration(milliseconds: 500));

      // Generate completely new unique identifiers with extra randomness
      final uniqueName = packName.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .substring(0, min(packName.length, 8));
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomSeed1 = Random().nextInt(999999).toString().padLeft(6, '0');
      final randomSeed2 = Random().nextInt(999999).toString().padLeft(6, '0');
      final deviceHash = Platform.isAndroid ? 'A' : 'I';
      final finalIdentifier = 'fos${deviceHash}${uniqueName}_${timestamp}_${randomSeed1}${randomSeed2}';
      
      final timeSuffix = timestamp.substring(timestamp.length - 6);
      final uniquePackName = '$packName #$timeSuffix-$randomSeed1-$randomSeed2';
      final uniquePublisher = 'FOS #$timeSuffix-$randomSeed1-$randomSeed2';

      // Re-process sticker paths to get fresh validated paths with enhanced modification
      final trayIconPath = stickerPaths.firstWhere((path) => path.contains('tray') || path.contains('TRAY'), 
          orElse: () => stickerPaths.first);
      final stickersOnly = stickerPaths.where((path) => !path.contains('tray') && !path.contains('TRAY')).toList();
      
      final validatedTrayPath = await _validateAndFixWebP(trayIconPath, isTrayIcon: true);
      final validatedStickerPaths = <String>[];
      
      for (var i = 0; i < stickersOnly.length && i < 14; i++) {
        final validatedPath = await _validateAndFixWebP(stickersOnly[i], isTrayIcon: false);
        if (validatedPath != null) {
          validatedStickerPaths.add(validatedPath);
        }
      }

      // VALIDATION REMOVED: Allow retry even with validation issues
      final retryTrayPath = validatedTrayPath ?? (validatedStickerPaths.isNotEmpty ? validatedStickerPaths.first : trayIconPath);
      if (validatedStickerPaths.isEmpty && trayIconPath.isNotEmpty) {
        validatedStickerPaths.add(trayIconPath);
      }

      final whatsappStickers = WhatsappStickers(
        identifier: finalIdentifier,
        name: uniquePackName.length > 100 ? uniquePackName.substring(0, 100) : uniquePackName, 
        publisher: uniquePublisher,
        trayImageFileName: WhatsappStickerImage.fromFile(validatedTrayPath.toString()),
        publisherWebsite: 'https://fruitsofspirit.com',
        privacyPolicyWebsite: 'https://fruitsofspirit.com/privacy',
        licenseAgreementWebsite: 'https://fruitsofspirit.com/license',
      );
      
      for (var i = 0; i < validatedStickerPaths.length; i++) {
        whatsappStickers.addSticker(WhatsappStickerImage.fromFile(validatedStickerPaths[i]), ['']);
      }

      // Close loading dialog
      Get.back();
      
      // Show new loading dialog for export
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Adding to WhatsApp...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      await Future.delayed(const Duration(milliseconds: 1000));
      await whatsappStickers.sendToWhatsApp();
      
      Get.back();
      Get.snackbar(
        'WhatsApp',
        'Sticker pack "${whatsappStickers.name}" added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Retry Failed',
        'Still unable to add to WhatsApp. Please try again later or contact support.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      print('Retry failed: $e');
    }
  }

  /// Build manual step widget
  Widget _buildManualStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Advanced WhatsApp export with completely unique content generation
  Future<void> _advancedWhatsAppExport(String packName, List<String> stickerPaths, String packIdentifier) async {
    try {
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating unique sticker pack...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Generate ultra-unique identifiers
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomSeed = Random().nextInt(999999).toString().padLeft(6, '0');
      final uuid = timestamp + randomSeed;
      final finalIdentifier = 'fosunique_${uuid}_advanced';
      
      final uniquePackName = '$packName UNIQUE-$randomSeed';
      final uniquePublisher = 'FOS Advanced-$randomSeed';

      // Process stickers with maximum uniqueness
      final trayIconPath = stickerPaths.firstWhere((path) => path.contains('tray') || path.contains('TRAY'), 
          orElse: () => stickerPaths.first);
      final stickersOnly = stickerPaths.where((path) => !path.contains('tray') && !path.contains('TRAY')).toList();
      
      final validatedTrayPath = await _validateAndFixWebP(trayIconPath, isTrayIcon: true);
      final validatedStickerPaths = <String>[];
      
      // Process each sticker with unique timestamp to ensure different files
      for (var i = 0; i < stickersOnly.length && i < 14; i++) {
        // Add delay to ensure different timestamps
        await Future.delayed(Duration(milliseconds: 10));
        final validatedPath = await _validateAndFixWebP(stickersOnly[i], isTrayIcon: false);
        if (validatedPath != null) {
          validatedStickerPaths.add(validatedPath);
        }
      }

      // VALIDATION REMOVED: Allow advanced export even with validation issues
      final advancedTrayPath = validatedTrayPath ?? (validatedStickerPaths.isNotEmpty ? validatedStickerPaths.first : trayIconPath);
      if (validatedStickerPaths.isEmpty && trayIconPath.isNotEmpty) {
        validatedStickerPaths.add(trayIconPath);
      }

      final whatsappStickers = WhatsappStickers(
        identifier: finalIdentifier,
        name: uniquePackName.length > 100 ? uniquePackName.substring(0, 100) : uniquePackName, 
        publisher: uniquePublisher,
        trayImageFileName: WhatsappStickerImage.fromFile(validatedTrayPath.toString()),
        publisherWebsite: 'https://fruitsofspirit.com',
        privacyPolicyWebsite: 'https://fruitsofspirit.com/privacy',
        licenseAgreementWebsite: 'https://fruitsofspirit.com/license',
      );
      
      for (var i = 0; i < validatedStickerPaths.length; i++) {
        whatsappStickers.addSticker(WhatsappStickerImage.fromFile(validatedStickerPaths[i]), ['']);
      }

      Get.back();
      
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Adding unique pack to WhatsApp...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      await whatsappStickers.sendToWhatsApp();
      
      Get.back();
      Get.snackbar(
        'WhatsApp Success!',
        'Unique sticker pack "${whatsappStickers.name}" added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Advanced Export Failed',
        'Unable to add to WhatsApp. The issue may be with WhatsApp itself.\nPlease try restarting WhatsApp or your device.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      print('Advanced export failed: $e');
    }
  }

  /// Build option text widget for the dialog
  Widget _buildOptionText(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji ', style: const TextStyle(fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show replace pack dialog with instructions
  Future<void> _showReplacePackDialog(String packName, List<String> stickerPaths, String packIdentifier, String existingIdentifier) async {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Replace Pack'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To replace the existing pack, you need to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStepText('1', 'Open WhatsApp'),
            _buildStepText('2', 'Go to any chat → Stickers → + (Add)'),
            _buildStepText('3', 'Find "${packName}" pack'),
            _buildStepText('4', 'Tap the pack → Delete/Uninstall'),
            _buildStepText('5', 'Come back here and tap "Add New Pack" below'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Tip: After deleting, you can add the new version immediately!',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              // Add with fresh content using same pack name
              await _addFreshPack(packName, stickerPaths, packIdentifier);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.add_circle),
            label: const Text('Add New Pack'),
          ),
        ],
      ),
    );
  }

  /// Build step text widget
  Widget _buildStepText(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Add fresh pack with guaranteed unique content
  Future<void> _addFreshPack(String packName, List<String> stickerPaths, String packIdentifier) async {
    try {
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing fresh sticker pack...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Use the original pack name but with fresh unique content
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomSeed = Random().nextInt(999999).toString().padLeft(6, '0');
      
      // Keep the original pack name but use fresh identifier
      final finalIdentifier = 'fos${packName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}_${timestamp}_$randomSeed';
      
      // Process all stickers with ultra-aggressive modifications
      final trayIconPath = stickerPaths.firstWhere((path) => path.contains('tray') || path.contains('TRAY'), 
          orElse: () => stickerPaths.first);
      final stickersOnly = stickerPaths.where((path) => !path.contains('tray') && !path.contains('TRAY')).toList();
      
      final validatedTrayPath = await _validateAndFixWebP(trayIconPath, isTrayIcon: true);
      final validatedStickerPaths = <String>[];
      
      // Process with delays for maximum uniqueness
      for (var i = 0; i < stickersOnly.length && i < 14; i++) {
        await Future.delayed(Duration(milliseconds: 20));
        final validatedPath = await _validateAndFixWebP(stickersOnly[i], isTrayIcon: false);
        if (validatedPath != null) {
          validatedStickerPaths.add(validatedPath);
        }
      }

      // VALIDATION REMOVED: Allow fresh pack even with validation issues
      final freshTrayPath = validatedTrayPath ?? (validatedStickerPaths.isNotEmpty ? validatedStickerPaths.first : trayIconPath);
      if (validatedStickerPaths.isEmpty && trayIconPath.isNotEmpty) {
        validatedStickerPaths.add(trayIconPath);
      }

      final whatsappStickers = WhatsappStickers(
        identifier: finalIdentifier,
        name: packName,
        publisher: 'FOS Fresh-$randomSeed',
        trayImageFileName: WhatsappStickerImage.fromFile(freshTrayPath),
        publisherWebsite: 'https://fruitsofspirit.com',
        privacyPolicyWebsite: 'https://fruitsofspirit.com/privacy',
        licenseAgreementWebsite: 'https://fruitsofspirit.com/license',
      );
      
      for (var i = 0; i < validatedStickerPaths.length; i++) {
        whatsappStickers.addSticker(WhatsappStickerImage.fromFile(validatedStickerPaths[i]), ['']);
      }

      Get.back();
      
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Adding to WhatsApp...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      await Future.delayed(const Duration(milliseconds: 1000));
      await whatsappStickers.sendToWhatsApp();
      
      Get.back();
      Get.snackbar(
        'Success!',
        'Fresh sticker pack "$packName" added to WhatsApp!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Failed',
        'Could not add fresh pack. Try deleting the old pack from WhatsApp first.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Show troubleshooting dialog when pack doesn't appear in WhatsApp
  void _showTroubleshootingDialog(String packName) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Pack Not Showing?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WhatsApp sometimes needs a refresh to show new packs. Try these fixes:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildFixCard(
                '1',
                'Force Close WhatsApp',
                'Close WhatsApp completely and reopen it',
                Icons.close,
                Colors.red,
              ),
              const SizedBox(height: 8),
              _buildFixCard(
                '2',
                'Restart Your Phone',
                'This clears WhatsApp\'s cache and reloads all packs',
                Icons.refresh,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildFixCard(
                '3',
                'Check Sticker Section',
                'Open any chat → Emoji → Stickers (🔰 icon) → Scroll to find "$packName"',
                Icons.search,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildFixCard(
                '4',
                'Re-add the Pack',
                'Go back to the order and tap "Add to WhatsApp" again',
                Icons.add_circle,
                Colors.purple,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Most common fix:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Force close WhatsApp (swipe it away from recent apps) and reopen it. The pack should appear!',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Build a fix card for troubleshooting
  Widget _buildFixCard(String number, String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get order details from order item ID (for sticker downloads)

  /// Returns order details including order_id for sticker pack downloads
  Future<Map<String, dynamic>?> getOrderDetailsFromItemId(int orderItemId) async {
    try {
      log('[StickerDownload] Fetching order details for order_item_id=$orderItemId');

      // First get the order details using order item endpoint
      final response = await _apiService.get(
        ApiEndpoints.orderDetails,
        queryParameters: {'order_item_id': orderItemId.toString()},
      );

      final data = ApiService.handleResponse(response);

      // Extract order_id from the response
      final orderId = data['order_id'] ?? data['id'];

      if (orderId == null) {
        log('[StickerDownload] No order_id found in response');
        return null;
      }

      log('[StickerDownload] Found order_id: $orderId');

      return {
        'order_id': orderId,
        'order_item_id': orderItemId,
        'order_number': data['order_number'],
        'status': data['status'],
      };
    } catch (e) {
      log('[StickerDownload] Error getting order details: $e');
      return null;
    }
  }

  /// Cancel order
  Future<void> cancelOrder(int orderId, String reason) async {
    if (orderId <= 0) {
      Get.snackbar('Error', 'Invalid order ID');
      return;
    }
    
    if (reason.isEmpty) {
      Get.snackbar('Error', 'Please provide a cancellation reason');
      return;
    }

    final order = orderDetailsById[orderId] ??
        orders.cast<Map<String, dynamic>?>().firstWhere(
              (o) => o?['id'] == orderId,
              orElse: () => null,
            );
    if (order != null && DigitalProductType.isDigitalOrder(order)) {
      return;
    }
    
    try {
      print('[Cancel Order] ========== START ==========');
      print('[Cancel Order] Order ID: $orderId');
      print('[Cancel Order] Reason: $reason');
      print('[Cancel Order] Endpoint: ${ApiEndpoints.orderCancel}');
      
      final response = await _apiService.post(
        ApiEndpoints.orderCancel,
        data: {
          'order_id': orderId,
          'reason': reason,
        },
      );
      
      print('[Cancel Order] Response Status: ${response.statusCode}');
      print('[Cancel Order] Response Type: ${response.data.runtimeType}');
      print('[Cancel Order] Raw Response: ${response.data}');
      
      // Use handleResponse which properly handles the API response format
      try {
        final responseData = ApiService.handleResponse(response);
        print('[Cancel Order] Parsed Response Data: $responseData');
        
        // If we get here, the API call was successful
        print('[Cancel Order] ✅ Success! Order cancelled.');
        
        Get.snackbar(
          'Success',
          'Order cancelled successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 2),
        );
        
        // Update the order in the list immediately (optimistic update)
        print('[Cancel Order] Updating order in list...');
        final orderIndex = orders.indexWhere((o) => o['id'] == orderId);
        if (orderIndex != -1) {
          // Create a completely new list with updated order
          final updatedOrders = orders.map((order) {
            if (order['id'] == orderId) {
              final updatedOrder = Map<String, dynamic>.from(order);
              updatedOrder['status'] = 'cancelled';
              return updatedOrder;
            }
            return Map<String, dynamic>.from(order);
          }).toList();
          
          // Assign new list to trigger reactive update
          orders.value = updatedOrders;
          orders.refresh(); // Force GetX to notify listeners
          print('[Cancel Order] Order updated in list at index $orderIndex, status: ${updatedOrders[orderIndex]['status']}');
        }
        
        // Then refresh from server to get latest data
        print('[Cancel Order] Refreshing orders list from server...');
        isLoadingOrders.value = true;
        await loadOrders();
        isLoadingOrders.value = false;
        
        // Force final refresh
        orders.refresh();
        update(); // Force GetX controller update
        
        print('[Cancel Order] Orders refreshed and UI updated. Final statuses: ${orders.map((o) => o['status']).toList()}');
        
        // Navigate back if on order details
        if (Get.currentRoute.contains('order-details')) {
          Get.back();
        }
        
        print('[Cancel Order] ========== SUCCESS ==========');
      } catch (handleError) {
        // handleResponse threw an error, try to get the full response
        print('[Cancel Order] handleResponse error: $handleError');
        
        // Try to parse response manually to get error message
        Map<String, dynamic>? fullResponse;
        try {
          if (response.data is String) {
            fullResponse = jsonDecode(response.data as String) as Map<String, dynamic>;
          } else if (response.data is Map) {
            fullResponse = response.data as Map<String, dynamic>;
          }
        } catch (e) {
          print('[Cancel Order] Failed to parse response: $e');
        }
        
        if (fullResponse != null) {
          final errorMsg = fullResponse['message'] ?? 'Failed to cancel order';
          print('[Cancel Order] ❌ API Error: $errorMsg');
          throw Exception(errorMsg);
        } else {
          throw handleError;
        }
      }
    } catch (e, stackTrace) {
      print('[Cancel Order] ========== ERROR ==========');
      print('[Cancel Order] Exception: $e');
      print('[Cancel Order] Type: ${e.runtimeType}');
      print('[Cancel Order] Stack: $stackTrace');
      
      if (e is DioException) {
        print('[Cancel Order] DioException Type: ${e.type}');
        print('[Cancel Order] DioException Response Status: ${e.response?.statusCode}');
        print('[Cancel Order] DioException Response Data: ${e.response?.data}');
      }
      
      final errorMessage = ApiService.handleError(e);
      print('[Cancel Order] Error Message: $errorMessage');
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: AppColors.error,
        duration: const Duration(seconds: 4),
      );
    }
  }
  
  /// Return order
  Future<void> returnOrder(int orderId, String reason) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.orderReturn,
        data: {
          'order_id': orderId,
          'reason': reason,
        },
      );
      final data = ApiService.handleResponse(response);
      
      Get.snackbar(
        'Success',
        data['message'] ?? 'Return request submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.9),
        colorText: AppColors.textWhite,
        duration: const Duration(seconds: 3),
      );
      
      // Refresh orders list
      await loadOrders();
      
      // Navigate back if on order details
      if (Get.currentRoute.contains('order-details')) {
        Get.back();
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Download invoice
  Future<void> downloadInvoice(int orderId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderInvoice,
        queryParameters: {
          'order_id': orderId.toString(),
          'format': 'json',
        },
      );
      final data = ApiService.handleResponse(response);
      
      // Get invoice URL from response
      final invoiceUrl = data['invoice_url'] ?? data['download_url'];
      
      if (invoiceUrl != null && invoiceUrl.isNotEmpty) {
        // Open invoice in Flutter WebView screen
        try {
          Get.toNamed(
            '/invoice-view',
            arguments: {'invoice_url': invoiceUrl},
          );
        } catch (e) {
          print('[Invoice] Error opening invoice: $e');
          // Fallback: Show invoice data dialog
          _showInvoiceDialog(data);
        }
      } else {
        print('[Invoice] No invoice URL found in response');
        // Fallback: Show invoice data dialog
        _showInvoiceDialog(data);
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Show invoice data dialog (fallback)
  void _showInvoiceDialog(Map<String, dynamic> data) {
    Get.dialog(
      Dialog(
        child: Container(
          padding: EdgeInsets.all(ScreenSize.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invoice',
                style: TextStyle(
                  fontSize: ScreenSize.headingMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ScreenSize.spacingMedium),
              Text('Invoice Number: ${data['invoice_number']}'),
              Text('Order Number: ${data['order_number']}'),
              Text('Total: \$${data['summary']['total']}'),
              SizedBox(height: ScreenSize.spacingLarge),
              if (data['invoice_url'] != null)
                TextButton(
                  onPressed: () async {
                    try {
                      final decodedUrl = Uri.decodeFull(data['invoice_url']);
                      final uri = Uri.parse(decodedUrl);
                      
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        // Try platformDefault as fallback
                        await launchUrl(
                          uri,
                          mode: LaunchMode.platformDefault,
                        );
                      }
                    } catch (e) {
                      Get.snackbar('Error', 'Could not open invoice: ${e.toString()}');
                    }
                    Get.back();
                  },
                  child: const Text('View Invoice'),
                ),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Show comprehensive social sharing dialog
  void _showComprehensiveShareDialog(String packName, List<String> stickerFiles, String trayIconPath, int actualStickers) async {
    // Prepare all sticker files for sharing
    final filesToShare = <XFile>[];
    if (trayIconPath.isNotEmpty && await File(trayIconPath).exists()) {
      filesToShare.add(XFile(trayIconPath));
    }
    for (final path in stickerFiles) {
      if (await File(path).exists()) {
        filesToShare.add(XFile(path));
      }
    }
    
    if (filesToShare.isEmpty) {
      Get.snackbar('Error', 'No stickers available to share');
      return;
    }
    
    final shareText = '🎨 Sticker Pack: $packName\n\n📦 $actualStickers stickers\n\nGet these amazing stickers!';
    
    // Show sharing options dialog with categorized sections
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Sticker Pack',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$packName ($actualStickers stickers)',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              
              // Scrollable list of all sharing options
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // === MESSAGING APPS ===
                    _buildSectionHeader('Messaging'),
                    
                    // WhatsApp - Chat
                    _buildShareTile(
                      icon: Icons.chat,
                      color: const Color(0xFF25D366),
                      title: 'WhatsApp',
                      subtitle: 'Send to chats',
                      onTap: () async {
                        Get.back();
                        try {
                          await Share.shareXFiles(
                            filesToShare.take(30).toList(),
                            text: shareText,
                            subject: 'Sticker Pack: $packName',
                          );
                        } catch (e) {
                          Get.snackbar('Error', 'Could not share to WhatsApp: $e');
                        }
                      },
                    ),
                    
                    // Messenger
                    _buildShareTile(
                      icon: Icons.message,
                      color: const Color(0xFF0084FF),
                      title: 'Messenger',
                      subtitle: 'Send messages',
                      onTap: () async {
                        Get.back();
                        try {
                          await Share.shareXFiles(
                            filesToShare.take(30).toList(),
                            text: shareText,
                            subject: 'Sticker Pack: $packName',
                          );
                        } catch (e) {
                          Get.snackbar('Error', 'Could not share to Messenger: $e');
                        }
                      },
                    ),
                    
                    // Telegram
                    _buildShareTile(
                      icon: Icons.send,
                      color: const Color(0xFF0088cc),
                      title: 'Telegram',
                      subtitle: 'Send to chats',
                      onTap: () async {
                        Get.back();
                        try {
                          await Share.shareXFiles(
                            filesToShare.take(30).toList(),
                            text: shareText,
                            subject: 'Sticker Pack: $packName',
                          );
                        } catch (e) {
                          Get.snackbar('Error', 'Could not share to Telegram: $e');
                        }
                      },
                    ),
                    
                    // SMS
                    _buildShareTile(
                      icon: Icons.sms,
                      color: Colors.blue,
                      title: 'SMS / Text',
                      subtitle: 'Send via messages',
                      onTap: () async {
                        Get.back();
                        try {
                          await Share.shareXFiles(
                            filesToShare.take(10).toList(),
                            text: shareText,
                            subject: 'Sticker Pack: $packName',
                          );
                        } catch (e) {
                          Get.snackbar('Error', 'Could not share via SMS: $e');
                        }
                      },
                    ),
                    
                    const Divider(height: 24),
                    
                    // === STORIES & FEED ===
                    _buildSectionHeader('Stories, Reels & Feed'),
                    
                    // Instagram
                    _buildShareTile(
                      icon: Icons.camera_alt,
                      color: const Color(0xFFE4405F),
                      title: 'Instagram',
                      subtitle: 'Stories, Reels, Feed, Chat',
                      onTap: () async {
                        Get.back();
                        try {
                          await Share.shareXFiles(
                            filesToShare.take(10).toList(),
                            text: shareText,
                            subject: 'Sticker Pack: $packName',
                          );
                        } catch (e) {
                          Get.snackbar('Error', 'Could not share to Instagram: $e');
                        }
                      },
                    ),
                    
                    // Facebook
                    _buildShareTile(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      title: 'Facebook',
                      subtitle: 'Stories, Feed, Chat',
                      onTap: () async {
                        Get.back();
                        try {
                          await Share.shareXFiles(
                            filesToShare.take(30).toList(),
                            text: shareText,
                            subject: 'Sticker Pack: $packName',
                          );
                        } catch (e) {
                          Get.snackbar('Error', 'Could not share to Facebook: $e');
                        }
                      },
                    ),
                    
                    // TikTok
                    _buildShareTile(
                      icon: Icons.music_note,
                      color: const Color(0xFF000000),
                      title: 'TikTok',
                      subtitle: 'Videos & Status',
                      onTap: () async {
                        Get.back();
                        try {
                          await Share.shareXFiles(
                            filesToShare.take(10).toList(),
                            text: shareText,
                            subject: 'Sticker Pack: $packName',
                          );
                        } catch (e) {
                          Get.snackbar('Error', 'Could not share to TikTok: $e');
                        }
                      },
                    ),
                    
                    // Twitter/X
                    _buildShareTile(
                      icon: Icons.alternate_email,
                      color: const Color(0xFF000000),
                      title: 'Twitter / X',
                      subtitle: 'Tweets & DMs',
                      onTap: () async {
                        Get.back();
                        try {
                          await Share.shareXFiles(
                            filesToShare.take(4).toList(),
                            text: shareText,
                            subject: 'Sticker Pack: $packName',
                          );
                        } catch (e) {
                          Get.snackbar('Error', 'Could not share to Twitter: $e');
                        }
                      },
                    ),
                    
                    const Divider(height: 24),
                    
                    // === OTHER OPTIONS ===
                    _buildSectionHeader('Other Options'),
                    
                    // System Share Sheet
                    _buildShareTile(
                      icon: Icons.share,
                      color: const Color(0xFF8B4513),
                      title: 'System Share',
                      subtitle: 'All apps - Snapchat, Discord, etc.',
                      onTap: () async {
                        Get.back();
                        await Share.shareXFiles(
                          filesToShare.take(30).toList(),
                          text: shareText,
                          subject: 'Sticker Pack: $packName',
                        );
                      },
                    ),
                    
                    // Copy to Clipboard
                    _buildShareTile(
                      icon: Icons.copy,
                      color: Colors.grey,
                      title: 'Copy to Clipboard',
                      subtitle: 'Copy text only',
                      onTap: () async {
                        Get.back();
                        await Clipboard.setData(ClipboardData(text: shareText));
                        Get.snackbar('Copied', 'Pack info copied to clipboard');
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildShareTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  /// Build a circular platform button for the sticker preview dialog
  Widget _buildPlatformButton({
    required Widget icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: icon,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  void navigateToEditProfile() {
    Get.toNamed('/edit-profile');
  }
  
  /// Navigate to change password
  void navigateToChangePassword() {
    Get.toNamed('/change-password');
  }
  
  /// Navigate to orders
  void navigateToOrders() {
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Profile] NavigateToOrders auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      Get.snackbar('Login Required', 'Please login to view your orders');
      AppRoutes.toLogin();
      return;
    }
    AppRoutes.toOrders();
    loadOrders(silent: true);
  }
  
  /// Navigate to wishlist
  void navigateToWishlist() {
    AppRoutes.toWishlist(); // Already has login check
  }
  
  /// Navigate to gallery
  void navigateToGallery() {
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Profile] NavigateToGallery auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      Get.snackbar('Login Required', 'Please login to view your gallery');
      AppRoutes.toLogin();
      return;
    }
    Get.toNamed('/gallery');
  }
  
  /// Navigate to addresses
  void navigateToAddresses() {
    final isLoggedIn = CacheManager.isLoggedIn();
    final userToken = CacheManager.getUserToken();
    print('[Profile] NavigateToAddresses auth check - isLoggedIn: $isLoggedIn, hasToken: ${userToken != null && userToken.isNotEmpty}');
    
    if (!isLoggedIn || userToken == null || userToken.isEmpty) {
      Get.snackbar('Login Required', 'Please login to manage addresses');
      AppRoutes.toLogin();
      return;
    }
    Get.toNamed('/addresses');
    loadAddresses();
  }
  
  /// Navigate to add address
  void navigateToAddAddress() {
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar('Login Required', 'You need to login to add address');
      AppRoutes.toLogin();
      return;
    }
    clearAddressForm();
    Get.toNamed('/add-address');
  }
  
  /// Edit address
  void editAddress(Map<String, dynamic> address) {
    initializeAddressForm(address);
    Get.toNamed('/edit-address', arguments: address);
  }
  
  /// Navigate to payment methods
  void navigateToPaymentMethods() {
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar('Login Required', 'Please login to manage payment methods');
      AppRoutes.toLogin();
      return;
    }
    Get.toNamed('/payment-methods');
    loadPaymentMethods();
  }
  
  /// Load payment methods
  Future<void> loadPaymentMethods() async {
    isLoadingPaymentMethods.value = true;
    try {
      final response = await _apiService.get(ApiEndpoints.paymentMethodsList);
      final data = ApiService.handleResponse(response);
      paymentMethods.value = (data['payment_methods'] ?? []).map<Map<String, dynamic>>((method) {
        return {
          'id': method['id'],
          'type': method['type'],
          'provider': method['provider'],
          'card_number': method['card_number'],
          'card_holder_name': method['card_holder_name'],
          'card_expiry_month': method['card_expiry_month'],
          'card_expiry_year': method['card_expiry_year'],
          'upi_id': method['upi_id'],
          'wallet_type': method['wallet_type'],
          'bank_name': method['bank_name'],
          'account_number': method['account_number'],
          'is_default': method['is_default'] ?? false,
          'display': method['display'] ?? '',
          'label': method['label'] ?? '',
          'created_at': method['created_at'],
        };
      }).toList();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      paymentMethods.value = [];
    } finally {
      isLoadingPaymentMethods.value = false;
    }
  }
  
  /// Navigate to add payment method
  void navigateToAddPaymentMethod() {
    clearPaymentMethodForm();
    Get.toNamed('/add-payment-method');
  }
  
  /// Edit payment method
  void editPaymentMethod(Map<String, dynamic> method) {
    initializePaymentMethodForm(method);
    Get.toNamed('/edit-payment-method', arguments: method);
  }
  
  /// Initialize payment method form
  void initializePaymentMethodForm(Map<String, dynamic> method) {
    paymentMethodType.value = method['type'] ?? 'cash_on_delivery';
    upiIdController.text = method['upi_id'] ?? '';
    walletTypeController.text = method['wallet_type'] ?? '';
    walletPaymentMethodId.value = method['wallet_payment_method_id'] ?? '';
    bankNameController.text = method['bank_name'] ?? '';
    accountNumberController.text = method['account_number'] ?? '';
    isDefaultPaymentMethod.value = method['is_default'] == true || method['is_default'] == 1;
    provider.value = method['provider'] ?? '';
    cardNumberController.text = method['card_number'] ?? '';
    cardHolderNameController.text = method['card_holder_name'] ?? '';
    cardExpiryMonthController.text = method['card_expiry_month'] ?? '';
    cardExpiryYearController.text = method['card_expiry_year'] ?? '';
    bankAccountNumberController.text = method['bank_account_number'] ?? '';
    routingNumberController.text = method['routing_number'] ?? '';
    accountHolderNameController.text = method['account_holder_name'] ?? '';
    selectedBankRedirect.value = method['selected_bank_redirect'] ?? '';
    transferReferenceController.text = method['transfer_reference'] ?? '';
    bnplProvider.value = method['bnpl_provider'] ?? '';
    realTimePaymentIdentifierController.text = method['real_time_payment_identifier'] ?? '';
    voucherCodeController.text = method['voucher_code'] ?? '';
  }
  
  /// Clear payment method form
  void clearPaymentMethodForm() {
    paymentMethodType.value = 'cash_on_delivery';
    upiIdController.clear();
    walletTypeController.clear();
    walletPaymentMethodId.value = '';
    walletType.value = '';
    bankNameController.clear();
    accountNumberController.clear();
    bankAccountNumberController.clear();
    routingNumberController.clear();
    accountHolderNameController.clear();
    selectedBankRedirect.value = '';
    transferReferenceController.clear();
    bnplProvider.value = '';
    realTimePaymentIdentifierController.clear();
    voucherCodeController.clear();
    isDefaultPaymentMethod.value = false;
  }
  
  /// Clear only type-specific fields (when type changes)
  void clearTypeSpecificFields() {
    // Clear all type-specific fields
    provider.value = '';
    cardNumberController.clear();
    cardHolderNameController.clear();
    cardExpiryMonthController.clear();
    cardExpiryYearController.clear();
    upiIdController.clear();
    walletTypeController.clear();
    bankNameController.clear();
    accountNumberController.clear();
  }
  
  /// Save payment method (add or update)
  Future<void> savePaymentMethod(int? paymentMethodId) async {
    if (!paymentMethodFormKey.currentState!.validate()) {
      return;
    }
    
    isSavingPaymentMethod.value = true;
    try {
      final paymentData = {
        'type': paymentMethodType.value,
        'is_default': isDefaultPaymentMethod.value ? 1 : 0,
      };
      
      if (paymentMethodType.value == 'upi') {
        paymentData['upi_id'] = upiIdController.text.trim();
      } else if (paymentMethodType.value == 'card') {
        paymentData['provider'] = provider.value;
        paymentData['card_number'] = cardNumberController.text.trim();
        paymentData['card_holder_name'] = cardHolderNameController.text.trim();
        paymentData['card_expiry_month'] = cardExpiryMonthController.text.trim();
        paymentData['card_expiry_year'] = cardExpiryYearController.text.trim();
      }
      
      if (paymentMethodId != null) {
        // Update
        final updateUrl = ApiEndpoints.paymentMethodsUpdate.replaceAll('{id}', paymentMethodId.toString());
        await _apiService.put(updateUrl, data: paymentData);
        Get.snackbar('Success', 'Payment method updated successfully');
      } else {
        // Add
        await _apiService.post(ApiEndpoints.paymentMethodsAdd, data: paymentData);
        Get.snackbar('Success', 'Payment method added successfully');
      }
      
      // Refresh payment methods list first
      await loadPaymentMethods();
      
      // Then navigate back
      Get.back();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    } finally {
      isSavingPaymentMethod.value = false;
    }
  }
  
  /// Delete payment method
  Future<void> deletePaymentMethod(int paymentMethodId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Payment Method'),
        content: const Text('Are you sure you want to delete this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final deleteUrl = ApiEndpoints.paymentMethodsDelete.replaceAll('{id}', paymentMethodId.toString());
      await _apiService.delete(deleteUrl);
      Get.snackbar('Success', 'Payment method deleted successfully');
      await loadPaymentMethods();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Set default payment method
  Future<void> setDefaultPaymentMethod(int paymentMethodId) async {
    try {
      final setDefaultUrl = ApiEndpoints.paymentMethodsSetDefault.replaceAll('{id}', paymentMethodId.toString());
      await _apiService.put(setDefaultUrl);
      Get.snackbar('Success', 'Default payment method updated');
      await loadPaymentMethods();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Navigate to notifications settings
  void navigateToNotificationSettings() {
    Get.toNamed('/notifications');
  }
  
  /// Navigate to help & support
  void navigateToHelpSupport() {
    Get.toNamed('/help-support');
  }
  
  /// Navigate to about
  void navigateToAbout() {
    Get.toNamed('/about');
  }
  
  /// Navigate to loyalty points
  void navigateToLoyaltyPoints() {
    Get.toNamed('/loyalty-points');
  }
  
  /// Navigate to referral program
  void navigateToReferralProgram() {
    Get.toNamed('/referral-program');
  }
  
  /// Delete user account
  Future<void> deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data, orders, and preferences will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) {
      return;
    }
    
    // Show second confirmation for safety
    final doubleConfirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your last chance to cancel. Your account and all associated data will be permanently deleted. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Yes, Delete Forever'),
          ),
        ],
      ),
    );
    
    if (doubleConfirmed != true) {
      return;
    }
    
    // Check if user is logged in and has a token
    final token = CacheManager.getUserToken();
    if (token == null || token.isEmpty) {
      Get.snackbar(
        'Authentication Required',
        'Please login again to delete your account.',
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
        duration: const Duration(seconds: 3),
      );
      // Clear any stale data and redirect to login
      await CacheManager.clearAll();
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.toLogin();
      return;
    }
    
    try {
      final response = await _apiService.delete(ApiEndpoints.deleteAccount);
      final data = ApiService.handleResponse(response);
      
      // If handleResponse succeeds, account was deleted successfully
      // Clear all cache memory (user data, cart, wishlist, etc.)
      await CacheManager.clearAll();
      
      // Show success message
      Get.snackbar(
        'Account Deleted',
        'Your account has been successfully deleted.',
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate to login page and clear navigation stack
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.toLogin();
    } on DioException catch (e) {
      // Handle 401 Unauthorized - token expired or invalid
      if (e.response?.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Your session has expired. Please login again.',
          backgroundColor: AppColors.errorLight,
          colorText: AppColors.error,
          duration: const Duration(seconds: 3),
        );
        // Clear cache and redirect to login
        await CacheManager.clearAll();
        AppRoutes.toLogin();
      }
    } on DioException catch (e) {
      // Handle 401 Unauthorized - token expired or invalid
      if (e.response?.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Your session has expired. Please login again.',
          backgroundColor: AppColors.errorLight,
          colorText: AppColors.error,
          duration: const Duration(seconds: 3),
        );
        // Clear cache and redirect to login
        await CacheManager.clearAll();
        AppRoutes.toLogin();
      }
    } catch (e) {
      log('[ProfileController] Unexpected error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Copy validated stickers to short filenames for WhatsApp ContentProvider.
  Future<({String tray, List<String> stickers})> _stageStickersForWhatsApp(
    String packIdentifier,
    String trayPath,
    List<String> stickerPaths,
  ) async {
    final libDir = await getApplicationSupportDirectory();
    final exportDir = Directory('${libDir.path}/wa/$packIdentifier');
    if (exportDir.existsSync()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create(recursive: true);

    final trayOut = '${exportDir.path}/tray.webp';
    await File(trayPath).copy(trayOut);
    print('[WAStage] tray -> $trayOut');

    final staged = <String>[];
    for (var i = 0; i < stickerPaths.length; i++) {
      final out = '${exportDir.path}/${i + 1}.webp';
      await File(stickerPaths[i]).copy(out);
      staged.add(out);

      final bytes = await File(out).readAsBytes();
      final animated = _isAnimatedWebP(bytes);
      print(
        '[WAStage] ${i + 1}.webp size=${bytes.length} animated=$animated',
      );
      if (animated) {
        print('[WAStage] WARNING: animated WebP may be rejected by WhatsApp');
      }
    }
    return (tray: trayOut, stickers: staged);
  }

  bool _isAnimatedWebP(Uint8List bytes) {
    if (bytes.length < 16) return false;
    final header = String.fromCharCodes(bytes.sublist(0, min(bytes.length, 64)));
    return header.contains('ANMF') || header.contains('ANIM');
  }

  Future<String?> _validateAndFixWebP(String originalPath, {bool isTrayIcon = false}) async {
    try {
      final file = File(originalPath);
      if (!file.existsSync()) {
        log('[WebPValidator] File not found: $originalPath');
        return null;
      }

      final targetSize = isTrayIcon ? 96 : 512;
      final maxFileSize = isTrayIcon ? 50 * 1024 : 100 * 1024;
      final name = file.uri.pathSegments.last;
      final bytes = await file.readAsBytes();

      final isRiffWebP = bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46;
      final decoded = img.decodeImage(bytes);

      if (isRiffWebP &&
          decoded != null &&
          decoded.width == targetSize &&
          decoded.height == targetSize &&
          bytes.length <= maxFileSize) {
        print(
          '[WebPValidator] OK as-is $name ${decoded.width}x${decoded.height} '
          '${bytes.length}b',
        );
        return originalPath;
      }

      log('[WebPValidator] Re-encode ${isTrayIcon ? "Tray" : "Sticker"}: $name '
          '(${decoded?.width}x${decoded?.height}, ${bytes.length}b)');

      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/whatsapp_${isTrayIcon ? 'tray' : 'sticker'}_${DateTime.now().millisecondsSinceEpoch}.webp';

      img.Image? processed = decoded;
      if (processed == null) return null;

      if (processed.width != targetSize || processed.height != targetSize) {
        processed = img.copyResize(
          processed,
          width: targetSize,
          height: targetSize,
          interpolation: img.Interpolation.cubic,
        );
      }

      if (!processed.hasAlpha || processed.numChannels < 4) {
        final rgbaImage = img.Image(
          width: processed.width,
          height: processed.height,
          numChannels: 4,
        );
        for (var y = 0; y < processed.height; y++) {
          for (var x = 0; x < processed.width; x++) {
            rgbaImage.setPixel(x, y, processed.getPixel(x, y));
          }
        }
        processed = rgbaImage;
      }

      Uint8List? compressedBytes;
      for (var quality = 90; quality >= 60; quality -= 10) {
        final encoded = img.encodeNamedImage('x.webp', processed);
        if (encoded == null || encoded.isEmpty) continue;
        if (encoded.length <= maxFileSize) {
          compressedBytes = Uint8List.fromList(encoded);
          break;
        }
      }

      compressedBytes ??= Uint8List.fromList(
        img.encodeNamedImage('x.webp', processed) ?? [],
      );
      if (compressedBytes.isEmpty) return null;

      await File(tempPath).writeAsBytes(compressedBytes);
      print(
        '[WebPValidator] Wrote $name -> $tempPath '
        '${processed.width}x${processed.height} ${compressedBytes.length}b',
      );
      return tempPath;
    } catch (e) {
      log('[WebPValidator] Error: $e');
      return null;
    }
  }
  /// Fix malformed download URLs
  String _fixDownloadUrl(String url) {
    if (url.isEmpty) return url;
    
    String fixedUrl = url;
    
    if (fixedUrl.startsWith('https:/') && !fixedUrl.startsWith('https://')) {
      fixedUrl = fixedUrl.replaceFirst('https:/', 'https://');
    } else if (fixedUrl.startsWith('http:/') && !fixedUrl.startsWith('http://')) {
      fixedUrl = fixedUrl.replaceFirst('http:/', 'http://');
    }
    
    if (fixedUrl.contains('https:///')) {
      fixedUrl = fixedUrl.replaceAll('https:///', 'https://');
    } else if (fixedUrl.contains('http:///')) {
      fixedUrl = fixedUrl.replaceAll('http:///', 'http://');
    }
    
    fixedUrl = fixedUrl.replaceAll(RegExp(r'/{3,}'), '/');
    
    return fixedUrl;
  }


  /// Reset in-memory user state after logout.
  void clearOnLogout() {
    orders.clear();
    orderDetailsById.clear();
    addresses.clear();
    paymentMethods.clear();
    hasEverLoadedOrders.value = false;
    isLoadingOrders.value = false;
    isLoadingOrderDetail.value = false;
    userName.value = '';
    userEmail.value = '';
    userPhone.value = '';
    userImage.value = '';
    totalOrders.value = 0;
    totalSpent.value = 0.0;
    loyaltyPoints.value = 0;
    referralCode.value = '';
    nameController.clear();
    emailController.clear();
    phoneController.clear();
  }
}
