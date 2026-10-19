import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/product_grid_card.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../services/notification_service.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/silent_loading.dart';
import '../../widgets/order_reason_dialog.dart';
import '../../routes/app_routes.dart';
import '../../utils/digital_product_type.dart';
import '../../watch_faces/watch_face_order_helper.dart';

/// Shows user's order history
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    // Try to get HomeController, but don't crash if not found
    HomeController? homeController;
    try {
      homeController = Get.find<HomeController>();
    } catch (e) {
      homeController = null;
    }
    
    // Debug notification count
    if (homeController != null) {
      print('[OrdersScreen] Build - Notification count: ${homeController.notificationCount.value}');
      print('[OrdersScreen] Build - Should show badge: ${homeController.notificationCount.value > 0}');
    }
    
    // Load orders when screen is opened (always refresh to get latest orders)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadOrders(silent: true);
      
      // Force notification count refresh
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = Get.find<NotificationService>();
        notificationService.refreshUnreadCount();
        print('[OrdersScreen] Forced notification refresh');
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
            style: TextStyle(fontSize: ScreenSize.headingSmall),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: ScreenSize.screenWidth >= 1000 ? ScreenSize.buttonHeightLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.buttonHeightMedium : ScreenSize.buttonHeightLarge),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, 
                      size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
            onPressed: () => Get.offAllNamed(AppRoutes.home),
          ),
          actions: [
            // Notification Badge
            if (homeController != null)
              Obx(() {
                final notificationCount = homeController!.notificationCount.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_none_outlined,
                                size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                      onPressed: () => Get.toNamed(AppRoutes.notifications),
                    ),
                    // Notification Badge
                    if (notificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              })
            else
              IconButton(
                icon: Icon(Icons.notifications_none_outlined,
                          size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                onPressed: () => Get.toNamed(AppRoutes.notifications),
              ),
            if (controller.orders.isNotEmpty)
              IconButton(
                icon: Icon(Icons.refresh, 
                          size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                onPressed: () => controller.loadOrders(silent: true),
              ),
          ],
        ),
        body: Obx(() {
          if (SilentLoading.blockUi(
            isLoading: controller.isLoadingOrders.value,
            hasContent: controller.hasEverLoadedOrders.value ||
                controller.orders.isNotEmpty,
          )) {
            return const LoadingWidget();
          }
          
          if (controller.orders.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () => controller.loadOrders(silent: true),
            child: Obx(() => ListView.builder(
              key: ValueKey('orders_${controller.orders.length}_${controller.orders.map((o) => '${o['id']}_${o['status']}').join('_')}'), // Force rebuild when orders change
              padding: EdgeInsets.all(ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall : ScreenSize.spacingMedium))),
              itemCount: controller.orders
                  .where(WatchFaceOrderHelper.isWatchFaceOrderForCurrentPlatform)
                  .length,
              itemBuilder: (context, index) {
                final visibleOrders = controller.orders
                    .where(WatchFaceOrderHelper.isWatchFaceOrderForCurrentPlatform)
                    .toList();
                final order = visibleOrders[index];
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
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ScreenSize.screenWidth >= 1200 ? ScreenSize.paddingLarge : (ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.paddingMedium : ScreenSize.paddingLarge))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ScreenSize.screenWidth >= 1200 ? 36 : (ScreenSize.screenWidth >= 1000 ? 32 : (ScreenSize.screenWidth >= 768 ? 28 : 24))),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: ScreenSize.screenWidth >= 1200 ? ScreenSize.iconExtraLarge * 2.4 : (ScreenSize.screenWidth >= 1000 ? ScreenSize.iconExtraLarge * 2.2 : (ScreenSize.screenWidth >= 768 ? ScreenSize.iconExtraLarge * 2 : ScreenSize.iconExtraLarge * 2)),
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingLarge))),
            Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.headingExtraLarge : (ScreenSize.screenWidth >= 1000 ? ScreenSize.headingExtraLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.headingLarge : ScreenSize.headingMedium)),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              'Start shopping to see your orders here',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium)),
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingLarge))),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed('/home'),
              icon: Icon(Icons.shopping_cart_outlined, 
                       size: ScreenSize.screenWidth >= 1200 ? 24 : (ScreenSize.screenWidth >= 1000 ? 22 : (ScreenSize.screenWidth >= 768 ? 20 : 20))),
              label: Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingLarge)),
                  vertical: ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1200 ? 28 : (ScreenSize.screenWidth >= 1000 ? 26 : (ScreenSize.screenWidth >= 768 ? 24 : 25))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order, ProfileController controller) {
    final items = order['items'] as List? ?? [];
    final hasPhysicalItems = DigitalProductType.hasPhysicalItemsInOrder(
      order,
      items: items,
    );
    final isWatchFaceOrder = order['is_watch_face_order'] == true ||
        WatchFaceOrderHelper.isWatchFaceOrder(order, items: items);
    final isDigitalOrder = DigitalProductType.isDigitalOrder(
      order,
      items: items,
    );
    final statusBadge = DigitalProductType.orderFulfillmentBadge(
      order,
      hasPhysicalItems: hasPhysicalItems,
      items: items,
    );
    final status = DigitalProductType.displayOrderStatus(
      order,
      items: items,
    );
    final statusColor = _getStatusColor(status);
    final isWatchFacePaid =
        isWatchFaceOrder && WatchFaceOrderHelper.isOrderPaid(order);
    
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall))),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.5), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall)), 
              ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall)), 
              ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall)), 
              ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingTiny : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingTiny : (ScreenSize.screenWidth >= 768 ? 2 : ScreenSize.spacingTiny))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order['order_number'] ?? order['id']}',
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textSmall)),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ScreenSize.screenWidth >= 1200 ? 2 : (ScreenSize.screenWidth >= 1000 ? 2 : (ScreenSize.screenWidth >= 768 ? 1 : 2))),
                      Text(
                        order['created_at'] ?? '',
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall)),
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                      if (isWatchFaceOrder) ...[
                        SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.secondary.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.watch, size: 12, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'Watch Face',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (statusBadge.show)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.screenWidth >= 1200 ? 10 : (ScreenSize.screenWidth >= 1000 ? 10 : (ScreenSize.screenWidth >= 768 ? 8 : 10)), 
                      vertical: ScreenSize.screenWidth >= 1200 ? 6 : (ScreenSize.screenWidth >= 1000 ? 6 : (ScreenSize.screenWidth >= 768 ? 4 : 6))
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1200 ? 12 : (ScreenSize.screenWidth >= 1000 ? 12 : (ScreenSize.screenWidth >= 768 ? 10 : 12))),
                      border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: TextStyle(
                        fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall)),
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          Divider(height: 1, color: AppColors.border.withOpacity(0.3)),
          
          // Order Items Preview
          Padding(
            padding: EdgeInsets.all(ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall))),
            child: Column(
              children: [
                if (order['items'] != null && (order['items'] as List).isNotEmpty)
                  _buildOrderItemPreview(order['items'][0]),
                
                if (order['items'] != null && (order['items'] as List).length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: ScreenSize.screenWidth >= 1200 ? 4 : (ScreenSize.screenWidth >= 1000 ? 4 : (ScreenSize.screenWidth >= 768 ? 2 : 4))),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+ ${(order['items'] as List).length - 1} more items',
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall)),
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                
                SizedBox(height: ScreenSize.screenWidth >= 1200 ? 6 : (ScreenSize.screenWidth >= 1000 ? 6 : (ScreenSize.screenWidth >= 768 ? 4 : 6))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall)),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textSmall)),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.fromLTRB(
              ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall)), 
              0, 
              ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall)), 
              ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall))
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactButton(
                    label: 'Details',
                    onPressed: () => controller.viewOrderDetails(order['id']),
                    isPrimary: false,
                  ),
                ),
                SizedBox(width: ScreenSize.screenWidth >= 1200 ? 6 : (ScreenSize.screenWidth >= 1000 ? 6 : (ScreenSize.screenWidth >= 768 ? 4 : 6))),
                if (hasPhysicalItems &&
                    status != 'cancelled' &&
                    status != 'pending')
                  Expanded(
                    child: _buildCompactButton(
                      label: 'Track',
                      icon: Icons.local_shipping,
                      onPressed: () => Get.toNamed('/order-tracking', arguments: order['id']),
                      isPrimary: true,
                    ),
                  )
                else if (isWatchFacePaid)
                  Expanded(
                    child: _buildCompactButton(
                      label: 'Install',
                      icon: Icons.watch,
                      onPressed: () {
                        final firstItem = items.isNotEmpty && items.first is Map
                            ? Map<String, dynamic>.from(items.first as Map)
                            : <String, dynamic>{};
                        WatchFaceOrderHelper.installFromOrder(order, firstItem);
                      },
                      isPrimary: true,
                      color: AppColors.secondary,
                    ),
                  )
                else if (!isDigitalOrder &&
                    DigitalProductType.canCancelOrder(order, items: items))
                  Expanded(
                    child: _buildCompactButton(
                      label: 'Cancel',
                      onPressed: () => _showCancelDialog(controller, order['id']),
                      isPrimary: true,
                      color: AppColors.error,
                    ),
                  )
                else if (hasPhysicalItems && status == 'delivered')
                  Expanded(
                    child: _buildCompactButton(
                      label: 'Reorder',
                      onPressed: () => controller.reorder(order['id']),
                      isPrimary: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isPrimary = true,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.primary;
    return SizedBox(
      height: ScreenSize.screenWidth >= 1200 ? 36 : (ScreenSize.screenWidth >= 1000 ? 36 : (ScreenSize.screenWidth >= 768 ? 32 : 32)),
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon != null ? Icon(icon, size: ScreenSize.screenWidth >= 1200 ? 16 : (ScreenSize.screenWidth >= 1000 ? 16 : (ScreenSize.screenWidth >= 768 ? 14 : 16))) : const SizedBox.shrink(),
              label: Text(label, style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall)), 
                fontWeight: FontWeight.w600
              )),
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveColor,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1200 ? 10 : (ScreenSize.screenWidth >= 1000 ? 10 : (ScreenSize.screenWidth >= 768 ? 8 : 10)))),
                padding: EdgeInsets.zero,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: icon != null ? Icon(icon, size: ScreenSize.screenWidth >= 1200 ? 16 : (ScreenSize.screenWidth >= 1000 ? 16 : (ScreenSize.screenWidth >= 768 ? 14 : 16))) : const SizedBox.shrink(),
              label: Text(label, style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall)), 
                fontWeight: FontWeight.w600
              )),
              style: OutlinedButton.styleFrom(
                foregroundColor: effectiveColor,
                side: BorderSide(color: effectiveColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1200 ? 10 : (ScreenSize.screenWidth >= 1000 ? 10 : (ScreenSize.screenWidth >= 768 ? 8 : 10)))),
                padding: EdgeInsets.zero,
              ),
            ),
    );
  }
  
  Widget _buildOrderItemPreview(Map<String, dynamic> item) {
    final imageSize = ScreenSize.screenWidth >= 1200 ? 56.0 : (ScreenSize.screenWidth >= 1000 ? 56.0 : (ScreenSize.screenWidth >= 768 ? 48.0 : 48.0));
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1200 ? 12 : (ScreenSize.screenWidth >= 1000 ? 12 : (ScreenSize.screenWidth >= 768 ? 10 : 12))),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1200 ? 12 : (ScreenSize.screenWidth >= 1000 ? 12 : (ScreenSize.screenWidth >= 768 ? 10 : 12))),
            child: _orderPreviewImage(item, imageSize),
          ),
        ),
        SizedBox(width: ScreenSize.screenWidth >= 1200 ? 8 : (ScreenSize.screenWidth >= 1000 ? 8 : (ScreenSize.screenWidth >= 768 ? 6 : 8))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['product_name'] ?? '',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall)),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ScreenSize.screenWidth >= 1200 ? 2 : (ScreenSize.screenWidth >= 1000 ? 2 : (ScreenSize.screenWidth >= 768 ? 1 : 2))),
              Text(
                'Qty: ${item['quantity'] ?? 1} • \$${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall)),
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orderPreviewImage(Map<String, dynamic> item, double imageSize) {
    if (item['watch_face_preview'] != null) {
      return WatchFaceOrderHelper.buildPreviewImage(
        item,
        size: imageSize,
        cacheKeyPrefix: 'order_preview',
      );
    }
    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: ProductCardImage(
        product: {
          'id': item['product_id'] ?? item['id'],
          'image': item['image'],
          'banner': item['banner'],
          'is_digital': item['is_digital'],
          'category_id': item['category_id'],
          'media_type': item['media_type'],
          'is_sticker_pack': item['is_sticker_pack'],
        },
        cacheKeyPrefix: 'order_preview',
      ),
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
      case 'paid':
        return AppColors.success;
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
      case 'paid':
        return 'Paid';
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


