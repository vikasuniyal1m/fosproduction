import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/coupon_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/silent_loading.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../utils/getx_registry.dart';

/// Coupons Screen
/// Displays all available coupons that can be used
class CouponsScreen extends StatelessWidget {
  CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(CouponController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Coupons',
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
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: ScreenSize.iconMedium,
            ),
            onPressed: () => controller.refreshCoupons(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() => SilentLoading.blockUi(
            isLoading: controller.isLoading.value,
            hasContent: controller.coupons.isNotEmpty,
          )
          ? const LoadingWidget()
          : _buildCouponsList(controller)),
    );
  }

  Widget _buildCouponsList(CouponController controller) {
    if (controller.coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: ScreenSize.iconExtraLarge * 2.5,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            Text(
              'No coupons available',
              style: TextStyle(
                fontSize: ScreenSize.headingSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              'Check back later for exciting offers!',
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.refreshCoupons(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.coupons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final coupon = controller.coupons[index];
          return _buildCouponCard(coupon, controller);
        },
      ),
    );
  }

  Widget _buildCouponCard(
    Map<String, dynamic> coupon,
    CouponController controller,
  ) {
    final cartController = GetXRegistry.cart();

    return Obx(() {
      final cartSubtotal = cartController.subtotal.value;
      final cartHasItems = cartController.cartItems.isNotEmpty;
      final isUsed =
          controller.isCouponUsed(coupon['code']?.toString() ?? '');
      final eligible = controller.isCouponEligible(
        coupon,
        cartSubtotal,
        cartHasItems: cartHasItems,
      );
      final disabledReason = controller.couponDisabledReason(
        coupon,
        cartSubtotal,
        cartHasItems: cartHasItems,
      );

      return _buildCouponCardBody(
        coupon: coupon,
        controller: controller,
        isUsed: isUsed,
        eligible: eligible,
        disabledReason: disabledReason,
        onTap: eligible
            ? () => _handleCouponTap(coupon, controller, cartSubtotal)
            : () => _handleDisabledCouponTap(
                  coupon,
                  cartSubtotal,
                  cartHasItems,
                  disabledReason,
                ),
      );
    });
  }

  Widget _buildCouponCardBody({
    required Map<String, dynamic> coupon,
    required CouponController controller,
    required bool isUsed,
    required bool eligible,
    required String disabledReason,
    required VoidCallback onTap,
  }) {
    final rawDiscount = coupon['discount_value'] ?? coupon['value'] ?? coupon['discount'];
    final discount = rawDiscount is int
        ? rawDiscount.toDouble()
        : (rawDiscount is double ? rawDiscount : double.tryParse(rawDiscount?.toString() ?? '0') ?? 0.0);
    final discountType = coupon['discount_type'] ?? coupon['type'] as String? ?? 'fixed';
    final description = coupon['description'] as String? ?? '';
    final validUntil = coupon['valid_until'] as String?;
    final productImage = coupon['product_image'] as String? ?? coupon['image'] as String? ?? '';
    final productName = coupon['product_name'] as String? ?? description;
    final couponCode = coupon['code'] as String? ?? '';

    String discountText = '';
    if (discountType == 'percentage') {
      discountText = '${discount.toInt()}% OFF';
    } else {
      discountText = '\$${discount.toStringAsFixed(0)} OFF';
    }

    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: Opacity(
        opacity: isUsed ? 0.5 : (eligible ? 1.0 : 0.55),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.textWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipPath(
            clipper: CouponClipper(),
            child: Row(
              children: [
                // Left Part - Brand/Type
                Container(
                  width: 85,
                  decoration: BoxDecoration(
                    color: isUsed ? AppColors.textTertiary : AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Discount Value - Big and Bold
                      Text(
                        discountType == 'percentage' ? '${discount.toInt()}%' : '\$${discount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // OFF text
                      const Text(
                        'OFF',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dash separator
                CustomPaint(
                  size: const Size(1, 110),
                  painter: DashedLinePainter(color: AppColors.border.withOpacity(0.5)),
                ),

                // Right Part - Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                productName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUsed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.textTertiary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'USED',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textTertiary),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (!eligible && !isUsed && disabledReason.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              disabledReason,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Text(
                                couponCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (validUntil != null)
                              Text(
                                'Ends ${_formatShortDate(validUntil)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
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
        ),
      ),
    );
  }

  void _handleDisabledCouponTap(
    Map<String, dynamic> coupon,
    double cartSubtotal,
    bool cartHasItems,
    String reason,
  ) {
    if (!cartHasItems || cartSubtotal <= 0) {
      Get.snackbar(
        'Cart empty',
        'Add products to your cart to use coupons',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final min = CouponController.couponMinAmount(coupon);
    if (min > 0 && cartSubtotal < min) {
      _showRequirementDialog(min, cartSubtotal);
    } else if (reason.isNotEmpty) {
      Get.snackbar('Coupon unavailable', reason, snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Apply only when cart + minimum are satisfied, then checkout.
  void _handleCouponTap(
    Map<String, dynamic> coupon,
    CouponController controller,
    double cartSubtotal,
  ) {
    final cartHasItems = Get.isRegistered<CartController>() &&
        Get.find<CartController>().cartItems.isNotEmpty;
    if (!controller.isCouponEligible(
      coupon,
      cartSubtotal,
      cartHasItems: cartHasItems,
    )) {
      _handleDisabledCouponTap(
        coupon,
        cartSubtotal,
        cartHasItems,
        controller.couponDisabledReason(
          coupon,
          cartSubtotal,
          cartHasItems: cartHasItems,
        ),
      );
      return;
    }
    controller.selectCoupon(coupon);
    Get.toNamed(AppRoutes.checkout);
  }

  /// Show popup dialog for minimum amount requirement
  void _showRequirementDialog(double requiredAmount, double currentAmount) {
    final remainingAmount = requiredAmount - currentAmount;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 16 : (ScreenSize.isSmallTablet ? 14 : 12)),
        ),
        child: Padding(
          padding: EdgeInsets.all(ScreenSize.isLargeTablet ? ScreenSize.paddingLarge : (ScreenSize.isSmallTablet ? ScreenSize.paddingMedium : ScreenSize.paddingMedium)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(ScreenSize.isLargeTablet ? ScreenSize.spacingLarge : (ScreenSize.isSmallTablet ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: ScreenSize.isLargeTablet ? ScreenSize.iconLarge * 2 : (ScreenSize.isSmallTablet ? ScreenSize.iconLarge * 1.5 : ScreenSize.iconLarge * 1.5),
                  color: AppColors.warning,
                ),
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingLarge : (ScreenSize.isSmallTablet ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),

              // Title
              Text(
                'Minimum Amount Required',
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingLarge : (ScreenSize.isSmallTablet ? ScreenSize.headingMedium : ScreenSize.headingSmall),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),

              // Message
              Text(
                'This coupon requires a minimum purchase of',
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textMedium),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingXSmall : ScreenSize.spacingXSmall)),

              // Required Amount
              Text(
                '\$${requiredAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingHuge : (ScreenSize.isSmallTablet ? ScreenSize.headingLarge : ScreenSize.headingMedium),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),

              // Current Amount Info
              Container(
                padding: EdgeInsets.all(ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 12 : (ScreenSize.isSmallTablet ? 10 : 8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Cart Total:',
                      style: TextStyle(
                        fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textMedium),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${currentAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textMedium),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingXSmall : ScreenSize.spacingXSmall)),

              // Remaining Amount
              Text(
                'Add \$${remainingAmount.toStringAsFixed(2)} more to use this coupon',
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textMedium),
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingLarge : (ScreenSize.isSmallTablet ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),

              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall),
                        ),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 12 : (ScreenSize.isSmallTablet ? 10 : 8)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textMedium),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),

                  // Shop Now Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.toNamed(AppRoutes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 12 : (ScreenSize.isSmallTablet ? 10 : 8)),
                        ),
                      ),
                      child: Text(
                        'Shop Now',
                        style: TextStyle(
                          fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textMedium),
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatShortDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class CouponClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // The entire card bounding box
    Path rectPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      
    // The cutouts (semi-circles) to remove
    const double radius = 10;
    const double cutoutX = 85;

    Path cutoutsPath = Path()
      ..addOval(Rect.fromCircle(center: const Offset(cutoutX, 0), radius: radius))
      ..addOval(Rect.fromCircle(center: Offset(cutoutX, size.height), radius: radius));
      
    // Subtract the cutouts from the rect to get the final shape
    return Path.combine(PathOperation.difference, rectPath, cutoutsPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color? color;
  DashedLinePainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
