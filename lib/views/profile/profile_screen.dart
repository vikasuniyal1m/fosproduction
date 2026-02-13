import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/cache_manager.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Profile Screen
/// User profile and settings screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: ScreenSize.headingMedium,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: ScreenSize.iconMedium,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final isLoggedIn = CacheManager.isLoggedIn();

        if (controller.isLoading.value && isLoggedIn) {
          return const LoadingWidget();
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(controller, isLoggedIn),

              // Menu Items (only show if logged in)
              if (isLoggedIn) _buildMenuSection(controller),

              // Login Button (show if not logged in)
              if (!isLoggedIn) _buildLoginSection(),
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildProfileHeader(ProfileController controller, bool isLoggedIn) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          SizedBox(height: ScreenSize.spacingMedium),
          
          // Profile Image
          Stack(
            alignment: Alignment.center,
            children: [
              Obx(() => CircleAvatar(
                radius: ScreenSize.iconExtraLarge * 1.3,
                backgroundColor: AppColors.textWhite,
                child: controller.userImage.value.isNotEmpty
                    ? CircleAvatar(
                        radius: ScreenSize.iconExtraLarge * 1.25,
                        backgroundImage: NetworkImage(controller.userImage.value),
                      )
                    : Icon(
                        Icons.person,
                        size: ScreenSize.iconExtraLarge * 1.7,
                        color: AppColors.primary,
                      ),
              )),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(ScreenSize.spacingExtraSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textWhite,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: ScreenSize.iconSmall,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          
          // User Name
          Text(
            isLoggedIn ? (controller.userName.value.isNotEmpty ? controller.userName.value : 'User') : 'Guest User',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          SizedBox(height: ScreenSize.spacingXSmall),
          
          // User Email
          Text(
            isLoggedIn ? (controller.userEmail.value.isNotEmpty ? controller.userEmail.value : 'Not available') : 'Login to access your account',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textWhite.withOpacity(0.9),
            ),
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          
          // Edit Profile Button (only show if logged in)
          if (isLoggedIn)
            SizedBox(
              height: ScreenSize.buttonHeightMedium,
              child: OutlinedButton(
                onPressed: controller.navigateToEditProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textWhite,
                  side: BorderSide(color: AppColors.textWhite),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                  ),
                ),
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMenuSection(ProfileController controller) {
    return Padding(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.shopping_bag_outlined,
            title: 'My Orders',
            subtitle: 'View your order history',
            onTap: controller.navigateToOrders,
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.favorite_outline,
            title: 'Wishlist',
            subtitle: 'Your saved items',
            onTap: controller.navigateToWishlist,
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            subtitle: 'Manage your addresses',
            onTap: controller.navigateToAddresses,
          ),
          // _buildDivider(),
          // _buildMenuTile(
          //   icon: Icons.payment_outlined,
          //   title: 'Payment Methods',
          //   subtitle: 'Manage payment options',
          //   onTap: controller.navigateToPaymentMethods,
          // ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.stars_outlined,
            title: 'Loyalty Points',
            subtitle: '${controller.loyaltyPoints.value} points available',
            onTap: controller.navigateToLoyaltyPoints,
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Refer & Earn',
            subtitle: 'Share and earn rewards',
            onTap: controller.navigateToReferralProgram,
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: controller.navigateToNotificationSettings,
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          
          // Help & Support Section
          _buildSectionTitle('Support'),
          SizedBox(height: ScreenSize.spacingMedium),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact us',
            onTap: controller.navigateToHelpSupport,
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and info',
            onTap: controller.navigateToAbout,
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          
          // Delete Account Section
          _buildSectionTitle('Account Management'),
          SizedBox(height: ScreenSize.spacingMedium),
          _buildMenuTile(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            onTap: controller.deleteAccount,
            isDestructive: true,
          ),
          SizedBox(height: ScreenSize.spacingLarge),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: ScreenSize.buttonHeightMedium,
            child: ElevatedButton(
              onPressed: controller.logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: ScreenSize.textLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ),
      leading: Container(
        padding: EdgeInsets.all(ScreenSize.spacingSmall),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        ),
        child: Icon(
          icon, 
          color: isDestructive ? AppColors.error : AppColors.primary,
          size: ScreenSize.iconMedium,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ScreenSize.textLarge,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: ScreenSize.textSmall,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
        size: ScreenSize.iconSmall,
      ),
      onTap: onTap,
    );
  }
  
  Widget _buildDivider() {
    return Divider(
      height: ScreenSize.spacingLarge,
      color: AppColors.border,
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: ScreenSize.headingSmall,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLoginSection() {
    return Padding(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      child: Column(
        children: [
          SizedBox(height: ScreenSize.spacingLarge),

          // Login Message
          Text(
            'Login to access your account',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ScreenSize.spacingLarge),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: ScreenSize.buttonHeightMedium,
            child: ElevatedButton(
              onPressed: () => AppRoutes.toLogin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                ),
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: ScreenSize.textLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: ScreenSize.spacingLarge),

          // Sign Up Link
          TextButton(
            onPressed: () => AppRoutes.toSignup(),
            child: Text(
              'Don\'t have an account? Sign Up',
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
