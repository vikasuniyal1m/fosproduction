import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';

/// Change Password Screen
/// Allows user to change their password
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
      body: Obx(() => controller.isLoading.value
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: EdgeInsets.all(ScreenSize.spacingLarge),
              child: Form(
                key: controller.changePasswordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: ScreenSize.spacingLarge),
                    
                    // Info Card
                    Container(
                      padding: EdgeInsets.all(ScreenSize.spacingLarge),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                        border: Border.all(color: AppColors.info),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info),
                          SizedBox(width: ScreenSize.spacingMedium),
                          Expanded(
                            child: Text(
                              'Your password must be at least 8 characters long',
                              style: TextStyle(
                                fontSize: ScreenSize.textMedium,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ScreenSize.spacingExtraLarge),
                    
                    // Current Password
                    Obx(() => TextFormField(
                      controller: controller.currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        hintText: 'Enter your current password',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showCurrentPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => controller.showCurrentPassword.value = !controller.showCurrentPassword.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                      ),
                      obscureText: !controller.showCurrentPassword.value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current password is required';
                        }
                        return null;
                      },
                    )),
                    SizedBox(height: ScreenSize.spacingLarge),
                    
                    // New Password
                    Obx(() => TextFormField(
                      controller: controller.newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter your new password',
                        prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showNewPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => controller.showNewPassword.value = !controller.showNewPassword.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                      ),
                      obscureText: !controller.showNewPassword.value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    )),
                    SizedBox(height: ScreenSize.spacingLarge),
                    
                    // Confirm New Password
                    Obx(() => TextFormField(
                      controller: controller.confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: 'Re-enter your new password',
                        prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showConfirmPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => controller.showConfirmPassword.value = !controller.showConfirmPassword.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                      ),
                      obscureText: !controller.showConfirmPassword.value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != controller.newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )),
                    SizedBox(height: ScreenSize.spacingExtraLarge),
                    
                    // Change Password Button
                    SizedBox(
                      height: ScreenSize.buttonHeightMedium,
                      child: ElevatedButton(
                        onPressed: controller.changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                          ),
                        ),
                        child: Obx(() => controller.isChangingPassword.value
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                                ),
                              )
                            : Text(
                                'Change Password',
                                style: TextStyle(
                                  fontSize: ScreenSize.textLarge,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),
                      ),
                    ),
                  ],
                ),
              ),
            )),
    );
  }
}

