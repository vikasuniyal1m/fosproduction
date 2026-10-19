import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/home_controller.dart';
import '../../utils/getx_registry.dart';
import '../../widgets/product_grid_card.dart';

/// Digital Products — See All from home.
class DigitalProductsScreen extends StatefulWidget {
  const DigitalProductsScreen({super.key});

  @override
  State<DigitalProductsScreen> createState() => _DigitalProductsScreenState();
}

class _DigitalProductsScreenState extends State<DigitalProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GetXRegistry.home().loadDigitalProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = GetXRegistry.home();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: ScreenSize.iconMedium,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Digital Products',
          style: TextStyle(
            fontSize: ScreenSize.isTablet
                ? ScreenSize.headingMedium
                : ScreenSize.headingSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.digitalProducts.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          onRefresh: () async => controller.loadDigitalProducts(),
          child: _buildProductsGrid(controller),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: ScreenSize.paddingMedium,
          vertical: ScreenSize.spacingLarge,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ScreenSize.screenWidth >= 600 ? 200 : 160,
              height: ScreenSize.screenWidth >= 600 ? 200 : 160,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_video_rounded,
                size: ScreenSize.screenWidth >= 600 ? 100 : 80,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            Text(
              'No Digital Products Yet',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 600
                    ? ScreenSize.headingSmall
                    : ScreenSize.textLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            Text(
              'Check back soon for amazing digital products!',
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(HomeController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenSize.paddingMedium,
        vertical: ScreenSize.spacingSmall,
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ScreenSize.screenWidth >= 1200
              ? 5
              : (ScreenSize.screenWidth >= 1000
                  ? 4
                  : (ScreenSize.screenWidth >= 768
                      ? 3
                      : (ScreenSize.screenWidth >= 600 ? 3 : 2))),
          crossAxisSpacing: ScreenSize.spacingSmall,
          mainAxisSpacing: ScreenSize.spacingSmall,
          childAspectRatio: ScreenSize.screenWidth >= 768
              ? 0.52
              : ScreenSize.productCardAspectRatio,
        ),
        itemCount: controller.digitalProducts.length,
        itemBuilder: (context, index) {
          final product = controller.digitalProducts[index];
          return ProductGridCard(
            key: ValueKey('digital_${product['id']}'),
            product: product,
            onTap: () => controller.navigateToProductDetails(
              product['id'],
              preview: product,
            ),
            onFavoriteToggle: () => controller.toggleFavorite(product['id']),
          );
        },
      ),
    );
  }
}
