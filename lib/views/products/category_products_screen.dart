import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/category_products_controller.dart';
import '../../widgets/loading_widget.dart';

/// Category Products Screen
/// Shows products filtered by category
class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    print('CategoryProductsScreen build - starting');
    print('CategoryProductsScreen build - arguments: ${Get.arguments}');
    
    // Always create new controller to get fresh arguments
    // Delete old one if exists
    if (Get.isRegistered<CategoryProductsController>()) {
      Get.delete<CategoryProductsController>();
    }
    final controller = Get.put(CategoryProductsController());
    
    print('CategoryProductsScreen build - controller initialized');
    print('CategoryProductsScreen build - categoryId: ${controller.categoryId}, categoryName: ${controller.categoryName}');
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: ScreenSize.iconMedium, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          controller.categoryName,
          style: TextStyle(
            fontSize: ScreenSize.headingMedium,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() => controller.isLoading.value
          ? const LoadingWidget()
          : controller.products.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: controller.loadCategoryProducts,
                  child: _buildProductsGrid(controller),
                )),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'There are no products in this category',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductsGrid(CategoryProductsController controller) {
    // Local override for mobile aspect ratio to make cards shorter
    final aspectRatio = ScreenSize.isTablet ? ScreenSize.productCardAspectRatio : 0.75;

    return Padding(
      padding: EdgeInsets.all(ScreenSize.paddingMedium),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ScreenSize.gridCrossAxisCount,
          crossAxisSpacing: ScreenSize.gridSpacing,
          mainAxisSpacing: ScreenSize.gridSpacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: controller.products.length,
        itemBuilder: (context, index) {
          final product = controller.products[index];
          return _buildProductCard(product, controller);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, CategoryProductsController controller) {
    final regularPrice = product['price'] ?? 0.0;
    final salePrice = product['sale_price'];
    final displayPrice = salePrice ?? regularPrice;
    
    // Local override for mobile image height
    final imageHeight = ScreenSize.isTablet 
        ? ScreenSize.productCardImageHeight 
        : (100 * (ScreenSize.screenWidth / 375)).h; // 100 base height scaled for mobile
    
    return GestureDetector(
      onTap: () => controller.navigateToProductDetails(product['id']),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ScreenSize.tileBorderRadius),
                  ),
                  child: _buildProductImage(product, height: imageHeight),
                ),
                // Favorite button
                Positioned(
                  top: ScreenSize.spacingSmall,
                  right: ScreenSize.spacingSmall,
                  child: Obx(() {
                    // Access observable products list directly
                    final productIndex = controller.products.indexWhere(
                      (p) => p['id'] == product['id'],
                    );
                    final isFavorite = productIndex != -1 
                        ? controller.products[productIndex]['isFavorite'] == true
                        : product['isFavorite'] == true;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.toggleFavorite(product['id']),
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: EdgeInsets.all(ScreenSize.spacingExtraSmall),
                          decoration: BoxDecoration(
                            color: AppColors.overlayLight, // Semi-transparent white
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.error
                                : AppColors.textSecondary,
                            size: ScreenSize.iconSmall,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Discount badge
                if (salePrice != null && regularPrice > salePrice)
                  Positioned(
                    top: ScreenSize.spacingSmall,
                    left: ScreenSize.spacingSmall,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.spacingTiny,
                        vertical: ScreenSize.spacingTiny,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                      ),
                      child: Text(
                        '${((regularPrice - salePrice) / regularPrice * 100).round()}% OFF',
                        style: TextStyle(
                          fontSize: ScreenSize.textExtraSmall,
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Info - Wrap in Expanded + SingleChildScrollView to fix tablet overflow
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), // Prevent individual card scrolling unless needed
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       // Category
                      if (product['category'] != null && product['category']['name'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: ScreenSize.spacingTiny),
                          child: Text(
                            product['category']['name'],
                            style: TextStyle(
                              fontSize: ScreenSize.textExtraSmall,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
    
                      // Product Name
                      Text(
                        product['name'] ?? '',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ScreenSize.spacingTiny),
    
                      // Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: ScreenSize.iconExtraSmall,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: ScreenSize.spacingTiny),
                          Text(
                            '${product['rating'] ?? 0.0}',
                            style: TextStyle(
                              fontSize: ScreenSize.textExtraSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: ScreenSize.spacingTiny),
                          Flexible(
                            child: Text(
                              '(${product['reviews'] ?? 0})',
                              style: TextStyle(
                                fontSize: ScreenSize.textExtraSmall,
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ScreenSize.spacingTiny),
    
                      // Price
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '\$${displayPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (salePrice != null && regularPrice > salePrice) ...[
                            SizedBox(width: ScreenSize.spacingTiny),
                            Flexible(
                              child: Text(
                                '\$${regularPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: ScreenSize.textExtraSmall,
                                  color: AppColors.textTertiary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Helper method to build product image widget
  Widget _buildProductImage(Map<String, dynamic> product, {double? height}) {
    final imageUrl = product['image'];
    final imageHeight = height ?? ScreenSize.productCardImageHeight;

    // Check if image URL is valid
    if (imageUrl != null && imageUrl is String && imageUrl.isNotEmpty) {
      // Clean the URL: remove escaped slashes and trim
      final cleanUrl = imageUrl.replaceAll('\\/', '/').trim();

      return CachedNetworkImage(
        imageUrl: cleanUrl,
        width: double.infinity,
        height: imageHeight,
        fit: BoxFit.contain,
        httpHeaders: const {
          'Accept': 'image/*',
        },
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: imageHeight,
          color: AppColors.backgroundGrey,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Image.network(
            cleanUrl,
            width: double.infinity,
            height: imageHeight,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: imageHeight,
                color: AppColors.backgroundGrey,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: imageHeight,
                color: AppColors.backgroundGrey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, color: AppColors.textTertiary, size: ScreenSize.iconLarge),
                    SizedBox(height: ScreenSize.spacingTiny),
                    Text(
                      'Image not found',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    // Return placeholder if no image
    return Container(
      width: double.infinity,
      height: imageHeight,
      color: AppColors.backgroundGrey,
      child: Icon(Icons.image, color: AppColors.textTertiary, size: ScreenSize.iconLarge),
    );
  }
}
