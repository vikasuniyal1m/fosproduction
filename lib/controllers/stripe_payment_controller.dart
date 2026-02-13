import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_storage/get_storage.dart';
import '../services/stripe_service.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/app_colors.dart';
import '../routes/app_routes.dart';
import '../controllers/checkout_controller.dart'; // Added import

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

      // Initialize Stripe with publishable key if not already done
      if (publishableKey.value.isNotEmpty) {
        await StripeService.initialize(publishableKey.value);
      } else {
        throw Exception('Stripe publishable key not found. Please contact support.');
      }
      
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
      await StripeService.initPaymentSheet(
        clientSecret: clientSecret.value,
        merchantDisplayName: 'FOS Productions',
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKeySecret,
        customerEmail: billingEmail.value.isNotEmpty ? billingEmail.value : null,
      );
      isProcessing.value = false;
    } catch (e) {
      isProcessing.value = false;
      Get.snackbar(
        'Error',
        'Failed to initialize payment sheet: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      log('Error initializing payment sheet: $e');
      // If payment sheet initialization fails, navigate back to checkout
      Get.back(result: {'success': false, 'message': 'Payment sheet initialization failed'});
    }
  }

  /// Process Payment using Payment Sheet (with multiple payment options)
  Future<void> processPaymentWithSheet() async {
    if (clientSecret.value.isEmpty) {
      Get.snackbar('Error', 'Payment not initialized. Please try again.');
      return;
    }
    
    isProcessing.value = true;
    errorMessage.value = '';
    
    try {
      // Present Payment Sheet (shows Card, Apple Pay, Google Pay, etc.)
      // This handles the entire payment flow automatically
      final result = await _stripeService.presentPaymentSheet();
      
      // Payment sheet completed successfully
      if (result['success'] == true) {
        await _handlePaymentSuccess();
      } else {
        throw Exception('Payment was not completed');
      }
      
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      errorMessage.value = errorMsg;

      if (errorMsg.toLowerCase().contains('cancelled')) {
        Get.back(result: {'success': false, 'message': 'Payment cancelled'}); // Navigate back on cancellation
      } else {
        Get.snackbar(
          'Payment Failed',
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 5),
        );
        Get.back(result: {'success': false, 'message': errorMsg}); // Navigate back on failure
      }
    } finally {
      isProcessing.value = false;
    }
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
      // Get CheckoutController instance
      final checkoutController = Get.find<CheckoutController>();

      // Prepare payment method map for createOrderFromPayment
      final paymentMethod = {
        'id': paymentMethodId.value,
        'type': 'stripe', // Assuming 'stripe' as the type for online payments
      };

      // Create order using CheckoutController's method
      final order = await checkoutController.createOrderFromPayment(
        paymentMethod,
        isPaymentSuccess: true,
      );
      
      if (order == null) {
        throw Exception('Failed to create order after successful payment.');
      }

      paymentStatus.value = 'paid';
      
      // Show success message
      Get.snackbar(
        'Success',
        'Payment completed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
      
      // Navigate to order confirmation and pass the created order
      Get.offAllNamed('/order-confirmation', arguments: order);

      // Return success result to CheckoutController
      Get.back(result: {'success': true, 'order': order});
      
    } catch (e) {
      // Payment succeeded on Stripe but order creation failed
      Get.snackbar(
        'Warning',
        'Payment completed but order creation failed. Please contact support.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textWhite,
      );
      log('Error creating order after successful payment: $e');
      // Return failure result to CheckoutController
      Get.back(result: {'success': false, 'message': 'Order creation failed after payment'});
    }
  }
  
  /// Retry Payment
  Future<void> retryPayment() async {
    errorMessage.value = '';
    await _createPaymentIntent();
  }
  
  /// Cancel Payment
  Future<void> cancelPayment() async {
    // If payment is already successful, just go back
    if (paymentStatus.value == 'paid') {
      Get.back(result: {'success': false, 'message': 'Payment already completed'});
      return;
    }

    // If payment is processing, don't allow cancel
    if (isProcessing.value) {
      Get.snackbar(
        'Payment Processing',
        'Please wait while payment is being processed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textWhite,
      );
      return;
    }

    // Simply navigate back to checkout screen, indicating cancellation
    Get.back(result: {'success': false, 'message': 'Payment cancelled by user'});
  }

  // Removed _cancelOrder method as it's no longer needed in this flow
}

