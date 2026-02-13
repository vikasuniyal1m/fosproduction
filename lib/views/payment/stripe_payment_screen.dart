import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_widget.dart';
import '../../controllers/stripe_payment_controller.dart';
import '../../widgets/responsive_button.dart';

/// Stripe Payment Screen
/// Professional payment screen with card input
class StripePaymentScreen extends StatefulWidget {
  const StripePaymentScreen({super.key});
  
  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  // Form controllers - preserved across rebuilds to prevent keyboard dismissal
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(StripePaymentController());
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Handle back button - show cancel dialog
        await controller.cancelPayment();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        resizeToAvoidBottomInset: true, // Allow scaffold to resize when keyboard appears
        appBar: AppBar(
          title: const Text('Secure Payment'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => controller.cancelPayment(),
          ),
        ),
        body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget();
        }
        
        if (controller.errorMessage.value.isNotEmpty && 
            controller.clientSecret.value.isEmpty) {
          return _buildErrorView(controller);
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(ScreenSize.spacingMedium),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ScreenSize.isTablet 
                    ? (ScreenSize.isLargeTablet ? 600 : 500)
                    : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Sheet Button (Apple Pay, Google Pay, Card, etc.)
                  _buildPaymentSheetButton(controller),
                  SizedBox(height: ScreenSize.spacingLarge),
                  _buildSecurityInfo(),
                  SizedBox(height: ScreenSize.spacingExtraLarge),
                ],
              ),
            ),
          ),
        );
      }),
      ),
    );
  }

  Widget _buildErrorView(StripePaymentController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ScreenSize.spacingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 60),
            SizedBox(height: ScreenSize.spacingMedium),
            Text(
              'Payment Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.accentDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.backgroundGrey,
              ),
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            ResponsiveButton(
                  onPressed: () => controller.cancelPayment(),
                  text: 'Back to Cart',
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                ),
              ],
            ),
          ),
        );
      }

      Widget _buildPaymentSheetButton(StripePaymentController controller) {
        return ResponsiveButton(
          onPressed: controller.processPaymentWithSheet,
          text: 'Pay with Card or Wallet',
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          icon: Icon(Icons.payment),
        );
      }

      Widget _buildSecurityInfo() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure Payment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Row(
              children: [
                Icon(Icons.lock, color: AppColors.success, size: 20),
                SizedBox(width: ScreenSize.spacingExtraSmall),
                Expanded(
                  child: Text(
                    'Your payment information is encrypted and secured by Stripe.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    }


