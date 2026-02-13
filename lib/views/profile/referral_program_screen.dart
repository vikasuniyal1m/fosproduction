import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/referral_controller.dart';
import '../../widgets/loading_widget.dart';

/// Referral Program Screen
/// Shows user's referral code, statistics, and referred users
class ReferralProgramScreen extends StatelessWidget {
  const ReferralProgramScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ReferralController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Refer & Earn',
          style: TextStyle(
            fontSize: ScreenSize.headingSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightMedium,
      ),
      body: Obx(() => controller.isLoading.value
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: controller.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(ScreenSize.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Referral Code Card
                    _buildReferralCodeCard(controller),
                    SizedBox(height: ScreenSize.spacingMedium),
                    
                    // Statistics
                    _buildStatistics(controller),
                    SizedBox(height: ScreenSize.spacingMedium),
                    
                    // Referred Users
                    _buildReferredUsers(controller),
                  ],
                ),
              ),
            )),
    );
  }
  
  Widget _buildReferralCodeCard(ReferralController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ScreenSize.paddingMedium),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Referral Code',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textWhite.withOpacity(0.9),
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSize.spacingMedium,
              vertical: ScreenSize.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.textWhite,
              borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
            ),
            child: Text(
              controller.referralCode.value,
              style: TextStyle(
                fontSize: ScreenSize.headingSmall,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: controller.referralCode.value));
                    Get.snackbar('Copied', 'Referral code copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success,
                      colorText: AppColors.textWhite,
                      margin: EdgeInsets.all(ScreenSize.spacingMedium),
                    );
                  },
                  icon: Icon(Icons.copy, size: ScreenSize.iconSmall),
                  label: Text('Copy', style: TextStyle(fontSize: ScreenSize.textSmall)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textWhite,
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: ScreenSize.spacingSmall),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.shareReferralCode,
                  icon: Icon(Icons.share, size: ScreenSize.iconSmall),
                  label: Text('Share', style: TextStyle(fontSize: ScreenSize.textSmall)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textWhite,
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'Share your code and earn rewards!',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textWhite.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatistics(ReferralController controller) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Statistics',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Obx(() => controller.isLoadingStats.value
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStatCard('Total Referrals', '${controller.totalReferrals.value}', Icons.people),
                    SizedBox(height: ScreenSize.spacingSmall),
                    _buildStatCard('Successful Referrals', '${controller.successfulReferrals.value}', Icons.check_circle),
                    SizedBox(height: ScreenSize.spacingSmall),
                    _buildStatCard('Rewards Earned', '${controller.rewardPointsEarned.value}', Icons.stars),
                  ],
                )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingSmall + 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: ScreenSize.iconSmall),
          ),
          SizedBox(width: ScreenSize.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReferredUsers(ReferralController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referred Users',
          style: TextStyle(
            fontSize: ScreenSize.textMedium,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ScreenSize.spacingSmall),
        Obx(() => controller.isLoadingStats.value
            ? const Center(child: CircularProgressIndicator())
            : controller.referredUsers.isEmpty
                ? _buildEmptyReferredUsers()
                : Column(
                    children: controller.referredUsers.map((user) => 
                      _buildReferredUserItem(user)
                    ).toList(),
                  )),
      ],
    );
  }
  
  Widget _buildEmptyReferredUsers() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: ScreenSize.iconLarge * 1.5,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'No referrals yet',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReferredUserItem(Map<String, dynamic> user) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      padding: EdgeInsets.all(ScreenSize.spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            radius: 18,
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          SizedBox(width: ScreenSize.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'User',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${user['orders_count'] ?? 0} orders • ₹${user['total_spent']?.toStringAsFixed(0) ?? '0'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (user['is_active'] == true)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

