import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_storage/get_storage.dart';
import '../services/stripe_service.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/app_colors.dart';
import '../routes/app_routes.dart';
import '../controllers/checkout_controller.dart';
import '../views/orders/order_details_screen.dart';

/// Stripe Payment Controller
/// Manages Stripe payment flow and state
class StripePaymentController extends GetxController {
  final StripeService _stripeService = StripeService();
  final ApiService _apiService = ApiService();
  
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
      currency.value = args['currency'] as String? ?? 'usd';
      paymentMethodId.value = args['payment_method_id'] as int? ?? 0;
      couponCode.value = args['coupon_code'] as String? ?? '';
      notes.value = args['notes'] as String? ?? '';
      shippingAddressId.value = args['shipping_address_id'] as int? ?? 0;
      isDigitalOrder.value = args['is_digital_order'] == true;
    }
    
    // Create payment intent immediately when screen loads
    _createPaymentIntent();
  }

  /// Create Payment Intent
  Future<void> _createPaymentIntent() async {
    // Removed orderId validation

    if (amount.value <= 0) {
      errorMessage.value = 'Invalid amount';
      Get.snackbar(
        'Error',
        'Invalid payment amount. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    
    try {
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
      await _initPaymentSheet(
        customerId: customerId.value,
        ephemeralKeySecret: ephemeralKeySecret.value,
      );

    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Payment Initialization Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
        duration: const Duration(seconds: 5),
      );
      // If payment intent creation fails, navigate back to checkout
      Get.back(result: {'success': false, 'message': 'Payment initialization failed'});
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Initialize Payment Sheet
  Future<void> _initPaymentSheet({
    required String customerId,
    required String ephemeralKeySecret,
  }) async {
    try {
      isProcessing.value = true;
      debugPrint('[StripePaymentController] Initializing payment sheet...');
      await StripeService.initPaymentSheet(
        clientSecret: clientSecret.value,
        merchantDisplayName: 'FOS Productions',
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKeySecret,
        customerEmail: billingEmail.value.isNotEmpty ? billingEmail.value : null,
      );
      debugPrint('[StripePaymentController] Payment sheet initialized successfully.');
      isProcessing.value = false;
    } catch (e) {
      isProcessing.value = false;
      log('Error initializing payment sheet: $e');
      debugPrint('[StripePaymentController] Error initializing payment sheet: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize payment sheet: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      // If payment sheet initialization fails, navigate back to checkout
      // Get.back(result: {'success': false, 'message': 'Payment sheet initialization failed'});
    }
  }

  /// Process Payment using Payment Sheet (with multiple payment options)
  Future<void> processPaymentWithSheet() async {
    if (clientSecret.value.isEmpty) {
      Get.snackbar('Error', 'Payment not initialized. Please try again.');
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
      
      // Present in next frame so native sheet can attach properly
      // On iOS, we need to ensure the view controller is ready to present
      if (Platform.isIOS) {
        log('[StripePayment] Waiting for view hierarchy readiness...');
        debugPrint('[StripePaymentController] Adding delay (500ms) for iOS to ensure view hierarchy readiness...');
        // Wait for potential transitions to settle
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('[StripePaymentController] Delay completed.');
      } else {
        await Future.delayed(const Duration(milliseconds: 150));
      }
      
      log('[StripePayment] Attempting to present payment sheet');
      debugPrint('[StripePaymentController] Calling _presentPaymentSheetWithRetry()...');
      
      // Use a timeout to prevent hanging indefinitely (reduced to 10s)
      final result = await _presentPaymentSheetWithRetry();
      
      log('[StripePayment] Payment sheet result: $result');
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
      try {
        attempts++;
        debugPrint('[StripePaymentController] _presentPaymentSheetWithRetry attempt $attempts starting...');
        final result = await _stripeService.presentPaymentSheet();
        debugPrint('[StripePaymentController] _presentPaymentSheetWithRetry attempt $attempts success: $result');
        return result;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        log('Stripe presentPaymentSheet failed (attempt $attempts): $msg');
        debugPrint('[StripePaymentController] Retry attempt $attempts due to error: $msg');
        
        // Check for common transient errors that might be fixed by a retry
        if (msg.contains('initialization failed') || 
            msg.contains('view is not in the window hierarchy') ||
            msg.contains('presentation failed')) {
          
          if (attempts >= 3) {
            debugPrint('[StripePaymentController] Max retries reached. Rethrowing error.');
            rethrow;
          }
          
          // Increasing backoff delay
          final delayMs = 500 * attempts;
          debugPrint('[StripePaymentController] Waiting ${delayMs}ms before retry...');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        debugPrint('[StripePaymentController] Non-retryable error encountered: $msg');
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
  
  /// Handle Successful Payment
  Future<void> _handlePaymentSuccess() async {
    try {
      if (!Get.isRegistered<CheckoutController>()) {
        log('[StripePayment] CheckoutController not found – cannot create order');
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

      if (order == null) {
        throw Exception('Failed to create order after successful payment.');
      }

      paymentStatus.value = 'paid';
      final orderId = order['id'];
      log('[StripePayment] Payment success | orderId=$orderId | is_digital=${isDigitalOrder.value}');
      debugPrint('[StripePayment] Payment success. Order ID: $orderId, is_digital: ${isDigitalOrder.value}');

      Get.snackbar(
        'Success',
        'Payment completed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );

      // Digital: payment ke baad Order Details pe – digital product + download option (direct widget se pakka navigate)
      if (isDigitalOrder.value && orderId != null) {
        final id = orderId is int ? orderId : int.tryParse(orderId.toString());
        if (id != null && id > 0) {
          log('[StripePayment] Digital → Order Details orderId=$id');
          debugPrint('[StripePayment] Navigating to Order Details (orderId: $id).');
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAll(() => OrderDetailsScreen(orderId: id));
          return;
        }
      }

      // Physical: order confirmation
      Get.offAllNamed('/order-confirmation', arguments: {
        'order': order,
        'is_digital_order': false,
      });
    } catch (e) {
      log('[StripePayment] _handlePaymentSuccess error: $e');
      debugPrint('[StripePayment] Error: $e');
      Get.snackbar(
        'Warning',
        'Payment done but something went wrong. Check My Orders.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textWhite,
      );
      // Kabhi bhi payment screen pe stuck na rahe – Orders pe bhejo
      Get.offAllNamed(AppRoutes.orders);
    }
  }
  
  /// Retry Payment
  Future<void> retryPayment() async {
    errorMessage.value = '';
    await _createPaymentIntent();
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

