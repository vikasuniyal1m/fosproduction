import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/screen_size.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Notification Settings Screen
/// Allows users to manage notification preferences and permissions
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
      ),
      body: Obx(() => SingleChildScrollView(
        padding: EdgeInsets.all(ScreenSize.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission Status Card
            _buildPermissionStatusCard(controller),
            
            SizedBox(height: ScreenSize.spacingLarge),
            
            // Notification Settings Section
            _buildSectionTitle('Notification Preferences'),
            SizedBox(height: ScreenSize.spacingMedium),
            
            // Enable/Disable All Notifications
            _buildNotificationSwitch(
              controller: controller,
              title: 'Enable Notifications',
              subtitle: 'Receive all types of notifications',
              value: controller.notificationsEnabled.value,
              onChanged: controller.toggleNotifications,
              icon: Icons.notifications_active,
            ),
            
            SizedBox(height: ScreenSize.spacingMedium),
            
            // Push Notifications
            _buildNotificationSwitch(
              controller: controller,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications on your device',
              value: controller.pushNotificationsEnabled.value,
              onChanged: controller.togglePushNotifications,
              icon: Icons.phone_android,
              enabled: controller.notificationsEnabled.value,
            ),
            
            SizedBox(height: ScreenSize.spacingSmall),
            
            // Email Notifications
            _buildNotificationSwitch(
              controller: controller,
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: controller.emailNotificationsEnabled.value,
              onChanged: controller.toggleEmailNotifications,
              icon: Icons.email_outlined,
              enabled: controller.notificationsEnabled.value,
            ),
            
            SizedBox(height: ScreenSize.spacingSmall),
            
            // SMS Notifications
            _buildNotificationSwitch(
              controller: controller,
              title: 'SMS Notifications',
              subtitle: 'Receive notifications via SMS',
              value: controller.smsNotificationsEnabled.value,
              onChanged: controller.toggleSmsNotifications,
              icon: Icons.sms_outlined,
              enabled: controller.notificationsEnabled.value,
            ),
            
            SizedBox(height: ScreenSize.spacingLarge),
            
            // Request Permission Button (if not granted)
            if (controller.notificationPermissionStatus.value != ph.PermissionStatus.granted)
              _buildRequestPermissionButton(controller),
            
            SizedBox(height: ScreenSize.spacingLarge),
            
            // Info Section
            _buildInfoSection(),
          ],
        ),
      )),
    );
  }
  
  /// Build permission status card
  Widget _buildPermissionStatusCard(NotificationController controller) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: controller.getPermissionStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(
          color: controller.getPermissionStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            controller.notificationPermissionStatus.value == ph.PermissionStatus.granted
              ? Icons.check_circle
              : Icons.warning_amber_rounded,
            color: controller.getPermissionStatusColor(),
            size: ScreenSize.iconLarge,
          ),
          SizedBox(width: ScreenSize.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permission Status',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  controller.getPermissionStatusText(),
                  style: TextStyle(
                    fontSize: ScreenSize.textLarge,
                    fontWeight: FontWeight.bold,
                    color: controller.getPermissionStatusColor(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ScreenSize.headingSmall,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
  
  /// Build notification switch
  Widget _buildNotificationSwitch({
    required NotificationController controller,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingSmall),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
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
                    color: enabled 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
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
          Switch(
            value: enabled ? value : false,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
  
  /// Build request permission button
  Widget _buildRequestPermissionButton(NotificationController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.isCheckingPermission.value
          ? null
          : controller.requestNotificationPermission,
        icon: controller.isCheckingPermission.value
            ? SizedBox(
                width: ScreenSize.iconSmall,
                height: ScreenSize.iconSmall,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                ),
              )
            : Icon(Icons.notifications_active, size: ScreenSize.iconMedium),
          label: Text(
          controller.isCheckingPermission.value
            ? 'Checking...'
            : 'Request Notification Permission',
          style: TextStyle(
            fontSize: ScreenSize.textMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          padding: EdgeInsets.symmetric(
            vertical: ScreenSize.spacingMedium,
            horizontal: ScreenSize.spacingLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
          ),
        ),
      ),
    );
  }
  
  /// Build info section
  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: ScreenSize.iconMedium,
          ),
          SizedBox(width: ScreenSize.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Notifications',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                Text(
                  'Enable notifications to receive:\n'
                  '• Order updates and tracking\n'
                  '• Special offers and discounts\n'
                  '• New product arrivals\n'
                  '• Payment confirmations\n'
                  '• Important account alerts',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

