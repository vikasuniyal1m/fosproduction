import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/checkout_controller.dart';
/// Digital product ke liye: checkout dikhaye bina seedha Stripe pe bhejne wala screen.
/// Sirf loading dikhata hai, phir Stripe open karta hai.
class DigitalPayRedirectScreen extends StatelessWidget {
  const DigitalPayRedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(CheckoutController());

    return Obx(() {
      if (controller.isDigitalQuickPay && controller.items.isNotEmpty && !controller.isLoading.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) => controller.tryGoDirectToStripe());
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Secure Payment',
            style: TextStyle(fontSize: ScreenSize.textMedium, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: ScreenSize.spacingLarge),
              Text(
                'Redirecting to payment...',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
