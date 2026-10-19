import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/getx_registry.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Login Screen
/// User authentication screen with professional error handling
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  
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
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 12 : 8),
                  
                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 32 : 20),
                  
                  // General Error Message
                  Obx(() => controller.generalError.value.isNotEmpty
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
                                  controller.generalError.value,
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
                          controller.email.value = value;
                          controller.clearEmailError();
                        },
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: AppColors.textPrimary,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            color: controller.emailError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: controller.emailError.value.isNotEmpty ? AppColors.error : AppColors.primary,
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
                          errorText: controller.emailError.value.isEmpty ? null : controller.emailError.value,
                        ),
                      ),
                      if (controller.emailError.value.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4,
                            left: 12,
                          ),
                          child: Text(
                            controller.emailError.value,
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
                          controller.password.value = value;
                          controller.clearPasswordError();
                        },
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: AppColors.textPrimary,
                        ),
                        obscureText: !controller.isPasswordVisible.value,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            color: controller.passwordError.value.isNotEmpty ? AppColors.error : AppColors.primary,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: controller.passwordError.value.isNotEmpty ? AppColors.error : AppColors.primary,
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
                          errorText: controller.passwordError.value.isEmpty ? null : controller.passwordError.value,
                        ),
                      ),
                      if (controller.passwordError.value.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4,
                            left: 12,
                          ),
                          child: Text(
                            controller.passwordError.value,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: isDesktop ? 12 : 10,
                            ),
                          ),
                        ),
                    ],
                  )),
                  SizedBox(height: isDesktop ? 16 : 12),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.toNamed('/forgot-password'),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 24 : 16),

                  // Login button
                  Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.login,
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
                                'Signing In...',
                                style: TextStyle(
                                  fontSize: ScreenSize.textMedium,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: ScreenSize.textMedium,
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
                            fontSize: ScreenSize.textSmall,
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
                              fontSize: ScreenSize.textSmall,
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
                                fontSize: ScreenSize.textSmall,
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

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.toNamed('/signup'),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
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
                          fontSize: ScreenSize.textSmall,
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
             
