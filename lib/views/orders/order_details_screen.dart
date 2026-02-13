import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';

/// Order Details Screen
/// Shows complete order information including items, address, payment, etc.
class OrderDetailsScreen extends StatelessWidget {
  final int orderId;
  
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    print('[OrderDetailsScreen] Building with orderId: $orderId');
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: controller.getOrderDetails(orderId),
        builder: (context, snapshot) {
          print('[OrderDetailsScreen] FutureBuilder state: ${snapshot.connectionState}');
          print('[OrderDetailsScreen] Has error: ${snapshot.hasError}');
          print('[OrderDetailsScreen] Has data: ${snapshot.hasData}');
          if (snapshot.hasError) {
            print('[OrderDetailsScreen] Error: ${snapshot.error}');
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('[OrderDetailsScreen] Showing loading widget');
            return const LoadingWidget();
          }
          
          if (snapshot.hasError || snapshot.data == null) {
            print('[OrderDetailsScreen] Showing error state');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ScreenSize.iconExtraLarge * 2,
                    color: AppColors.error,
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  Text(
                    'Failed to load order details',
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingMedium),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.buttonPaddingHorizontal,
                        vertical: ScreenSize.buttonPaddingVertical,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                      ),
                    ),
                    child: Text('Go Back', style: TextStyle(fontSize: ScreenSize.textMedium)),
                  ),
                ],
              ),
            );
          }
          
          final order = snapshot.data!;
          print('[OrderDetailsScreen] Order loaded: ${order['id']}, items: ${(order['items'] as List?)?.length ?? 0}');
          
          final items = order['items'] as List? ?? [];
          final shippingAddress = order['shipping_address'] as Map<String, dynamic>?;
          final billingAddress = order['billing_address'] as Map<String, dynamic>?;
          final status = (order['status'] ?? 'pending').toString().toLowerCase();
          
          print('[OrderDetailsScreen] Building order details UI');
          return SingleChildScrollView(
            padding: EdgeInsets.all(ScreenSize.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header Card
                _buildOrderHeaderCard(order, status),
                
                SizedBox(height: ScreenSize.spacingMedium),
                
                // Order Items
                if (items.isNotEmpty) ...[
                  _buildSectionTitle('Order Items'),
                  SizedBox(height: ScreenSize.spacingSmall),
                  _buildOrderItems(items),
                  SizedBox(height: ScreenSize.spacingMedium),
                ],
                
                // Shipping Address
                if (shippingAddress != null) ...[
                  _buildSectionTitle('Shipping Address'),
                  SizedBox(height: ScreenSize.spacingSmall),
                  _buildAddressCard(shippingAddress, 'Shipping'),
                  SizedBox(height: ScreenSize.spacingMedium),
                ],
                
                // Billing Address (if different)
                if (billingAddress != null && billingAddress != shippingAddress) ...[
                  _buildSectionTitle('Billing Address'),
                  SizedBox(height: ScreenSize.spacingSmall),
                  _buildAddressCard(billingAddress, 'Billing'),
                  SizedBox(height: ScreenSize.spacingMedium),
                ],
                
                // Payment Information
                _buildSectionTitle('Payment Information'),
                SizedBox(height: ScreenSize.spacingSmall),
                _buildPaymentCard(order),
                
                SizedBox(height: ScreenSize.spacingMedium),
                
                // Order Summary
                _buildSectionTitle('Order Summary'),
                SizedBox(height: ScreenSize.spacingSmall),
                _buildOrderSummary(order),
                
                SizedBox(height: ScreenSize.spacingLarge),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildOrderHeaderCard(Map<String, dynamic> order, String status) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Order #${order['order_number'] ?? order['id']}',
                  style: TextStyle(
                    fontSize: ScreenSize.headingMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: ScreenSize.spacingSmall),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.spacingSmall,
                  vertical: ScreenSize.spacingExtraSmall,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                  border: Border.all(
                    color: _getStatusColor(status),
                    width: 1,
                  ),
                ),
                child: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'Placed on: ${_formatDate(order['created_at'])}',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
          if (order['tracking_number'] != null) ...[
            SizedBox(height: ScreenSize.spacingSmall),
            Row(
              children: [
                Icon(Icons.local_shipping, size: ScreenSize.iconSmall, color: AppColors.primary),
                SizedBox(width: ScreenSize.spacingSmall),
                Expanded(
                  child: Text(
                    'Tracking: ${order['tracking_number']}',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ScreenSize.textLarge,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
  
  Widget _buildOrderItems(List items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final isLast = index == items.length - 1;
          
          return Container(
            padding: EdgeInsets.all(ScreenSize.spacingMedium),
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                  child: CachedNetworkImage(
                    imageUrl: item['image'] ?? '',
                    width: ScreenSize.widthPercent(12),
                    height: ScreenSize.widthPercent(12),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: ScreenSize.widthPercent(12),
                      height: ScreenSize.widthPercent(12),
                      color: AppColors.backgroundGrey,
                      child: Icon(Icons.image, color: AppColors.textSecondary, size: ScreenSize.iconMedium),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: ScreenSize.widthPercent(12),
                      height: ScreenSize.widthPercent(12),
                      color: AppColors.backgroundGrey,
                      child: Icon(Icons.image, color: AppColors.textSecondary, size: ScreenSize.iconMedium),
                    ),
                  ),
                ),
                SizedBox(width: ScreenSize.spacingMedium),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'] ?? 'Product',
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
                        'Qty: ${item['quantity']} × \$${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Total
                Text(
                  '\$${item['total']?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildAddressCard(Map<String, dynamic> address, String type) {
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
          Row(
            children: [
              Icon(
                type == 'Shipping' ? Icons.local_shipping : Icons.payment,
                size: ScreenSize.iconSmall,
                color: AppColors.primary,
              ),
              SizedBox(width: ScreenSize.spacingSmall),
              Text(
                '$type Address',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            address['name'] ?? '',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (address['phone'] != null) ...[
            SizedBox(height: ScreenSize.spacingExtraSmall),
            Text(
              address['phone'],
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: ScreenSize.spacingExtraSmall),
          Text(
            '${address['address_line1'] ?? ''}${address['address_line2'] != null && address['address_line2'].toString().isNotEmpty ? ', ${address['address_line2']}' : ''}',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['pincode'] ?? ''}',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentCard(Map<String, dynamic> order) {
    final paymentMethod = order['payment_method'] ?? 'cash_on_delivery';
    final paymentStatus = (order['payment_status'] ?? 'pending').toString().toLowerCase();
    final paymentDetails = order['payment_method_details'] as Map<String, dynamic>?;
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.spacingSmall,
                  vertical: ScreenSize.spacingExtraSmall,
                ),
                decoration: BoxDecoration(
                  color: paymentStatus == 'paid' 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                ),
                child: Text(
                  _formatStatus(paymentStatus),
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    fontWeight: FontWeight.w600,
                    color: paymentStatus == 'paid' 
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            _formatPaymentMethod(paymentMethod),
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
          if (paymentDetails != null) ...[
            SizedBox(height: ScreenSize.spacingSmall),
            if (paymentDetails['card_last_4'] != null)
              Text(
                'Card ending in ${paymentDetails['card_last_4']}',
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  color: AppColors.textTertiary,
                ),
              ),
            if (paymentDetails['upi_id'] != null)
              Text(
                'UPI: ${paymentDetails['upi_id']}',
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildOrderSummary(Map<String, dynamic> order) {
    final subtotal = _parseDouble(order['subtotal'] ?? 0.0);
    final shipping = _parseDouble(order['shipping_amount'] ?? 0.0);
    final tax = _parseDouble(order['tax_amount'] ?? 0.0);
    final discount = _parseDouble(order['discount_amount'] ?? 0.0);
    final total = _parseDouble(order['total_amount'] ?? 0.0);
    
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal),
          if (shipping > 0) _buildSummaryRow('Shipping', shipping),
          if (tax > 0) _buildSummaryRow('Tax', tax),
          if (discount > 0) _buildSummaryRow('Discount', -discount, isDiscount: true),
          Divider(height: ScreenSize.spacingLarge),
          _buildSummaryRow('Total', total, isTotal: true),
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
              fontSize: isTotal ? ScreenSize.textLarge : ScreenSize.textMedium,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
  
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'upi':
        return 'UPI';
      case 'wallet':
        return 'Digital Wallet';
      case 'net_banking':
        return 'Net Banking';
      default:
        return method.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

