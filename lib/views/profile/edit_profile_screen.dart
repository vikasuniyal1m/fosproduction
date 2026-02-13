import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';

/// Edit Profile Screen
/// Allows user to edit their profile information
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: ScreenSize.isLargeTablet ? ScreenSize.headingMedium : (ScreenSize.isSmallTablet ? ScreenSize.headingSmall : ScreenSize.textExtraLarge),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: ScreenSize.isLargeTablet ? ScreenSize.iconMedium : (ScreenSize.isSmallTablet ? ScreenSize.iconMedium : ScreenSize.iconSmall),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() => controller.isLoading.value
            ? const LoadingWidget()
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.isTablet ? ScreenSize.paddingExtraLarge * 1.5 : ScreenSize.spacingLarge,
                  vertical: ScreenSize.spacingLarge,
                ),
                child: Form(
                  key: controller.editProfileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: ScreenSize.spacingLarge),
                      
                      // Profile Image Section
                      _buildProfileImageSection(controller),
                      SizedBox(height: ScreenSize.spacingExtraLarge),
                      
                      // Form Fields Container
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name Field
                          TextFormField(
                            controller: controller.nameController,
                            style: TextStyle(
                              fontSize: ScreenSize.isTablet ? ScreenSize.textLarge : ScreenSize.textMedium,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: TextStyle(
                                fontSize: ScreenSize.isTablet ? ScreenSize.textMedium : ScreenSize.textSmall,
                              ),
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(
                                Icons.person_outline, 
                                color: AppColors.primary,
                                size: ScreenSize.isTablet ? ScreenSize.iconMedium : ScreenSize.iconSmall,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ScreenSize.inputPadding,
                                vertical: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.inputPadding,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ScreenSize.spacingMedium),
                          
                          // Email Field (Read-only)
                          TextFormField(
                            controller: controller.emailController,
                            enabled: false,
                            style: TextStyle(
                              fontSize: ScreenSize.isTablet ? ScreenSize.textLarge : ScreenSize.textMedium,
                              color: AppColors.textSecondary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                fontSize: ScreenSize.isTablet ? ScreenSize.textMedium : ScreenSize.textSmall,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined, 
                                color: AppColors.textTertiary,
                                size: ScreenSize.isTablet ? ScreenSize.iconMedium : ScreenSize.iconSmall,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ScreenSize.inputPadding,
                                vertical: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.inputPadding,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundGrey,
                            ),
                          ),
                          SizedBox(height: ScreenSize.spacingMedium),
                          
                          // Phone Field
                          TextFormField(
                            controller: controller.phoneController,
                            style: TextStyle(
                              fontSize: ScreenSize.isTablet ? ScreenSize.textLarge : ScreenSize.textMedium,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              labelStyle: TextStyle(
                                fontSize: ScreenSize.isTablet ? ScreenSize.textMedium : ScreenSize.textSmall,
                              ),
                              hintText: 'Enter your phone number',
                              prefixIcon: Icon(
                                Icons.phone_outlined, 
                                color: AppColors.primary,
                                size: ScreenSize.isTablet ? ScreenSize.iconMedium : ScreenSize.iconSmall,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ScreenSize.inputPadding,
                                vertical: ScreenSize.isTablet ? ScreenSize.spacingMedium : ScreenSize.inputPadding,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final phoneRegex = RegExp(r'^[0-9]{10}$');
                                if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
                                  return 'Enter a valid 10-digit phone number';
                                }
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ScreenSize.spacingExtraLarge),
                          
                          // Save Button
                          SizedBox(
                            height: ScreenSize.isTablet ? 60.0 : ScreenSize.buttonHeightMedium,
                            child: ElevatedButton(
                              onPressed: controller.updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                                ),
                              ),
                              child: Obx(() => controller.isUpdating.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: ScreenSize.isTablet ? ScreenSize.textLarge : ScreenSize.textMedium,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )),
                            ),
                          ),
                          SizedBox(height: ScreenSize.spacingMedium),
                          
                          // Change Password Button
                          SizedBox(
                            height: ScreenSize.isTablet ? 60.0 : ScreenSize.buttonHeightMedium,
                            child: OutlinedButton(
                              onPressed: controller.navigateToChangePassword,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                                ),
                              ),
                              child: Text(
                                'Change Password',
                                style: TextStyle(
                                  fontSize: ScreenSize.isTablet ? ScreenSize.textLarge : ScreenSize.textMedium,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // Increased bottom spacing for iPad compatibility
                          SizedBox(height: ScreenSize.isTablet ? 100.0 : 40.0),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
      ),
    );
  }
  
  Widget _buildProfileImageSection(ProfileController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Obx(() => CircleAvatar(
              radius: ScreenSize.isTablet ? 70 : 50,
              backgroundColor: AppColors.backgroundGrey,
              backgroundImage: controller.userImage.value.isNotEmpty
                  ? NetworkImage(controller.userImage.value)
                  : null,
              child: controller.userImage.value.isEmpty
                  ? Icon(
                      Icons.person,
                      size: ScreenSize.isTablet ? 70 : 50,
                      color: AppColors.textTertiary,
                    )
                  : null,
            )),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: ScreenSize.isTablet ? 28 : 20,
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ScreenSize.spacingSmall),
        TextButton(
          onPressed: () {
            Get.snackbar('Info', 'Image upload coming soon');
          },
          child: Text(
            'Change Photo',
            style: TextStyle(
              fontSize: ScreenSize.isTablet ? ScreenSize.textMedium : ScreenSize.textSmall,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
