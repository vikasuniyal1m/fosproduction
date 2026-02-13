import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';

/// Order Confirmation Screen
/// Shows order success message and order details
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    Map<String, dynamic>? order;
    
    // Handle different argument types
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      order = args;
    } else if (args is int) {
      // If only order ID is passed, create minimal order map
      order = {
        'id': args,
        'order_number': 'ORD-$args',
        'status': 'confirmed',
        'payment_status': 'pending',
        'total': 0.0,
      };
    } else {
      order = null;
    }
    
    return PopScope(
      // Prevent back navigation from order confirmation
      // User should use the action buttons to navigate
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Show message that they should use action buttons
          Get.snackbar(
            'Info',
            'Please use the buttons below to continue',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ScreenSize.spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: ScreenSize.spacingExtraLarge),
              
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
              
              SizedBox(height: ScreenSize.spacingLarge),
              
              // Success Message
              Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: ScreenSize.headingLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: ScreenSize.spacingSmall),
              
              Text(
                'Thank you for your order. We have received your order and will begin processing it right away.',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: ScreenSize.spacingMedium),
              
              // Invoice Email Info
              Container(
                padding: EdgeInsets.all(ScreenSize.spacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: ScreenSize.spacingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice Sent',
                            style: TextStyle(
                              fontSize: ScreenSize.textMedium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your invoice has been sent to your email address',
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
              
              SizedBox(height: ScreenSize.spacingExtraLarge),
              
              // Order Details Card
              if (order != null) _buildOrderDetailsCard(order),
              
              SizedBox(height: ScreenSize.spacingExtraLarge),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
      ),
    );
  }
  
  Widget _buildOrderDetailsCard(Map<String, dynamic> order) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: TextStyle(
              fontSize: ScreenSize.headingSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          _buildDetailRow('Order Number', order['order_number'] ?? ''),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildDetailRow('Order Status', order['status'] ?? 'pending'),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildDetailRow('Payment Status', order['payment_status'] ?? 'pending'),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildDetailRow(
            'Total Amount',
            '\$${(order['total'] ?? 0.0).toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ScreenSize.textMedium,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? ScreenSize.textLarge : ScreenSize.textMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Replace order confirmation with orders screen
              // When user presses back from orders, it will go to home
              Get.offNamed(AppRoutes.orders);
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
              'View Orders',
              style: TextStyle(
                fontSize: ScreenSize.textLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: ScreenSize.spacingMedium),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Go back to home, clearing checkout flow
              Get.offAllNamed(AppRoutes.home);
            },
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
                fontSize: ScreenSize.textLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

