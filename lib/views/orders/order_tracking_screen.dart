import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';

/// Order Tracking Screen
class OrderTrackingScreen extends StatelessWidget {
  final int orderId;
  
  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: controller.getOrderTracking(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ScreenSize.iconExtraLarge * 2,
                    color: AppColors.error,
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  Text(
                    'Failed to load tracking information',
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingMedium),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          
          final trackingData = snapshot.data!;
          final trackingHistory = trackingData['tracking_history'] as List? ?? [];
          final currentStatus = trackingData['current_status'] ?? 'pending';
          final trackingNumber = trackingData['tracking_number'];
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Info Card
                Container(
                  padding: EdgeInsets.all(ScreenSize.spacingLarge),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Order #${trackingData['order_number']}',
                              style: TextStyle(
                                fontSize: ScreenSize.headingMedium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: ScreenSize.spacingSmall),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ScreenSize.spacingSmall,
                              vertical: ScreenSize.spacingExtraSmall,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(currentStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(currentStatus),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _formatStatus(currentStatus),
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(currentStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (trackingNumber != null) ...[
                        SizedBox(height: ScreenSize.spacingMedium),
                        Row(
                          children: [
                            Icon(Icons.local_shipping, size: 20, color: AppColors.primary),
                            SizedBox(width: ScreenSize.spacingSmall),
                            Text(
                              'Tracking Number: ',
                              style: TextStyle(
                                fontSize: ScreenSize.textMedium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                trackingNumber,
                                style: TextStyle(
                                  fontSize: ScreenSize.textMedium,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: ScreenSize.spacingLarge),
                
                // Tracking Timeline
                Text(
                  'Tracking History',
                  style: TextStyle(
                    fontSize: ScreenSize.textLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingMedium),
                
                if (trackingHistory.isEmpty)
                  Container(
                    padding: EdgeInsets.all(ScreenSize.spacingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                    ),
                    child: Center(
                      child: Text(
                        'No tracking information available yet',
                        style: TextStyle(
                          fontSize: ScreenSize.textMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  _buildTrackingTimeline(trackingHistory),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTrackingTimeline(List trackingHistory) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trackingHistory.length,
        separatorBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingLarge),
          child: Divider(height: 1, color: AppColors.border),
        ),
        itemBuilder: (context, index) {
          final item = trackingHistory[index];
          final status = item['status'] ?? '';
          final isCompleted = item['is_completed'] ?? false;
          final isCurrent = item['is_current'] ?? false;
          final date = item['date'];
          
          return Padding(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent ? AppColors.primary : AppColors.border,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted || isCurrent ? AppColors.primary : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: isCompleted || isCurrent
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.textWhite,
                            )
                          : null,
                    ),
                    if (index < trackingHistory.length - 1)
                      Container(
                        width: 2,
                        height: 60,
                        color: isCompleted ? AppColors.primary : AppColors.border,
                      ),
                  ],
                ),
                SizedBox(width: ScreenSize.spacingMedium),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatStatus(status),
                        style: TextStyle(
                          fontSize: ScreenSize.textLarge,
                          fontWeight: FontWeight.w600,
                          color: isCompleted || isCurrent ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (date != null) ...[
                        SizedBox(height: ScreenSize.spacingSmall),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
  
  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

