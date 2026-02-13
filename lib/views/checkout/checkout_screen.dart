import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/checkout_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Checkout Screen
/// Complete checkout process with address, payment, and order summary
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(CheckoutController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(
            fontSize: ScreenSize.headingMedium,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: ScreenSize.iconMedium),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() => controller.isLoading.value
          ? const LoadingWidget()
          : _buildCheckoutContent(controller)),
    );
  }
  
  Widget _buildCheckoutContent(CheckoutController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ScreenSize.isTablet ? 700 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Items
              _buildOrderItems(controller),
              SizedBox(height: ScreenSize.spacingLarge),
              
              // Shipping Address
              _buildShippingAddress(controller),
              SizedBox(height: ScreenSize.spacingLarge),
              
              // Payment Method
              _buildPaymentMethod(controller),
              SizedBox(height: ScreenSize.spacingLarge),
              
              // Coupon Code
              _buildCouponCode(controller),
              SizedBox(height: ScreenSize.spacingLarge),
              
              // Order Summary
              _buildOrderSummary(controller),
              SizedBox(height: ScreenSize.spacingExtraLarge),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderItems(CheckoutController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: TextStyle(
            fontSize: ScreenSize.headingSmall,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ScreenSize.spacingSmall),
        ...controller.items.map((item) => _buildOrderItemCard(item)),
      ],
    );
  }
  
  Widget _buildOrderItemCard(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['image'] ?? '',
              width: ScreenSize.iconLarge * 1.5,
              height: ScreenSize.iconLarge * 1.5,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: ScreenSize.iconLarge * 1.5,
                height: ScreenSize.iconLarge * 1.5,
                color: AppColors.backgroundGrey,
                child: Icon(
                  Icons.image, 
                  color: AppColors.textTertiary,
                  size: ScreenSize.iconMedium,
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
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ScreenSize.spacingExtraSmall),
                Text(
                  'Qty: ${item['quantity']}',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item['size'] != null || item['color'] != null)
                  Text(
                    '${item['size'] ?? ''}${item['size'] != null && item['color'] != null ? ', ' : ''}${item['color'] ?? ''}',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          
          // Price
          Text(
            '\$${item['item_total'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: ScreenSize.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShippingAddress(CheckoutController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shipping Address',
              style: TextStyle(
                fontSize: ScreenSize.headingSmall,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => AppRoutes.toAddAddress(),
              child: Text(
                'Add New',
                style: TextStyle(fontSize: ScreenSize.textMedium),
              ),
            ),
          ],
        ),
        SizedBox(height: ScreenSize.spacingSmall),
        if (controller.addresses.isEmpty)
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.location_on_outlined, size: 48, color: AppColors.textTertiary),
                SizedBox(height: ScreenSize.spacingSmall),
                Text(
                  'No address found',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                ElevatedButton(
                  onPressed: () => AppRoutes.toAddAddress(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.spacingMedium,
                      vertical: ScreenSize.spacingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                    ),
                  ),
                  child: Text(
                    'Add Address',
                    style: TextStyle(fontSize: ScreenSize.textMedium),
                  ),
                ),
              ],
            ),
          )
        else
          ...controller.addresses.map((address) => Obx(() => _buildAddressCard(
            address,
            controller,
            controller.selectedAddressId.value == address['id'],
          ))),
      ],
    );
  }
  
  Widget _buildAddressCard(Map<String, dynamic> address, CheckoutController controller, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.selectAddress(address['id'] as int),
      child: Container(
        margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
        padding: EdgeInsets.all(ScreenSize.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Radio<int>(
              value: address['id'] as int,
              groupValue: controller.selectedAddressId.value,
              onChanged: (value) => controller.selectAddress(value!),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address['full_name'] ?? '',
                          style: TextStyle(
                            fontSize: ScreenSize.textMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (address['is_default'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  SizedBox(height: ScreenSize.spacingExtraSmall),
                  Text(
                    '${address['address_line1'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['postal_code'] ?? ''}',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingExtraSmall),
                  Text(
                    address['phone'] ?? '',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentMethod(CheckoutController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: ScreenSize.headingSmall,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            // TextButton(
            //   onPressed: () => AppRoutes.toAddPaymentMethod(),
            //   child: Text(
            //     'Add New',
            //     style: TextStyle(fontSize: ScreenSize.textMedium),
            //   ),
            // ),
          ],
        ),
        SizedBox(height: ScreenSize.spacingSmall),
        if (controller.paymentMethods.isEmpty)
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.payment_outlined, size: 48, color: AppColors.textTertiary),
                SizedBox(height: ScreenSize.spacingSmall),
                Text(
                  'No payment method found',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                ElevatedButton(
                  onPressed: () => AppRoutes.toAddPaymentMethod(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.spacingMedium,
                      vertical: ScreenSize.spacingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                    ),
                  ),
                  child: Text(
                    'Add Payment Method',
                    style: TextStyle(fontSize: ScreenSize.textMedium),
                  ),
                ),
              ],
            ),
          )
        else
          ...controller.paymentMethods.map((method) => Obx(() => _buildPaymentMethodCard(
            method,
            controller,
            controller.selectedPaymentMethodId.value == method['id'],
          ))),
      ],
    );
  }
  
  Widget _buildPaymentMethodCard(Map<String, dynamic> method, CheckoutController controller, bool isSelected) {
    String displayText = '';
    IconData icon = Icons.payment;
    
    switch (method['type']) {
      case 'card':
        displayText = '${method['provider'] ?? 'Card'} •••• ${method['card_number'] ?? ''}';
        icon = Icons.credit_card;
        break;
      case 'stripe': // Added for Stripe Payment Sheet
        displayText = 'Pay with Stripe (Cards, Wallets)';
        icon = Icons.payment;
        break;
      case 'upi':
        displayText = 'UPI: ${method['upi_id'] ?? ''}';
        icon = Icons.account_balance_wallet;
        break;
      case 'wallet':
        displayText = '${method['wallet_type'] ?? 'Wallet'}';
        icon = Icons.account_balance_wallet;
        break;
      case 'netbanking':
        displayText = 'Net Banking: ${method['account_number'] ?? ''}';
        icon = Icons.account_balance;
        break;
      case 'cod':
        displayText = 'Cash on Delivery';
        icon = Icons.money;
        break;
    }
    
    return GestureDetector(
      onTap: () => controller.selectPaymentMethod(method['id'] as int),
      child: Container(
        margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
        padding: EdgeInsets.all(ScreenSize.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Radio<int>(
              value: method['id'] as int,
              groupValue: controller.selectedPaymentMethodId.value,
              onChanged: (value) => controller.selectPaymentMethod(value!),
              activeColor: AppColors.primary,
            ),
            Icon(icon, color: AppColors.primary),
            SizedBox(width: ScreenSize.spacingSmall),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (method['is_default'] == true)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }
  
  Widget _buildCouponCode(CheckoutController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coupon Code',
          style: TextStyle(
            fontSize: ScreenSize.headingSmall,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ScreenSize.spacingSmall),
        
        // Available Coupons Suggestions
        Obx(() => controller.availableCoupons.isNotEmpty && controller.appliedCoupon.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Coupons',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  SizedBox(
                    height: ScreenSize.iconLarge * 2.5,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.availableCoupons.length,
                      itemBuilder: (context, index) {
                        final coupon = controller.availableCoupons[index];
                        return _buildCouponSuggestionCard(coupon, controller);
                      },
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingMedium),
                ],
              )
            : const SizedBox.shrink()),
        
        // Coupon Input or Applied Coupon
        Obx(() => controller.appliedCoupon.isEmpty
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: ScreenSize.spacingMedium,
                          vertical: 0.0, // Changed from ScreenSize.spacingSmall
                        ),
                      ),
                      onChanged: (value) => controller.couponCode.value = value,
                    ),
                  ),
                  SizedBox(width: ScreenSize.spacingSmall),
                  ElevatedButton(
                    onPressed: () => controller.applyCoupon(controller.couponCode.value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.spacingMedium,
                        vertical: ScreenSize.spacingSmall,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: TextStyle(fontSize: ScreenSize.textMedium),
                    ),
                  ),
                ],
              )
            : Container(
                padding: EdgeInsets.all(ScreenSize.spacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: ScreenSize.spacingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coupon Applied: ${controller.appliedCoupon['code']}',
                            style: TextStyle(
                              fontSize: ScreenSize.textMedium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            'Discount: \$${controller.discount.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: ScreenSize.textSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => controller.removeCoupon(),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
  
  Widget _buildCouponSuggestionCard(Map<String, dynamic> coupon, CheckoutController controller) {
    return GestureDetector(
      onTap: () {
        controller.couponCode.value = coupon['code'] as String;
        controller.applyCoupon(coupon['code'] as String);
      },
      child: Container(
        width: ScreenSize.isLargeTablet ? ScreenSize.widthPercent(25) : 
               (ScreenSize.isSmallTablet ? ScreenSize.widthPercent(30) : ScreenSize.widthPercent(40)),
        margin: EdgeInsets.only(right: ScreenSize.spacingSmall),
        padding: EdgeInsets.all(ScreenSize.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          border: Border.all(color: AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Take only the space needed
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: AppColors.primary, size: 20),
                SizedBox(width: ScreenSize.spacingSmall),
                Flexible(
                  child: Text(
                    coupon['code'] as String,
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Flexible(
              child: Text(
                coupon['description'] as String? ?? '',
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              'Save \$${(coupon['discount'] is int ? (coupon['discount'] as int).toDouble() : (coupon['discount'] as double? ?? 0.0)).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderSummary(CheckoutController controller) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: ScreenSize.headingSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          Obx(() => _buildSummaryRow('Subtotal', controller.subtotal.value)),
          Obx(() => _buildSummaryRow('Shipping', controller.shippingCharges.value)),
          Obx(() => _buildSummaryRow('Tax', controller.tax.value)),
          Obx(() => controller.discount.value > 0
              ? _buildSummaryRow('Discount', -controller.discount.value, isDiscount: true)
              : const SizedBox.shrink()),
          Divider(height: ScreenSize.spacingLarge),
          Obx(() => _buildSummaryRow(
            'Total',
            controller.total.value,
            isTotal: true,
          )),
          SizedBox(height: ScreenSize.spacingLarge),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isPlacingOrder.value
                  ? null
                  : () => _handlePlaceOrder(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                ),
              ),
              child: controller.isPlacingOrder.value
                  ? SizedBox(
                      height: ScreenSize.iconSmall,
                      width: ScreenSize.iconSmall,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: ScreenSize.textLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? ScreenSize.textLarge : ScreenSize.textMedium,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? ScreenSize.headingSmall : ScreenSize.textMedium,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handlePlaceOrder(CheckoutController controller) async {
    final order = await controller.placeOrder();
    if (order != null) {
      // Navigate to order confirmation
      // Use offNamed to replace checkout screen but keep navigation stack
      // This allows back button to work properly from order confirmation
      Get.offNamed('/order-confirmation', arguments: order);
    }
  }
}

