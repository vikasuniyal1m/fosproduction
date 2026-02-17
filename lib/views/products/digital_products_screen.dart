import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/loading_widget.dart';

/// Digital Products Screen – responsive grid, content ache se dikhane ke liye
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
      final controller = Get.find<HomeController>();
      controller.loadDigitalProducts();
    });
  }

  /// Responsive grid columns: small phone 2, tablet 3, large tablet 4.
  static int _crossAxisCount(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    if (width >= 400) return 2;
    return 2;
  }

  /// Padding so content doesn't stick to edges on any screen.
  static double _horizontalPadding(double width) {
    if (width >= 600) return 20;
    if (width >= 360) return 16;
    return 12;
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.find<HomeController>();
    final width = MediaQuery.of(context).size.width;
    final crossCount = _crossAxisCount(width);
    final hPadding = _horizontalPadding(width);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: ScreenSize.iconMedium, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Icon(Icons.download_rounded, size: ScreenSize.isTablet ? 26 : 22, color: AppColors.primary),
            SizedBox(width: width >= 600 ? 10 : 8),
            Flexible(
              child: Text(
                'Digital Products',
                style: TextStyle(
                  fontSize: ScreenSize.isTablet ? ScreenSize.headingLarge : ScreenSize.headingMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        final list = controller.digitalProducts;
        if (list.isEmpty) {
          return _buildEmptyState(width);
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final cWidth = constraints.maxWidth;
            final count = _crossAxisCount(cWidth);
            final padding = _horizontalPadding(cWidth);
            final spacing = cWidth >= 600 ? 18.0 : (cWidth >= 360 ? 14.0 : 10.0);
            final aspectRatio = ScreenSize.isTablet ? 0.72 : 0.65;
            return RefreshIndicator(
              onRefresh: controller.loadDigitalProducts,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: ScreenSize.paddingMedium),
                child: GridView.builder(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final product = list[index];
                    final innerWidth = cWidth - 2 * padding;
                    return _buildProductCard(product, controller, innerWidth, count, spacing);
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    final isNarrow = screenWidth < 360;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth >= 600 ? 32 : (screenWidth >= 360 ? 24 : 16),
            vertical: ScreenSize.paddingLarge,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_video_rounded,
                size: screenWidth >= 600 ? 100 : (isNarrow ? 64 : 80),
                color: AppColors.primary.withOpacity(0.5),
              ),
              SizedBox(height: ScreenSize.spacingLarge),
              Text(
                'Music & Video',
                style: TextStyle(
                  fontSize: ScreenSize.isTablet ? ScreenSize.headingLarge : ScreenSize.headingMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.spacingSmall),
              Text(
                'Digital products will appear here once added in the panel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isNarrow ? ScreenSize.textSmall : ScreenSize.textMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    HomeController controller,
    double availableWidth,
    int crossCount,
    double spacing,
  ) {
    final imageUrl = product['image'] as String?;
    final name = product['name'] as String? ?? '';
    final regularPrice = (product['price'] ?? 0.0) as num;
    final salePrice = product['sale_price'] as num?;
    final displayPrice = (salePrice ?? regularPrice).toDouble();
    final cardWidth = (availableWidth - (crossCount - 1) * spacing) / crossCount;
    final imageHeight = cardWidth * 0.85;

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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(ScreenSize.tileBorderRadius)),
                  child: SizedBox(
                    width: double.infinity,
                    height: imageHeight,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.background, child: Icon(Icons.music_note, color: AppColors.textTertiary)),
                            errorWidget: (_, __, ___) => Container(color: AppColors.background, child: Icon(Icons.music_video_rounded, color: AppColors.textTertiary)),
                          )
                        : Container(
                            color: AppColors.background,
                            child: Icon(Icons.music_video_rounded, size: 48, color: AppColors.textTertiary),
                          ),
                  ),
                ),
                // Play icon sirf video ke liye (audio/image ke liye nahi)
                if (product['media_type'] == 'video')
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(availableWidth >= 600 ? 12 : 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: availableWidth >= 600 ? 52 : 44,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: ScreenSize.spacingSmall,
                  left: ScreenSize.spacingSmall,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: availableWidth >= 600 ? 8 : 6,
                      vertical: availableWidth >= 600 ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, size: availableWidth >= 600 ? 14 : 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Digital',
                          style: TextStyle(
                            fontSize: availableWidth >= 600 ? 12 : 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (product['category'] != null && product['category']['name'] != null)
                        Text(
                          product['category']['name'],
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: 2),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\$${displayPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: ScreenSize.textMedium,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
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
}
