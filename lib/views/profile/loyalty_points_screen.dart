import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/loyalty_controller.dart';
import '../../widgets/loading_widget.dart';

/// Loyalty Points Screen
/// Shows user's loyalty points, history, and redemption options
class LoyaltyPointsScreen extends StatelessWidget {
  const LoyaltyPointsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(LoyaltyController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Loyalty Points',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
      ),
      body: Obx(() => controller.isLoading.value
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: controller.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(ScreenSize.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Points Card
                    _buildPointsCard(controller),
                    SizedBox(height: ScreenSize.spacingLarge),
                    
                    // Statistics
                    _buildStatistics(controller),
                    SizedBox(height: ScreenSize.spacingLarge),
                    
                    // History Section
                    _buildHistorySection(controller),
                  ],
                ),
              ),
            )),
    );
  }
  
  Widget _buildPointsCard(LoyaltyController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ScreenSize.spacingXLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Points',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textWhite.withOpacity(0.9),
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            '${controller.currentPoints.value}',
            style: TextStyle(
              fontSize: ScreenSize.headingHuge,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            '10 points = 1 currency unit',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textWhite.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatistics(LoyaltyController controller) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
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
            'Statistics',
            style: TextStyle(
              fontSize: ScreenSize.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          _buildStatRow('Total Points Earned', '${controller.totalEarned.value}'),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildStatRow('Total Orders', '${controller.totalOrders.value}'),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildStatRow('Points per Order', '${controller.pointsPerOrder.value}'),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ScreenSize.textMedium,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: ScreenSize.textMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistorySection(LoyaltyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Points History',
          style: TextStyle(
            fontSize: ScreenSize.textLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: ScreenSize.spacingMedium),
        Obx(() => controller.isLoadingHistory.value
            ? const Center(child: CircularProgressIndicator())
            : controller.history.isEmpty
                ? _buildEmptyHistory()
                : Column(
                    children: [
                      ...controller.history.map((transaction) => 
                        _buildHistoryItem(transaction)
                      ),
                      if (controller.hasMore.value)
                        Padding(
                          padding: EdgeInsets.only(top: ScreenSize.spacingMedium),
                          child: ElevatedButton(
                            onPressed: () {
                              controller.loadHistory(page: controller.currentPage.value + 1);
                            },
                            child: Text('Load More', style: TextStyle(fontSize: ScreenSize.textMedium)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textWhite,
                              padding: EdgeInsets.symmetric(
                                horizontal: ScreenSize.buttonPaddingHorizontal,
                                vertical: ScreenSize.buttonPaddingVertical,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )),
      ],
    );
  }
  
  Widget _buildEmptyHistory() {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingXLarge),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: ScreenSize.iconExtraLarge * 1.5,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          Text(
            'No points history yet',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryItem(Map<String, dynamic> transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingSmall),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
            ),
            child: Icon(
              Icons.stars,
              color: AppColors.primary,
              size: ScreenSize.iconMedium,
            ),
          ),
          SizedBox(width: ScreenSize.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'] ?? 'Points earned',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingXSmall),
                Text(
                  'Order #${transaction['order_number'] ?? ''}',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingXSmall),
                Text(
                  transaction['transaction_date'] ?? '',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${transaction['points'] ?? 0}',
            style: TextStyle(
              fontSize: ScreenSize.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

