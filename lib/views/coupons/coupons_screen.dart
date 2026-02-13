import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/coupon_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

/// Coupons Screen
/// Displays all available coupons that can be used
class CouponsScreen extends StatelessWidget {
  CouponsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(CouponController());
    
    return Scaffold(
      backgroundColor: AppColors.background, // Match home page theme
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
      body: Obx(() => controller.isLoading.value
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
      child: ListView.builder(
        padding: EdgeInsets.all(ScreenSize.paddingMedium),
        itemCount: controller.coupons.length,
        itemBuilder: (context, index) {
          final coupon = controller.coupons[index];
          final isUsed = controller.isCouponUsed(coupon['code'] as String);
          return _buildCouponCard(coupon, controller, isUsed);
        },
      ),
    );
  }
  
  Widget _buildCouponCard(
    Map<String, dynamic> coupon,
    CouponController controller,
    bool isUsed,
  ) {
    // Handle both int and double values from JSON
    final discountValue = coupon['discount'];
    final discount = discountValue is int 
        ? discountValue.toDouble() 
        : (discountValue as double?) ?? 0.0;
    final discountType = coupon['discount_type'] as String? ?? 'fixed'; // 'fixed' or 'percentage'
    final description = coupon['description'] as String? ?? '';
    final validUntil = coupon['valid_until'] as String?;
    final productImage = coupon['product_image'] as String? ?? coupon['image'] as String? ?? '';
    final productName = coupon['product_name'] as String? ?? description;
    final couponCode = coupon['code'] as String? ?? '';
    
    // Format discount text
    String discountText = '';
    if (discountType == 'percentage') {
      discountText = '${discount.toInt()}% OFF';
    } else {
      discountText = '\$${discount.toStringAsFixed(0)}';
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
      child: _buildTicketShape(
        child: Row(
          children: [
            // Left side - Product Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: productImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(ScreenSize.isLargeTablet ? 16 : (ScreenSize.isSmallTablet ? 14 : 12)),
                        bottomLeft: Radius.circular(ScreenSize.isLargeTablet ? 16 : (ScreenSize.isSmallTablet ? 14 : 12)),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: productImage.startsWith('http') ? productImage : '${ApiService.imageBaseUrl}$productImage',
                        fit: BoxFit.fitHeight,
                        placeholder: (context, url) => Container(
                          color: AppColors.backgroundGrey,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.backgroundGrey,
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            size: ScreenSize.iconLarge,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.backgroundGrey,
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        size: ScreenSize.iconLarge,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
            
            // Dashed Line Separator
            CustomPaint(
              size: Size(1, 100),
              painter: DashedLinePainter(),
            ),
            
            // Right side - Coupon Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ScreenSize.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Discount Offer (Bold)
                    Text(
                      discountText,
                      style: TextStyle(
                        fontSize: ScreenSize.headingMedium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Coupon Code
                    if (couponCode.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ScreenSize.spacingSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              couponCode,
                              style: TextStyle(
                                fontSize: ScreenSize.textMedium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (couponCode.isNotEmpty)
                      SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Product Name
                    Text(
                      productName,
                      style: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Valid Until Date
                    if (validUntil != null)
                      Text(
                        'Valid until ${_formatDate(validUntil)}',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    
                    // Used Badge
                    if (isUsed) ...[
                      SizedBox(height: ScreenSize.spacingSmall),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ScreenSize.spacingSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'USED',
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        isUsed: isUsed,
        onTap: isUsed
            ? null
            : () => _handleCouponTap(coupon, controller),
      ),
    );
  }
  
  /// Handle coupon tap - check minimum requirement and navigate
  void _handleCouponTap(Map<String, dynamic> coupon, CouponController controller) {
    // Get cart subtotal
    double cartSubtotal = 0.0;
    try {
      if (Get.isRegistered<CartController>()) {
        final cartController = Get.find<CartController>();
        cartSubtotal = cartController.subtotal.value;
      }
    } catch (e) {
      print('Error getting cart subtotal: $e');
    }
    
    // Get minimum amount requirement from coupon
    // Check multiple possible field names
    final minAmountValue = coupon['minimum_amount'] ?? 
                          coupon['minimum_purchase'] ?? 
                          coupon['min_amount'] ?? 
                          coupon['min_purchase'] ?? 
                          coupon['minimum_order_value'] ??
                          0.0;
    
    final minAmount = minAmountValue is int 
        ? minAmountValue.toDouble() 
        : (minAmountValue is double ? minAmountValue : double.tryParse(minAmountValue.toString()) ?? 0.0);
    
    // Check if requirement is met
    if (minAmount > 0 && cartSubtotal < minAmount) {
      // Show popup with requirement message
      _showRequirementDialog(minAmount, cartSubtotal);
    } else {
      // Requirement met or no requirement - proceed to checkout
      controller.selectCoupon(coupon);
      Get.toNamed(AppRoutes.checkout);
    }
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
  
  Widget _buildTicketShape({
    required Widget child,
    required bool isUsed,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUsed 
              ? AppColors.backgroundGrey.withOpacity(0.5)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 16 : (ScreenSize.isSmallTablet ? 14 : 12)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Stack(
          children: [
            // Ticket shape with semicircular cutouts
            ClipPath(
              clipper: TicketClipper(),
              child: Container(
                decoration: BoxDecoration(
                  color: isUsed 
                      ? AppColors.backgroundGrey.withOpacity(0.5)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 16 : (ScreenSize.isSmallTablet ? 14 : 12)),
                ),
                child: child,
              ),
            ),
            
            // Left top semicircle
            Positioned(
              left: -(ScreenSize.isLargeTablet ? 10.0 : (ScreenSize.isSmallTablet ? 9.0 : 7.5)),
              top: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
              child: Container(
                width: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
                height: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
                decoration: BoxDecoration(
                  color: AppColors.background, // Match background
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Right top semicircle
            Positioned(
              right: -(ScreenSize.isLargeTablet ? 10.0 : (ScreenSize.isSmallTablet ? 9.0 : 7.5)),
              top: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
              child: Container(
                width: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
                height: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
                decoration: BoxDecoration(
                  color: AppColors.background, // Match background
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Left bottom semicircle
            Positioned(
              left: -(ScreenSize.isLargeTablet ? 10.0 : (ScreenSize.isSmallTablet ? 9.0 : 7.5)),
              bottom: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
              child: Container(
                width: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
                height: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
                decoration: BoxDecoration(
                  color: AppColors.background, // Match background
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Right bottom semicircle
            Positioned(
              right: -(ScreenSize.isLargeTablet ? 10.0 : (ScreenSize.isSmallTablet ? 9.0 : 7.5)),
              bottom: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
              child: Container(
                width: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
                height: ScreenSize.isLargeTablet ? 20.0 : (ScreenSize.isSmallTablet ? 18.0 : 15.0),
                decoration: BoxDecoration(
                  color: AppColors.background, // Match background
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Used overlay
            if (isUsed)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 16 : (ScreenSize.isSmallTablet ? 14 : 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                      'July', 'August', 'September', 'October', 'November', 'December'];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

/// Custom Clipper for ticket shape
class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 12.0;
    
    // Top left corner
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    
    // Top right corner
    path.arcToPoint(
      Offset(size.width, radius),
      radius: Radius.circular(radius),
    );
    
    // Right edge
    path.lineTo(size.width, size.height - radius);
    
    // Bottom right corner
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: Radius.circular(radius),
    );
    
    // Bottom edge
    path.lineTo(radius, size.height);
    
    // Bottom left corner
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: Radius.circular(radius),
    );
    
    // Left edge
    path.lineTo(0, radius);
    
    // Top left corner
    path.arcToPoint(
      Offset(radius, 0),
      radius: Radius.circular(radius),
    );
    
    path.close();
    return path;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom Painter for dashed line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
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
