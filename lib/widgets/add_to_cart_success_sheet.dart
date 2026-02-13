import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';

/// Add to Cart Success Bottom Sheet
/// Shows a beautiful success message with options to view cart or continue shopping
class AddToCartSuccessSheet extends StatelessWidget {
  final Map<String, dynamic> product;
  final int quantity;
  
  const AddToCartSuccessSheet({
    super.key,
    required this.product,
    this.quantity = 1,
  });
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ScreenSize.tileBorderRadiusLarge),
          topRight: Radius.circular(ScreenSize.tileBorderRadiusLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: ScreenSize.spacingMedium),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingLarge),
                child: Column(
                  children: [
                    SizedBox(height: ScreenSize.spacingLarge),
                    
                    // Success icon and message
                    Column(
                      children: [
                        // Success icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 50,
                          ),
                        ),
                        SizedBox(height: ScreenSize.spacingLarge),
                        
                        // Success message
                        Text(
                          'Added to Cart!',
                          style: TextStyle(
                            fontSize: ScreenSize.headingLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: ScreenSize.spacingSmall),
                        Text(
                          'Product successfully added to your cart',
                          style: TextStyle(
                            fontSize: ScreenSize.textMedium,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: ScreenSize.spacingExtraLarge),
                    
                    // Product preview
                    Container(
                      padding: EdgeInsets.all(ScreenSize.spacingLarge),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Product image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                            child: CachedNetworkImage(
                              imageUrl: product['image'] ?? '',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 100,
                                height: 100,
                                color: AppColors.backgroundGrey,
                                child: Icon(Icons.image, color: AppColors.textSecondary),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 100,
                                height: 100,
                                color: AppColors.backgroundGrey,
                                child: Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          SizedBox(width: ScreenSize.spacingMedium),
                          
                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? 'Product',
                                  style: TextStyle(
                                    fontSize: ScreenSize.textLarge,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: ScreenSize.spacingSmall),
                                Text(
                                  'Quantity: $quantity',
                                  style: TextStyle(
                                    fontSize: ScreenSize.textMedium,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: ScreenSize.spacingSmall),
                                Text(
                                  '₹${product['sale_price'] ?? product['price'] ?? '0'}',
                                  style: TextStyle(
                                    fontSize: ScreenSize.headingSmall,
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
                  ],
                ),
              ),
            ),
            
            // Action buttons - Fixed at bottom
            Container(
              padding: EdgeInsets.all(ScreenSize.spacingLarge),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  // Continue Shopping button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                        ),
                      ),
                      child: Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: ScreenSize.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ScreenSize.spacingMedium),
                  
                  // View Cart button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.toNamed('/cart');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                        ),
                      ),
                      child: Text(
                        'View Cart',
                        style: TextStyle(
                          fontSize: ScreenSize.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

