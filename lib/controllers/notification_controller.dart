import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../utils/cache_manager.dart';
import '../utils/app_colors.dart';
import '../utils/screen_size.dart';

/// Notification Controller
/// Handles notification settings and permissions
class NotificationController extends GetxController {
  // Notification settings
  final RxBool notificationsEnabled = true.obs;
  final RxBool pushNotificationsEnabled = true.obs;
  final RxBool emailNotificationsEnabled = true.obs;
  final RxBool smsNotificationsEnabled = false.obs;
  
  // Permission status
  final Rx<ph.PermissionStatus> notificationPermissionStatus = ph.PermissionStatus.denied.obs;
  final RxBool isCheckingPermission = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadNotificationSettings();
    checkNotificationPermission();
  }
  
  /// Load notification settings from cache
  void loadNotificationSettings() {
    notificationsEnabled.value = CacheManager.isNotificationsEnabled();
    // Load other settings if needed
  }
  
  /// Check current notification permission status
  Future<void> checkNotificationPermission() async {
    isCheckingPermission.value = true;
    try {
      final status = await ph.Permission.notification.status;
      notificationPermissionStatus.value = status;
    } catch (e) {
      print('[Notification] Error checking permission: $e');
    } finally {
      isCheckingPermission.value = false;
    }
  }
  
  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      // Check if already granted
      final currentStatus = await ph.Permission.notification.status;
      if (currentStatus == ph.PermissionStatus.granted) {
        notificationPermissionStatus.value = ph.PermissionStatus.granted;
        return true;
      }
      
      // Request permission
      final status = await ph.Permission.notification.request();
      notificationPermissionStatus.value = status;
      
      if (status == ph.PermissionStatus.granted) {
        // Save preference
        await CacheManager.setNotificationsEnabled(true);
        notificationsEnabled.value = true;
        
        Get.snackbar(
          'Permission Granted',
          'Notifications are now enabled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else if (status == ph.PermissionStatus.permanentlyDenied) {
        // Show dialog to open settings
        _showPermissionDeniedDialog();
        return false;
      } else {
        Get.snackbar(
          'Permission Denied',
          'Please enable notifications from settings to receive updates',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning.withOpacity(0.9),
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      print('[Notification] Error requesting permission: $e');
      Get.snackbar(
        'Error',
        'Failed to request notification permission',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: AppColors.textWhite,
      );
      return false;
    }
  }
  
  /// Show dialog when permission is permanently denied
  void _showPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
          'Notifications are disabled. Please enable them from app settings to receive order updates, offers, and important alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Open app settings
  Future<void> openAppSettings() async {
    try {
      final opened = await ph.openAppSettings();
      if (opened) {
        // Wait a bit and check permission again when user returns
        await Future.delayed(const Duration(seconds: 1));
        await checkNotificationPermission();
      }
    } catch (e) {
      print('[Notification] Error opening settings: $e');
      Get.snackbar(
        'Error',
        'Could not open app settings',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  /// Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    if (value) {
      // If enabling, request permission first
      final granted = await requestNotificationPermission();
      if (granted) {
        notificationsEnabled.value = true;
        await CacheManager.setNotificationsEnabled(true);
      } else {
        // Permission not granted, keep it disabled
        notificationsEnabled.value = false;
      }
    } else {
      // Disabling notifications
      notificationsEnabled.value = false;
      await CacheManager.setNotificationsEnabled(false);
      
      Get.snackbar(
        'Notifications Disabled',
        'You will not receive push notifications',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
  
  /// Toggle push notifications
  Future<void> togglePushNotifications(bool value) async {
    if (value) {
      // If enabling, check permission first
      final status = await ph.Permission.notification.status;
      if (status != ph.PermissionStatus.granted) {
        final granted = await requestNotificationPermission();
        if (!granted) {
          return; // Don't enable if permission not granted
        }
      }
    }
    pushNotificationsEnabled.value = value;
  }
  
  /// Toggle email notifications
  void toggleEmailNotifications(bool value) {
    emailNotificationsEnabled.value = value;
  }
  
  /// Toggle SMS notifications
  void toggleSmsNotifications(bool value) {
    smsNotificationsEnabled.value = value;
  }
  
  /// Get permission status text
  String getPermissionStatusText() {
    switch (notificationPermissionStatus.value) {
      case ph.PermissionStatus.granted:
        return 'Granted';
      case ph.PermissionStatus.denied:
        return 'Denied';
      case ph.PermissionStatus.restricted:
        return 'Restricted';
      case ph.PermissionStatus.limited:
        return 'Limited';
      case ph.PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      default:
        return 'Unknown';
    }
  }
  
  /// Get permission status color
  Color getPermissionStatusColor() {
    switch (notificationPermissionStatus.value) {
      case ph.PermissionStatus.granted:
        return AppColors.success;
      case ph.PermissionStatus.denied:
      case ph.PermissionStatus.permanentlyDenied:
        return AppColors.error;
      case ph.PermissionStatus.restricted:
      case ph.PermissionStatus.limited:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

