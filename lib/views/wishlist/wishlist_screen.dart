import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/wishlist_controller.dart';
import '../../widgets/loading_widget.dart';

/// Wishlist Screen
/// Shows user's saved wishlist items
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(WishlistController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Wishlist',
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
          icon: Icon(
            Icons.arrow_back,
            size: ScreenSize.iconMedium,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => controller.wishlistItems.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: ScreenSize.iconMedium,
                  ),
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        title: Text(
                          'Clear Wishlist',
                          style: TextStyle(
                            fontSize: ScreenSize.headingMedium,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to clear all items from wishlist?',
                          style: TextStyle(
                            fontSize: ScreenSize.textLarge,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: ScreenSize.textLarge,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.back();
                              controller.clearWishlist();
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: ScreenSize.textLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() => controller.isLoading.value
          ? const LoadingWidget()
          : controller.wishlistItems.isEmpty
              ? _buildEmptyState()
              : _buildWishlistItems(controller)),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: ScreenSize.iconExtraLarge * 2,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'Start adding items to your wishlist',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWishlistItems(WishlistController controller) {
    return ListView.builder(
      padding: EdgeInsets.all(ScreenSize.paddingMedium),
      itemCount: controller.wishlistItems.length,
      itemBuilder: (context, index) {
        final item = controller.wishlistItems[index];
        return _buildWishlistItem(item, controller);
      },
    );
  }
  
  Widget _buildWishlistItem(Map<String, dynamic> item, WishlistController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Product Image
          GestureDetector(
            onTap: () => controller.navigateToProductDetails(item['id']),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ScreenSize.tileBorderRadius),
                bottomLeft: Radius.circular(ScreenSize.tileBorderRadius),
              ),
              child: CachedNetworkImage(
                imageUrl: item['image'] ?? '',
                width: ScreenSize.productCardHorizontalImageHeight,
                height: ScreenSize.productCardHorizontalImageHeight,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: ScreenSize.productCardHorizontalImageHeight,
                  height: ScreenSize.productCardHorizontalImageHeight,
                  color: AppColors.backgroundGrey,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: ScreenSize.productCardHorizontalImageHeight,
                  height: ScreenSize.productCardHorizontalImageHeight,
                  color: AppColors.backgroundGrey,
                  child: Icon(
                    Icons.image_not_supported,
                    size: ScreenSize.iconLarge,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          
          // Product Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(ScreenSize.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => controller.navigateToProductDetails(item['id']),
                    child: Text(
                      item['name'] ?? '',
                      style: TextStyle(
                        fontSize: ScreenSize.textLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  
                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: ScreenSize.iconSmall,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: ScreenSize.spacingExtraSmall),
                      Text(
                        '${item['rating'] ?? 0.0}',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: ScreenSize.spacingSmall),
                      Flexible(
                        child: Text(
                          '(${item['reviews'] ?? 0})',
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  
                  // Price
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '\$${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            fontSize: ScreenSize.textLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item['originalPrice'] != null &&
                          item['originalPrice'] > item['price'])
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: ScreenSize.spacingSmall),
                            child: Text(
                              '\$${item['originalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                                color: AppColors.textTertiary,
                                decoration: TextDecoration.lineThrough,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  
                  // Stock Status
                  if (item['inStock'] == false)
                    Text(
                      'Out of Stock',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  
                  // Actions
                  SizedBox(height: ScreenSize.spacingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: item['inStock'] == true
                              ? () => controller.addToCart(item['id'])
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: EdgeInsets.symmetric(
                              vertical: ScreenSize.spacingSmall,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ScreenSize.buttonBorderRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: ScreenSize.textMedium,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: ScreenSize.spacingSmall),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: ScreenSize.iconMedium,
                          color: AppColors.error,
                        ),
                        onPressed: () => controller.removeFromWishlist(item['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

