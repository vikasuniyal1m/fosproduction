import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/digital_product_type.dart';
import '../../controllers/wishlist_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/product_grid_card.dart';
import '../../utils/silent_loading.dart';

/// Wishlist Screen
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
          style: TextStyle(fontSize: ScreenSize.headingSmall),
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
        actions: [
          Obx(() => controller.wishlistItems.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.delete_outline, size: ScreenSize.iconMedium),
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        title: Text(
                          'Clear Wishlist',
                          style: TextStyle(fontSize: ScreenSize.headingMedium),
                        ),
                        content: Text(
                          'Are you sure you want to clear all items from wishlist?',
                          style: TextStyle(fontSize: ScreenSize.textLarge),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cancel',
                                style: TextStyle(fontSize: ScreenSize.textLarge)),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.back();
                              controller.clearWishlist();
                            },
                            child: Text('Clear',
                                style: TextStyle(fontSize: ScreenSize.textLarge)),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() => SilentLoading.blockUi(
            isLoading: controller.isLoading.value,
            hasContent: controller.wishlistItems.isNotEmpty,
          )
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

  bool _showAddToCart(Map<String, dynamic> item) {
    if (DigitalProductType.isDigitalNoCart(item)) return false;
    if (DigitalProductType.isDigitalProduct(item)) return false;
    return true;
  }

  Widget _buildWishlistItem(
    Map<String, dynamic> item,
    WishlistController controller,
  ) {
    final imageSize = ScreenSize.productCardHorizontalImageHeight;
    final showCart = _showAddToCart(item);

    return GestureDetector(
      onTap: () => controller.navigateToProductDetails(item['id'], preview: item),
      child: Container(
        margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ScreenSize.tileBorderRadius),
                bottomLeft: Radius.circular(ScreenSize.tileBorderRadius),
              ),
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: ProductCardImage(
                  product: item,
                  cacheKeyPrefix: 'wishlist',
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ScreenSize.spacingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(item['price'] as num? ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (!showCart) ...[
                      const SizedBox(height: 4),
                      Text(
                        _digitalLabel(item),
                        style: TextStyle(
                          fontSize: ScreenSize.textExtraSmall,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (showCart)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => controller.addToCart(item['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'Add to Cart',
                                style:
                                    TextStyle(fontSize: ScreenSize.textSmall),
                              ),
                            ),
                          ),
                        if (showCart) const SizedBox(width: 8),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 18,
                          ),
                          onPressed: () =>
                              controller.removeFromWishlist(item['id']),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _digitalLabel(Map<String, dynamic> item) {
    if (DigitalProductType.isStickerPack(item)) {
      return 'Sticker pack — tap to buy';
    }
    if (DigitalProductType.isVideo(item)) return 'Video — tap to buy';
    if (DigitalProductType.isAudio(item)) return 'Audio — tap to buy';
    if (DigitalProductType.isDigitalProduct(item)) {
      return 'Digital — tap to buy';
    }
    return 'Tap to view';
  }
}
