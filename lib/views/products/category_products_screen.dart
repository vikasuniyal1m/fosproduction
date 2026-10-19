import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/category_products_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/product_grid_card.dart';
import '../../utils/silent_loading.dart';

/// Category Products Screen — See All / shop by category.
class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);

    if (Get.isRegistered<CategoryProductsController>()) {
      Get.delete<CategoryProductsController>();
    }
    final controller = Get.put(CategoryProductsController());

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
          controller.categoryName,
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
        final showBlockingLoader = SilentLoading.blockUi(
          isLoading: controller.isLoading.value,
          hasContent: controller.products.isNotEmpty,
        );
        if (showBlockingLoader) {
          return const LoadingWidget();
        }
        if (controller.products.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          onRefresh: controller.loadCategoryProducts,
          child: _buildProductsGrid(controller),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ScreenSize.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ScreenSize.paddingLarge),
              decoration: const BoxDecoration(
                color: AppColors.backgroundGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: ScreenSize.iconExtraLarge,
                color: AppColors.textTertiary,
              ),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(CategoryProductsController controller) {
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
        itemCount: controller.products.length,
        itemBuilder: (context, index) {
          final product = controller.products[index];
          return ProductGridCard(
            key: ValueKey('cat_${product['id']}'),
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
