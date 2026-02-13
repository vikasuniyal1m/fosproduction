import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/order_reason_dialog.dart';
import '../../routes/app_routes.dart';

/// Orders Screen
/// Shows user's order history
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    // Load orders when screen is opened (always refresh to get latest orders)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isLoadingOrders.value) {
        controller.loadOrders();
      }
    });
    
    return PopScope(
      // Handle Android back button
      // Always go to home when back is pressed (common e-commerce behavior)
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Navigate to home page (common e-commerce behavior)
          Get.offAllNamed(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'My Orders',
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
            onPressed: () => Get.offAllNamed(AppRoutes.home),
          ),
        ),
        body: Obx(() {
          if (controller.isLoadingOrders.value) {
            return const LoadingWidget();
          }
          
          if (controller.orders.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: controller.loadOrders,
            child: Obx(() => ListView.builder(
              key: ValueKey('orders_${controller.orders.length}_${controller.orders.map((o) => '${o['id']}_${o['status']}').join('_')}'), // Force rebuild when orders change
              padding: EdgeInsets.all(ScreenSize.spacingMedium),
              itemCount: controller.orders.length,
              itemBuilder: (context, index) {
                final order = controller.orders[index];
                return _buildOrderCard(order, controller);
              },
            )),
          );
        }),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: ScreenSize.iconExtraLarge * 2,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'Start shopping to see your orders here',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order, ProfileController controller) {
    // Ensure status is lowercase for comparison
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final statusColor = _getStatusColor(status);
    
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
                Container(
                  padding: EdgeInsets.all(ScreenSize.spacingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ScreenSize.tileBorderRadius),
                      topRight: Radius.circular(ScreenSize.tileBorderRadius),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Order #${order['order_number'] ?? order['id']}',
                                  style: TextStyle(
                                    fontSize: ScreenSize.textLarge,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: ScreenSize.spacingExtraSmall),
                                Text(
                                  order['created_at'] ?? '',
                                  style: TextStyle(
                                    fontSize: ScreenSize.textSmall,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: ScreenSize.spacingSmall),
                          Flexible(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ScreenSize.spacingSmall,
                                vertical: ScreenSize.spacingExtraSmall,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: ScreenSize.spacingExtraSmall),
                                  Flexible(
                                    child: Text(
                                      _formatStatus(status),
                                      style: TextStyle(
                                        fontSize: ScreenSize.textSmall,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ScreenSize.spacingSmall),
                      _buildDetailRow('Payment Status', _formatPaymentStatus(order['payment_status'] ?? 'pending')),
                    ],
                  ),
                ),
          
          // Order Items
          Padding(
            padding: EdgeInsets.all(ScreenSize.spacingMedium),
            child: Column(
              children: [
                // First item preview
                if (order['items'] != null && (order['items'] as List).isNotEmpty)
                  _buildOrderItemPreview(order['items'][0]),
                
                // Total
                Padding(
                  padding: EdgeInsets.only(top: ScreenSize.spacingMedium),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: ScreenSize.textLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '\$${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            fontSize: ScreenSize.headingSmall,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingMedium),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final orderId = order['id'];
                          print('[OrdersScreen] View Details clicked for order: $orderId (type: ${orderId.runtimeType})');
                          controller.viewOrderDetails(orderId);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingSmall),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                          ),
                        ),
                        child: Text('View Details', style: TextStyle(fontSize: ScreenSize.textMedium)),
                      ),
                    ),
                    SizedBox(width: ScreenSize.spacingSmall),
                    if (status != 'cancelled' && status != 'pending')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.toNamed('/order-tracking', arguments: order['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingSmall),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                            ),
                          ),
                          icon: Icon(Icons.local_shipping, size: ScreenSize.iconSmall),
                          label: Text('Track', style: TextStyle(fontSize: ScreenSize.textMedium)),
                        ),
                      ),
                  ],
                ),
                // Cancel button (for pending, confirmed, processing orders)
                // Use lowercase comparison
                if (status == 'pending' || status == 'confirmed' || status == 'processing') ...[
                  SizedBox(height: ScreenSize.spacingSmall),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(controller, order['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingSmall),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                        ),
                      ),
                      icon: Icon(Icons.cancel_outlined, size: ScreenSize.iconSmall),
                      label: Text('Cancel Order', style: TextStyle(fontSize: ScreenSize.textMedium)),
                    ),
                  ),
                ],
                
                // Return button (for delivered orders)
                if (status == 'delivered') ...[
                  SizedBox(height: ScreenSize.spacingSmall),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReturnDialog(controller, order['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: BorderSide(color: AppColors.warning),
                        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingSmall),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                        ),
                      ),
                      icon: Icon(Icons.assignment_return, size: ScreenSize.iconSmall),
                      label: Text('Return Order', style: TextStyle(fontSize: ScreenSize.textMedium)),
                    ),
                  ),
                ],
                
                // Reorder and Invoice buttons (for delivered or shipped orders)
                if (status == 'delivered' || status == 'shipped') ...[
                  SizedBox(height: ScreenSize.spacingSmall),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.reorder(order['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingSmall),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                            ),
                          ),
                          icon: Icon(Icons.shopping_cart, size: ScreenSize.iconSmall),
                          label: Text('Reorder', style: TextStyle(fontSize: ScreenSize.textMedium)),
                        ),
                      ),
                      SizedBox(width: ScreenSize.spacingSmall),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.downloadInvoice(order['id'] as int),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingSmall),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                            ),
                          ),
                          icon: Icon(Icons.download, size: ScreenSize.iconSmall),
                          label: Text('Invoice', style: TextStyle(fontSize: ScreenSize.textMedium)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderItemPreview(Map<String, dynamic> item) {
    final imageSize = ScreenSize.widthPercent(15);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          child: CachedNetworkImage(
            imageUrl: item['image'] ?? '',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: imageSize,
              height: imageSize,
              color: AppColors.backgroundGrey,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              width: imageSize,
              height: imageSize,
              color: AppColors.backgroundGrey,
              child: Icon(Icons.image_not_supported, color: AppColors.textTertiary, size: ScreenSize.iconMedium),
            ),
          ),
        ),
        SizedBox(width: ScreenSize.spacingMedium),
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
                'Qty: ${item['quantity'] ?? 1} × \$${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ScreenSize.textMedium,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? ScreenSize.textLarge : ScreenSize.textMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.info;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
  
  String _formatStatus(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  String _formatPaymentStatus(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  void _showCancelDialog(ProfileController controller, dynamic orderId) {
    // Ensure orderId is an int
    final intOrderId = orderId is int ? orderId : (orderId is String ? int.tryParse(orderId) : int.tryParse(orderId.toString()));
    
    if (intOrderId == null || intOrderId <= 0) {
      Get.snackbar('Error', 'Invalid order ID');
      return;
    }
    
    final cancelReasons = [
      'Changed my mind',
      'Found better price elsewhere',
      'Item no longer needed',
      'Wrong item ordered',
      'Payment issue',
      'Other',
    ];
    
    Get.dialog(
      OrderReasonDialog(
        title: 'Cancel Order',
        hintText: 'Please provide a reason for cancellation',
        predefinedReasons: cancelReasons,
        isReturn: false,
      ),
    ).then((reason) {
      print('[Orders Screen] Dialog closed with reason: $reason');
      if (reason != null && reason is String && reason.isNotEmpty) {
        print('[Orders Screen] Calling cancelOrder with ID: $intOrderId, Reason: $reason');
        controller.cancelOrder(intOrderId, reason);
      } else {
        print('[Orders Screen] No reason provided, not cancelling');
      }
    });
  }
  
  void _showReturnDialog(ProfileController controller, dynamic orderId) {
    // Ensure orderId is an int
    final intOrderId = orderId is int ? orderId : (orderId is String ? int.tryParse(orderId) : int.tryParse(orderId.toString()));
    
    if (intOrderId == null || intOrderId <= 0) {
      Get.snackbar('Error', 'Invalid order ID');
      return;
    }
    
    final returnReasons = [
      'Defective/Damaged item',
      'Wrong item received',
      'Item not as described',
      'Size/Color mismatch',
      'Changed my mind',
      'Other',
    ];
    
    Get.dialog(
      OrderReasonDialog(
        title: 'Return Order',
        hintText: 'Please provide a reason for return',
        predefinedReasons: returnReasons,
        isReturn: true,
      ),
    ).then((reason) {
      if (reason != null && reason is String) {
        controller.returnOrder(intOrderId, reason);
      }
    });
  }
}


