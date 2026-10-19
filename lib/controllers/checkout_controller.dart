import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../routes/app_routes.dart';
import 'coupon_controller.dart';
import 'cart_controller.dart'; // Added import for CartController
import 'stripe_payment_controller.dart';
import '../watch_faces/watch_face_product_ids.dart';

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

  /// When true, cart is digital-only (e.g. from preview "Pay & Download"); no address required.
  bool isDigitalQuickPay = false;
  bool _hasTriggeredDirectStripe = false;
  double? _quickPayAmount;
  String? watchFaceId;
  String? watchFaceTitle;

  /// Digital quick pay: checkout screen skip karke seedha Stripe pe bhejne ke liye (sirf ek baar).
  Future<void> tryGoDirectToStripe() async {
    if (!isDigitalQuickPay || items.isEmpty || _hasTriggeredDirectStripe) return;
    _hasTriggeredDirectStripe = true;
    try {
      final order = await placeOrder();
      _closeDigitalPayRedirect(order);
    } catch (_) {
      _closeDigitalPayRedirect(null);
    }
  }

  int? _orderItemIdFromOrder(dynamic order) {
    if (order is! Map) return null;
    final direct = order['order_item_id'];
    if (direct is int) return direct;
    if (direct != null) return int.tryParse(direct.toString());
    final items = order['items'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map) {
        final id = first['id'] ?? first['order_item_id'];
        if (id is int) return id;
        return int.tryParse(id?.toString() ?? '');
      }
    }
    return null;
  }

  void _closeDigitalPayRedirect(dynamic order) {
    if (!isDigitalQuickPay) {
      if (order == null && (Get.key.currentState?.canPop() ?? false)) Get.back();
      return;
    }
    // Watch face: Stripe already popped payment stack via Get.until
    if (watchFaceId != null) {
      if (Get.currentRoute == AppRoutes.digitalPayRedirect) {
        Get.back(result: <String, dynamic>{
          'success': order != null,
          'watch_face_id': watchFaceId,
        });
      }
      return;
    }
    if (Get.currentRoute == AppRoutes.digitalPayRedirect) {
      Get.back(result: <String, dynamic>{
        'success': order != null,
        if (order != null) 'order_item_id': _orderItemIdFromOrder(order),
      });
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    isDigitalQuickPay = args?['digital_quick_pay'] == true;
    _quickPayAmount = (args?['quick_pay_amount'] as num?)?.toDouble();
    watchFaceId = (args?['watch_face_id'] as String?)?.trim();
    if (watchFaceId != null && watchFaceId!.isEmpty) watchFaceId = null;
    watchFaceTitle = (args?['watch_face_title'] as String?)?.trim();
    if (watchFaceTitle != null && watchFaceTitle!.isEmpty) watchFaceTitle = null;
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
              if (subtotal.value > 0 && items.isNotEmpty) {
                applyCoupon(couponCode);
              } else {
                couponController.clearSelectedCoupon();
              }
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

      // For direct digital payment from product details, force selected product amount
      // so Stripe always charges exactly what user saw on product page.
      if (isDigitalQuickPay && _quickPayAmount != null && _quickPayAmount! > 0) {
        subtotal.value = _quickPayAmount!;
        shippingCharges.value = 0.0;
        tax.value = 0.0;
        discount.value = 0.0;
        total.value = _quickPayAmount!;
      }
      
      print('Checkout loaded - Items: ${items.length}, Total: $total');
      
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
        if (isDigitalQuickPay) {
          final stripePayment = paymentMethods.cast<Map<String, dynamic>>().firstWhereOrNull((pm) => pm['type'] == 'stripe');
          if (stripePayment != null) {
            selectedPaymentMethodId.value = stripePayment['id'] as int;
          }
          selectedAddressId.value = 0; // Digital-only: no shipping address
        } else {
          final defaultPayment = paymentMethods.firstWhereOrNull((pm) => pm['is_default'] == true);
          if (defaultPayment != null) {
            selectedPaymentMethodId.value = defaultPayment['id'] as int;
          } else {
            selectedPaymentMethodId.value = paymentMethods.first['id'] as int;
          }
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
      // Get.snackbar('Error', 'Please enter a coupon code');
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
      
      // Get.snackbar('Success', 'Coupon applied successfully');
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
      // Get.snackbar('Error', 'Your cart is empty. Please add items before placing an order.');
      return null;
    }

    if (selectedAddressId.value == 0 && !isDigitalQuickPay) {
      // Get.snackbar('Error', 'Please select a shipping address');
      return null;
    }
    
    if (paymentMethods.isEmpty) {
      // Get.snackbar('Error', 'Please add a payment method');
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
      final args = {
        'amount': total.value,
        'currency': 'usd',
        'payment_method_id': selectedPaymentMethodId.value,
        'shipping_address_id': selectedAddressId.value,
        'coupon_code': couponCode.value,
        'notes': notes.value,
        'is_digital_order': isDigitalQuickPay,
        if (watchFaceId != null) 'watch_face_id': watchFaceId,
      };
      // Fresh Stripe controller taaki watch_face_id args miss na ho (purana instance stuck karta tha)
      if (Get.isRegistered<StripePaymentController>()) {
        await Get.delete<StripePaymentController>(force: true);
      }

      // Digital: Stripe pe toNamed use karo taaki Checkout stack me rahe – payment success par createOrderFromPayment ke liye controller mile
      final result = await Get.toNamed(AppRoutes.stripePayment, arguments: args);

      // Check if payment was successful and order was created
      if (result != null && result is Map<String, dynamic> && result['success'] == true) {
        final createdOrder = result['order'];
        if (createdOrder is Map<String, dynamic> && createdOrder.isNotEmpty) {
          return createdOrder;
        }
        // Watch face quick pay: order optional, success flag enough
        if (watchFaceId != null) return result;
        return createdOrder is Map<String, dynamic> ? createdOrder : null;
      } else {
        if (!isDigitalQuickPay) {
          // Get.snackbar('Payment Failed', 'Your payment could not be processed. Please try again.');
        }
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
      
      // Digital product: shipping address not required (send 0 if API requires the key)
      final orderData = <String, dynamic>{
        'shipping_address_id': isDigitalQuickPay ? 0 : selectedAddressId.value,
        'billing_address_id': isDigitalQuickPay ? 0 : selectedAddressId.value,
        'payment_method': paymentType,
        if (couponCode.value.isNotEmpty) 'coupon_code': couponCode.value,
        if (notes.value.isNotEmpty) 'notes': notes.value,
        if (watchFaceId != null) 'notes': 'watch_face_id:$watchFaceId',
      };

      // Watch face: cart server pe empty ho sakta hai — catalog price + product id use karo.
      if (watchFaceId != null && isDigitalQuickPay) {
        final price = _quickPayAmount ?? total.value;
        final productId = WatchFaceProductIds.resolve(watchFaceId!, null) ??
            (items.isNotEmpty
                ? int.tryParse(
                    (items.first['product_id'] ?? items.first['id'])?.toString() ?? '',
                  )
                : null);
        if (productId != null && productId > 0 && price > 0) {
          final title = watchFaceTitle?.trim();
          orderData['items'] = [
            {
              'product_id': productId,
              'product_name': title != null && title.isNotEmpty
                  ? 'Watch Face · $title'
                  : 'FOS Watch Face',
              'price': price,
              'quantity': 1,
              'is_digital': true,
            },
          ];
        }
      }
      
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
      final orderRaw = data['order'];
      if (orderRaw is! Map) {
        throw Exception('Order was not created. Please check My Orders.');
      }
      final order = Map<String, dynamic>.from(orderRaw);
      final orderId = order['id'] ?? data['order_id'];
      if (orderId == null || int.tryParse(orderId.toString()) == null || int.parse(orderId.toString()) <= 0) {
        throw Exception('Order was not created. Please check My Orders.');
      }
      order['id'] = int.parse(orderId.toString());
      
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

