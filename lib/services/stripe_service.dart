import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/app_colors.dart';

/// Stripe Payment Service
/// Handles all Stripe payment operations
class StripeService {
  final ApiService _apiService = ApiService();
  
  /// Initialize Stripe with publishable key
  /// Call this in main.dart or app initialization
  static Future<void> initialize(String publishableKey) async {
    Stripe.publishableKey = publishableKey;
    Stripe.merchantIdentifier = 'merchant.com.test'; // Test merchant ID for development
    await Stripe.instance.applySettings();
  }
  
  /// Create Payment Intent on backend
  /// Returns client_secret and payment_intent_id
  Future<Map<String, dynamic>> createPaymentIntent({
    required int orderId,
    required double amount,
    String currency = 'usd',
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.stripeCreateIntent,
        data: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
        },
      );
      
      final data = ApiService.handleResponse(response);
      
      return {
        'success': true,
        'payment_intent_id': data['payment_intent_id'],
        'client_secret': data['client_secret'],
        'publishable_key': data['publishable_key'],
        'amount': data['amount'],
        'currency': data['currency'],
        'customer_id': data['customer_id'],
        'ephemeral_key_secret': data['ephemeral_key_secret'],
      };
    } catch (e) {
      throw Exception('Failed to create payment intent: ${ApiService.handleError(e)}');
    }
  }
  
  /// Confirm Payment Intent with Stripe
  /// Returns payment status
  Future<Map<String, dynamic>> confirmPayment({
    required String clientSecret,
    PaymentMethodParams? paymentMethodParams,
  }) async {
    try {
      // Confirm payment with Stripe SDK
      // API requires paymentIntentClientSecret as named parameter and data
      PaymentIntent paymentIntent;
      
      if (paymentMethodParams != null) {
        // If payment method params provided, use them
        paymentIntent = await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: paymentMethodParams,
        );
      } else {
        // If no params, just confirm with client secret
        paymentIntent = await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
        );
      }
      
      return {
        'success': true,
        'status': paymentIntent.status,
        'payment_intent_id': paymentIntent.id,
      };
    } on StripeException catch (e) {
      throw Exception('Stripe error: ${e.error.message ?? e.error.code}');
    } catch (e) {
      throw Exception('Payment confirmation failed: $e');
    }
  }
  
  /// Confirm Payment on Backend
  /// Updates order status after successful payment
  Future<Map<String, dynamic>> confirmPaymentOnBackend({
    required int orderId,
    required String paymentIntentId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.stripeConfirmPayment,
        data: {
          'order_id': orderId,
          'payment_intent_id': paymentIntentId,
        },
      );
      
      final data = ApiService.handleResponse(response);
      
      return {
        'success': true,
        'order_id': data['order_id'],
        'status': data['status'],
        'charge_id': data['charge_id'],
      };
    } catch (e) {
      throw Exception('Failed to confirm payment on backend: ${ApiService.handleError(e)}');
    }
    }
  
  /// Get Payment Status
  Future<Map<String, dynamic>> getPaymentStatus({
    int? orderId,
    String? paymentIntentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (orderId != null) queryParams['order_id'] = orderId;
      if (paymentIntentId != null) queryParams['payment_intent_id'] = paymentIntentId;
      
      final response = await _apiService.get(
        ApiEndpoints.stripeGetStatus,
        queryParameters: queryParams,
      );
      
      final data = ApiService.handleResponse(response);
      
      return {
        'success': true,
        'status': data['status'],
        'payment_intent_id': data['payment_intent_id'],
        'amount': data['amount'],
        'currency': data['currency'],
        'charge_id': data['charge_id'],
        'charge_status': data['charge_status'],
        'paid': data['paid'],
      };
    } catch (e) {
      throw Exception('Failed to get payment status: ${ApiService.handleError(e)}');
    }
  }
  
  /// Handle Payment Authentication (3D Secure)
  Future<Map<String, dynamic>> handlePaymentAuthentication({
    required String clientSecret,
  }) async {
    try {
      // handleNextAction takes clientSecret as positional argument
      final paymentIntent = await Stripe.instance.handleNextAction(clientSecret);
      
      return {
        'success': true,
        'status': paymentIntent.status,
        'payment_intent_id': paymentIntent.id,
      };
    } on StripeException catch (e) {
      throw Exception('Authentication failed: ${e.error.message ?? e.error.code}');
    } catch (e) {
      throw Exception('Payment authentication failed: $e');
    }
  }
  
  /// Create Payment Method from Card Details via Backend API
  /// This creates a Stripe PaymentMethod on the backend (PCI compliant)
  /// Returns payment method ID to use for payment confirmation
  Future<Map<String, dynamic>> createPaymentMethod({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    String? billingEmail,
    String? billingName,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.stripeCreatePaymentMethod,
        data: {
          'card_number': cardNumber,
          'expiry_month': expiryMonth,
          'expiry_year': expiryYear,
          'cvc': cvc,
          if (billingEmail != null) 'billing_email': billingEmail,
          if (billingName != null) 'billing_name': billingName,
        },
      );

      final data = ApiService.handleResponse(response);

      return {
        'success': true,
        'payment_method_id': data['payment_method_id'],
        'card': data['card'],
      };
    } catch (e) {
      throw Exception('Failed to create payment method: ${ApiService.handleError(e)}');
    }
  }

  static Future<void> initPaymentSheet({
    required String clientSecret,
    String? merchantDisplayName,
    String? customerId,
    String? customerEphemeralKeySecret,
    String? customerEmail,
    BillingDetails? billingDetails,
  }) async {
    try {
      log('[StripeService] ========== INIT PAYMENT SHEET ==========');
      debugPrint('[StripeService] Initializing payment sheet with clientSecret: ${clientSecret.substring(0, 10)}...');
      log('[StripeService] Client Secret: ${clientSecret.substring(0, 20)}...');
      debugPrint('[StripeService] Customer ID: $customerId');
      log('[StripeService] Customer ID: $customerId');
      debugPrint('[StripeService] Customer Ephemeral Key: ${customerEphemeralKeySecret != null ? "Present" : "Null"}');
      log('[StripeService] Ephemeral Key: ${customerEphemeralKeySecret != null ? "Present (length: ${customerEphemeralKeySecret.length})" : "Null"}');
      log('[StripeService] Merchant Display Name: ${merchantDisplayName ?? "FOS Productions"}');
      log('[StripeService] Customer Email: ${customerEmail ?? "Not provided"}');
      
      // Prepare billing details if customer email is provided and billingDetails are not already set
      BillingDetails? finalBillingDetails = billingDetails;
      if (customerEmail != null && customerEmail.isNotEmpty && finalBillingDetails == null) {
        finalBillingDetails = BillingDetails(
          email: customerEmail,
        );
        debugPrint('[StripeService] Using customer email: $customerEmail');
      }

      debugPrint('[StripeService] About to call Stripe.instance.initPaymentSheet...');
      log('[StripeService] Calling Stripe.instance.initPaymentSheet...');
      
      // Set merchant identifier for Apple Pay
      Stripe.merchantIdentifier = 'merchant.com.test';
      await Stripe.instance.applySettings();
      
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName ?? 'FOS Productions',
          customerId: (customerId?.isNotEmpty ?? false) ? customerId : null,
          customerEphemeralKeySecret: (customerEphemeralKeySecret?.isNotEmpty ?? false) ? customerEphemeralKeySecret : null,
          allowsDelayedPaymentMethods: true,
          returnURL: 'com.fruitsofspirit.ecommerce://stripe-redirect',
          style: ThemeMode.system,
          // Only enable Google Pay on Android to prevent iOS conflicts
          googlePay: GetPlatform.isIOS ? null : const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            testEnv: true,
            currencyCode: 'USD',
          ),
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.primary,
            ),
          ),
          billingDetails: finalBillingDetails,
        ),
      );
      
      log('[StripeService] SUCCESS: Payment sheet initialized successfully');
      debugPrint('[StripeService] Payment sheet initialization completed successfully.');
    } catch (e) {
      log('[StripeService] ERROR: Failed to initialize payment sheet');
      log('[StripeService] Error details: $e');
      debugPrint('[StripeService] Error initializing payment sheet: $e');
      rethrow;
    }
  }

  /// Present Payment Sheet
  /// Shows Stripe's PaymentSheet with all available payment options
  /// Returns payment result
  Future<Map<String, dynamic>> presentPaymentSheet() async {
    try {
      log('[StripeService] ========== PRESENT PAYMENT SHEET ==========');
      debugPrint('[StripeService] Presenting payment sheet via Stripe SDK...');
      
      // Check if payment sheet is properly initialized
      try {
        Stripe.instance;
        debugPrint('[StripeService] Stripe instance available');
      } catch (e) {
        debugPrint('[StripeService] Error accessing Stripe instance: $e');
        rethrow;
      }
      
      // On iOS, wait for current frame to complete before presenting
      if (GetPlatform.isIOS) {
        debugPrint('[StripeService] iOS detected - waiting for view hierarchy...');
        // Wait for the current frame to complete and view hierarchy to be ready
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('[StripeService] iOS wait completed, attempting to present...');
      }

      debugPrint('[StripeService] About to call Stripe.instance.presentPaymentSheet()...');
      log('[StripeService] Calling Stripe.instance.presentPaymentSheet()...');

      await Stripe.instance.presentPaymentSheet().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          log('[StripeService] TIMEOUT: Payment sheet presentation timed out after 60 seconds');
          debugPrint('[StripeService] Payment sheet presentation timed out');
          throw TimeoutException('Payment sheet timed out', const Duration(seconds: 60));
        },
      );

      log('[StripeService] SUCCESS: Payment sheet presented and completed successfully');
      debugPrint('[StripeService] Payment sheet presented and completed successfully.');

      // If we reach here, payment was successful
      // The payment intent status is updated automatically by Stripe
      return {
        'success': true,
        'message': 'Payment completed successfully',
        'payment_intent_id': '', // Will be populated by the calling controller
      };
      
    } on StripeException catch (e) {
      log('[StripeService] STRIPE EXCEPTION: ${e.error.localizedMessage}');
      log('[StripeService] StripeException error code: ${e.error.code}');
      log('[StripeService] StripeException localizedMessage: ${e.error.localizedMessage}');
      debugPrint('[StripeService] StripeException caught: ${e.error.localizedMessage}');
      debugPrint('[StripeService] StripeException error code: ${e.error.code}');
      debugPrint('[StripeService] StripeException localizedMessage: ${e.error.localizedMessage}');
      
      // Handle specific Stripe errors
      String errorMessage = e.error.localizedMessage ?? 'Payment failed';
      
      if (e.error.code.toString().toLowerCase().contains('cancelled')) {
        return {
          'success': false,
          'message': 'Payment cancelled',
          'error_code': 'CANCELLED',
        };
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error_code': e.error.code.toString(),
      };
      
    } on TimeoutException catch (e) {
      log('[StripeService] TIMEOUT EXCEPTION: ${e.message}');
      debugPrint('[StripeService] TimeoutException caught: ${e.message}');
      return {
        'success': false,
        'message': 'Payment timed out. Please try again.',
        'error_code': 'TIMEOUT',
      };
      
    } catch (e) {
      log('[StripeService] GENERIC ERROR: $e');
      debugPrint('[StripeService] Generic error caught in presentPaymentSheet: $e');
      return {
        'success': false,
        'message': 'Payment failed: ${e.toString()}',
        'error_code': 'UNKNOWN',
      };
    }
  }
}
