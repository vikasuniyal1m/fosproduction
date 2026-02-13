import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_widget.dart';
import '../../services/api_service.dart';
import '../../services/api_endpoints.dart';
import '../../routes/app_routes.dart';
import '../../widgets/responsive_button.dart';
import '../../controllers/checkout_controller.dart';

/// Payment Gateway Screen
/// Order review screen before payment - shows address, items, coupon, and summary
class PaymentGatewayScreen extends StatefulWidget {
  final int? orderId;
  final String? paymentMethod;
  final double? amount;
  
  const PaymentGatewayScreen({
    super.key,
    this.orderId,
    this.paymentMethod,
    this.amount,
  });
  
  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final ApiService _apiService = ApiService();
  final RxBool isLoading = true.obs;
  final RxBool isPlacingOrder = false.obs;

  Map<String, dynamic>? orderData;
  Map<String, dynamic>? address;
  List<Map<String, dynamic>> orderItems = [];
  Map<String, dynamic>? appliedCoupon;
  double subtotal = 0.0;
  double shippingCharges = 0.0;
  double tax = 0.0;
  double discount = 0.0;
  double total = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }
  
  Future<void> _loadOrderData() async {
    isLoading.value = true;
    try {
      // Get CheckoutController to access selected address and coupon
      CheckoutController? checkoutController;
      try {
        checkoutController = Get.find<CheckoutController>();
      } catch (e) {
        // CheckoutController not found, will load from API
      }

      // Load checkout summary to get order details
      final response = await _apiService.get(ApiEndpoints.checkoutSummary);
      final data = ApiService.handleResponse(response);

      // Get order items
      orderItems = List<Map<String, dynamic>>.from(data['items'] ?? []);

      // If cart is empty, navigate back and show error
      if (orderItems.isEmpty) {
        Get.back();
        Get.snackbar(
          'Error',
          'Your cart is empty. Please add items before placing an order.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Get selected address - use from CheckoutController if available, otherwise use default
      final addresses = List<Map<String, dynamic>>.from(data['addresses'] ?? []);
      if (addresses.isNotEmpty) {
        if (checkoutController != null && checkoutController.selectedAddressId.value > 0) {
          // Use selected address from CheckoutController
          try {
            address = addresses.firstWhere(
              (addr) => addr['id'] == checkoutController!.selectedAddressId.value,
            );
          } catch (e) {
            // Selected address not found, use default
            final defaultAddress = addresses.firstWhereOrNull((addr) => addr['is_default'] == true);
            address = defaultAddress ?? addresses.first;
          }
        } else {
          // Use default address
          final defaultAddress = addresses.firstWhereOrNull((addr) => addr['is_default'] == true);
          address = defaultAddress ?? addresses.first;
        }
      }

      // Get summary
      final summary = data['summary'] ?? {};
      subtotal = double.tryParse(summary['subtotal']?.toString() ?? '0') ?? 0.0;
      shippingCharges = double.tryParse(summary['shipping_charges']?.toString() ?? '0') ?? 0.0;
      tax = double.tryParse(summary['tax']?.toString() ?? '0') ?? 0.0;
      discount = double.tryParse(summary['discount']?.toString() ?? '0') ?? 0.0;
      total = double.tryParse(summary['total']?.toString() ?? '0') ?? 0.0;

      // Get applied coupon - use from CheckoutController if available
      if (checkoutController != null && checkoutController.appliedCoupon.isNotEmpty) {
        appliedCoupon = Map<String, dynamic>.from(checkoutController.appliedCoupon);
      } else {
        // Get from summary
        final couponCode = summary['coupon_code'] as String?;
        if (couponCode != null && couponCode.isNotEmpty) {
          appliedCoupon = {
            'code': couponCode,
            'discount': discount,
          };
        }
      }

      setState(() {});
    } catch (e) {
      Get.snackbar('Error', 'Failed to load order data: ${ApiService.handleError(e)}');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _handlePlaceOrder() async {
    // Validate cart is not empty
    if (orderItems.isEmpty) {
      Get.snackbar(
        'Error',
        'Your cart is empty. Please add items before placing an order.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      // Navigate back to checkout or home
      Get.back();
      return;
    }

    if (address == null) {
      Get.snackbar('Error', 'Please select a shipping address');
      return;
    }
    
    // Get payment method from arguments or default to stripe
    final paymentMethod = widget.paymentMethod ?? 'stripe';
    final isCOD = paymentMethod == 'cod';

    isPlacingOrder.value = true;

    try {
      // Get CheckoutController to access payment method ID and notes
      CheckoutController? checkoutController;
      int? paymentMethodId;
      String? notes;

      try {
        checkoutController = Get.find<CheckoutController>();
        if (checkoutController.selectedPaymentMethodId.value > 0) {
          paymentMethodId = checkoutController.selectedPaymentMethodId.value;
        }
        if (checkoutController.notes.value.isNotEmpty) {
          notes = checkoutController.notes.value;
        }
      } catch (e) {
        // CheckoutController not found, continue without it
      }

      // Create order first
      final orderData = {
        'shipping_address_id': address!['id'],
        'billing_address_id': address!['id'],
        'payment_method': paymentMethod,
        if (appliedCoupon != null) 'coupon_code': appliedCoupon!['code'],
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (paymentMethodId != null && paymentMethodId! > 0) 'payment_method_id': paymentMethodId,
      };

      final orderResponse = await _apiService.post(
        ApiEndpoints.ordersCreate,
        data: orderData,
      );

      final orderDataResponse = ApiService.handleResponse(orderResponse);
      final order = orderDataResponse['order'] ?? {};
      final orderId = order['id'] as int? ?? 0;

      if (orderId == 0) {
        throw Exception('Failed to create order');
      }

      // Clear coupon from CheckoutController after order creation
      if (checkoutController != null && appliedCoupon != null) {
        try {
          checkoutController.removeCoupon();
        } catch (e) {
          // Ignore error
        }
      }

      // For COD, navigate directly to order confirmation
      if (isCOD) {
        // Fetch full order details for confirmation screen
        try {
          final orderDetailsResponse = await _apiService.get(
            ApiEndpoints.orderDetails,
            queryParameters: {'id': orderId.toString()},
          );
          final orderDetailsData = ApiService.handleResponse(orderDetailsResponse);
          final fullOrder = orderDetailsData['order'] ?? order;

          Get.offNamed('/order-confirmation', arguments: fullOrder);
        } catch (e) {
          // If order details fetch fails, use basic order data
          Get.offNamed('/order-confirmation', arguments: order);
        }
      } else {
        // For Stripe and other online payments, navigate to Stripe Payment Screen
        await Get.toNamed(
          AppRoutes.stripePayment,
          arguments: {
            'order_id': orderId,
            'amount': total,
            'currency': 'usd',
          },
        );
      }

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to place order: ${ApiService.handleError(e)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    } finally {
      isPlacingOrder.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Review Order'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const LoadingWidget();
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ScreenSize.spacingMedium),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ScreenSize.isTablet
                          ? (ScreenSize.isLargeTablet ? 700 : 600)
                          : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: ScreenSize.spacingLarge),

                        // Shipping Address
                        _buildShippingAddress(),
                        SizedBox(height: ScreenSize.spacingLarge),

                        // Order Items
                        _buildOrderItems(),
                        SizedBox(height: ScreenSize.spacingLarge),

                        // Coupon Code (always visible)
                        _buildCouponCode(),
                        SizedBox(height: ScreenSize.spacingLarge),

                        // Order Summary (without button)
                        _buildOrderSummary(),
                        SizedBox(height: ScreenSize.spacingExtraLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Sticky bottom button
            _buildStickyPlaceOrderButton(),
          ],
        );
      }),
    );
  }
  
  Widget _buildHeader() {
    final paymentMethod = widget.paymentMethod ?? 'stripe';
    final isCOD = paymentMethod == 'cod';
    final paymentMethodText = isCOD ? 'Cash on Delivery' : 'Stripe Payment';
    final paymentIcon = isCOD ? Icons.money_rounded : Icons.payment_rounded;

    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ScreenSize.spacingSmall),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_cart_rounded,
                  color: AppColors.textWhite,
                  size: ScreenSize.iconLarge,
                ),
              ),
              SizedBox(width: ScreenSize.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Your Order',
                      style: TextStyle(
                        fontSize: ScreenSize.headingSmall,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(height: ScreenSize.spacingTiny),
                    Text(
                      'Please review your order details before proceeding',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        color: AppColors.textWhite.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSize.spacingMedium,
              vertical: ScreenSize.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  paymentIcon,
                  color: AppColors.textWhite,
                  size: ScreenSize.iconSmall,
                ),
                SizedBox(width: ScreenSize.spacingSmall),
                Text(
                  'Payment Method: $paymentMethodText',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: ScreenSize.iconMedium,
            ),
            SizedBox(width: ScreenSize.spacingSmall),
            Text(
              'Shipping Address',
              style: TextStyle(
                fontSize: ScreenSize.headingSmall,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: ScreenSize.spacingMedium),
        if (address == null)
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 48, color: AppColors.textTertiary),
                  SizedBox(height: ScreenSize.spacingSmall),
                  Text(
                    'No address selected',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address!['full_name'] ?? '',
                        style: TextStyle(
                          fontSize: ScreenSize.textLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (address!['is_default'] == true)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ScreenSize.spacingSmall,
                          vertical: ScreenSize.spacingTiny,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                Text(
                  '${address!['address_line1'] ?? ''}, ${address!['city'] ?? ''}, ${address!['state'] ?? ''} - ${address!['postal_code'] ?? ''}',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingExtraSmall),
                Row(
                  children: [
                    Icon(Icons.phone, size: ScreenSize.iconSmall, color: AppColors.textSecondary),
                    SizedBox(width: ScreenSize.spacingExtraSmall),
                    Text(
                      address!['phone'] ?? '',
                      style: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_bag_rounded,
              color: AppColors.primary,
              size: ScreenSize.iconMedium,
            ),
            SizedBox(width: ScreenSize.spacingSmall),
            Text(
              'Order Items',
              style: TextStyle(
                fontSize: ScreenSize.headingSmall,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: ScreenSize.spacingMedium),
        if (orderItems.isEmpty)
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textTertiary),
                  SizedBox(height: ScreenSize.spacingSmall),
                  Text(
                    'No items in order',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...orderItems.map((item) => _buildOrderItemCard(item)),
      ],
    );
  }

  Widget _buildOrderItemCard(Map<String, dynamic> item) {
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final totalPrice = price * quantity;

    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: ScreenSize.iconLarge * 1.8,
              height: ScreenSize.iconLarge * 1.8,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.network(
                item['image'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.backgroundGrey,
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.textTertiary,
                    size: ScreenSize.iconMedium,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: ScreenSize.spacingMedium),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? '',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.spacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (quantity > 1)
                          Text(
                            '× $quantity',
                            style: TextStyle(
                              fontSize: ScreenSize.textExtraSmall,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: ScreenSize.textLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCode() {
    final TextEditingController couponController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_offer_rounded,
              color: AppColors.primary,
              size: ScreenSize.iconMedium,
            ),
            SizedBox(width: ScreenSize.spacingSmall),
            Text(
              'Coupon Code',
              style: TextStyle(
                fontSize: ScreenSize.headingSmall,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: ScreenSize.spacingMedium),
        if (appliedCoupon != null)
          Container(
            margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
            padding: EdgeInsets.all(ScreenSize.spacingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.successLight,
                  AppColors.successLight.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              border: Border.all(color: AppColors.success, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: ScreenSize.iconMedium),
                ),
                SizedBox(width: ScreenSize.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coupon Applied',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(height: ScreenSize.spacingTiny),
                      Text(
                        '${appliedCoupon!['code']} • Save \$${discount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: ScreenSize.textMedium,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    // Remove coupon logic would go here
                    setState(() {
                      appliedCoupon = null;
                      discount = 0.0;
                      total = subtotal + shippingCharges + tax;
                    });
                  },
                  tooltip: 'Remove coupon',
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponController,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.spacingMedium,
                      vertical: ScreenSize.spacingMedium,
                    ),
                    prefixIcon: Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.textSecondary,
                      size: ScreenSize.iconSmall,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(ScreenSize.spacingSmall),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final code = couponController.text.trim();
                      if (code.isNotEmpty) {
                        // Apply coupon logic would go here
                        Get.snackbar(
                          'Info',
                          'Coupon feature will be implemented',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.info,
                          colorText: AppColors.textWhite,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.spacingLarge,
                        vertical: ScreenSize.spacingMedium,
                      ),
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: ScreenSize.textMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ScreenSize.spacingSmall),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryLight.withOpacity(0.2),
                      AppColors.primaryLight.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: ScreenSize.iconMedium,
                ),
              ),
              SizedBox(width: ScreenSize.spacingMedium),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: ScreenSize.headingSmall,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          _buildSummaryRow(
            'Subtotal',
            subtotal,
            icon: Icons.shopping_cart_outlined,
          ),
          if (shippingCharges > 0)
            _buildSummaryRow(
              'Shipping',
              shippingCharges,
              icon: Icons.local_shipping_outlined,
            ),
          if (tax > 0)
            _buildSummaryRow(
              'Tax',
              tax,
              icon: Icons.receipt_outlined,
            ),
          if (discount > 0)
            _buildSummaryRow(
              'Discount',
              -discount,
              isDiscount: true,
              icon: Icons.local_offer_outlined,
            ),
          SizedBox(height: ScreenSize.spacingMedium),
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.1),
                  AppColors.primaryLight.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _buildSummaryRow('Total', total, isTotal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyPlaceOrderButton() {
    return Obx(() {
      final paymentMethod = widget.paymentMethod ?? 'stripe';
      final isCOD = paymentMethod == 'cod';
      final buttonText = isPlacingOrder.value
          ? 'Placing Order...'
          : (isCOD ? 'Place Order' : 'Place Order & Pay');

      return Container(
        padding: EdgeInsets.all(ScreenSize.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total amount preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ScreenSize.headingMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ScreenSize.spacingMedium),
              // Place Order Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                  boxShadow: isPlacingOrder.value ? null : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ResponsiveButton(
                  text: buttonText,
                  onPressed: isPlacingOrder.value ? null : _handlePlaceOrder,
                  backgroundColor: AppColors.primary,
                  isLoading: isPlacingOrder.value,
                  icon: isPlacingOrder.value || isCOD
                      ? null
                      : Icon(Icons.payment_rounded, color: AppColors.textWhite, size: ScreenSize.iconSmall),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
    IconData? icon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : ScreenSize.spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null && !isTotal) ...[
                Icon(
                  icon,
                  size: ScreenSize.iconSmall,
                  color: isDiscount ? AppColors.success : AppColors.textSecondary,
                ),
                SizedBox(width: ScreenSize.spacingSmall),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? ScreenSize.textLarge : ScreenSize.textMedium,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            '${isDiscount ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? ScreenSize.headingMedium : ScreenSize.textMedium,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal
                  ? AppColors.primary
                  : (isDiscount ? AppColors.success : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
