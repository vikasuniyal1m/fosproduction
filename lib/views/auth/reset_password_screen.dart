import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Reset Password Screen
/// Password reset screen
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.find<AuthController>();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: AppColors.textBlack,
            size: ScreenSize.iconMedium, // Consistent responsive icon size
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ScreenSize.isLargeTablet ? ScreenSize.paddingMedium : (ScreenSize.isSmallTablet ? ScreenSize.paddingExtraLarge : ScreenSize.spacingSmall)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/App Name - Optimized size for mobile
              Center(
                child: Image.asset(
                  'assets/images/fos_logo.jpg',
                  width: ScreenSize.isLargeTablet ? ScreenSize.widthPercent(40) : (ScreenSize.isSmallTablet ? ScreenSize.widthPercent(50) : ScreenSize.widthPercent(50)),
                  height: ScreenSize.isLargeTablet ? ScreenSize.widthPercent(40) : (ScreenSize.isSmallTablet ? ScreenSize.widthPercent(50) : ScreenSize.widthPercent(50)),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.lock_reset,
                      size: ScreenSize.isLargeTablet ? ScreenSize.iconExtraLarge * 4 : (ScreenSize.isSmallTablet ? ScreenSize.iconExtraLarge * 3.5 : ScreenSize.iconExtraLarge * 2.5),
                      color: AppColors.primary, // Green color
                    );
                  },
                ),
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),
              
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: ScreenSize.isTablet ? ScreenSize.headingHuge : ScreenSize.headingLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack, // Black matching onboarding
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              
              Text(
                'Enter your email address and we\'ll send you a link to reset your password',
                style: TextStyle(
                  fontSize: ScreenSize.headingSmall,
                  color: AppColors.textSecondary, // Gray matching onboarding
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),
              
              // Error message
              Obx(() => controller.forgotPasswordError.value.isNotEmpty
                  ? Container(
                      padding: EdgeInsets.all(ScreenSize.spacingSmall),
                      margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error, size: ScreenSize.iconMedium),
                          SizedBox(width: ScreenSize.spacingSmall),
                          Expanded(
                            child: Text(
                              controller.forgotPasswordError.value,
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: ScreenSize.textLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),
              
              // Email field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (value) {
                      controller.forgotPasswordEmail.value = value;
                      controller.clearForgotPasswordError();
                    },
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        color: AppColors.primary, // Green color
                      ),
                      floatingLabelStyle: TextStyle(
                        color: AppColors.primary, // Green color
                      ),
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(
                        fontSize: ScreenSize.textLarge,
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: ScreenSize.spacingSmall, right: ScreenSize.spacingExtraSmall),
                        child: Icon(
                          Icons.email_outlined, 
                          color: AppColors.textSecondary,
                          size: ScreenSize.iconMedium,
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: ScreenSize.iconMedium + ScreenSize.spacingMedium,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.inputPadding,
                        vertical: ScreenSize.isTablet ? ScreenSize.inputPadding : ScreenSize.spacingMedium, // Reduced padding for mobile
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(color: AppColors.primary, width: 2), // Green matching login/signup
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),
              
              // Send reset link button
              Obx(() => SizedBox(
                width: double.infinity,
                height: ScreenSize.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: controller.isForgotPasswordLoading.value ? null : () {
                    controller.forgotPassword();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Green matching login/signup
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.buttonPaddingHorizontal,
                      vertical: ScreenSize.buttonPaddingVertical,
                    ),
                  ),
                  child: ButtonLoading(
                    isLoading: controller.isForgotPasswordLoading.value,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: ScreenSize.headingMedium,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              )),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),
              
              // Back to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remember your password? ',
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                      color: AppColors.textSecondary, // Gray matching onboarding
                    ),
                  ),
                  TextButton(
                    onPressed: () => AppRoutes.toLogin(),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: ScreenSize.textLarge,
                        color: AppColors.primary, // Green matching login/signup
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ScreenSize.spacingSmall),
            ],
          ),
        ),
      ),
    );
  }
}
