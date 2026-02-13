import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';

/// About Screen
/// Shows app information and version
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'About',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ScreenSize.spacingLarge),
        child: Column(
          children: [
            SizedBox(height: ScreenSize.spacingExtraLarge),
            
            // App Logo/Icon
            Container(
              width: ScreenSize.isLargeTablet ? ScreenSize.widthPercent(25) : (ScreenSize.isSmallTablet ? ScreenSize.widthPercent(30) : ScreenSize.widthPercent(35)),
              height: ScreenSize.isLargeTablet ? ScreenSize.widthPercent(25) : (ScreenSize.isSmallTablet ? ScreenSize.widthPercent(30) : ScreenSize.widthPercent(35)),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadiusLarge),
              ),
              child: Icon(
                Icons.shopping_bag,
                size: ScreenSize.isLargeTablet ? ScreenSize.iconExtraLarge * 2.5 : (ScreenSize.isSmallTablet ? ScreenSize.iconExtraLarge * 2 : ScreenSize.iconExtraLarge * 1.5),
                color: AppColors.textWhite,
              ),
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            
            // App Name
            Text(
              'FOS Productions',
              style: TextStyle(
                fontSize: ScreenSize.headingLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            
            // App Version
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingExtraLarge),
            
            // App Description
            Container(
              padding: EdgeInsets.all(ScreenSize.spacingLarge),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              ),
              child: Text(
                'Your one-stop shop for all your shopping needs. Browse thousands of products, enjoy fast delivery, and secure payments.',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: ScreenSize.spacingExtraLarge),
            
            // Information Cards
            _buildInfoCard(
              icon: Icons.code,
              title: 'Developed with',
              subtitle: 'Flutter & PHP',
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            _buildInfoCard(
              icon: Icons.copyright,
              title: 'Copyright',
              subtitle: '© 2026 FOS Productions. All rights reserved.',
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'License',
              subtitle: 'Proprietary Software',
            ),
            SizedBox(height: ScreenSize.spacingExtraLarge),
            
            // Social Links
            Text(
              'Follow Us',
              style: TextStyle(
                fontSize: ScreenSize.textLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  onTap: () {
                    Get.snackbar('Info', 'Facebook page coming soon');
                  },
                ),
                SizedBox(width: ScreenSize.spacingLarge),
                _buildSocialButton(
                  icon: Icons.alternate_email,
                  onTap: () {
                    Get.snackbar('Info', 'Twitter page coming soon');
                  },
                ),
                SizedBox(width: ScreenSize.spacingLarge),
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  onTap: () {
                    Get.snackbar('Info', 'Instagram page coming soon');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: ScreenSize.iconLarge),
          SizedBox(width: ScreenSize.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingExtraSmall),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final buttonSize = ScreenSize.isLargeTablet ? ScreenSize.iconExtraLarge * 1.5 : (ScreenSize.isSmallTablet ? ScreenSize.iconExtraLarge * 1.3 : ScreenSize.iconExtraLarge * 1.1);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(buttonSize / 2),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary),
        ),
        child: Icon(
          icon, 
          color: AppColors.primary,
          size: buttonSize * 0.5,
        ),
      ),
    );
  }
}

