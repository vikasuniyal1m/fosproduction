import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/cache_manager.dart';
import '../../controllers/profile_controller.dart';
import '../../utils/getx_registry.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/silent_loading.dart';
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
      body: CacheManager.isLoggedIn()
          ? Obx(() {
              if (SilentLoading.blockUi(
                isLoading: controller.isLoading.value,
                hasContent: controller.userName.value.isNotEmpty,
              )) {
                return const LoadingWidget();
              }
              return _buildProfileBody(controller, isLoggedIn: true);
            })
          : _buildProfileBody(controller, isLoggedIn: false),
    );
  }

  Widget _buildProfileBody(ProfileController controller, {required bool isLoggedIn}) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      child: Column(
        children: [
          _buildProfileHeader(controller, isLoggedIn),
          if (isLoggedIn) ...[
            _buildQuickActionsGrid(controller),
            _buildMenuSection(controller),
          ],
          if (!isLoggedIn) _buildLoginSection(),
        ],
      ),
    );
  }
  
  Widget _buildProfileHeader(ProfileController controller, bool isLoggedIn) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ScreenSize.spacingMedium,
        ScreenSize.spacingSmall,
        ScreenSize.spacingMedium,
        ScreenSize.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image
          Stack(
            alignment: Alignment.center,
            children: [
              Obx(() => Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.textWhite,
                  shape: BoxShape.circle,
                ),
                child: controller.userImage.value.isNotEmpty
                    ? CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(controller.userImage.value),
                      )
                    : const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          Icons.person,
                          size: 35,
                          color: AppColors.primary,
                        ),
                      ),
              )),
              if (isLoggedIn)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textWhite,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: isLoggedIn
                ? Obx(() => _buildUserInfoTexts(controller))
                : _buildGuestInfoTexts(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestInfoTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Guest User',
          style: TextStyle(
            fontSize: ScreenSize.headingSmall,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ScreenSize.spacingTiny),
        Text(
          'Login to access your account',
          style: TextStyle(
            fontSize: ScreenSize.textExtraSmall,
            color: AppColors.textWhite.withOpacity(0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildUserInfoTexts(ProfileController controller) {
    final name = controller.userName.value.isNotEmpty
        ? controller.userName.value
        : 'User';
    final email = controller.userEmail.value.isNotEmpty
        ? controller.userEmail.value
        : 'Not available';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: ScreenSize.headingSmall,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ScreenSize.spacingTiny),
        Text(
          email,
          style: TextStyle(
            fontSize: ScreenSize.textExtraSmall,
            color: AppColors.textWhite.withOpacity(0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: controller.navigateToEditProfile,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSize.paddingSmall,
              vertical: ScreenSize.spacingTiny,
            ),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
            ),
            child: Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: ScreenSize.textExtraSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(ProfileController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ScreenSize.spacingMedium,
        ScreenSize.spacingMedium,
        ScreenSize.spacingMedium,
        0,
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: ScreenSize.spacingXSmall,
        crossAxisSpacing: ScreenSize.spacingXSmall,
        childAspectRatio: 0.9,
        children: [
          _buildQuickActionItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Orders',
            onTap: controller.navigateToOrders,
          ),
          _buildQuickActionItem(
            icon: Icons.favorite_outline,
            label: 'Wishlist',
            onTap: controller.navigateToWishlist,
          ),
          _buildQuickActionItem(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: () => Get.toNamed(AppRoutes.gallery),
          ),
          _buildQuickActionItem(
            icon: Icons.location_on_outlined,
            label: 'Addresses',
            onTap: controller.navigateToAddresses,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingXSmall),
            decoration: BoxDecoration(
              color: AppColors.textWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: ScreenSize.iconMedium,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: ScreenSize.textExtraSmall,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuSection(ProfileController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingLarge),
      child: Column(
        children: [
          SizedBox(height: ScreenSize.spacingSmall),
          
          // More Features Card
          _buildMenuCard([
            _buildMenuTile(
              icon: Icons.photo_library_outlined,
              title: 'Gallery',
              subtitle: 'View saved images',
              onTap: () => Get.toNamed(AppRoutes.gallery),
            ),
            _buildMenuTile(
              icon: Icons.card_giftcard_outlined,
              title: 'Refer & Earn',
              subtitle: 'Share and earn rewards',
              onTap: controller.navigateToReferralProgram,
            ),
            _buildMenuTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage settings',
              onTap: controller.navigateToNotificationSettings,
            ),
          ]),
          
          SizedBox(height: ScreenSize.spacingMedium),
          
          // Support Card
          _buildSectionTitle('Support'),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildMenuCard([
            _buildMenuTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Contact us',
              onTap: controller.navigateToHelpSupport,
            ),
            _buildMenuTile(
              icon: Icons.info_outline,
              title: 'About App',
              subtitle: 'Version and more',
              onTap: controller.navigateToAbout,
            ),
          ]),
          
          SizedBox(height: ScreenSize.spacingMedium),
          
          // Account Card
          _buildSectionTitle('Security'),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildMenuCard([
            _buildMenuTile(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanent deletion',
              onTap: controller.deleteAccount,
              isDestructive: true,
            ),
          ]),
          
          SizedBox(height: ScreenSize.spacingLarge),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: ScreenSize.buttonHeightMedium,
            child: ElevatedButton.icon(
              onPressed: () => GetXRegistry.auth().logout(),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withOpacity(0.1),
                foregroundColor: AppColors.error,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.error.withOpacity(0.2)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      leading: Icon(
        icon, 
        color: isDestructive ? AppColors.error : AppColors.primary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ScreenSize.textMedium,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
        size: 18,
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
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: ScreenSize.textExtraSmall,
          fontWeight: FontWeight.bold,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
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
