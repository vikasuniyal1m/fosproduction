import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/getx_registry.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Reset Password Screen
/// Password reset screen with email input and professional error handling
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = GetXRegistry.auth();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 480 : (isTablet ? 420 : double.infinity),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                vertical: isDesktop ? 24 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/App Name - Responsive size
                  Center(
                    child: Image.asset(
                      'assets/images/fos_logo.jpg',
                      width: isDesktop ? 160 : (isTablet ? 140 : 120),
                      height: isDesktop ? 160 : (isTablet ? 140 : 120),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shopping_bag,
                          size: isDesktop ? 80 : (isTablet ? 70 : 60),
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: isDesktop ? 32 : 24),
                  
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 12 : 8),
                  
                  Text(
                    'Enter your email to receive reset instructions',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isDesktop ? 32 : 20),
                  
                  // General Error Message
                  Obx(() => controller.forgotPasswordError.value.isNotEmpty
                      ? Container(
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.only(bottom: isDesktop ? 12 : 8),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error, size: isDesktop ? 20 : 16),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  controller.forgotPasswordError.value,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: isDesktop ? 14 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink()),
                  
                  // Email field
                  Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (value) {
                          controller.forgotPasswordEmail.value = value;
                          controller.clearForgotPasswordError();
                        },
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: AppColors.textPrimary,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: controller.forgotPasswordError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: controller.forgotPasswordError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          hintText: 'Enter your email address',
                          hintStyle: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: AppColors.textTertiary,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isDesktop ? 12 : 10,
                          ),
                          prefixIcon: Icon(
                            Icons.mail_outline, 
                            color: AppColors.textSecondary,
                            size: isDesktop ? 20 : 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          errorText: controller.forgotPasswordError.value.isEmpty ? null : controller.forgotPasswordError.value,
                        ),
                      ),
                      if (controller.forgotPasswordError.value.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4,
                            left: 12,
                          ),
                          child: Text(
                            controller.forgotPasswordError.value,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: isDesktop ? 12 : 10,
                            ),
                          ),
                        ),
                    ],
                  )),
                  SizedBox(height: isDesktop ? 24 : 16),

                  // Reset Password button
                  Obx(() => ElevatedButton(
                    onPressed: controller.isForgotPasswordLoading.value ? null : controller.forgotPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: isDesktop ? 14 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                    child: controller.isForgotPasswordLoading.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Sending...',
                                style: TextStyle(
                                  fontSize: isDesktop ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                  )),
                  SizedBox(height: isDesktop ? 24 : 16),

                  // Back to login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Remember your password? ",
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.toNamed('/login'),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
