import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/product_controller.dart';
import '../../widgets/loading_widget.dart';

/// Product Details Screen
/// Shows product details, images, reviews, and related products
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProductController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Obx(() => controller.isLoading.value || controller.product == null
            ? const LoadingWidget()
            : CustomScrollView(
                slivers: [
                  // App Bar with Images
                  _buildAppBar(controller),
                  
                  // Product Info
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name & Price
                        _buildProductHeader(controller),
                        
                        // Stock Status & Discount Badge
                        _buildProductBadges(controller),
                        SizedBox(height: ScreenSize.spacingSmall),
                        
                        // Size Selection
                        if (controller.product!['sizes'] != null && (controller.product!['sizes'] as List).isNotEmpty)
                          _buildSizeSelection(controller),
                        
                        // Color Selection
                        if (controller.product!['colors'] != null && (controller.product!['colors'] as List).isNotEmpty)
                          _buildColorSelection(controller),
                        
                        // Quantity & Price Row
                        _buildQuantityAndPrice(controller),
                        SizedBox(height: ScreenSize.spacingSmall),
                        
                        // Shipping & Return Info
                        _buildShippingInfo(controller),
                        SizedBox(height: ScreenSize.spacingSmall),
                        
                        // Description
                        _buildDescription(controller),
                        SizedBox(height: ScreenSize.spacingSmall),
                        
                        // Specifications
                        _buildSpecifications(controller),
                        SizedBox(height: ScreenSize.spacingSmall),
                        
                        // Reviews Section
                        _buildReviewsSection(controller),
                        SizedBox(height: ScreenSize.spacingSmall),
                        
                        // Related Products
                        _buildRelatedProducts(controller),
                        SizedBox(height: ScreenSize.spacingSmall),
                      ],
                    ),
                  ),
                ],
              )),
      ),
      bottomNavigationBar: _buildBottomBar(controller),
    );
  }
  
  Widget _buildAppBar(ProductController controller) {
    return SliverAppBar(
      expandedHeight: ScreenSize.heightPercent(35),
      pinned: true,
      floating: false,
      automaticallyImplyLeading: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Builder(
              builder: (context) {
                final images = controller.product!['images'] as List? ?? [];
                final imageCount = images.isEmpty ? 1 : images.length;
                
                return PageView.builder(
                  itemCount: imageCount,
                  onPageChanged: (index) => controller.selectedImageIndex.value = index,
                  itemBuilder: (context, index) {
                    final imageUrl = images.isNotEmpty 
                        ? (images[index] is String ? images[index] : images[index]?.toString() ?? '')
                        : controller.product!['image']?.toString() ?? '';
                    
                    return Container(
                      color: Colors.white,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.white,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white,
                          child: Icon(
                            Icons.image_not_supported,
                            size: ScreenSize.iconExtraLarge,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Image indicators
            Positioned(
              bottom: ScreenSize.spacingSmall,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final images = controller.product!['images'] as List? ?? [];
                  final imageCount = images.isEmpty ? 1 : images.length;
                  if (imageCount <= 1) return const SizedBox.shrink();
                  
                  return Obx(() {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(imageCount, (index) {
                        final isSelected = controller.selectedImageIndex.value == index;
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: ScreenSize.spacingTiny),
                          width: isSelected ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.textWhite 
                                : AppColors.textWhite.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() => AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: IconButton(
            key: ValueKey(controller.isFavorite.value),
            icon: Icon(
              controller.isFavorite.value ? Icons.favorite : Icons.favorite_border,
              color: controller.isFavorite.value ? AppColors.error : AppColors.textWhite,
            ),
            onPressed: controller.toggleFavorite,
          ),
        )),
        IconButton(
          icon: const Icon(Icons.share, color: AppColors.textWhite),
          onPressed: () => _shareProduct(controller),
        ),
      ],
    );
  }
  
  Widget _buildProductHeader(ProductController controller) {
    final product = controller.product!;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ScreenSize.spacingMedium,
        ScreenSize.spacingMedium,
        ScreenSize.spacingMedium,
        ScreenSize.spacingTiny,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product['name'] ?? '',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          
          // Rating
          Row(
            children: [
              Icon(Icons.star, size: 12, color: AppColors.accent),
              SizedBox(width: 4),
              Text(
                '${product['rating'] ?? 0.0}',
                style: TextStyle(
                  fontSize: ScreenSize.textExtraSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '(${product['reviews'] ?? 0} reviews)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          
          // Price
          Row(
            children: [
              Text(
                '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (product['originalPrice'] != null &&
                  product['originalPrice'] > product['price'])
                Padding(
                  padding: EdgeInsets.only(left: ScreenSize.spacingSmall),
                  child: Text(
                    '\$${product['originalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraSmall,
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSizeSelection(ProductController controller) {
    final sizes = controller.product!['sizes'] as List? ?? [];
    if (sizes.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Size',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Obx(() {
            final selectedIndex = controller.selectedSizeIndex.value;
            return Wrap(
              spacing: ScreenSize.spacingSmall,
              children: List.generate(sizes.length, (index) {
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => controller.selectSize(index),
                  child: Container(
                    width: ScreenSize.heightPercent(4.5),
                    height: ScreenSize.heightPercent(4.5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      sizes[index].toString(),
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildColorSelection(ProductController controller) {
    final colors = controller.product!['colors'] as List? ?? [];
    if (colors.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Obx(() {
            final selectedIndex = controller.selectedColorIndex.value;
            return Wrap(
              spacing: ScreenSize.spacingSmall,
              children: List.generate(colors.length, (index) {
                final isSelected = selectedIndex == index;
                final color = colors[index];
                final colorCode = color is Map 
                    ? (color['code'] ?? color['name'] ?? '#000000')
                    : (color?.toString() ?? '#000000');
                
                return GestureDetector(
                  onTap: () => controller.selectColor(index),
                  child: Container(
                    width: ScreenSize.heightPercent(4.5),
                    height: ScreenSize.heightPercent(4.5),
                    decoration: BoxDecoration(
                      color: _parseColor(colorCode),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildQuantityAndPrice(ProductController controller) {
    final product = controller.product!;
    final hasDiscount = product['originalPrice'] != null && 
                       product['originalPrice'] > product['price'];
    final discountPercent = hasDiscount 
        ? ((product['originalPrice'] - product['price']) / product['originalPrice'] * 100).round()
        : 0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingTiny),
      child: Row(
        children: [
          // Quantity Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: ScreenSize.textExtraSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 14),
                      onPressed: controller.decreaseQuantity,
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                    ),
                    Obx(() => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${controller.quantity.value}',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                    IconButton(
                      icon: Icon(Icons.add, size: 14),
                      onPressed: controller.increaseQuantity,
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(width: ScreenSize.spacingMedium),
          
          // Price Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  Text(
                    '\$${product['originalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraSmall,
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: ScreenSize.textLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (hasDiscount && discountPercent > 0)
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 2),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
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
  
  Widget _buildProductBadges(ProductController controller) {
    final product = controller.product!;
    final inStock = product['inStock'] ?? true;
    final stock = product['stock'] ?? 0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: 2),
      child: Row(
        children: [
          // Stock Status
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: inStock ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: inStock ? AppColors.success : AppColors.error,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  inStock ? Icons.check_circle : Icons.cancel,
                  size: 12,
                  color: inStock ? AppColors.success : AppColors.error,
                ),
                SizedBox(width: 4),
                Text(
                  inStock 
                      ? (stock > 0 ? 'In Stock ($stock)' : 'In Stock')
                      : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: inStock ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 8),
          
          // Brand Badge (if available)
          if (product['brand'] != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1,
                ),
              ),
              child: Text(
                product['brand'] is Map 
                    ? (product['brand']['name'] ?? 'Brand')
                    : product['brand'].toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildShippingInfo(ProductController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingTiny),
      child: Container(
        padding: EdgeInsets.all(ScreenSize.spacingTiny),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.local_shipping,
              title: 'Free Shipping',
              subtitle: 'On orders above \$50',
            ),
            SizedBox(height: 2),
            Divider(height: 1, color: AppColors.border),
            SizedBox(height: 2),
            _buildInfoRow(
              icon: Icons.assignment_return,
              title: 'Easy Returns',
              subtitle: '30 days return policy',
            ),
            SizedBox(height: 2),
            Divider(height: 1, color: AppColors.border),
            SizedBox(height: 2),
            _buildInfoRow(
              icon: Icons.verified,
              title: 'Authentic Products',
              subtitle: '100% genuine guarantee',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSpecifications(ProductController controller) {
    final product = controller.product!;
    final specs = <String, String>{};
    
    if (product['weight'] != null) {
      specs['Weight'] = '${product['weight']} kg';
    }
    if (product['dimensions'] != null) {
      specs['Dimensions'] = product['dimensions'].toString();
    }
    if (product['material'] != null) {
      specs['Material'] = product['material'].toString();
    }
    if (product['warranty'] != null) {
      specs['Warranty'] = product['warranty'].toString();
    }
    if (product['sku'] != null) {
      specs['SKU'] = product['sku'].toString();
    }
    
    if (specs.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingTiny),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: specs.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDescription(ProductController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            controller.product!['description'] ?? '',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewsSection(ProductController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Reviews',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Obx(() => Text(
                    '${controller.reviews.length} ${controller.reviews.length == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  )),
                ],
              ),
              TextButton.icon(
                onPressed: controller.writeReview,
                icon: Icon(Icons.edit, size: 14, color: AppColors.primary),
                label: Text(
                  'Write Review',
                  style: TextStyle(
                    fontSize: ScreenSize.textExtraSmall,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Obx(() {
            print('[UI] Reviews section rebuild, count: ${controller.reviews.length}');
            if (controller.reviews.isEmpty) {
              return Container(
                padding: EdgeInsets.all(ScreenSize.spacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.reviews_outlined,
                      size: 32,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Be the first to review this product',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...controller.reviews.take(3).map((review) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _buildReviewCard(controller, review),
                )),
                if (controller.reviews.length > 3)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full reviews screen
                      Get.snackbar('Info', 'View all reviews coming soon');
                    },
                    child: Text(
                      'View All ${controller.reviews.length} Reviews',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildReviewCard(ProductController controller, Map<String, dynamic> review) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  (review['userName']?[0] ?? 'U').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review['rating'] ?? 0).floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 12,
                            color: AppColors.accent,
                          );
                        }),
                        SizedBox(width: 8),
                        Text(
                          review['date'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (review['status'] == 'pending') ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['title'] != null && review['title'].toString().isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              review['title'],
              style: TextStyle(
                fontSize: ScreenSize.textExtraSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          SizedBox(height: 2),
          Text(
            review['comment'] ?? '',
            style: TextStyle(
              fontSize: ScreenSize.textExtraSmall,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
          if (review['images'] != null && (review['images'] as List).isNotEmpty) ...[
            SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (review['images'] as List).map((image) {
                return GestureDetector(
                  onTap: () {
                    // TODO: Show image in full screen
                    Get.snackbar('Info', 'Image preview coming soon');
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: image,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 40,
                        height: 40,
                        color: AppColors.backgroundGrey,
                        child: Icon(Icons.image, size: 12, color: AppColors.textTertiary),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 40,
                        height: 40,
                        color: AppColors.backgroundGrey,
                        child: Icon(Icons.image_not_supported, size: 12, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: 4),
          // Like and Report buttons
          Row(
            children: [
              // Like button
              InkWell(
                onTap: () => controller.toggleReviewLike(review['id']),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review['is_liked'] == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 14,
                      color: review['is_liked'] == true ? AppColors.primary : AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${review['like_count'] ?? 0}',
                      style: TextStyle(
                        fontSize: 10,
                        color: review['is_liked'] == true ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: review['is_liked'] == true ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Report button
              InkWell(
                onTap: () => _showReportDialog(controller, review['id']),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showReportDialog(ProductController controller, int reviewId) {
    final descriptionController = TextEditingController();
    String selectedReason = 'other';
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.all(ScreenSize.spacingMedium),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Review',
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Why are you reporting this review?',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  ...['spam', 'inappropriate', 'fake', 'offensive', 'other'].map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason[0].toUpperCase() + reason.substring(1), style: TextStyle(fontSize: ScreenSize.textSmall)),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value!;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Additional details (optional)',
                      labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
                    maxLines: 2,
                    style: TextStyle(fontSize: ScreenSize.textSmall),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel', style: TextStyle(fontSize: ScreenSize.textSmall)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          controller.reportReview(
                            reviewId,
                            selectedReason,
                            description: descriptionController.text.isEmpty ? null : descriptionController.text,
                          );
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textWhite,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: Text('Report', style: TextStyle(fontSize: ScreenSize.textSmall)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Share product on social media
  void _shareProduct(ProductController controller) {
    final product = controller.product;
    if (product == null) return;
    
    final productName = product['name'] ?? 'Product';
    final productPrice = product['sale_price'] ?? product['price'] ?? 0;
    final productUrl = 'https://ecommercepanel.templateforwebsites.com/product/${product['id']}';
    
    final shareText = '''
Check out this amazing product!

$productName
Price: \$$productPrice

$productUrl
''';
    
    Share.share(
      shareText,
      subject: productName,
    );
  }
  
  Widget _buildRelatedProducts(ProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You May Also Like',
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (controller.relatedProducts.length > 4)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to see all related products
                    Get.snackbar('Info', 'View all related products coming soon');
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraSmall,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Obx(() {
          if (controller.relatedProducts.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium),
              child: Container(
                padding: EdgeInsets.all(ScreenSize.spacingSmall),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No related products found',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            height: ScreenSize.heightPercent(20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium),
              itemCount: controller.relatedProducts.length,
              itemBuilder: (context, index) {
                final product = controller.relatedProducts[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to product details
                    Get.toNamed('/product-details', arguments: product['id']);
                  },
                  child: Container(
                    width: ScreenSize.widthPercent(30),
                    margin: EdgeInsets.only(right: ScreenSize.spacingSmall),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(ScreenSize.tileBorderRadius),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: product['image'] ?? '',
                                width: double.infinity,
                                height: ScreenSize.heightPercent(12),
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Container(
                                  color: AppColors.backgroundGrey,
                                  height: ScreenSize.heightPercent(12),
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.backgroundGrey,
                                  height: ScreenSize.heightPercent(12),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 16,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                            if (product['rating'] != null && (product['rating'] as double) > 0)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 8,
                                        color: AppColors.textWhite,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        product['rating'].toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: ScreenSize.textExtraSmall,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildBottomBar(ProductController controller) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingSmall),
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
        child: Row(
          children: [
            Expanded(
              child: Obx(() => OutlinedButton(
                onPressed: controller.isAddingToCart.value ? null : controller.addToCart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                  ),
                ),
                child: controller.isAddingToCart.value
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: controller.buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                  ),
                ),
                child: Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
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
  
  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.textPrimary;
    }
  }
}

