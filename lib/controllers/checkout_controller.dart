import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../routes/app_routes.dart';
import 'coupon_controller.dart';
import 'cart_controller.dart'; // Added import for CartController

/// Checkout Controller
/// Manages checkout state and order creation
class CheckoutController extends GetxController {
  final ApiService _apiService = ApiService();
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isPlacingOrder = false.obs;
  
  // Checkout data
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> addresses = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paymentMethods = <Map<String, dynamic>>[].obs;
  
  // Selected values
  final RxInt selectedAddressId = 0.obs;
  final RxInt selectedPaymentMethodId = 0.obs;
  final RxString couponCode = ''.obs;
  final RxString notes = ''.obs;
  
  // Summary
  final RxDouble subtotal = 0.0.obs;
  final RxDouble shippingCharges = 0.0.obs;
  final RxDouble tax = 0.0.obs;
  final RxDouble discount = 0.0.obs;
  final RxDouble total = 0.0.obs;
  
  // Coupon
  final RxMap<String, dynamic> appliedCoupon = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> availableCoupons = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadCheckoutSummary();
  }
  
  /// Check for pre-selected coupon from CouponController
  void _checkPreSelectedCoupon() {
    try {
      if (Get.isRegistered<CouponController>()) {
        final couponController = Get.find<CouponController>();
        if (couponController.selectedCoupon.isNotEmpty) {
          final selectedCoupon = couponController.selectedCoupon;
          final couponCode = selectedCoupon['code'] as String? ?? '';
          if (couponCode.isNotEmpty) {
            // Apply the pre-selected coupon after a short delay to ensure subtotal is loaded
            Future.delayed(const Duration(milliseconds: 500), () {
              applyCoupon(couponCode);
            });
          }
        }
      }
    } catch (e) {
      // CouponController might not be registered, ignore
      print('No pre-selected coupon: $e');
    }
  }
  
  /// Load checkout summary
  Future<void> loadCheckoutSummary() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get(ApiEndpoints.checkoutSummary);
      final data = ApiService.handleResponse(response);
      
      items.value = List<Map<String, dynamic>>.from(data['items'] ?? []);
      addresses.value = List<Map<String, dynamic>>.from(data['addresses'] ?? []);
      paymentMethods.value = List<Map<String, dynamic>>.from(data['payment_methods'] ?? []);
      print('Payment Methods: ${paymentMethods.value}');

      // Ensure Stripe payment method is always available
      if (!paymentMethods.any((pm) => pm['type'] == 'stripe')) {
        paymentMethods.add({
          'id': -1, // Unique ID for the manually added Stripe option
          'type': 'stripe',
          'name': 'Stripe',
          'is_default': false, // Not default unless explicitly set
        });
        print('Manually added Stripe payment method.');
      }

      // Sort payment methods to ensure 'cod' is always last, and 'stripe' is first if present
      paymentMethods.sort((a, b) {
        if (a['type'] == 'stripe') return -1; // Stripe comes first
        if (b['type'] == 'stripe') return 1;
        if (a['type'] == 'cod') return 1; // COD comes last
        if (b['type'] == 'cod') return -1;
        return 0;
      });


      final summary = data['summary'] ?? {};
      subtotal.value = double.tryParse(summary['subtotal']?.toString() ?? '0') ?? 0.0;
      shippingCharges.value = double.tryParse(summary['shipping_charges']?.toString() ?? '0') ?? 0.0;
      tax.value = double.tryParse(summary['tax']?.toString() ?? '0') ?? 0.0;
      discount.value = double.tryParse(summary['discount']?.toString() ?? '0') ?? 0.0;
      total.value = double.tryParse(summary['total']?.toString() ?? '0') ?? 0.0;
      
      // Select default address and payment method
      if (addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhereOrNull((addr) => addr['is_default'] == true);
        if (defaultAddress != null) {
          selectedAddressId.value = defaultAddress['id'] as int;
        } else {
          selectedAddressId.value = addresses.first['id'] as int;
        }
      }
      
      if (paymentMethods.isNotEmpty) {
        final defaultPayment = paymentMethods.firstWhereOrNull((pm) => pm['is_default'] == true);
        if (defaultPayment != null) {
          selectedPaymentMethodId.value = defaultPayment['id'] as int;
        } else {
          selectedPaymentMethodId.value = paymentMethods.first['id'] as int;
        }
      }
      
      // Load available coupons
      await loadAvailableCoupons();
      
      // Check for pre-selected coupon after loading summary
      _checkPreSelectedCoupon();
      
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Load available coupons
  Future<void> loadAvailableCoupons() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.checkoutAvailableCoupons,
        queryParameters: {'subtotal': subtotal.value},
      );
      final data = ApiService.handleResponse(response);
      availableCoupons.value = List<Map<String, dynamic>>.from(data['coupons'] ?? []);
    } catch (e) {
      // Silently fail - coupons are optional
      print('Error loading coupons: ${ApiService.handleError(e)}');
      availableCoupons.value = [];
    }
  }
  
  /// Apply coupon code
  Future<bool> applyCoupon(String code) async {
    if (code.isEmpty) {
      Get.snackbar('Error', 'Please enter a coupon code');
      return false;
    }
    
    try {
      final response = await _apiService.post(
        ApiEndpoints.checkoutApplyCoupon,
        data: {
          'coupon_code': code,
          'subtotal': subtotal.value,
        },
      );
      
      final data = ApiService.handleResponse(response);
      final coupon = data['coupon'] ?? {};
      
      appliedCoupon.value = coupon;
      couponCode.value = code;
      discount.value = double.tryParse(coupon['discount']?.toString() ?? '0') ?? 0.0;
      
      // Recalculate total
      total.value = subtotal.value + shippingCharges.value + tax.value - discount.value;
      
      Get.snackbar('Success', 'Coupon applied successfully');
      return true;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return false;
    }
  }
  
  /// Remove coupon
  void removeCoupon() {
    appliedCoupon.clear();
    couponCode.value = '';
    discount.value = 0.0;
    total.value = subtotal.value + shippingCharges.value + tax.value;
  }
  
  /// Place order
  Future<Map<String, dynamic>?> placeOrder() async {
    // Validate cart is not empty
    if (items.isEmpty) {
      Get.snackbar('Error', 'Your cart is empty. Please add items before placing an order.');
      return null;
    }

    if (selectedAddressId.value == 0) {
      Get.snackbar('Error', 'Please select a shipping address');
      return null;
    }
    
    if (paymentMethods.isEmpty) {
      Get.snackbar('Error', 'Please add a payment method');
      return null;
    }
    
    // Get selected payment method
    final selectedPayment = paymentMethods.firstWhere(
      (pm) => pm['id'] == selectedPaymentMethodId.value,
    );
    

    // Create order first (for both COD and online payments)
    final paymentType = selectedPayment['type'] ?? 'cod';

    if (paymentType == 'cod') {
      // For COD, create the order immediately
      final order = await createOrderFromPayment(selectedPayment, isPaymentSuccess: false);
      if (order == null) {
        return null; // Order creation failed
      }
      return order; // Return order for confirmation screen
    } else {
      // For Stripe and other online payments, navigate to Stripe Payment Screen
      // The order will be created *after* successful payment in StripePaymentController
      final result = await Get.toNamed(
        AppRoutes.stripePayment,
        arguments: {
          'amount': total.value,
          'currency': 'usd', // Assuming currency is always USD for now
        },
      );

      // Check if payment was successful and order was created
      if (result != null && result is Map<String, dynamic> && result['success'] == true) {
        // Payment was successful, and order should have been created by StripePaymentController
        // StripePaymentController should return the created order.
        return result['order'];
      } else {
        // Payment failed or was cancelled
        Get.snackbar('Payment Failed', 'Your payment could not be processed. Please try again.');
        return null;
      }
    }
  }

  /// Create order (internal method)
  /// This method is now public so StripePaymentController can call it after successful payment.
  Future<Map<String, dynamic>?> createOrderFromPayment(Map<String, dynamic> paymentMethod, {bool isPaymentSuccess = false}) async {
    isPlacingOrder.value = true;
    try {
      final paymentType = paymentMethod['type'] ?? 'cod';
      
      // Prepare order data
      final orderData = {
        'shipping_address_id': selectedAddressId.value,
        'billing_address_id': selectedAddressId.value,
        'payment_method': paymentType,
        if (couponCode.value.isNotEmpty) 'coupon_code': couponCode.value,
        if (notes.value.isNotEmpty) 'notes': notes.value,
      };
      
      // Set payment_status: 'paid' for successful online payments, 'pending' for COD
      if (isPaymentSuccess && paymentType != 'cod') {
        orderData['payment_status'] = 'paid';
      } else if (paymentType == 'cod') {
        orderData['payment_status'] = 'pending'; // COD is paid on delivery
      }
      
      // Only add payment_method_id if it's not COD (COD has id = 0)
      final paymentMethodId = paymentMethod['id'] as int? ?? 0;
      if (paymentMethodId > 0) {
        orderData['payment_method_id'] = paymentMethodId;
      }
      
      final response = await _apiService.post(
        ApiEndpoints.ordersCreate,
        data: orderData,
      );
      
      final data = ApiService.handleResponse(response);
      final order = data['order'] ?? {};
      
      // Clear selected coupon from CouponController after successful order
      try {
        if (Get.isRegistered<CouponController>()) {
          final couponController = Get.find<CouponController>();
          couponController.clearSelectedCoupon();
          couponController.refreshCoupons();
        }
      } catch (e) {
        print('Error clearing coupon: $e');
      }

      // Clear the cart after successful order placement
      try {
        if (Get.isRegistered<CartController>()) {
          final cartController = Get.find<CartController>();
          await cartController.clearCart();
          print('Cart cleared after successful order.');
        }
      } catch (e) {
        print('Error clearing cart after order: $e');
      }
      
      return order;
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      return null;
    } finally {
      isPlacingOrder.value = false;
    }
  }
  
  /// Process online payment
  Future<Map<String, dynamic>?> _processOnlinePayment(Map<String, dynamic> paymentMethod) async {
    // This method is no longer used as placeOrder now handles navigation to StripePaymentScreen
    // and order creation is deferred until after successful payment.
    return null;
  }

  // The _createOrder method is now renamed to createOrderFromPayment and made public.
  // The original _createOrder method is removed.


  /// Select address
  void selectAddress(int addressId) {
    selectedAddressId.value = addressId;
  }
  
  /// Select payment method
  void selectPaymentMethod(int paymentMethodId) {
    selectedPaymentMethodId.value = paymentMethodId;
  }
  
  /// Get selected address
  Map<String, dynamic>? get selectedAddress {
    try {
      return addresses.firstWhere((addr) => addr['id'] == selectedAddressId.value);
    } catch (e) {
      return null;
    }
  }
  
  /// Get selected payment method
  Map<String, dynamic>? get selectedPaymentMethod {
    try {
      return paymentMethods.firstWhere((pm) => pm['id'] == selectedPaymentMethodId.value);
    } catch (e) {
      return null;
    }
  }
}

