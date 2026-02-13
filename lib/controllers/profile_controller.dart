import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'checkout_controller.dart';
import 'dart:async';
import 'dart:convert';
import '../utils/cache_manager.dart';
import '../utils/app_colors.dart';
import '../utils/screen_size.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/location_service.dart';
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
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  
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
    // Only load profile if user is logged in and data is not already loaded
    if (CacheManager.isLoggedIn() && userName.value.isEmpty) {
      loadUserProfile();
    } else {
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
  
  /// Load user profile data
  Future<void> loadUserProfile() async {
    isLoading.value = true;
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
    } catch (e) {
      // If API fails, load from cache
      userName.value = CacheManager.getUserName() ?? 'User';
      userEmail.value = CacheManager.getUserEmail() ?? '';
      userPhone.value = CacheManager.getUserPhone() ?? '';
      nameController.text = userName.value;
      emailController.text = userEmail.value;
      phoneController.text = userPhone.value;
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
      
      Get.snackbar('Success', 'Profile updated successfully');
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
      Get.snackbar('Error', 'Passwords do not match');
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
      
      Get.snackbar('Success', 'Password changed successfully');
      Get.back();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    } finally {
      isChangingPassword.value = false;
    }
  }
  
  /// Load orders
  Future<void> loadOrders() async {
    print('[ProfileController] loadOrders() called');
    isLoadingOrders.value = true;
    try {
      final response = await _apiService.get(ApiEndpoints.ordersList);
      print('[ProfileController] API response received');
      final data = ApiService.handleResponse(response);
      print('[ProfileController] Parsed data, orders count: ${(data['orders'] ?? []).length}');
      final formattedOrders = (data['orders'] ?? []).map<Map<String, dynamic>>((order) {
        // Ensure id is an int
        final orderId = order['id'] is int 
            ? order['id'] 
            : (order['id'] is String 
                ? int.tryParse(order['id']) 
                : int.tryParse(order['id']?.toString() ?? '0')) ?? 0;
        
        // Ensure status is lowercase for consistent comparison
        final orderStatus = (order['status'] ?? 'pending').toString().toLowerCase();
        
        return {
          'id': orderId,
          'order_number': order['order_number'] ?? orderId.toString(),
          'status': orderStatus,
          'total_amount': double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0,
          'created_at': order['created_at'] ?? '',
          'items': order['items'] ?? [],
          'payment_status': order['payment_status'] ?? 'pending', // Add payment_status
        };
      }).toList();
      
      // Update orders list
      orders.assignAll(formattedOrders);
      print('[Load Orders] Loaded ${orders.length} orders, statuses: ${orders.map((o) => o['status']).toList()}');
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      orders.value = [];
    } finally {
      isLoadingOrders.value = false;
    }
  }
  
  /// Load addresses
  Future<void> loadAddresses() async {
    isLoadingAddresses.value = true;
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
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      addresses.value = [];
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
  
  /// Detect current location
  Future<void> detectCurrentLocation() async {
    final locationService = LocationService();
    
    // 1. Request Permission first
    final permission = await locationService.requestLocationPermission();
    
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      // Go back to previous page as requested if permission failed
      Future.delayed(const Duration(seconds: 2), () {
        if (Get.currentRoute.contains('add-edit-address')) {
          Get.back();
        }
      });
      return;
    }

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    try {
      // Get current location with a timeout
      final locationData = await locationService.getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (Get.isDialogOpen!) Get.back(); // Close loading dialog
          Get.snackbar(
            'Location Timeout',
            'Could not get location in time. Please check your GPS and try again.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return null; // Return null on timeout
        },
      );
      
      if (Get.isDialogOpen!) {
        Get.back(); // Close loading dialog if still open
      }
      
      if (locationData != null) {
        // Fill form with location data
        addressLine1Controller.text = locationData['address_line1'] ?? '';
        addressLine2Controller.text = locationData['address_line2'] ?? '';
        addressCityController.text = locationData['city'] ?? '';
        addressStateController.text = locationData['state'] ?? '';
        addressPincodeController.text = locationData['pincode'] ?? '';
        
        Get.snackbar(
          'Success',
          'Location detected! Please verify your address.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        // Handle other cases where locationData is null
        Get.snackbar(
          'Location Unavailable',
          'Could not detect location. Please enter address manually.',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        // Go back if location detection failed
        Future.delayed(const Duration(seconds: 2), () {
          if (Get.currentRoute.contains('add-edit-address')) {
            Get.back();
          }
        });
      }
    } catch (e) {
      if (Get.isDialogOpen!) {
        Get.back(); // Close dialog on error
      }
      if (e is! TimeoutException) {
        Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}');
      }
      
      // Go back on error
      Future.delayed(const Duration(seconds: 2), () {
        if (Get.currentRoute.contains('add-edit-address')) {
          Get.back();
        }
      });
    }
  }
  
  /// Save address (add or update)
  Future<void> saveAddress(int? addressId) async {
    if (!addressFormKey.currentState!.validate()) {
      return;
    }
    
    isSavingAddress.value = true;
    try {
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
      
      if (addressId != null) {
        // Update existing address
        final updateUrl = ApiEndpoints.addressesUpdate.replaceAll('{id}', addressId.toString());
        await _apiService.put(updateUrl, data: addressData);
        Get.snackbar('Success', 'Address updated successfully');
      } else {
        // Add new address
        await _apiService.post(ApiEndpoints.addressesAdd, data: addressData);
        Get.snackbar('Success', 'Address added successfully');
      }
      
      clearAddressForm();
      await loadAddresses();
      
      // Refresh checkout summary if we are coming from checkout
      try {
        if (Get.isRegistered<CheckoutController>()) {
          Get.find<CheckoutController>().loadCheckoutSummary();
        }
      } catch (e) {
        print('Error refreshing checkout: $e');
      }

      Get.back();
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    } finally {
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
  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    print('[ProfileController] getOrderDetails() called with orderId: $orderId');
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderDetails,
        queryParameters: {'id': orderId.toString()},
      );
      print('[ProfileController] API response received, status: ${response.statusCode}');
      print('[ProfileController] Response data type: ${response.data.runtimeType}');
      
      final data = ApiService.handleResponse(response);
      print('[ProfileController] Parsed data keys: ${data.keys.toList()}');
      print('[ProfileController] Order ID in data: ${data['id']}');
      print('[ProfileController] Items count: ${(data['items'] as List?)?.length ?? 0}');
      
      return data;
    } catch (e) {
      print('[ProfileController] Error in getOrderDetails: $e');
      print('[ProfileController] Error type: ${e.runtimeType}');
      ApiService.showErrorSnackbar(e);
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
  
  /// Navigate to edit profile
  void navigateToEditProfile() {
    Get.toNamed('/edit-profile');
  }
  
  /// Navigate to change password
  void navigateToChangePassword() {
    Get.toNamed('/change-password');
  }
  
  /// Navigate to orders
  void navigateToOrders() {
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar('Login Required', 'Please login to view your orders');
      AppRoutes.toLogin();
      return;
    }
    Get.toNamed('/orders');
    loadOrders();
  }
  
  /// Navigate to wishlist
  void navigateToWishlist() {
    AppRoutes.toWishlist(); // Already has login check
  }
  
  /// Navigate to addresses
  void navigateToAddresses() {
    if (!CacheManager.isLoggedIn()) {
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
      } else if (paymentMethodType.value == 'wallet') {
        paymentData['wallet_type'] = walletTypeController.text.trim();
      } else if (paymentMethodType.value == 'netbanking') {
        paymentData['bank_name'] = bankNameController.text.trim();
        paymentData['account_number'] = accountNumberController.text.trim();
      } else if (paymentMethodType.value == 'cash_on_delivery') {
        // No additional fields for Cash on Delivery
      } else if (paymentMethodType.value == 'bank_debit') {
        paymentData['bank_account_number'] = bankAccountNumberController.text.trim();
        paymentData['routing_number'] = routingNumberController.text.trim();
        paymentData['account_holder_name'] = accountHolderNameController.text.trim();
      } else if (paymentMethodType.value == 'bank_redirect') {
        paymentData['selected_bank_redirect'] = selectedBankRedirect.value;
      } else if (paymentMethodType.value == 'bank_transfer') {
        paymentData['bank_name'] = bankNameController.text.trim(); // Reusing existing
        paymentData['account_number'] = accountNumberController.text.trim(); // Reusing existing
        paymentData['transfer_reference'] = transferReferenceController.text.trim();
      } else if (paymentMethodType.value == 'buy_now_pay_later') {
        paymentData['bnpl_provider'] = bnplProvider.value;
      } else if (paymentMethodType.value == 'real_time_payment') {
        paymentData['real_time_payment_identifier'] = realTimePaymentIdentifierController.text.trim();
      } else if (paymentMethodType.value == 'voucher') {
        paymentData['voucher_code'] = voucherCodeController.text.trim();
      } else if (paymentMethodType.value == 'card') {
        paymentData['provider'] = provider.value;
        paymentData['card_number'] = cardNumberController.text.trim();
        paymentData['card_holder_name'] = cardHolderNameController.text.trim();
        paymentData['card_expiry_month'] = cardExpiryMonthController.text.trim();
          paymentData['card_expiry_year'] = cardExpiryYearController.text.trim();
        } else if (paymentMethodType.value == 'wallet') {
          paymentData['wallet_payment_method_id'] = walletPaymentMethodId.value;
          paymentData['wallet_type'] = walletType.value;
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
        await Future.delayed(const Duration(milliseconds: 500));
        AppRoutes.toLogin();
      } else {
        Get.snackbar(
          'Error',
          ApiService.handleError(e),
          backgroundColor: AppColors.errorLight,
          colorText: AppColors.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        ApiService.handleError(e),
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
      );
    }
  }
  
  /// Logout
  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await CacheManager.clearUserData();
      AppRoutes.toLogin();
    }
  }
}
