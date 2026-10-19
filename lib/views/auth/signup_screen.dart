import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/getx_registry.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Sign Up Screen
/// User registration screen with professional error handling
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = GetXRegistry.auth();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
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
                    'Create Account',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 12 : 8),
                  
                  Text(
                    'Sign up to get started',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 32 : 20),
                  
                  // General Error Message
                  Obx(() => controller.signupGeneralError.value.isNotEmpty
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
                                  controller.signupGeneralError.value,
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
                  
                  // Name field
                  Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (value) {
                          controller.signupName.value = value;
                          controller.clearSignupNameError();
                        },
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: AppColors.textPrimary,
                        ),
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: controller.signupNameError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: controller.signupNameError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          hintText: 'Enter your full name',
                          hintStyle: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: AppColors.textTertiary,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isDesktop ? 12 : 10,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline, 
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
                          errorText: controller.signupNameError.value.isEmpty ? null : controller.signupNameError.value,
                        ),
                      ),
                      if (controller.signupNameError.value.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4,
                            left: 12,
                          ),
                          child: Text(
                            controller.signupNameError.value,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: isDesktop ? 12 : 10,
                            ),
                          ),
                        ),
                    ],
                  )),
                  SizedBox(height: isDesktop ? 16 : 12),

                  // Email field
                  Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (value) {
                          controller.signupEmail.value = value;
                          controller.clearSignupEmailError();
                        },
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: AppColors.textPrimary,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: controller.signupEmailError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: controller.signupEmailError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          hintText: 'Enter your email',
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
                          errorText: controller.signupEmailError.value.isEmpty ? null : controller.signupEmailError.value,
                        ),
                      ),
                      if (controller.signupEmailError.value.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4,
                            left: 12,
                          ),
                          child: Text(
                            controller.signupEmailError.value,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: isDesktop ? 12 : 10,
                            ),
                          ),
                        ),
                    ],
                  )),
                  SizedBox(height: isDesktop ? 16 : 12),

                  // Phone field
                  Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (value) {
                          controller.signupPhone.value = value;
                          controller.clearSignupPhoneError();
                        },
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: AppColors.textPrimary,
                        ),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: controller.signupPhoneError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: controller.signupPhoneError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          hintText: 'Enter your phone number',
                          hintStyle: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: AppColors.textTertiary,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isDesktop ? 12 : 10,
                          ),
                          prefixIcon: Icon(
                            Icons.phone, 
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
                          errorText: controller.signupPhoneError.value.isEmpty ? null : controller.signupPhoneError.value,
                        ),
                      ),
                      if (controller.signupPhoneError.value.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4,
                            left: 12,
                          ),
                          child: Text(
                            controller.signupPhoneError.value,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: isDesktop ? 12 : 10,
                            ),
                          ),
                        ),
                    ],
                  )),
                  SizedBox(height: isDesktop ? 16 : 12),

                  // Password field
                  Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (value) {
                          controller.signupPassword.value = value;
                          controller.clearSignupPasswordError();
                        },
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: AppColors.textPrimary,
                        ),
                        obscureText: !controller.isPasswordVisible.value,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: controller.signupPasswordError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: controller.signupPasswordError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: AppColors.textTertiary,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isDesktop ? 12 : 10,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline, 
                            color: AppColors.textSecondary,
                            size: isDesktop ? 20 : 18,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                              color: AppColors.textSecondary,
                              size: isDesktop ? 20 : 18,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          errorText: controller.signupPasswordError.value.isEmpty ? null : controller.signupPasswordError.value,
                        ),
                      ),
                      if (controller.signupPasswordError.value.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4,
                            left: 12,
                          ),
                          child: Text(
                            controller.signupPasswordError.value,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: isDesktop ? 12 : 10,
                            ),
                          ),
                        ),
                    ],
                  )),
                  SizedBox(height: isDesktop ? 16 : 12),

                  // Confirm Password field
                  Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (value) {
                          controller.signupConfirmPassword.value = value;
                          controller.clearSignupConfirmPasswordError();
                        },
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: AppColors.textPrimary,
                        ),
                        obscureText: !controller.isPasswordVisible.value,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: controller.signupConfirmPasswordError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: controller.signupConfirmPasswordError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          hintText: 'Confirm your password',
                          hintStyle: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: AppColors.textTertiary,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isDesktop ? 12 : 10,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline, 
                            color: AppColors.textSecondary,
                            size: isDesktop ? 20 : 18,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                              color: AppColors.textSecondary,
                              size: isDesktop ? 20 : 18,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          errorText: controller.signupConfirmPasswordError.value.isEmpty ? null : controller.signupConfirmPasswordError.value,
                        ),
                      ),
                      if (controller.signupConfirmPasswordError.value.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4,
                            left: 12,
                          ),
                          child: Text(
                            controller.signupConfirmPasswordError.value,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: isDesktop ? 12 : 10,
                            ),
                          ),
                        ),
                    ],
                  )),
                  SizedBox(height: isDesktop ? 24 : 16),

                  // Sign Up button
                  Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.signup,
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
                    child: controller.isLoading.value
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
                                'Creating Account...',
                                style: TextStyle(
                                  fontSize: isDesktop ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                  )),
                  SizedBox(height: isDesktop ? 20 : 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),

                  // Social Login Buttons
                  Column(
                    children: [
                      // Google Login Button
                      SizedBox(
                        width: double.infinity,
                        height: isDesktop ? 44 : 40,
                        child: OutlinedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.signInWithGoogle(),
                          icon: controller.isLoading.value
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/google.png',
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.g_mobiledata, size: 18);
                                  },
                                ),
                          label: Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: AppColors.background,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Apple Login Button (iOS only)
                      if (isIOS)
                        SizedBox(
                          width: double.infinity,
                          height: isDesktop ? 44 : 40,
                          child: OutlinedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : () => controller.signInWithApple(),
                            icon: controller.isLoading.value
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  )
                                : Icon(Icons.apple, size: 18),
                            label: Text(
                              'Continue with Apple',
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: AppColors.background,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 20 : 16),

                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
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
                  SizedBox(height: isDesktop ? 16 : 12),
                  
                  // Continue as Guest Option
                  Center(
                    child: TextButton.icon(
                      onPressed: () => controller.continueAsGuest(),
                      icon: Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      label: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
