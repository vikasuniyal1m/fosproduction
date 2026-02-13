import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/cart_controller.dart';
import '../../widgets/loading_widget.dart';

/// Cart Screen
/// Shows user's shopping cart items
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(CartController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: TextStyle(fontSize: ScreenSize.headingSmall),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightMedium,
        actions: [
          Obx(() => controller.cartItems.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.delete_outline, size: ScreenSize.iconSmall),
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        title: Text('Clear Cart', style: TextStyle(fontSize: ScreenSize.textLarge)),
                        content: Text('Are you sure you want to clear all items from cart?', style: TextStyle(fontSize: ScreenSize.textSmall)),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cancel', style: TextStyle(fontSize: ScreenSize.textSmall)),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.back();
                              controller.clearCart();
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(color: AppColors.error, fontSize: ScreenSize.textSmall),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const SizedBox.shrink()),
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, size: ScreenSize.iconSmall),
            onPressed: () => controller.loadCart(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget();
        }
        
        if (controller.cartItems.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => controller.loadCart(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: ScreenSize.screenHeight * 0.8,
                child: _buildEmptyState(),
              ),
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => controller.loadCart(),
          child: _buildCartContent(controller),
        );
      }),
      bottomNavigationBar: Obx(() => controller.cartItems.isNotEmpty
          ? _buildBottomBar(controller)
          : const SizedBox.shrink()),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: ScreenSize.iconExtraLarge * 2,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'Start adding items to your cart',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingExtraLarge),
          ElevatedButton(
            onPressed: () => Get.offAllNamed('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: EdgeInsets.symmetric(
                horizontal: ScreenSize.spacingLarge,
                vertical: ScreenSize.spacingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
              ),
            ),
            child: Text(
              'Continue Shopping',
              style: TextStyle(fontSize: ScreenSize.textLarge),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCartContent(CartController controller) {
    return ListView.builder(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      itemCount: controller.cartItems.length,
      itemBuilder: (context, index) {
        final item = controller.cartItems[index];
        return _buildCartItem(item, controller);
      },
    );
  }
  
  Widget _buildCartItem(Map<String, dynamic> item, CartController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          GestureDetector(
            onTap: () => controller.navigateToProductDetails(item['product_id']),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ScreenSize.tileBorderRadius),
                bottomLeft: Radius.circular(ScreenSize.tileBorderRadius),
              ),
              child: CachedNetworkImage(
                imageUrl: item['image'] ?? '',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 90,
                  height: 90,
                  color: AppColors.backgroundGrey,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 90,
                  height: 90,
                  color: AppColors.backgroundGrey,
                  child: Icon(
                    Icons.image_not_supported,
                    size: ScreenSize.iconMedium,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          
          // Product Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(ScreenSize.spacingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  GestureDetector(
                    onTap: () => controller.navigateToProductDetails(item['product_id']),
                    child: Text(
                      item['product_name'] ?? '',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4),
                  
                  // Size and Color
                  if (item['size'] != null || item['color'] != null)
                    Wrap(
                      spacing: 4,
                      children: [
                        if (item['size'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Size: ${item['size']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        if (item['color'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Color: ${item['color']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  
                  SizedBox(height: 4),
                  
                  // Price
                  Text(
                    '₹${item['item_total'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Quantity Selector
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: 12),
                              iconSize: 12,
                              onPressed: () => controller.decreaseQuantity(
                                item['id'],
                                item['quantity'],
                              ),
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item['quantity']}',
                                style: TextStyle(
                                  fontSize: ScreenSize.textSmall,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: 12),
                              iconSize: 12,
                              onPressed: () => controller.increaseQuantity(
                                item['id'],
                                item['quantity'],
                                item['stock_quantity'] ?? 99,
                              ),
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        onPressed: () {
                          Get.dialog(
                            AlertDialog(
                              title: Text('Remove Item', style: TextStyle(fontSize: ScreenSize.textLarge)),
                              content: Text('Are you sure you want to remove this item from cart?', style: TextStyle(fontSize: ScreenSize.textSmall)),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('Cancel', style: TextStyle(fontSize: ScreenSize.textSmall)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    controller.removeFromCart(item['id']);
                                  },
                                  child: Text(
                                    'Remove',
                                    style: TextStyle(color: AppColors.error, fontSize: ScreenSize.textSmall),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  // Stock warning
                  if (item['in_stock'] == false)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Out of Stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar(CartController controller) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Obx(() => Text(
                  '₹${controller.subtotal.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: ScreenSize.textLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Shipping and taxes calculated at checkout',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.navigateToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

