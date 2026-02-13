import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Login Screen
/// User authentication screen with professional error handling
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  
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
            mainAxisAlignment: MainAxisAlignment.center,
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
                      Icons.shopping_bag,
                      size: ScreenSize.isLargeTablet ? ScreenSize.iconExtraLarge * 4 : (ScreenSize.isSmallTablet ? ScreenSize.iconExtraLarge * 3.5 : ScreenSize.iconExtraLarge * 2.5),
                      color: AppColors.primary, // Green color
                    );
                  },
                ),
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),
              
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: ScreenSize.isTablet ? ScreenSize.headingHuge : ScreenSize.headingLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack, // Black matching onboarding
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              
              Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: ScreenSize.headingSmall,
                  color: AppColors.textSecondary, // Gray matching onboarding
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),
              
              // General Error Message
              Obx(() => controller.generalError.value.isNotEmpty
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
                              controller.generalError.value,
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
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (value) {
                      controller.email.value = value;
                      controller.clearEmailError();
                    },
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        color: controller.emailError.value.isNotEmpty ? AppColors.error : AppColors.primary, // Green when no error, red only on error
                      ),
                      floatingLabelStyle: TextStyle(
                        color: controller.emailError.value.isNotEmpty ? AppColors.error : AppColors.primary, // Green when no error, red only on error
                      ),
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(
                        fontSize: ScreenSize.textLarge,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.inputPadding,
                        vertical: ScreenSize.isTablet ? ScreenSize.inputPadding : ScreenSize.spacingMedium, // Reduced padding for mobile
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: ScreenSize.spacingSmall, right: ScreenSize.spacingExtraSmall),
                        child: Icon(
                          Icons.mail_outline, 
                          color: AppColors.textSecondary,
                          size: ScreenSize.iconMedium,
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: ScreenSize.iconMedium + ScreenSize.spacingMedium,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(
                          color: controller.emailError.value.isNotEmpty
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(
                          color: controller.emailError.value.isNotEmpty
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(
                          color: controller.emailError.value.isNotEmpty
                              ? AppColors.error
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(color: AppColors.error, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  if (controller.emailError.value.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: ScreenSize.spacingExtraSmall,
                        left: ScreenSize.spacingSmall,
                      ),
                      child: Text(
                        controller.emailError.value,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: ScreenSize.textMedium,
                        ),
                      ),
                    ),
                ],
              )),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),

              // Password field
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (value) {
                      controller.password.value = value;
                      controller.clearPasswordError();
                    },
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                    ),
                    obscureText: !controller.isPasswordVisible.value,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        color: controller.passwordError.value.isNotEmpty ? AppColors.error : AppColors.primary, // Green when no error, red only on error
                      ),
                      floatingLabelStyle: TextStyle(
                        color: controller.passwordError.value.isNotEmpty ? AppColors.error : AppColors.primary, // Green when no error, red only on error
                      ),
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        fontSize: ScreenSize.textLarge,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.inputPadding,
                        vertical: ScreenSize.isTablet ? ScreenSize.inputPadding : ScreenSize.spacingMedium, // Reduced padding for mobile
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: ScreenSize.spacingSmall, right: ScreenSize.spacingExtraSmall),
                        child: Icon(
                          Icons.lock_outline, 
                          color: AppColors.textSecondary,
                          size: ScreenSize.iconMedium,
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: ScreenSize.iconMedium + ScreenSize.spacingMedium,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: ScreenSize.iconMedium,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(
                          color: controller.passwordError.value.isNotEmpty
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(
                          color: controller.passwordError.value.isNotEmpty
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(
                          color: controller.passwordError.value.isNotEmpty
                              ? AppColors.error
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        borderSide: BorderSide(color: AppColors.error, width: 2),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.login(),
                  ),
                  if (controller.passwordError.value.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: ScreenSize.spacingExtraSmall,
                        left: ScreenSize.spacingSmall,
                      ),
                      child: Text(
                        controller.passwordError.value,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: ScreenSize.textMedium,
                        ),
                      ),
                    ),
                ],
              )),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => AppRoutes.toForgotPassword(),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                      color: AppColors.primary, // Green matching onboarding
                    ),
                  ),
                ),
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),

              // Login button
              Obx(() => SizedBox(
                width: double.infinity,
                height: ScreenSize.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Green matching onboarding
                    foregroundColor: AppColors.textWhite,
                    disabledBackgroundColor: AppColors.buttonDisabled,
                    disabledForegroundColor: AppColors.textTertiary,
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
                    isLoading: controller.isLoading.value,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Login',
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

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                      color: AppColors.textSecondary, // Gray matching onboarding
                    ),
                  ),
                  TextButton(
                    onPressed: () => AppRoutes.toSignup(),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: ScreenSize.textLarge,
                        color: AppColors.primary, // Green matching onboarding
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.privacyPolicy),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
