import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Sign Up Screen
/// User registration screen with professional error handling
/// Scrollable page that adapts to all device sizes
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  
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
                      Icons.shopping_bag,
                      size: ScreenSize.isLargeTablet ? ScreenSize.iconExtraLarge * 4 : (ScreenSize.isSmallTablet ? ScreenSize.iconExtraLarge * 3.5 : ScreenSize.iconExtraLarge * 2.5),
                      color: AppColors.primary, // Green color
                    );
                  },
                ),
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),
              
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: ScreenSize.isTablet ? ScreenSize.headingHuge : ScreenSize.headingLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack, // Black matching onboarding
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              
              Text(
                'Sign up to get started',
                style: TextStyle(
                  fontSize: ScreenSize.headingSmall,
                  color: AppColors.textSecondary, // Gray matching onboarding
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.sectionSpacing : ScreenSize.spacingMedium),

              // General Error Message
              Obx(() => controller.signupGeneralError.value.isNotEmpty
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
                          Icon(
                            Icons.error_outline, 
                            color: AppColors.error, 
                            size: ScreenSize.iconMedium, // Responsive error icon
                          ),
                          SizedBox(width: ScreenSize.spacingSmall),
                          Expanded(
                            child: Text(
                              controller.signupGeneralError.value,
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
              
              // Name field
              Obx(() => _buildTextField(
                context: context,
                controller: controller,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  controller.signupName.value = value;
                  controller.clearSignupNameError();
                },
                error: controller.signupNameError.value,
              )),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              
              // Email field
              Obx(() => _buildTextField(
                context: context,
                controller: controller,
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  controller.signupEmail.value = value;
                  controller.clearSignupEmailError();
                },
                error: controller.signupEmailError.value,
              )),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              
              // Phone field
              Obx(() => _buildTextField(
                context: context,
                controller: controller,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  controller.signupPhone.value = value;
                  controller.clearSignupPhoneError();
                },
                error: controller.signupPhoneError.value,
              )),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              
              // Password field
              Obx(() => _buildPasswordField(
                context: context,
                controller: controller,
                label: 'Password',
                hint: 'Enter your password',
                onChanged: (value) {
                  controller.signupPassword.value = value;
                  controller.clearSignupPasswordError();
                },
                error: controller.signupPasswordError.value,
              )),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              
              // Confirm Password field
              Obx(() => _buildPasswordField(
                context: context,
                controller: controller,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                onChanged: (value) {
                  controller.signupConfirmPassword.value = value;
                  controller.clearSignupConfirmPasswordError();
                },
                error: controller.signupConfirmPasswordError.value,
                onSubmitted: (_) => controller.signup(),
              )),
              SizedBox(height: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
              
              // Sign up button
              Obx(() => SizedBox(
                width: double.infinity,
                height: ScreenSize.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.signup,
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
                        'Sign Up',
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
              
              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
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
                        color: AppColors.primary, // Green matching onboarding
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ScreenSize.spacingSmall),
              // Privacy Policy link
              Center(
                child: TextButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build a standard text field
  Widget _buildTextField({
    required BuildContext context,
    required AuthController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    required Function(String) onChanged,
    required String error,
    VoidCallback? onSubmitted,
  }) {
    final bool hasError = error.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: hasError ? AppColors.error : AppColors.primary, // Green when no error, red only on error
            ),
            floatingLabelStyle: TextStyle(
              color: hasError ? AppColors.error : AppColors.primary, // Green when no error, red only on error
            ),
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: ScreenSize.textLarge,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: ScreenSize.spacingSmall, right: ScreenSize.spacingExtraSmall),
              child: Icon(
                icon, 
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
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
          ),
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
          style: TextStyle(
            fontSize: ScreenSize.textLarge, // Consistent responsive text size
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(
              top: ScreenSize.spacingExtraSmall,
              left: ScreenSize.spacingSmall,
            ),
            child: Text(
              error,
              style: TextStyle(
                color: AppColors.error,
                fontSize: ScreenSize.textMedium,
              ),
            ),
          ),
      ],
    );
  }
  
  /// Build a password field with visibility toggle
  Widget _buildPasswordField({
    required BuildContext context,
    required AuthController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    required String error,
    ValueChanged<String>? onSubmitted,
  }) {
    final bool hasError = error.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: onChanged,
          obscureText: !controller.isPasswordVisible.value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: hasError ? AppColors.error : AppColors.primary, // Green when no error, red only on error
            ),
            floatingLabelStyle: TextStyle(
              color: hasError ? AppColors.error : AppColors.primary, // Green when no error, red only on error
            ),
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: ScreenSize.textLarge,
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
                size: ScreenSize.iconMedium, // Consistent responsive icon size
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ScreenSize.inputPadding,
              vertical: ScreenSize.isTablet ? ScreenSize.inputPadding : ScreenSize.spacingMedium, // Reduced padding for mobile
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
          ),
          textInputAction: onSubmitted != null ? TextInputAction.done : TextInputAction.next,
          onSubmitted: onSubmitted,
          style: TextStyle(
            fontSize: ScreenSize.textLarge, // Consistent responsive text size
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(
              top: ScreenSize.spacingExtraSmall,
              left: ScreenSize.spacingSmall,
            ),
            child: Text(
              error,
              style: TextStyle(
                color: AppColors.error,
                fontSize: ScreenSize.textMedium,
              ),
            ),
          ),
      ],
    );
  }
}
