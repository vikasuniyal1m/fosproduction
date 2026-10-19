import 'dart:convert';
import 'dart:developer' as log;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../services/stripe_service.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/app_colors.dart';
import '../routes/app_routes.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/cart_controller.dart';
import '../utils/cache_manager.dart';
import '../watch_faces/controllers/watch_faces_controller.dart';
import '../utils/getx_registry.dart';
import '../views/orders/order_details_screen.dart';

/// Stripe Payment Controller
/// Manages Stripe payment flow and state
class StripePaymentController extends GetxController {
  final StripeService _stripeService = StripeService();
  final ApiService _apiService = ApiService();
  
  // Check if user is logged in
  bool get _isLoggedIn {
    final token = CacheManager.getUserToken();
    return token != null && token.isNotEmpty;
  }
  
  // Payment data
  final RxInt orderId = 0.obs; // Removed orderId
  final RxDouble amount = 0.0.obs;
  final RxString currency = 'usd'.obs;
  
  // New arguments from CheckoutController
  final RxInt paymentMethodId = 0.obs;
  final RxString couponCode = ''.obs;
  final RxString notes = ''.obs;
  final RxInt shippingAddressId = 0.obs;
  final RxBool isDigitalOrder = false.obs;
  /// When `fos_lens`, payment completes without creating an order (image export fee).
  final RxString paymentPurpose = ''.obs;
  final RxString watchFaceId = ''.obs;

  // Payment Intent
  final RxString paymentIntentId = ''.obs;
  final RxString clientSecret = ''.obs;
  final RxString publishableKey = ''.obs;
  final RxString customerId = ''.obs;
  final RxString ephemeralKeySecret = ''.obs;

  // States
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString paymentStatus = 'pending'.obs;

  /// Prevents double back (e.g. back button + leading arrow) to avoid crash or wrong stack
  bool _cancelRequested = false;

  // Card details (no longer used for manual input, but kept for potential future use with PaymentSheet)
  final RxString cardNumber = ''.obs;
  final RxInt expiryMonth = 0.obs;
  final RxInt expiryYear = 0.obs;
  final RxString cvc = ''.obs;
  final RxString cardHolderName = ''.obs;
  final RxString billingEmail = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      amount.value = (args['amount'] as num?)?.toDouble() ?? 0.0;
      orderId.value = args['order_id'] as int? ?? 0;
      currency.value = args['currency'] as String? ?? 'usd';
      paymentMethodId.value = args['payment_method_id'] as int? ?? 0;
      couponCode.value = args['coupon_code'] as String? ?? '';
      notes.value = args['notes'] as String? ?? '';
      shippingAddressId.value = args['shipping_address_id'] as int? ?? 0;
      isDigitalOrder.value = args['is_digital_order'] == true;
      paymentPurpose.value = (args['purpose'] as String?)?.trim() ?? '';
      watchFaceId.value = (args['watch_face_id'] as String?)?.trim() ?? '';
    }
    
    // Create payment intent immediately when screen loads
    _createPaymentIntent();
  }

  /// Create Payment Intent
  Future<void> _createPaymentIntent() async {
    // Removed orderId validation

    if (amount.value <= 0) {
      errorMessage.value = 'Invalid amount';
      // Get.snackbar(
      //   'Error',
      //   'Invalid payment amount. Please try again.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: AppColors.error,
      //   colorText: AppColors.textWhite,
      // );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      debugPrint('[StripePaymentController] Creating payment intent: orderId=${orderId.value}, amount=${amount.value}, currency=${currency.value}');
      final result = await _stripeService.createPaymentIntent(
        orderId: orderId.value,
        // Removed orderId parameter
        amount: amount.value,
        currency: currency.value,
      );
      
      paymentIntentId.value = result['payment_intent_id'] ?? '';
      clientSecret.value = result['client_secret'] ?? '';
      publishableKey.value = result['publishable_key'] ?? '';
      customerId.value = result['customer_id'] ?? '';
      ephemeralKeySecret.value = result['ephemeral_key_secret'] ?? '';
      
      // log('[StripePaymentController] Payment Intent ID: ${paymentIntentId.value}');
      // log('[StripePaymentController] Customer ID from backend: ${customerId.value}');
      // log('[StripePaymentController] Ephemeral Key: ${ephemeralKeySecret.value.isNotEmpty ? "Present" : "Empty"}');

      if (clientSecret.value.isEmpty) {
        throw Exception('Failed to get payment intent. Please try again.');
      }

      // Wait for Activity to be ready before initializing Stripe (fixes "initialization failed" on Android)
      await Future.delayed(const Duration(milliseconds: 300));

      // Initialize Stripe with publishable key if not already done
      if (publishableKey.value.isNotEmpty) {
        Stripe.publishableKey = publishableKey.value;
        await Stripe.instance.applySettings();
      } else {
        throw Exception('Stripe publishable key not found. Please contact support.');
      }

      // Give native plugin time to attach after applySettings
      await Future.delayed(const Duration(milliseconds: 250));

      // Initialize Payment Sheet with multiple payment options
      // Validate customer ID exists, if not, create payment without customer
      final hasValidCustomer = customerId.value.isNotEmpty && customerId.value.startsWith('cus_') && ephemeralKeySecret.value.isNotEmpty;
      // log('[StripePaymentController] Customer ID validation: $hasValidCustomer');
      // log('[StripePaymentController] Customer ID value: "${customerId.value}"');
      // log('[StripePaymentController] Ephemeral Key length: ${ephemeralKeySecret.value.length}');
      await _initPaymentSheet(
        customerId: hasValidCustomer ? customerId.value : null,
        customerEphemeralKeySecret: hasValidCustomer ? ephemeralKeySecret.value : null,
      );

    } catch (e) {
      errorMessage.value = e.toString();
      // Get.snackbar(
      //   'Payment Initialization Failed',
      //   e.toString().replaceAll('Exception: ', ''),
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: AppColors.error,
      //   colorText: AppColors.textWhite,
      //   duration: const Duration(seconds: 5),
      // );
      // If payment intent creation fails, navigate back to checkout
      Get.back(result: {'success': false, 'message': 'Payment initialization failed'});
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Initialize Payment Sheet
  Future<void> _initPaymentSheet({
    String? customerId,
    String? customerEphemeralKeySecret,
  }) async {
    try {
      isProcessing.value = true;
      debugPrint('[StripePaymentController] Initializing payment sheet...');
      log.log('[StripePaymentController] Passing Customer ID to init: ${customerId ?? "null"}');
      log.log('[StripePaymentController] Passing Ephemeral Key to init: ${customerEphemeralKeySecret != null ? "Present (length: ${customerEphemeralKeySecret.length})" : "null"}');
      await StripeService.initPaymentSheet(
        clientSecret: clientSecret.value,
        merchantDisplayName: 'FOS Productions',
        customerId: customerId,
        customerEphemeralKeySecret: customerEphemeralKeySecret,
        customerEmail: billingEmail.value.isNotEmpty ? billingEmail.value : null,
      );
      debugPrint('[StripePaymentController] Payment sheet initialized successfully.');
      log.log('[StripePaymentController] Payment sheet initialization SUCCESS');
      isProcessing.value = false;
    } catch (e) {
      isProcessing.value = false;
      log.log('[StripePaymentController] ERROR initializing payment sheet: $e');
      debugPrint('[StripePaymentController] Error initializing payment sheet: $e');
      // Get.snackbar(
      //   'Error',
      //   'Failed to initialize payment sheet: ${e.toString()}',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: AppColors.error,
      //   colorText: AppColors.textWhite,
      // );
      // If payment sheet initialization fails, navigate back to checkout
      // Get.back(result: {'success': false, 'message': 'Payment sheet initialization failed'});
    }
  }

  /// Process Payment using Payment Sheet (with multiple payment options)
  Future<void> processPaymentWithSheet() async {
    if (clientSecret.value.isEmpty) {
      // Get.snackbar('Error', 'Payment not initialized. Please try again.');
      return;
    }
    if (isProcessing.value) return; // Prevent double tap

    isProcessing.value = true;
    errorMessage.value = '';

    // Immediate feedback so user knows tap registere
    // Get.snackbar(
    //   'Opening payment…',
    //   'Please wait.',
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: AppColors.primary,
    //   colorText: AppColors.textWhite,
    //   duration: const Duration(seconds: 1),
    // );
    

    try {
      debugPrint('[StripePaymentController] Starting payment presentation process...');

      // Show loading indicator to user (skip on iOS to prevent view hierarchy interference)
      if (!Platform.isIOS) {
        Get.snackbar(
          'Opening Payment',
          'Please wait while we open the payment sheet...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 3),
          showProgressIndicator: true,
        );
      }

      // Present in next frame so native sheet can attach properly
      // iOS delay is now handled in stripe_service.dart
      if (!Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      log.log('[StripePayment] Attempting to present payment sheet');
      debugPrint('[StripePaymentController] Calling _presentPaymentSheetWithRetry()...');

      // Use a timeout to prevent hanging indefinitely
      final result = await _presentPaymentSheetWithRetry();
      
      log.log('[StripePayment] Payment sheet result: $result');
      debugPrint('[StripePaymentController] Payment sheet result received: $result');

      if (result['success'] == true) {
        debugPrint('[StripePaymentController] Payment successful, handling success logic...');
        await _handlePaymentSuccess();
      } else {
        debugPrint('[StripePaymentController] Payment not successful: ${result['message']}');
        throw Exception(result['message'] as String? ?? 'Payment was not completed');
      }
    } catch (e) {
      debugPrint('[StripePaymentController] Error caught in processPaymentWithSheet: $e');
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      errorMessage.value = errorMsg;

      if (errorMsg.toLowerCase().contains('cancelled')) {
        debugPrint('[StripePaymentController] Payment cancelled by user.');
        Get.back(result: {'success': false, 'message': 'Payment cancelled'});
      } else if (errorMsg.toLowerCase().contains('view is not in the window hierarchy') && Platform.isIOS) {
        debugPrint('[StripePaymentController] iOS view hierarchy issue, showing fallback payment method...');
        _showFallbackPaymentDialog();
      } else {
        debugPrint('[StripePaymentController] Payment failed with error: $errorMsg');
        Get.snackbar(
          'Payment Failed',
          errorMsg.length > 80 ? '${errorMsg.substring(0, 80)}...' : errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 5),
        );
        Get.back(result: {'success': false, 'message': errorMsg});
      }
    } finally {
      isProcessing.value = false;
    }
  }
  /// Present payment sheet; retry once if native "initialization failed" (Android timing) or "not in window hierarchy".
  Future<Map<String, dynamic>> _presentPaymentSheetWithRetry() async {
    int attempts = 0;
    while (attempts < 3) {
      attempts++;
      try {
        debugPrint('[StripePaymentController] _presentPaymentSheetWithRetry attempt $attempts starting...');
        log.log('[StripePaymentController] Attempt $attempts: Calling presentPaymentSheet...');
        
        // Add timeout wrapper to prevent hanging (must match service timeout of 60s)
        final result = await _stripeService.presentPaymentSheet().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            log.log('[StripePaymentController] TIMEOUT after 60 seconds');
            debugPrint('[StripePaymentController] Payment sheet timed out after 60 seconds');
            return {
              'success': false,
              'message': 'Payment sheet timed out. Please try again.',
              'error_code': 'TIMEOUT',
            };
          },
        );
        
        log.log('[StripePaymentController] SUCCESS: Payment sheet completed on attempt $attempts');
        debugPrint('[StripePaymentController] Payment sheet completed successfully on attempt $attempts');
        return result;
        
      } catch (e) {
        final msg = e.toString().toLowerCase();
        log.log('[StripePaymentController] ERROR on attempt $attempts: $e');
        log.log('[StripePaymentController] Error message: $msg');
        debugPrint('[StripePaymentController] Payment sheet failed on attempt $attempts: $e');
        
        // Check for timeout specifically
        if (msg.contains('timeout') || msg.contains('timed out')) {
          log.log('[StripePaymentController] TIMEOUT detected - showing fallback dialog');
          debugPrint('[StripePaymentController] Payment sheet timeout detected, showing fallback dialog');
          _showFallbackPaymentDialog();
          return {'success': false, 'message': 'Payment timed out. Please try again.'};
        }
        
        // Check for common transient errors that might be fixed by a retry
        if (msg.contains('initialization failed') || 
            msg.contains('view is not in the window hierarchy') ||
            msg.contains('presentation failed')) {
          
          if (attempts >= 3) {
            debugPrint('[StripePaymentController] Max retries reached, showing fallback dialog');
            _showFallbackPaymentDialog();
            return {'success': false, 'message': 'Payment sheet failed after multiple attempts'};
          }
          
          // Wait before retry
          if (Platform.isIOS) {
            debugPrint('[StripePaymentController] iOS retry $attempts - waiting...');
            await Future.delayed(Duration(milliseconds: 500 * attempts));
          } else {
            final delayMs = 500 * attempts;
            debugPrint('[StripePaymentController] Waiting ${delayMs}ms before retry...');
            await Future.delayed(Duration(milliseconds: delayMs));
          }
          continue;
        }
        
        // For other errors, don't retry
        rethrow;
      }
    }
    throw Exception('Failed to present payment sheet after retries');
  }

  // Removed processPayment method (manual card details)

  /// Handle 3D Secure Authentication
  Future<void> _handle3DSecure() async {
    try {
      final result = await _stripeService.handlePaymentAuthentication(
        clientSecret: clientSecret.value,
      );
      
      final status = result['status'] as String? ?? '';
      
      if (status == 'succeeded') {
        await _handlePaymentSuccess();
      } else {
        throw Exception('3D Secure authentication failed');
      }
    } catch (e) {
      throw Exception('3D Secure authentication error: $e');
    }
  }
  
  Future<void> _markDigitalProductPurchased(Map<String, dynamic> order) async {
    try {
      int? orderItemId;
      final direct = order['order_item_id'];
      if (direct is int) {
        orderItemId = direct;
      } else if (direct != null) {
        orderItemId = int.tryParse(direct.toString());
      }
      final items = order['items'];
      if (orderItemId == null && items is List && items.isNotEmpty) {
        final first = items.first;
        if (first is Map) {
          final raw = first['id'] ?? first['order_item_id'];
          orderItemId =
              raw is int ? raw : int.tryParse(raw?.toString() ?? '');
        }
      }
      final pc = GetXRegistry.product();
      await pc.applyDigitalPurchase(orderItemId: orderItemId);
    } catch (e) {
      debugPrint('[StripePayment] markDigitalProductPurchased: $e');
    }
  }

  /// Handle Successful Payment
  Future<void> _handlePaymentSuccess() async {
    try {
      if (paymentPurpose.value == 'fos_lens') {
        paymentStatus.value = 'paid';
        Get.back(result: <String, dynamic>{'success': true, 'purpose': 'fos_lens'});
        return;
      }

      if (!Get.isRegistered<CheckoutController>()) {
        // log('[StripePayment] CheckoutController not found – cannot create order');
        debugPrint('[StripePayment] CheckoutController not registered. Navigating to Orders.');
        Get.snackbar('Warning', 'Please check My Orders for your purchase.', snackPosition: SnackPosition.BOTTOM);
        Get.offAllNamed(AppRoutes.orders);
        return;
      }
      final checkoutController = Get.find<CheckoutController>();

      final paymentMethod = {
        'id': paymentMethodId.value,
        'type': 'stripe',
      };

      final order = await checkoutController.createOrderFromPayment(
        paymentMethod,
        isPaymentSuccess: true,
      );

      if (order == null || order.isEmpty || order['id'] == null) {
        throw Exception('Failed to create order after successful payment.');
      }

      paymentStatus.value = 'paid';
      final createdOrderId = order['id'];
      // log('[StripePayment] Payment success | orderId=$createdOrderId | is_digital=${isDigitalOrder.value}');
      debugPrint('[StripePayment] Payment success. Order ID: $createdOrderId, is_digital: ${isDigitalOrder.value}');

      final faceId = _watchFaceIdForPay;
      if (faceId.isEmpty) {
        Get.snackbar(
          'Success',
          'Payment completed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: AppColors.textWhite,
        );
      }

      if (faceId.isNotEmpty) {
        _returnToWatchFaces(faceId: faceId);
        return;
      }

      // Digital: mark owned instantly, then Order Details
      if (isDigitalOrder.value && createdOrderId != null) {
        final int? id = createdOrderId is int
            ? createdOrderId
            : int.tryParse(createdOrderId.toString());
        if (id != null && id > 0) {
          await _markDigitalProductPurchased(order);
          debugPrint('[StripePayment] Navigating to Order Details (orderId: $id).');
          await Future.delayed(const Duration(milliseconds: 300));
          Get.offNamed(AppRoutes.orderDetails, arguments: id);
          return;
        }
      }

      // Physical: order confirmation
      Get.offNamed(AppRoutes.orderConfirmation, arguments: {
        'order': order,
        'is_digital_order': false,
      });
    } catch (e) {
      // log('[StripePayment] _handlePaymentSuccess error: $e');
      debugPrint('[StripePayment] Error: $e');
      final faceId = _watchFaceIdForPay;
      if (faceId.isNotEmpty) {
        Get.snackbar(
          'Payment received',
          'Return to the watch face and tap Install.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: AppColors.textWhite,
        );
        _returnToWatchFaces(faceId: faceId);
        return;
      }
      Get.snackbar(
        'Warning',
        'Payment done but something went wrong. Check My Orders.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textWhite,
      );
      Get.offAllNamed(AppRoutes.orders);
    }
  }
  
  /// Retry Payment
  Future<void> retryPayment() async {
    errorMessage.value = '';
    // Clear stale customer ID to force backend to create new one
    customerId.value = '';
    ephemeralKeySecret.value = '';
    await _createPaymentIntent();
  }
  
  /// Show Fallback Payment Dialog for iOS
  /// When payment sheet fails due to view hierarchy issues
  void _showFallbackPaymentDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Payment Issue'),
        content: const Text(
          'The payment sheet cannot be displayed on this device. Would you like to:\n\n'
          '1. Try again with the payment sheet\n'
          '2. Use test card details for manual payment\n'
          '3. Cancel payment',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              processPaymentWithSheet(); // Retry
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _processTestPayment(); // Use test payment
            },
            child: const Text('Test Payment'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              cancelPayment();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Process Test Payment (for development/testing)
  /// Simulates successful payment without actual Stripe integration
  Future<void> _processTestPayment() async {
    isProcessing.value = true;
    errorMessage.value = '';
    
    try {
      debugPrint('[StripePaymentController] Processing test payment...');
      
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful payment
      debugPrint('[StripePaymentController] Test payment successful, handling success logic...');
      await _handlePaymentSuccess();
      
    } catch (e) {
      debugPrint('[StripePaymentController] Test payment failed: $e');
      Get.snackbar(
        'Payment Failed',
        'Test payment failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  String get _watchFaceIdForPay {
    if (watchFaceId.value.isNotEmpty) return watchFaceId.value;
    if (Get.isRegistered<CheckoutController>()) {
      return Get.find<CheckoutController>().watchFaceId ?? '';
    }
    return '';
  }

  void _returnToWatchFaces({required String faceId}) async {
    if (Get.isRegistered<WatchFacesController>()) {
      await Get.find<WatchFacesController>().markFacePurchased(faceId);
    }

    try {
      GetXRegistry.profile().loadOrders(silent: true);
    } catch (_) {}

    // Stripe + Secure Payment dono band karke watch faces / home pe lao
    Get.until((route) {
      final name = route.settings.name;
      return name == AppRoutes.watchFaces ||
          name == AppRoutes.home ||
          route.isFirst;
    });

    Get.snackbar(
      'Unlocked',
      'Payment done — tap Install on your watch face.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.secondary,
      colorText: AppColors.textWhite,
    );
  }

  /// Cancel Payment
  /// Guards against double back (system back + leading arrow) to prevent crash/wrong stack
  Future<void> cancelPayment() async {
    if (_cancelRequested) return;
    _cancelRequested = true;

    try {
      if (paymentStatus.value == 'paid') {
        Get.back(result: {'success': false, 'message': 'Payment already completed'});
        return;
      }
      if (isProcessing.value) {
        _cancelRequested = false;
        Get.snackbar(
          'Payment Processing',
          'Please wait while payment is being processed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: AppColors.textWhite,
        );
        return;
      }
      Get.back(result: {'success': false, 'message': 'Payment cancelled by user'});
    } catch (e) {
      _cancelRequested = false;
      rethrow;
    }
  }

  // Removed _cancelOrder method as it's no longer needed in this flow
}

