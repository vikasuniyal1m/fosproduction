import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../utils/cache_manager.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/silent_loading.dart';
import '../../utils/digital_product_type.dart';
import '../../widgets/stable_cached_image.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/favorite_button.dart';
import '../../utils/getx_registry.dart';
import '../../widgets/video_preview_widget.dart';
import '../../widgets/cached_video_preview_widget.dart';
import '../fos_lens/fos_lens_entry.dart';
import '../../watch_faces/watch_faces_config.dart';
import '../../widgets/cached_audio_preview_widget.dart';
import '../products/digital_preview_player_screen.dart';
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
    final homeController = GetXRegistry.home();
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    
    // Initialize cart controller once (singleton)
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    
    // Initialize notification controller once (singleton)
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController());
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
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => homeController.loadHomeData(silent: true),
                child: CustomScrollView(
                  slivers: [
                    // Custom Header with Location, Cart, Search, Profile
                    _buildCustomHeader(homeController, authController),

                    // Content
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar (tappable)
                          _buildSearchBar(homeController),
                          SizedBox(height: ScreenSize.spacingSmall),
                          _buildFosLensBanner(context),
                          if (WatchFacesConfig.isFeatureEnabled) ...[
                            SizedBox(height: ScreenSize.spacingSmall),
                            _buildWatchFacesBanner(context),
                          ],
                          SizedBox(height: ScreenSize.spacingMedium),

                          // My Orders Section
                          _buildMyOrdersSection(homeController),
                          SizedBox(height: ScreenSize.spacingMedium),

                          // Promotional Banner Carousel
                          _buildPromotionalBanner(homeController),
                          SizedBox(height: ScreenSize.spacingMedium),

                          // Trust Badges Strip
                          _buildTrustBadges(),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // Category Grid (2×3)
                          _buildCategoryGrid(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // Digital Products
                          _buildDigitalProductsSection(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // Home Decor Picks
                          _buildCategoryShowcase(
                            homeController,
                            title: '🎬 Video',
                            products: homeController.homeDecorProducts,
                            categoryId: 13,
                          ),

                          // Featured Products Carousel
                          _buildFeaturedProductsShowcase(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // 🚀 New Arrivals Section
                          _buildCategoryShowcase(
                            homeController,
                            title: '🚀 New Arrivals',
                            products: homeController.newArrivalsProducts,
                            categoryId: 0,
                            hideSeeAll: true,
                          ),

                          // 💰 Budget Picks
                          _buildCategoryShowcase(
                            homeController,
                            title: r'💰 Shop Under $50',
                            products: homeController.budgetProducts,
                            categoryId: 0,
                            hideSeeAll: true,
                          ),

                          // 🎁 Gifts for You (Random items)
                          Obx(() {
                            print('Gifts section - Products count: ${homeController.products.length}');
                            if (homeController.products.isEmpty) {
                              print('No products found in gifts section');
                            }
                            return _buildCategoryShowcase(
                              homeController,
                              title: '🎁 Gifts for You',
                              products: homeController.products,
                              categoryId: 0,
                              hideSeeAll: true,
                            );
                          }),

                          // 🤝 Refer & Earn Banner
                          Obx(() => GestureDetector(
                            onTap: () => AppRoutes.toReferralProgram(),
                            child: _buildPromoBannerCard(
                              'Refer & Earn!',
                              'Give \$10, Get \$10 for every friend you refer.',
                              Icons.group_add_outlined,
                              AppColors.accent,
                              count: homeController.referralCount.value,
                            ),
                          )),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // Health & Wellness
                          _buildCategoryShowcase(
                            homeController,
                            title: '🎵 Audio',
                            products: homeController.healthProducts,
                            categoryId: 12,
                          ),

                          // 📺 Media & Entertainment spotlight
                          _buildCategoryShowcase(
                            homeController,
                            title: '📺 Media Spotlight',
                            products: homeController.mediaShowcaseProducts,
                            categoryId: 0,
                          ),

                          // ✨ Stickers Showcase
                          _buildCategoryShowcase(
                            homeController,
                            title: '✨ Stickers',
                            products: homeController.stickerProducts,
                            categoryId: 15,
                          ),

                          // Deals / Up to 70% off
                          _buildSectionHeader('🔥 Deals of the Day', 'Popular', () => homeController.showDiscountedSortDialog()),
                          SizedBox(height: ScreenSize.spacingSmall),
                          _buildDiscountedProducts(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // Stationery Favorites
                          _buildCategoryShowcase(
                            homeController,
                            title: '✨ More Stickers',
                            products: homeController.stationeryProducts,
                            categoryId: 15,
                          ),

                          // Collectibles Corner
                          _buildCategoryShowcase(
                            homeController,
                            title: '🎬 More Videos',
                            products: homeController.collectiblesProducts,
                            categoryId: 13,
                          ),

                          // 🌟 Customer Reviews (Static)
                          _buildReviewsSection(),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // Cartoon Line
                          _buildCategoryShowcase(
                            homeController,
                            title: '🎵 More Audio',
                            products: homeController.cartoonLineProducts,
                            categoryId: 12,
                          ),

                          // Top Rated Picks
                          _buildTopRatedSection(homeController),
                          SizedBox(height: ScreenSize.sectionSpacing),

                          // Recently Viewed
                          _buildRecentlyViewed(homeController),

                          // Footer
                          _buildFooter(),
                          SizedBox(height: ScreenSize.spacingLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() {
                if (!SilentLoading.blockUi(
                  isLoading: homeController.isLoading.value,
                  hasContent: homeController.hasEverLoaded.value,
                )) {
                  return const SizedBox.shrink();
                }
                return const ColoredBox(
                  color: AppColors.background,
                  child: LoadingWidget(),
                );
              }),
            ],
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

  /// Tappable Search Bar
  Widget _buildSearchBar(HomeController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
      child: GestureDetector(
        onTap: controller.navigateToSearch,
        child: Container(
          height: ScreenSize.isTablet ? ScreenSize.buttonHeightLarge : ScreenSize.buttonHeightMedium,
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textTertiary, size: ScreenSize.iconSmall),
              SizedBox(width: ScreenSize.spacingSmall),
              Expanded(
                child: Text(
                  'Search Health, Decor, Collectibles...',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: ScreenSize.textMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.tune_outlined, color: AppColors.textTertiary, size: ScreenSize.iconSmall),
            ],
          ),
        ),
      ),
    );
  }

  /// Trust Badges Strip
  Widget _buildTrustBadges() {
    final badges = [
      {'icon': Icons.local_shipping_outlined, 'text': 'Free Shipping'},
      {'icon': Icons.verified_user_outlined, 'text': 'Secure Pay'},
      {'icon': Icons.support_agent_outlined, 'text': '24/7 Support'},
      {'icon': Icons.replay_outlined, 'text': 'Easy Returns'},
    ];

    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
        itemCount: badges.length,
        separatorBuilder: (_, __) => SizedBox(width: ScreenSize.spacingSmall),
        itemBuilder: (context, index) {
          final badge = badges[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingSmall, vertical: ScreenSize.spacingTiny),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(ScreenSize.borderRadiusLarge),
              border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badge['icon'] as IconData, size: ScreenSize.iconSmall, color: AppColors.primary),
                SizedBox(width: 4.w),
                Text(
                  badge['text'] as String,
                  style: TextStyle(
                    fontSize: ScreenSize.textExtraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWatchFacesBanner(BuildContext context) {
    final subtitle = !kIsWeb && Platform.isIOS
        ? 'Free fruit-themed faces for Apple Watch'
        : (!kIsWeb && Platform.isAndroid
            ? 'Galaxy & Wear OS watch faces from FOS'
            : 'Watch faces for Apple Watch & Wear OS');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
      child: Material(
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: AppRoutes.toWatchFaces,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.circular(ScreenSize.borderRadiusMedium),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(ScreenSize.paddingMedium),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.watch,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: ScreenSize.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FOS Watch Faces',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFosLensBanner(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
      child: Material(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        child: InkWell(
          onTap: () => showFosLensImageSourceSheet(context),
          child: Padding(
            padding: EdgeInsets.all(ScreenSize.paddingMedium),
            child: Row(
              children: [
                Icon(Icons.camera_enhance, color: AppColors.primary),
                SizedBox(width: ScreenSize.spacingSmall),
                Expanded(
                  child: Text(
                    'FOS Lens - Add Bible Quotes to Photos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Category Grid (2 rows × 3 cols)
  Widget _buildCategoryGrid(HomeController controller) {
    // Main categories with image assets
    final mainCategories = [
      {'id': 6, 'name': 'Cartoon Line', 'image': 'assets/category/cartoonline.png'},
      {'id': 3, 'name': 'Collectibles', 'image': 'assets/category/collectibles.png'},
      {'id': 5, 'name': 'Health', 'image': 'assets/category/medicine-drug.png'},
      {'id': 2, 'name': 'Home Decor', 'image': 'assets/category/home-decor.png'},
      {'id': 4, 'name': 'Stationery', 'image': 'assets/category/stationery.png'},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          child: Text(
            'Shop by Category',
            style: TextStyle(
              fontSize: ScreenSize.headingSmall, // Unified Heading Size
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: ScreenSize.spacingSmall),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ScreenSize.screenWidth >= 1200 ? 6 : (ScreenSize.screenWidth >= 1000 ? 5 : (ScreenSize.screenWidth >= 768 ? 4 : 3)),
              mainAxisSpacing: ScreenSize.spacingSmall,
              crossAxisSpacing: ScreenSize.spacingSmall,
              childAspectRatio: ScreenSize.screenWidth >= 1200 ? 1.2 : (ScreenSize.screenWidth >= 1000 ? 1.1 : (ScreenSize.screenWidth >= 768 ? 1.0 : 1.15)),
            ),
            itemCount: mainCategories.length,
            itemBuilder: (context, index) {
              final cat = mainCategories[index];
              return GestureDetector(
                onTap: () {
                  Get.toNamed('/category-products', arguments: {
                    'categoryId': cat['id'],
                    'categoryName': cat['name'],
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                    border: Border.all(color: AppColors.border, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Category Icon
                      Container(
                        width: ScreenSize.screenWidth >= 1200 ? 60.w : 
                               (ScreenSize.screenWidth >= 1000 ? 55.w : 
                                (ScreenSize.screenWidth >= 768 ? 50.w : 45.w)),
                        height: ScreenSize.screenWidth >= 1200 ? 60.h : 
                               (ScreenSize.screenWidth >= 1000 ? 55.h : 
                                (ScreenSize.screenWidth >= 768 ? 50.h : 45.h)),
                        child: Image.asset(
                          cat['image'] as String,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: ScreenSize.spacingXSmall),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textLarge :
                                     (ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium :
                                      (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium)),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Featured Products Showcase with Carousel and See All
  Widget _buildFeaturedProductsShowcase(HomeController controller) {
    return Obx(() {
      if (controller.featuredProducts.isEmpty) return const SizedBox.shrink();
      
      return Column(
        mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with See All and Sort
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '⭐ Featured Products',
                  style: TextStyle(
                    fontSize: ScreenSize.isTablet ? ScreenSize.headingMedium : ScreenSize.headingSmall,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    // Sort button
                    GestureDetector(
                      onTap: () => controller.showSortDialog(),
                      child: Row(
                        children: [
                          Text(
                            'Sort',
                            style: TextStyle(
                              fontSize: ScreenSize.textSmall,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: ScreenSize.spacingExtraSmall),
                          Icon(Icons.sort, size: ScreenSize.iconSmall, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    SizedBox(width: ScreenSize.spacingMedium),
                    // See All button
                    /*GestureDetector(
                      onTap: () {
                        Get.toNamed('/featured-products', arguments: {
                          'title': 'Featured Products',
                          'products': controller.featuredProducts.toList(),
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              fontSize: ScreenSize.textSmall,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: ScreenSize.iconSmall, color: AppColors.primary),
                        ],
                      ),
                    ),*/
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          // Horizontal product carousel
          SizedBox(
            height: ScreenSize.productCardHorizontalHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              cacheExtent: 600,
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
              itemCount: controller.featuredProducts.length,
              separatorBuilder: (_, __) => SizedBox(width: ScreenSize.spacingSmall),
              itemBuilder: (context, index) {
                final product = controller.featuredProducts[index];
                return _buildHomeProductCard(controller, product);
              },
            ),
          ),
          SizedBox(height: ScreenSize.sectionSpacing),
        ],
      );
    });
  }

  /// Reusable Category Showcase Section (horizontal scroll)
  Widget _buildCategoryShowcase(
    HomeController controller, {
    required String title,
    required RxList<Map<String, dynamic>> products,
    required int categoryId,
    bool hideSeeAll = false,
  }) {
    return Obx(() {
      print('Building showcase: $title - Products count: ${products.length}');
      if (products.isEmpty) {
        print('Showcase $title is empty, returning SizedBox.shrink()');
        return const SizedBox.shrink();
      }
      return Column(
        mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with See All
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ScreenSize.isTablet ? ScreenSize.headingMedium : ScreenSize.headingSmall,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!hideSeeAll) GestureDetector(
                  onTap: () {
                    Get.toNamed('/category-products', arguments: {
                      'categoryId': categoryId,
                      'categoryName': title.replaceAll(RegExp(r'[^\w\s&]'), '').trim(),
                      'products': products.toList(),
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: ScreenSize.iconSmall, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          // Horizontal product list - increased height for better visibility
          SizedBox(
            height: ScreenSize.productCardHorizontalHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              cacheExtent: 600,
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
              itemCount: products.length,
              separatorBuilder: (_, __) => SizedBox(width: ScreenSize.spacingSmall),
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildHomeProductCard(controller, product);
              },
            ),
          ),
          SizedBox(height: ScreenSize.sectionSpacing),
        ],
      );
    });
  }

  Widget _buildFavoriteButton(HomeController controller, Map<String, dynamic> product) {
    return Positioned(
      top: ScreenSize.screenWidth >= 1000 ? 6 : (ScreenSize.screenWidth >= 768 ? 5 : 4),
      right: ScreenSize.screenWidth >= 1000 ? 6 : (ScreenSize.screenWidth >= 768 ? 5 : 4),
      child: FavoriteButton(
        productId: product['id'],
        onToggle: () => controller.toggleFavorite(product['id']),
      ),
    );
  }

  /// Recently Viewed Section
  Widget _buildRecentlyViewed(HomeController controller) {
    return Obx(() {
      if (controller.recentlyViewed.isEmpty) return const SizedBox.shrink();
      return Column(
        mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
            child: Text(
              '🕐 Recently Viewed',
              style: TextStyle(
                fontSize: ScreenSize.headingSmall, // Unified Heading Size
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          SizedBox(
            height: ScreenSize.productCardHorizontalHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
              itemCount: controller.recentlyViewed.length,
              separatorBuilder: (_, __) => SizedBox(width: ScreenSize.spacingSmall),
              itemBuilder: (context, index) {
                return _buildHomeProductCard(controller, controller.recentlyViewed[index]);
              },
            ),
          ),
          SizedBox(height: ScreenSize.sectionSpacing),
        ],
      );
    });
  }

  /// Promotional Banner Card (Static for Referral/Promos)
  Widget _buildPromoBannerCard(String title, String subtitle, IconData icon, Color color, {int? count}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
      padding: EdgeInsets.all(ScreenSize.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: ScreenSize.iconLarge),
          ),
          SizedBox(width: ScreenSize.spacingMedium),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ScreenSize.headingSmall,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (count != null) ...[
                      SizedBox(width: ScreenSize.spacingSmall),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ScreenSize.spacingSmall,
                          vertical: ScreenSize.spacingTiny,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: color),
        ],
      ),
    );
  }

  /// Build video thumbnail for video products
  Widget _buildVideoThumbnail(Map<String, dynamic> product, {BoxFit fit = BoxFit.cover}) {
    // Check if banner image is available for video products
    final bannerUrl = product['banner']?.toString();
    final hasBanner = bannerUrl != null && bannerUrl.isNotEmpty;
    
    // If banner is available, use it instead of video placeholder
    if (hasBanner) {
      return StableCachedImage(
        imageUrl: bannerUrl,
        cacheKey: 'video_banner_${product['id']}',
        fit: fit,
        placeholderColor: Colors.black,
        errorIconColor: Colors.white54,
      );
    }
    
    // If no banner, use the regular product image as fallback
    final productImage = product['image']?.toString();
    if (productImage != null && productImage.isNotEmpty) {
      final cleanImage = productImage.replaceAll('\\/', '/').trim();
      return StableCachedImage(
        imageUrl: cleanImage,
        cacheKey: 'home_product_${product['id']}',
        fit: fit,
        placeholderColor: Colors.black,
        errorIconColor: Colors.white54,
        errorIconSize: 40,
      );
    }
    
    // Final fallback - show video placeholder
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video placeholder with play icon
          Icon(
            Icons.videocam,
            size: 40,
            color: Colors.white.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  /// Build audio thumbnail for audio products
  Widget _buildAudioThumbnail(Map<String, dynamic> product, {BoxFit fit = BoxFit.cover}) {
    // Check if banner image is available for audio products
    final bannerUrl = product['banner']?.toString();
    final hasBanner = bannerUrl != null && bannerUrl.isNotEmpty;
    
    // If banner is available, use it instead of audio preview
    if (hasBanner) {
      return StableCachedImage(
        imageUrl: bannerUrl,
        cacheKey: 'audio_banner_${product['id']}',
        fit: fit,
      );
    }
    
    // If no banner, use the regular product image as fallback
    final productImage = product['image']?.toString();
    if (productImage != null && productImage.isNotEmpty) {
      final cleanImage = productImage.replaceAll('\\/', '/').trim();
      return StableCachedImage(
        imageUrl: cleanImage,
        cacheKey: 'home_product_${product['id']}',
        fit: fit,
      );
    }
    
    // Get audio URL from digital_file_path or video_url
    String audioUrl = '';
    if (product['digital_file_path'] != null) {
      final digitalFilePath = product['digital_file_path'].toString();
      if (digitalFilePath.startsWith('[')) {
        // JSON array format
        try {
          final List<dynamic> files = json.decode(digitalFilePath);
          if (files.isNotEmpty) {
            audioUrl = '${ApiService.imageBaseUrl}uploads/digital_products/${files.first.toString()}';
          }
        } catch (e) {
          print('Error parsing digital_file_path: $e');
        }
      } else {
        // Direct file path
        audioUrl = '${ApiService.imageBaseUrl}uploads/digital_products/$digitalFilePath';
      }
    }
    
    if (audioUrl.isEmpty && product['video_url'] != null) {
      audioUrl = product['video_url'].toString();
    }
    
    if (audioUrl.isEmpty) {
      // Fallback to static thumbnail if no audio URL
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.blue.withOpacity(0.6),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Audio icon
            Icon(
              Icons.audiotrack,
              size: 40,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      );
    }
    
    // Use cached audio widget only if no banner available
    return CachedAudioPreviewWidget(
      audioUrl: audioUrl,
      autoPlay: false, // Don't auto-play in home screen
      previewDuration: const Duration(seconds: 12),
      onPreviewEnd: () {
        // Show purchase prompt when preview ends
        Get.snackbar(
          'Purchase Required',
          'Please purchase this product to listen to the full audio',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      },
    );
  }

  /// Static Reviews Section
  Widget _buildReviewsSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          child: Text(
            '🌟 What our customers say',
            style: TextStyle(
              fontSize: ScreenSize.headingSmall, // Unified Heading Size
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: ScreenSize.spacingSmall),
        SizedBox(
          height: 100.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
            children: [
              _buildReviewCard('Vikram Singh', 'Amazing quality stickers! Fully satisfied.', 5),
              SizedBox(width: 10.w),
              _buildReviewCard('Anjali P.', 'Home decor items are unique and beautiful.', 5),
              SizedBox(width: 10.w),
              _buildReviewCard('Rahul K.', 'Great collectibles collection. Highly recommend!', 4.5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String name, String comment, double rating) {
    return Container(
      width: 250.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: ScreenSize.textSmall)),
              const Spacer(),
              Icon(Icons.star, color: Colors.amber, size: ScreenSize.iconExtraSmall),
              Text(' $rating', style: TextStyle(fontSize: ScreenSize.textSmall)),
            ],
          ),
          SizedBox(height: ScreenSize.spacingTiny),
          Text(
            comment,
            style: TextStyle(fontSize: ScreenSize.textSmall, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Footer Info
  Widget _buildFooter() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
      padding: EdgeInsets.all(ScreenSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
      ),
      child: Column(
        children: [
          Icon(Icons.eco, size: 28.w, color: AppColors.primary),
          SizedBox(height: 6.h),
          Text(
            'Fruits of Spirit',
            style: TextStyle(
              fontSize: ScreenSize.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your one-stop shop for all things creative & healthy',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 14.w, color: AppColors.textTertiary),
              SizedBox(width: 4.w),
              Text(
                'support@fruitofspirit.com',
                style: TextStyle(fontSize: 10.sp, color: AppColors.textTertiary),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Made with ❤️',
            style: TextStyle(fontSize: 10.sp, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  
  Widget _buildPromotionalBanner(HomeController controller) {
    return Obx(() {
      if (controller.banners.isEmpty) {
        // Default banner if no banners from API (Commented out per user request)
        /*
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
                    mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
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
        */
        
        // Return a sleek loading state or empty box while banners fetch
        return Container(
          height: ScreenSize.bannerHeight,
          margin: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
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

  /// My Orders Section – with notification badge and responsive icons
  Widget _buildMyOrdersSection(HomeController homeController) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: () {
            final profileController = Get.put(ProfileController());
            profileController.navigateToOrders();
          },
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSize.spacingMedium,
              vertical: ScreenSize.spacingSmall * 1.5,
            ),
            child: Row(
              children: [
                // Icon container with notification badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(ScreenSize.spacingSmall),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                      ),
                      child: Stack(
                        children: [
                          // Background notification icon
                          // Icon(
                          //   Icons.notifications_active,
                          //   size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconLarge :
                          //          (ScreenSize.screenWidth >= 768 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                          //   color: AppColors.primary.withOpacity(0.3),
                          // ),
                          // Main shopping bag icon
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconLarge : 
                                   (ScreenSize.screenWidth >= 768 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    // Notification badge
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Obx(() => homeController.activeOrdersCount.value > 0
                        ? Container(
                          width: ScreenSize.screenWidth >= 1000 ? 20.w : 
                                 (ScreenSize.screenWidth >= 768 ? 18.w : 16.w),
                          height: ScreenSize.screenWidth >= 1000 ? 20.h : 
                                 (ScreenSize.screenWidth >= 768 ? 18.h : 16.h),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBackground, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              homeController.activeOrdersCount.value.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall :
                                           (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        : const SizedBox.shrink()),
                    ),
                  ],
                ),
                SizedBox(width: ScreenSize.spacingMedium),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Orders',
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textLarge :
                                     (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textLarge),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: ScreenSize.spacingTiny),
                      Text(
                        'View orders & download digital products',
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall :
                                     (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textSmall),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconLarge : 
                         (ScreenSize.screenWidth >= 768 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Digital Products – alag widget/section (sirf digital products: music/video, download after payment)
  Widget _buildDigitalProductsSection(HomeController controller) {
    return Obx(() {
      // TEMP: Use regular products to test if UI works
      final allProducts = controller.products;
      final digitalList = allProducts.where((p) => 
        p['is_digital'] == true || p['is_digital'] == 1
      ).toList();
      
      final list = digitalList.isNotEmpty ? digitalList : controller.digitalProducts;
      
      // Debug print
      print('=== HomeScreen._buildDigitalProductsSection ===');
      print('All products length: ${allProducts.length}');
      print('Digital products from all products: ${digitalList.length}');
      print('Digital products list length: ${list.length}');
      if (list.isNotEmpty) {
        print('First digital product: ${list.first}');
        print('First product is_digital: ${list.first['is_digital']}');
        print('First product media_type: ${list.first['media_type']}');
      }
      print('===========================================');
      
      return Column(
        mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with See All
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🎵 Digital Products',
                  style: TextStyle(
                    fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.headingMedium : ScreenSize.headingSmall,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => AppRoutes.toDigitalProducts(),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: ScreenSize.iconSmall, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          SizedBox(
            height: ScreenSize.productCardHorizontalHeight,
            child: list.isEmpty
                ? _buildDigitalProductsPlaceholder()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final product = list[index];
                      return Padding(
                        padding: EdgeInsets.only(right: ScreenSize.spacingMedium),
                        child: _buildHomeProductCard(controller, product),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  /// Placeholder when no digital products (music/video) – T-shirt etc. yahan nahi aate
  Widget _buildDigitalProductsPlaceholder() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.music_video_rounded, size: 48, color: AppColors.primary.withOpacity(0.6)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Music & Video',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Digital products will appear here once added',
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

  /// Shared horizontal product card — used across all home sections
  Widget _buildHomeProductCard(HomeController controller, Map<String, dynamic> product) {
    final name = product['name'] as String? ?? '';
    final regularPrice = (product['price'] ?? 0.0) as num;
    final salePrice = product['sale_price'] as num?;
    final displayPrice = (salePrice ?? regularPrice).toDouble();
    final rating = (product['rating'] ?? 0.0) as double;

    return GestureDetector(
      key: ValueKey('home_card_${product['id']}'),
      onTap: () {
        controller.addToRecentlyViewed(product);
        controller.navigateToProductDetails(product['id'], preview: product);
      },
      child: Container(
        width: ScreenSize.productCardHorizontalWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Media
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(ScreenSize.tileBorderRadius)),
                  child: SizedBox(
                    height: ScreenSize.productCardHorizontalImageHeight,
                    width: double.infinity,
                    child: ProductCardImage(
                      product: product,
                      cacheKeyPrefix: 'home_product',
                    ),
                  ),
                ),
                // Media type badge
                // if (isVideo || isAudio)
                //   Positioned(
                //     top: 8,
                //     right: 8,
                //     child: Container(
                //       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //       decoration: BoxDecoration(
                //         color: isVideo ? Colors.red.withOpacity(0.9) : Colors.blue.withOpacity(0.9),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           Icon(
                //             isVideo ? Icons.videocam : Icons.audiotrack,
                //             size: 12,
                //             color: Colors.white,
                //           ),
                //           SizedBox(width: 4),
                //           Text(
                //             isVideo ? 'Video' : 'Audio',
                //             style: TextStyle(
                //               color: Colors.white,
                //               fontSize: 10,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // Digital badge
                /*Positioned(
                  bottom: ScreenSize.spacingSmall,
                  left: ScreenSize.spacingSmall,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isStickerPack ? Colors.orange : AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isStickerPack ? Icons.sticky_note_2 : Icons.download, size: 10, color: AppColors.textWhite),
                        SizedBox(width: 4),
                        Text(isStickerPack ? 'Sticker' : 'Digital', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
                      ],
                    ),
                  ),
                ),*/
                // Favorite button
                _buildFavoriteButton(controller, product),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingSmall, vertical: ScreenSize.spacingSmall),
                child: Column(
                  mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    if (product['category'] != null && product['category']['name'] != null)
                      Text(
                        product['category']['name'].toString(),
                        style: TextStyle(
                          fontSize: ScreenSize.textExtraSmall,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: ScreenSize.spacingTiny),
                    // Product Name
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,  // Reduced size to prevent overflow
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                    const Spacer(),
                    // Price & Rating Row
                    Row(
                      children: [
                        Text(
                          '\$${displayPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (rating > 0) ...[
                          const Spacer(),
                          Icon(Icons.star, size: ScreenSize.iconExtraSmall, color: AppColors.accent),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(fontSize: ScreenSize.textExtraSmall, color: AppColors.textSecondary),
                          ),
                        ],
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

  
  Widget _buildCategoriesSection(HomeController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
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
            // Filter out "All" and "Stickers" for display
            final displayCategories = controller.categories.where((cat) => cat['id'] != 0 && cat['id'] != 15).toList();
            
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
                              style: TextStyle(fontSize: ScreenSize.headingLarge),
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
    } else if (name.contains('sticker')) {
      return '✨';
    } else if (name.contains('cartoon')) {
      return '🎨';
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
                fontSize: 20.sp,
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
  
  Widget _buildDiscountedProducts(HomeController controller) {
    return Obx(() {
      if (controller.discountedProducts.isEmpty) {
        return SizedBox.shrink();
      }

      return Container(
        height: ScreenSize.productCardHorizontalHeight,
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
        mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
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
                  height: ScreenSize.productCardHorizontalHeight,
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
      onTap: () => controller.navigateToProductDetails(product['id'], preview: product),
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
          mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
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
                // Digital badge
                Positioned(
                  top: ScreenSize.spacingSmall,
                  left: ScreenSize.spacingSmall,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, size: 10, color: AppColors.textWhite),
                        SizedBox(width: 4),
                        Text(
                          'Digital',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite button
                _buildFavoriteButton(controller, product),
              ],
            ),
            // Product Info - Wrap in Expanded + SingleChildScrollView to fix tablet overflow
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), // Prevent individual card scrolling unless needed
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        maxLines: 1,
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
      onTap: () => controller.navigateToProductDetails(product['id'], preview: product),
      child: Container(
        width: ScreenSize.productCardHorizontalWidth,
        margin: EdgeInsets.only(right: ScreenSize.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
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
                if (product['is_digital'] == true)
                  Positioned(
                    bottom: ScreenSize.spacingSmall,
                    left: ScreenSize.spacingSmall,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download, size: 10, color: AppColors.textWhite),
                          SizedBox(width: 4),
                          Text('Digital', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
                        ],
                      ),
                    ),
                  ),
                // Favorite button
                _buildFavoriteButton(controller, product),
              ],
            ),
            
            // Product Info - Wrap in Expanded + SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        maxLines: 1,
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
      onTap: () => controller.navigateToProductDetails(product['id'], preview: product),
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
          mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
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
                _buildFavoriteButton(controller, product),
              ],
            ),
            
            // Product Info - Wrap in Expanded + SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        maxLines: 1,
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
            minHeight: ScreenSize.isTablet ? 100 * (ScreenSize.screenWidth / 768) : 75,
            maxHeight: ScreenSize.isTablet ? 100 * (ScreenSize.screenWidth / 768) : 75,
          ),
          child: Row(
            children: [
              // Location Selector
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
                          mainAxisSize: MainAxisSize.min,  // Added to prevent overflow
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
              
              // Notification Icon with Badge
              SizedBox(
                width: 48,
                child: GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.textPrimary,
                          size: ScreenSize.iconLarge,
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.notifications),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                      // Notification Badge
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Obx(() {
                          final notificationController = Get.isRegistered<NotificationController>() 
                              ? Get.find<NotificationController>() 
                              : Get.put(NotificationController());
                          return notificationController.unreadCount.value > 0
                            ? Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                notificationController.unreadCount.value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            )
                            : const SizedBox.shrink();
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  double get maxExtent => ScreenSize.isTablet ? 100 * (ScreenSize.screenWidth / 768) : 75;
  
  @override
  double get minExtent => ScreenSize.isTablet ? 100 * (ScreenSize.screenWidth / 768) : 75;
  
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
    
    // Start auto-slide if more than 1 banner
    if (widget.banners.length > 1) {
      Future.delayed(const Duration(seconds: 1), () {
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
    // Auto-slide every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && widget.banners.length > 1) {
        final nextPage = (_currentPage + 1) % widget.banners.length;
        _currentPage = nextPage;
        widget.currentIndex.value = nextPage;
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
              if (banner['link_url'] != null && (banner['link_url'] as String).isNotEmpty) {
                // Navigate to link if needed
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                color: AppColors.backgroundGrey,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner image only – no text overlay
                  if (banner['image'] != null && (banner['image'] as String).isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: banner['image'] as String,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.backgroundGrey,
                        child: Center(
                          child: Icon(Icons.image_not_supported, size: ScreenSize.iconLarge, color: AppColors.textTertiary),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.image, size: ScreenSize.iconLarge, color: AppColors.textWhite.withOpacity(0.3)),
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
                              width: (indicatorIndex == _currentPage ? 24 : 8) * ScreenSize.screenWidth / 375, // Proportional width
                              height: 6 * ScreenSize.screenHeight / 812, // Proportional height
                              decoration: BoxDecoration(
                                color: indicatorIndex == _currentPage
                                    ? AppColors.textWhite
                                    : AppColors.textWhite.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
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
