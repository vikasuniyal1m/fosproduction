import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/getx_registry.dart';
/// Digital product ke liye: checkout dikhaye bina seedha Stripe pe bhejne wala screen.
/// Sirf loading dikhata hai, phir Stripe open karta hai.
class DigitalPayRedirectScreen extends StatefulWidget {
  const DigitalPayRedirectScreen({super.key});

  @override
  State<DigitalPayRedirectScreen> createState() => _DigitalPayRedirectScreenState();
}

class _DigitalPayRedirectScreenState extends State<DigitalPayRedirectScreen> {
  String _status = 'Redirecting to payment...';
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = GetXRegistry.checkout();

    return Obx(() {
      if (!_started &&
          controller.isDigitalQuickPay &&
          controller.items.isNotEmpty &&
          !controller.isLoading.value) {
        _started = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await controller.tryGoDirectToStripe();
        });
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
                _status,
                textAlign: TextAlign.center,
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
