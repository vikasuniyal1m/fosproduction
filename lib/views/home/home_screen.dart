import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/floating_help_button.dart';
import '../../routes/app_routes.dart';

/// Home Screen
/// Main screen showing categories, banners, and products
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final homeController = Get.put(HomeController());
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    
    // Initialize cart controller once (singleton)
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    
    return PopScope(
      // Prevent back navigation from home - show exit confirmation
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Show exit confirmation dialog
          final shouldExit = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Do you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          
          if (shouldExit == true) {
            // Exit the app
            SystemNavigator.pop(); // Exits the app on Android
            // For iOS, this will also work in most cases
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Obx(() {
            if (homeController.isLoading.value) {
              return const LoadingWidget();
            }
            return RefreshIndicator(
                onRefresh: homeController.loadHomeData,
                child: CustomScrollView(
                  slivers: [
                    // Custom Header with Location, Cart, Search, Profile
                    _buildCustomHeader(homeController, authController),
                    
                    // Content
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Promotional Banner
                          _buildPromotionalBanner(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),
                          
                          // Categories
                          _buildCategoriesSection(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),
                          
                          // Featured Products
                          _buildSectionHeader('Featured Products', 'Sort', () => homeController.showSortDialog()),
                          SizedBox(height: ScreenSize.spacingSmall),
                          _buildFeaturedProductsGrid(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),
                          
                          // Up to 70% off Section
                          _buildSectionHeader('Up to 70% off', 'Popular', () => homeController.showDiscountedSortDialog()),
                          SizedBox(height: ScreenSize.spacingSmall),
                          _buildDiscountedProducts(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // Top Rated Picks
                          _buildTopRatedSection(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: const FloatingHelpButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
  
  Widget _buildCustomHeader(HomeController controller, AuthController authController) {
    return SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _CustomHeaderDelegate(
        controller: controller,
        authController: authController,
      ),
    );
  }
  
  Widget _buildPromotionalBanner(HomeController controller) {
    return Obx(() {
      if (controller.banners.isEmpty) {
        // Default banner if no banners from API
        return Container(
          margin: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          height: ScreenSize.bannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSize.paddingMedium,
              vertical: ScreenSize.spacingMedium*0.4,
            ),
            child: Row(
              children: [
                // Left side - Text Content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Up To',
                              style: TextStyle(
                                fontSize: ScreenSize.textLarge,
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: ScreenSize.spacingXSmall),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '70% OFF',
                                style: TextStyle(
                                  fontSize: ScreenSize.headingLarge,
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            SizedBox(height: ScreenSize.spacingSmall),
                            Text(
                              'with free delivery',
                              style: TextStyle(
                                fontSize: ScreenSize.textLarge,
                                color: AppColors.textWhite.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ScreenSize.spacingLarge),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textWhite,
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: ScreenSize.paddingMedium,
                            vertical: ScreenSize.spacingSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Shop Now',
                              style: TextStyle(
                                fontSize: ScreenSize.textMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: ScreenSize.spacingSmall),
                            Icon(
                              Icons.arrow_forward,
                              size: ScreenSize.iconSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right side - Image placeholder
                SizedBox(
                  width: 120.w,
                  height: 120.h,
                  child: Icon(
                    Icons.image,
                    size: 100.w,
                    color: AppColors.textWhite.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      // Use PageView with auto-slide for banner carousel
      return _BannerCarousel(
        banners: controller.banners,
        currentIndex: controller.currentBannerIndex,
      );
    });
  }
  
  
  Widget _buildCategoriesSection(HomeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
        ),
        SizedBox(height: ScreenSize.spacingMedium),
        SizedBox(
          height: ScreenSize.categorySectionHeight,
          child: Obx(() {
            // Filter out "All" category (index 0) for display
            final displayCategories = controller.categories.where((cat) => cat['id'] != 0).toList();
            
            if (displayCategories.isEmpty) {
              // Show at least some default categories if API fails
              final defaultCategories = [
                {'id': 1, 'name': 'Apparel', 'icon': '👕', 'image': ''},
                {'id': 2, 'name': 'Home', 'icon': '☕', 'image': ''},
                {'id': 3, 'name': 'Books', 'icon': '📚', 'image': ''},
                {'id': 4, 'name': 'Health', 'icon': '💊', 'image': ''},
              ];
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingSmall),
                itemCount: defaultCategories.length,
                itemBuilder: (context, index) {
                  final category = defaultCategories[index];
                  
                  return GestureDetector(
                    onTap: () {
                      // Do nothing for default categories or handle appropriately
                    },
                  child: Container(
                    width: ScreenSize.categoryItemWidth,
                    margin: EdgeInsets.only(right: ScreenSize.spacingSmall),
                    child: Column(
                      children: [
                        Container(
                          width: ScreenSize.categoryIconSize,
                          height: ScreenSize.categoryIconSize,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGrey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category['icon'] as String,
                              style: TextStyle(fontSize: 30.sp),
                            ),
                          ),
                        ),
                        SizedBox(height: ScreenSize.spacingSmall),
                        Text(
                          (category['name'] ?? '') as String,
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              });
            }
            
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingSmall),
              itemCount: displayCategories.length,
              itemBuilder: (context, index) {
                final category = displayCategories[index];
                // Find the actual index in the original categories list
                final actualIndex = controller.categories.indexWhere((cat) => cat['id'] == category['id']);

                // Map category names to icons
                String icon = _getCategoryIcon((category['name'] ?? '') as String);
                
                return GestureDetector(
                  onTap: () {
                    if (actualIndex != -1) {
                      controller.selectCategory(actualIndex);
                    }
                  },
                  child: Container(
                    width: ScreenSize.categoryItemWidth,
                    margin: EdgeInsets.only(right: ScreenSize.spacingSmall),
                    child: Column(
                      children: [
                        Container(
                          width: ScreenSize.categoryIconSize,
                          height: ScreenSize.categoryIconSize,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGrey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: category['image'] != null && (category['image'] as String).isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: category['image'],
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Center(
                                      child: Text(
                                        icon,
                                        style: TextStyle(fontSize: ScreenSize.headingMedium),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    icon,
                                    style: TextStyle(fontSize: 30.sp),
                                  ),
                                ),
                        ),
                        SizedBox(height: ScreenSize.spacingSmall),
                        Text(
                          (category['name'] ?? '') as String,
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
  
  String _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('apparel') || name.contains('clothing') || name.contains('shirt')) {
      return '👕';
    } else if (name.contains('home') || name.contains('mug')) {
      return '☕';
    } else if (name.contains('stationary') || name.contains('book') || name.contains('journal')) {
      return '📚';
    } else if (name.contains('health') || name.contains('vitamin')) {
      return '💊';
    }
    return '📦';
  }
  
  Widget _buildSectionHeader(String title, String rightText, VoidCallback onRightTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: ScreenSize.headingMedium,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          GestureDetector(
            onTap: onRightTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rightText,
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: ScreenSize.spacingExtraSmall),
                Icon(
                  Icons.swap_vert,
                  size: ScreenSize.iconMedium,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeaturedProductsGrid(HomeController controller) {
    return Obx(() {
      if (controller.featuredProducts.isEmpty) {
        return SizedBox(
          height: 400.h,
          child: Center(
            child: Text(
              'No featured products available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      }
      
        return Container(
          height: ScreenSize.productCardHorizontalHeight * 1.13,
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ScreenSize.gridCrossAxisCount,
              crossAxisSpacing: ScreenSize.gridSpacing,
              mainAxisSpacing: ScreenSize.gridSpacing,
              childAspectRatio: ScreenSize.productCardAspectRatio,
            ),
            itemCount: controller.featuredProducts.length > 6 ? 6 : controller.featuredProducts.length,
            itemBuilder: (context, index) {
              final product = controller.featuredProducts[index];
              return _buildProductCard(product, controller);
            },
          ),
        );
    });
  }

  Widget _buildDiscountedProducts(HomeController controller) {
    return Obx(() {
      if (controller.discountedProducts.isEmpty) {
        return SizedBox.shrink();
      }

      return Container(
        height: ScreenSize.productCardHorizontalHeight * 1.15,
        margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
        clipBehavior: Clip.none,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          clipBehavior: Clip.none,
          itemCount: controller.discountedProducts.length,
          itemBuilder: (context, index) {
            final product = controller.discountedProducts[index];
            return _buildDiscountedProductCard(product, controller);
          },
        ),
      );
    });
  }

  Widget _buildTopRatedSection(HomeController controller) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Top Rated Picks', 'Popular', () => controller.showTopRatedSortDialog()),
          SizedBox(height: ScreenSize.spacingSmall*3),
          controller.topRatedProducts.isEmpty
              ? Container(
                  height: ScreenSize.productCardHorizontalHeight * 1.15,
                  padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
                  child: Center(
                    child: Text(
                      'No top rated products available',
                      style: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : Container(
                  height: ScreenSize.productCardHorizontalHeight * 1.15,
                  margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
                  clipBehavior: Clip.none,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
                    clipBehavior: Clip.none,
                    itemCount: controller.topRatedProducts.length,
                    itemBuilder: (context, index) {
                      final product = controller.topRatedProducts[index];
                      return _buildTopRatedProductCard(product, controller);
                    },
                  ),
                ),
        ],
      );
    });
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
                    SizedBox(height: 4.h),
                    Text(
                      'Image not found',
                      style: TextStyle(
                        fontSize: 10.sp,
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

  Widget _buildProductCard(Map<String, dynamic> product, HomeController controller) {
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
                  child: _buildProductImage(product),
                ),
                // Favorite button
                Positioned(
                  top: ScreenSize.spacingSmall,
                  right: ScreenSize.spacingSmall,
                  child: Material(
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
                          product['isFavorite'] == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product['isFavorite'] == true
                              ? AppColors.error
                              : AppColors.textSecondary,
                          size: ScreenSize.iconSmall,
                        ),
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
                          padding: EdgeInsets.only(bottom: 2.h),
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
                      SizedBox(height: 3.h),
    
                      // Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 11.sp,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${product['rating'] ?? 0.0}',
                            style: TextStyle(
                              fontSize: ScreenSize.textExtraSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 2.w),
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
                      SizedBox(height: 3.h),
    
                      // Price
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '\$${(product['sale_price'] != null && (product['sale_price'] as num) > 0 ? product['sale_price'] : product['price'])?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product['sale_price'] != null &&
                              (product['sale_price'] as num) > 0 &&
                              (product['price'] as num) > (product['sale_price'] as num)) ...[
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                '\$${(product['price'] as num).toStringAsFixed(2)}',
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
  
  Widget _buildDiscountedProductCard(Map<String, dynamic> product, HomeController controller) {
    // Get prices - API returns 'price' (regular) and 'sale_price' (discounted)
    final regularPrice = (product['price'] ?? 0.0) as double;
    final salePrice = (product['sale_price'] ?? 0.0) as double;
    final displayPrice = salePrice > 0 ? salePrice : regularPrice;
    
    // Calculate discount percentage
    final discountPercent = product['discount_percent'] ?? 
        (regularPrice > 0 && salePrice > 0 && regularPrice > salePrice
            ? ((regularPrice - salePrice) / regularPrice * 100).round()
            : 0);
    
    return GestureDetector(
      onTap: () => controller.navigateToProductDetails(product['id']),
      child: Container(
        width: ScreenSize.productCardHorizontalWidth,
        margin: EdgeInsets.only(right: ScreenSize.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ScreenSize.tileBorderRadius),
                  ),
                  child: _buildProductImage(product, height: ScreenSize.productCardHorizontalImageHeight),
                ),
                // Discount Badge
                if (discountPercent > 0)
                  Positioned(
                    top: ScreenSize.spacingSmall,
                    left: ScreenSize.spacingSmall,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: TextStyle(
                          fontSize: ScreenSize.textExtraSmall,
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Favorite button
                Positioned(
                  top: ScreenSize.spacingSmall,
                  right: ScreenSize.spacingSmall,
                  child: IconButton(
                    icon: Icon(
                      product['isFavorite'] == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: product['isFavorite'] == true
                          ? AppColors.error
                          : AppColors.textWhite,
                      size: ScreenSize.iconMedium,
                    ),
                    onPressed: () => controller.toggleFavorite(product['id']),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.overlayLight,
                      padding: EdgeInsets.all(ScreenSize.spacingExtraSmall),
                    ),
                  ),
                ),
              ],
            ),
            
            // Product Info - Wrap in Expanded + SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category
                      if (product['category'] != null && product['category']['name'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
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
                      SizedBox(height: 3.h),
                      
                      // Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 11.sp,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${product['rating'] ?? 0.0}',
                            style: TextStyle(
                              fontSize: ScreenSize.textExtraSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Flexible(
                            child: Text(
                              '(${product['reviews'] ?? product['review_count'] ?? 0})',
                              style: TextStyle(
                                fontSize: ScreenSize.textExtraSmall,
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      
                      // Price - Show sale price if available, otherwise regular price
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
                          if (salePrice > 0 && regularPrice > salePrice) ...[
                            SizedBox(width: 4.w),
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
  
  Widget _buildTopRatedProductCard(Map<String, dynamic> product, HomeController controller) {
    // Get prices
    final regularPrice = (product['price'] ?? 0.0) as double;
    final salePrice = (product['sale_price'] ?? 0.0) as double;
    final displayPrice = salePrice > 0 ? salePrice : regularPrice;
    
    return GestureDetector(
      onTap: () => controller.navigateToProductDetails(product['id']),
      child: Container(
        width: ScreenSize.productCardHorizontalWidth,
        margin: EdgeInsets.only(right: ScreenSize.spacingMedium),
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ScreenSize.tileBorderRadius),
                  ),
                  child: _buildProductImage(product, height: ScreenSize.productCardHorizontalImageHeight),
                ),
                // Top Rated Badge
                Positioned(
                  top: ScreenSize.spacingSmall,
                  left: ScreenSize.spacingSmall,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 10.sp, color: AppColors.textWhite),
                        SizedBox(width: 2.w),
                        Text(
                          'TOP',
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: ScreenSize.spacingSmall,
                  right: ScreenSize.spacingSmall,
                  child: IconButton(
                    icon: Icon(
                      product['isFavorite'] == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: product['isFavorite'] == true
                          ? AppColors.error
                          : AppColors.textWhite,
                      size: ScreenSize.iconMedium,
                    ),
                    onPressed: () => controller.toggleFavorite(product['id']),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.overlayLight,
                      padding: EdgeInsets.all(ScreenSize.spacingExtraSmall),
                    ),
                  ),
                ),
              ],
            ),
            
            // Product Info - Wrap in Expanded + SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category
                      if (product['category'] != null && product['category']['name'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
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
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      
                      // Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 11.sp,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${product['rating'] ?? 0.0}',
                            style: TextStyle(
                              fontSize: ScreenSize.textExtraSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Flexible(
                            child: Text(
                              '(${product['reviews'] ?? product['review_count'] ?? 0})',
                              style: TextStyle(
                                fontSize: ScreenSize.textExtraSmall,
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      
                      // Price - Show sale price if available, otherwise regular price
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
                          if (salePrice > 0 && regularPrice > salePrice) ...[
                            SizedBox(width: 4.w),
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
  
  Widget _buildBottomNavigationBar() {
    return CustomBottomNavBar(
      currentIndex: 0, // Home is selected
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            // Navigate to wishlist
            AppRoutes.toWishlist();
            break;
          case 2:
            // Navigate to cart
            Get.find<HomeController>().navigateToCart();
            break;
          case 3:
            // Navigate to coupons
            AppRoutes.toCoupons();
            break;
          case 4:
            // Navigate to profile
            Get.toNamed(AppRoutes.profile);
            break;
        }
      },
      items: [
        BottomNavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'Home',
          route: '/home',
        ),
        BottomNavItem(
          icon: Icons.favorite_border,
          selectedIcon: Icons.favorite,
          label: 'Wishlist',
          route: '/wishlist',
        ),
        BottomNavItem(
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart,
          label: 'Cart',
          route: '/cart',
        ),
        BottomNavItem(
          icon: Icons.local_offer_outlined,
          selectedIcon: Icons.local_offer,
          label: 'Coupons',
          route: '/coupons',
        ),
        BottomNavItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'Profile',
          route: '/profile',
        ),
      ],
    );
  }
}

class _CustomHeaderDelegate extends SliverPersistentHeaderDelegate {
  final HomeController controller;
  final AuthController authController;
  
  _CustomHeaderDelegate({
    required this.controller,
    required this.authController,
  });
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: ScreenSize.paddingMedium,
        vertical: ScreenSize.spacingSmall,
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: BoxConstraints(
            minHeight: 50.h,
          ),
          child: Row(
            children: [
              // Location
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.navigateToLocationSelection(),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(ScreenSize.spacingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.textWhite,
                          size: ScreenSize.iconSmall,
                        ),
                      ),
                      SizedBox(width: ScreenSize.spacingSmall),
                      Expanded(
                        child: Obx(() => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    controller.locationLabel,
                                    style: TextStyle(
                                      fontSize: ScreenSize.textSmall,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: ScreenSize.spacingExtraSmall),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: ScreenSize.iconMedium,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),
                            Text(
                              controller.locationDisplayText,
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        )),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Search
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: AppColors.textPrimary,
                  size: ScreenSize.iconMedium,
                ),
                onPressed: controller.navigateToSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  double get maxExtent => 80.h;
  
  @override
  double get minExtent => 80.h;
  
  @override
  bool shouldRebuild(_CustomHeaderDelegate oldDelegate) => false;
}

/// Banner Carousel Widget with Auto-Slide
class _BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final RxInt currentIndex;
  
  const _BannerCarousel({
    required this.banners,
    required this.currentIndex,
  });
  
  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _currentPage = 0;
    
    // Start auto-slide if more than 1 banner - delayed to prevent initial rebuild
    if (widget.banners.length > 1) {
      // Delay auto-slide start to prevent immediate rebuilds on screen load
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && widget.banners.length > 1) {
          _startAutoSlide();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  
  void _startAutoSlide() {
    // Increase timer interval to reduce rebuilds - 5 seconds instead of 3
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && widget.banners.length > 1) {
        final nextPage = (_currentPage + 1) % widget.banners.length;
        _currentPage = nextPage;
        widget.currentIndex.value = nextPage;
        // Use animateToPage without setState to prevent rebuilds
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  void _onPageChanged(int index) {
    // Only update if index actually changed to prevent unnecessary rebuilds
    if (_currentPage != index) {
      _currentPage = index;
      widget.currentIndex.value = index;
      // Remove setState to prevent widget rebuild - only update reactive value
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenSize.bannerHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.banners.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final banner = widget.banners[index];
          return GestureDetector(
            onTap: () {
              // Handle banner tap
              if (banner['link_url'] != null && (banner['link_url'] as String).isNotEmpty) {
                // Navigate to link if needed
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                image: banner['image'] != null && (banner['image'] as String).isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(banner['image'] as String),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: banner['image'] == null || (banner['image'] as String).isEmpty
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.paddingMedium,
                    vertical: ScreenSize.spacingMedium,
                  ),
                      child: Row(
                        children: [
                          // Left side - Text Content
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (banner['title'] != null && (banner['title'] as String).isNotEmpty)
                                  Text(
                                    banner['title'] as String,
                                    style: TextStyle(
                                      fontSize: ScreenSize.textMedium,
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                if (banner['title'] != null && (banner['title'] as String).isNotEmpty)
                                  SizedBox(height: ScreenSize.spacingXSmall),
                            Text(
                              banner['description'] ?? '70% OFF',
                              style: TextStyle(
                                fontSize: ScreenSize.headingLarge,
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                                if (banner['subtitle'] != null && (banner['subtitle'] as String).isNotEmpty) ...[
                                  SizedBox(height: ScreenSize.spacingSmall),
                                  Text(
                                    banner['subtitle'] as String,
                                    style: TextStyle(
                                      fontSize: ScreenSize.textMedium,
                                      color: AppColors.textWhite.withOpacity(0.9),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                                if (banner['link_text'] != null && (banner['link_text'] as String).isNotEmpty) ...[
                              SizedBox(height: ScreenSize.spacingMedium),
                              ElevatedButton(
                                onPressed: () {
                                  if (banner['link_url'] != null && (banner['link_url'] as String).isNotEmpty) {
                                    // Handle link navigation
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ScreenSize.paddingMedium,
                                    vertical: ScreenSize.spacingSmall,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                                  ),
                                  elevation: 2,
                                ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          banner['link_text'] as String,
                                          style: TextStyle(
                                            fontSize: ScreenSize.textMedium,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: ScreenSize.spacingSmall),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: ScreenSize.iconSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                      // Right side - Image (if banner has image)
                      if (banner['image'] != null && (banner['image'] as String).isNotEmpty)
                        SizedBox(
                          width: 120.w,
                          height: 120.h,
                              child: CachedNetworkImage(
                                imageUrl: banner['image'] as String,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.image,
                                  size: 80.w,
                                  color: AppColors.textWhite.withOpacity(0.3),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Page indicators
                  if (widget.banners.length > 1)
                    Positioned(
                      bottom: ScreenSize.spacingSmall,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.banners.length,
                          (indicatorIndex) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              width: indicatorIndex == _currentPage ? 24.w : 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: indicatorIndex == _currentPage 
                                    ? AppColors.textWhite 
                                    : AppColors.textWhite.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      );

  }
}
