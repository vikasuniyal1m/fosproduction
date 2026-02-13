import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// New Password Screen
/// Screen for entering reset token and new password
class NewPasswordScreen extends StatelessWidget {
  final String? token;
  
  const NewPasswordScreen({super.key, this.token});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.find<AuthController>();
    
    // Set token if provided
    if (token != null && token!.isNotEmpty) {
      controller.resetToken.value = token!;
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: Colors.black,
            size: ScreenSize.isLargeTablet ? ScreenSize.textMedium * 2 : (ScreenSize.isSmallTablet ? ScreenSize.iconMedium : ScreenSize.iconSmall),
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
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingHuge : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraLarge : ScreenSize.spacingSmall)),
              
              // Logo/App Name - Bigger size for better visibility
              Center(
                child: Image.asset(
                  'assets/images/fos_logo.jpg',
                  width: ScreenSize.isLargeTablet ? ScreenSize.widthPercent(40) : (ScreenSize.isSmallTablet ? ScreenSize.widthPercent(50) : ScreenSize.widthPercent(60)),
                  height: ScreenSize.isLargeTablet ? ScreenSize.widthPercent(40) : (ScreenSize.isSmallTablet ? ScreenSize.widthPercent(50) : ScreenSize.widthPercent(60)),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.lock_outline,
                      size: ScreenSize.isLargeTablet ? ScreenSize.iconExtraLarge * 4 : (ScreenSize.isSmallTablet ? ScreenSize.iconExtraLarge * 3.5 : ScreenSize.iconExtraLarge * 3),
                      color: const Color(0xFF0B5306), // Green color
                    );
                  },
                ),
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingHuge : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraLarge : ScreenSize.spacingLarge)),
              
              Text(
                'Set New Password',
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingHuge * 2.2 : (ScreenSize.isSmallTablet ? ScreenSize.headingHuge * 1.5 : ScreenSize.headingExtraLarge),
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Black matching onboarding
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingLarge : (ScreenSize.isSmallTablet ? ScreenSize.spacingMedium : ScreenSize.spacingSmall)),
              
              Text(
                'Enter your reset token and new password',
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.textExtraLarge * 2.2 : (ScreenSize.isSmallTablet ? ScreenSize.textExtraLarge * 1.6 : ScreenSize.textLarge),
                  color: Colors.grey[600], // Gray matching onboarding
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingHuge : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraLarge : ScreenSize.spacingSmall)),
              
              // General error message
              Obx(() => controller.resetGeneralError.value.isNotEmpty
                  ? Container(
                      padding: EdgeInsets.all(ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
                      margin: EdgeInsets.only(bottom: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error, size: ScreenSize.isLargeTablet ? ScreenSize.iconMedium : (ScreenSize.isSmallTablet ? ScreenSize.iconMedium : ScreenSize.iconSmall)),
                          SizedBox(width: ScreenSize.spacingSmall),
                          Expanded(
                            child: Text(
                              controller.resetGeneralError.value,
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: ScreenSize.isLargeTablet ? ScreenSize.textExtraLarge : (ScreenSize.isSmallTablet ? ScreenSize.textLarge : ScreenSize.textSmall),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink()),
              
              // Reset Token field
              Obx(() => TextField(
                onChanged: (value) {
                  controller.resetToken.value = value;
                  controller.resetTokenError.value = '';
                  controller.resetGeneralError.value = '';
                },
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textExtraLarge * 2 : ScreenSize.textMedium),
                ),
                decoration: InputDecoration(
                  labelText: 'Reset Token',
                  labelStyle: TextStyle(
                    fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingMedium : (ScreenSize.isSmallTablet ? ScreenSize.headingLarge * 1.6 : ScreenSize.textMedium),
                    color: controller.resetTokenError.value.isNotEmpty ? Colors.red : const Color(0xFF0B5306), // Green when no error, red only on error
                  ),
                  floatingLabelStyle: TextStyle(
                    color: controller.resetTokenError.value.isNotEmpty ? Colors.red : const Color(0xFF0B5306), // Green when no error, red only on error
                  ),
                  hintText: 'Enter reset token from email',
                  hintStyle: TextStyle(
                    fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingMedium : (ScreenSize.isSmallTablet ? ScreenSize.textLarge : ScreenSize.textMedium),
                  ),
                  prefixIcon: Icon(
                    Icons.vpn_key_outlined, 
                    color: Colors.grey[600],
                    size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall : (ScreenSize.isSmallTablet ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                  ),
                  contentPadding: ScreenSize.isLargeTablet 
                      ? EdgeInsets.symmetric(vertical: ScreenSize.spacingExtraSmall, horizontal: ScreenSize.paddingLarge)
                      : (ScreenSize.isSmallTablet 
                          ? EdgeInsets.symmetric(vertical: ScreenSize.spacingLarge * 2, horizontal: ScreenSize.paddingMedium)
                          : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: const BorderSide(color: Color(0xFF0B5306), width: 2), // Green matching login/signup
                  ),
                ),
                readOnly: token != null && token!.isNotEmpty,
              )),
              
              // Token error
              Obx(() => controller.resetTokenError.value.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingExtraSmall), 
                        left: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall),
                      ),
                      child: Text(
                        controller.resetTokenError.value,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge * 2 : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textSmall),
                        ),
                      ),
                    )
                  : SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraLarge : ScreenSize.spacingSmall))),
              
              // New Password field
              Obx(() => TextField(
                onChanged: (value) {
                  controller.newPassword.value = value;
                  controller.resetPasswordError.value = '';
                  controller.resetGeneralError.value = '';
                },
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textExtraLarge * 2 : ScreenSize.textMedium),
                ),
                obscureText: !controller.isPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(
                    fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingMedium : (ScreenSize.isSmallTablet ? ScreenSize.headingLarge * 1.6 : ScreenSize.textMedium),
                    color: controller.resetPasswordError.value.isNotEmpty ? Colors.red : const Color(0xFF0B5306), // Green when no error, red only on error
                  ),
                  floatingLabelStyle: TextStyle(
                    color: controller.resetPasswordError.value.isNotEmpty ? Colors.red : const Color(0xFF0B5306), // Green when no error, red only on error
                  ),
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(
                    fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingMedium : (ScreenSize.isSmallTablet ? ScreenSize.textLarge : ScreenSize.textMedium),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outlined, 
                    color: Colors.grey[600],
                    size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall : (ScreenSize.isSmallTablet ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                      size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall : (ScreenSize.isSmallTablet ? ScreenSize.iconMedium : ScreenSize.iconSmall),
                    ),
                    onPressed: () {
                      controller.isPasswordVisible.value = !controller.isPasswordVisible.value;
                    },
                  ),
                  contentPadding: ScreenSize.isLargeTablet 
                      ? EdgeInsets.symmetric(vertical: ScreenSize.spacingExtraSmall, horizontal: ScreenSize.paddingLarge)
                      : (ScreenSize.isSmallTablet 
                          ? EdgeInsets.symmetric(vertical: ScreenSize.spacingLarge * 2, horizontal: ScreenSize.paddingMedium)
                          : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: const BorderSide(color: Color(0xFF0B5306), width: 2), // Green matching login/signup
                  ),
                ),
              )),
              
              // Password error
              Obx(() => controller.resetPasswordError.value.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingExtraSmall), 
                        left: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall),
                      ),
                      child: Text(
                        controller.resetPasswordError.value,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge * 2 : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textSmall),
                        ),
                      ),
                    )
                  : SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraLarge : ScreenSize.spacingSmall))),
              
              // Confirm Password field
              Obx(() => TextField(
                onChanged: (value) {
                  controller.resetConfirmPassword.value = value;
                  controller.resetConfirmPasswordError.value = '';
                  controller.resetGeneralError.value = '';
                },
                style: TextStyle(
                  fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textExtraLarge * 2 : ScreenSize.textMedium),
                ),
                obscureText: !controller.isPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(
                    fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingMedium : (ScreenSize.isSmallTablet ? ScreenSize.headingLarge * 1.6 : ScreenSize.textMedium),
                    color: controller.resetConfirmPasswordError.value.isNotEmpty ? Colors.red : const Color(0xFF0B5306), // Green when no error, red only on error
                  ),
                  floatingLabelStyle: TextStyle(
                    color: controller.resetConfirmPasswordError.value.isNotEmpty ? Colors.red : const Color(0xFF0B5306), // Green when no error, red only on error
                  ),
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(
                    fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingMedium : (ScreenSize.isSmallTablet ? ScreenSize.textLarge : ScreenSize.textMedium),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outlined, 
                    color: Colors.grey[600],
                    size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall : (ScreenSize.isSmallTablet ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                      size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall : (ScreenSize.isSmallTablet ? ScreenSize.iconMedium : ScreenSize.iconSmall),
                    ),
                    onPressed: () {
                      controller.isPasswordVisible.value = !controller.isPasswordVisible.value;
                    },
                  ),
                  contentPadding: ScreenSize.isLargeTablet 
                      ? EdgeInsets.symmetric(vertical: ScreenSize.spacingExtraSmall, horizontal: ScreenSize.paddingLarge)
                      : (ScreenSize.isSmallTablet 
                          ? EdgeInsets.symmetric(vertical: ScreenSize.spacingLarge * 2, horizontal: ScreenSize.paddingMedium)
                          : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    borderSide: const BorderSide(color: Color(0xFF0B5306), width: 2), // Green matching login/signup
                  ),
                ),
              )),
              
              // Confirm password error
              Obx(() => controller.resetConfirmPasswordError.value.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingExtraSmall), 
                        left: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall),
                      ),
                      child: Text(
                        controller.resetConfirmPasswordError.value,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge * 2 : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textSmall),
                        ),
                      ),
                    )
                  : SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraLarge : ScreenSize.spacingSmall))),
              
              // Reset password button
              Obx(() => SizedBox(
                width: double.infinity,
                height: ScreenSize.isLargeTablet ? ScreenSize.buttonPaddingVertical * 5 : (ScreenSize.isSmallTablet ? ScreenSize.buttonPaddingVertical * 9 : ScreenSize.buttonHeightMedium),
                child: ElevatedButton(
                  onPressed: controller.isResetPasswordLoading.value ? null : () {
                    controller.resetPassword();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5306), // Green matching login/signup
                    foregroundColor: Colors.white,
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
                    isLoading: controller.isResetPasswordLoading.value,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: ScreenSize.isLargeTablet ? ScreenSize.textExtraLarge * 3 : (ScreenSize.isSmallTablet ? ScreenSize.textExtraLarge * 2.2 : ScreenSize.textMedium),
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
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingHuge * 1.5 : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraLarge : ScreenSize.spacingMedium)),
              
              // Back to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remember your password? ',
                    style: TextStyle(
                      fontSize: ScreenSize.isLargeTablet ? ScreenSize.textExtraLarge : (ScreenSize.isSmallTablet ? ScreenSize.textExtraLarge * 1.8 : ScreenSize.textSmall),
                      color: Colors.grey[600], // Gray matching onboarding
                    ),
                  ),
                  TextButton(
                    onPressed: () => AppRoutes.toLogin(),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: ScreenSize.isLargeTablet ? ScreenSize.textExtraLarge : (ScreenSize.isSmallTablet ? ScreenSize.textExtraLarge * 1.8 : ScreenSize.textSmall),
                        color: const Color(0xFF0B5306), // Green matching login/signup
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
    );
  }
}

