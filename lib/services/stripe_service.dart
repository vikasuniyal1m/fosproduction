import 'dart:developer';

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
    Stripe.merchantIdentifier = 'merchant.com.yourapp'; // Optional, for Apple Pay
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
      // Prepare billing details if customer email is provided and billingDetails are not already set
      BillingDetails? finalBillingDetails = billingDetails;
      if (customerEmail != null && customerEmail.isNotEmpty && finalBillingDetails == null) {
        finalBillingDetails = BillingDetails(
          email: customerEmail,
        );
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName ?? 'Your Store',
          customerId: customerId,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          billingDetails: finalBillingDetails,
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'IN',
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'IN',
            testEnv: true, // Set to false for production
          ),
          style: ThemeMode.system,
        ),
      );
    } catch (e) {
      log('Error initializing payment sheet: $e');
      rethrow;
    }
  }

  /// Present Payment Sheet
  /// Shows Stripe's PaymentSheet with all available payment options
  /// Returns the payment result
  Future<Map<String, dynamic>> presentPaymentSheet() async {
    try {
      // Present payment sheet - this will handle the entire payment flow
      // including card input, Apple Pay, Google Pay, etc.
      await Stripe.instance.presentPaymentSheet();

      // If we reach here, payment was successful
      // The payment intent status is updated automatically by Stripe
      return {
        'success': true,
        'status': 'succeeded',
      };
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        throw Exception('Payment was cancelled');
      } else {
        throw Exception('Payment failed: ${e.error.message ?? e.error.code}');
      }
    } catch (e) {
      throw Exception('Payment sheet error: $e');
    }
  }
}

