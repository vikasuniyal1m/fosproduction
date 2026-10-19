import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../services/notification_service.dart';
import '../utils/cache_manager.dart';
import '../utils/app_colors.dart';

/// Enhanced Notification Controller
/// Handles notification settings, permissions, and integrates with NotificationService
class NotificationController extends GetxController {
  // Use NotificationService - handle case where service might not be initialized
  late final NotificationService _notificationService;
  
  // Notification settings - synced from NotificationService
  final RxBool notificationsEnabled = true.obs;
  final RxBool pushNotificationsEnabled = true.obs;
  final RxBool emailNotificationsEnabled = true.obs;
  final RxBool smsNotificationsEnabled = false.obs;
  
  // Notification type toggles
  final RxBool ordersNotificationsEnabled = true.obs;
  final RxBool offersNotificationsEnabled = true.obs;
  final RxBool paymentsNotificationsEnabled = true.obs;
  final RxBool generalNotificationsEnabled = true.obs;
  
  // Permission status
  final Rx<ph.PermissionStatus> notificationPermissionStatus = ph.PermissionStatus.denied.obs;
  final RxBool isCheckingPermission = false.obs;
  final RxBool isSavingSettings = false.obs;
  
  // Unread count - safe getter
  RxInt get unreadCount {
    try {
      if (Get.isRegistered<NotificationService>()) {
        return _notificationService.unreadCount;
      }
    } catch (e) {
      print('[NotificationController] Error getting unread count: $e');
    }
    return 0.obs; // Fallback value
  }
  
  // Helper method to safely call NotificationService methods
  Future<void> _safeServiceCall(Future<void> Function(NotificationService) action) async {
    try {
      if (Get.isRegistered<NotificationService>()) {
        await action(_notificationService);
      } else {
        print('[NotificationController] NotificationService not available, skipping operation');
      }
    } catch (e) {
      print('[NotificationController] Error calling service method: $e');
    }
  }
  
  @override
  void onInit() {
    super.onInit();
    
    // Safely get NotificationService
    try {
      if (Get.isRegistered<NotificationService>()) {
        _notificationService = Get.find<NotificationService>();
        _syncWithService();
      } else {
        print('[NotificationController] NotificationService not found, using fallback');
        // Initialize with default values since Firebase is temporarily disabled
        return;
      }
    } catch (e) {
      print('[NotificationController] Error accessing NotificationService: $e');
      return;
    }
    
    loadNotificationSettings();
    checkNotificationPermission();
  }
  
  /// Sync settings from NotificationService
  void _syncWithService() {
    // Bind to NotificationService observables
    ever(_notificationService.pushEnabled, (value) {
      pushNotificationsEnabled.value = value;
      notificationsEnabled.value = value;
    });
    ever(_notificationService.emailEnabled, (value) => emailNotificationsEnabled.value = value);
    ever(_notificationService.smsEnabled, (value) => smsNotificationsEnabled.value = value);
    ever(_notificationService.ordersEnabled, (value) => ordersNotificationsEnabled.value = value);
    ever(_notificationService.offersEnabled, (value) => offersNotificationsEnabled.value = value);
    ever(_notificationService.paymentsEnabled, (value) => paymentsNotificationsEnabled.value = value);
    ever(_notificationService.generalEnabled, (value) => generalNotificationsEnabled.value = value);
  }
  
  /// Load notification settings from cache and backend
  void loadNotificationSettings() {
    notificationsEnabled.value = CacheManager.isNotificationsEnabled();
    
    // Safely load from service if available
    if (Get.isRegistered<NotificationService>()) {
      try {
        pushNotificationsEnabled.value = _notificationService.pushEnabled.value;
        emailNotificationsEnabled.value = _notificationService.emailEnabled.value;
        smsNotificationsEnabled.value = _notificationService.smsEnabled.value;
        ordersNotificationsEnabled.value = _notificationService.ordersEnabled.value;
        offersNotificationsEnabled.value = _notificationService.offersEnabled.value;
        paymentsNotificationsEnabled.value = _notificationService.paymentsEnabled.value;
        generalNotificationsEnabled.value = _notificationService.generalEnabled.value;
      } catch (e) {
        print('[NotificationController] Error loading settings from service: $e');
        // Use default values
        pushNotificationsEnabled.value = true;
        emailNotificationsEnabled.value = true;
        smsNotificationsEnabled.value = false;
        ordersNotificationsEnabled.value = true;
        offersNotificationsEnabled.value = true;
        paymentsNotificationsEnabled.value = true;
        generalNotificationsEnabled.value = true;
      }
    } else {
      // Use default values when service is not available
      pushNotificationsEnabled.value = true;
      emailNotificationsEnabled.value = true;
      smsNotificationsEnabled.value = false;
      ordersNotificationsEnabled.value = true;
      offersNotificationsEnabled.value = true;
      paymentsNotificationsEnabled.value = true;
      generalNotificationsEnabled.value = true;
    }
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
  
  /// Toggle all notifications
  Future<void> toggleNotifications(bool value) async {
    if (value) {
      final granted = await requestNotificationPermission();
      if (granted) {
        notificationsEnabled.value = true;
        await CacheManager.setNotificationsEnabled(true);
        await _safeServiceCall((service) => service.togglePush(true));
      } else {
        notificationsEnabled.value = false;
      }
    } else {
      notificationsEnabled.value = false;
      await CacheManager.setNotificationsEnabled(false);
      await _safeServiceCall((service) => service.togglePush(false));
      
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
    isSavingSettings.value = true;
    try {
      if (value) {
        final status = await ph.Permission.notification.status;
        if (status != ph.PermissionStatus.granted) {
          final granted = await requestNotificationPermission();
          if (!granted) return;
        }
      }
      await _safeServiceCall((service) => service.togglePush(value));
      pushNotificationsEnabled.value = value;
      
      Get.snackbar(
        value ? 'Push Enabled' : 'Push Disabled',
        value ? 'You will now receive push notifications' : 'Push notifications turned off',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isSavingSettings.value = false;
    }
  }
  
  /// Toggle email notifications
  Future<void> toggleEmailNotifications(bool value) async {
    isSavingSettings.value = true;
    try {
      await _safeServiceCall((service) => service.toggleEmail(value));
      emailNotificationsEnabled.value = value;
      
      Get.snackbar(
        value ? 'Email Enabled' : 'Email Disabled',
        value ? 'You will now receive email notifications' : 'Email notifications turned off',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isSavingSettings.value = false;
    }
  }
  
  /// Toggle SMS notifications
  Future<void> toggleSmsNotifications(bool value) async {
    isSavingSettings.value = true;
    try {
      await _safeServiceCall((service) => service.toggleSms(value));
      smsNotificationsEnabled.value = value;
      
      Get.snackbar(
        value ? 'SMS Enabled' : 'SMS Disabled',
        value ? 'You will now receive SMS notifications' : 'SMS notifications turned off',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isSavingSettings.value = false;
    }
  }
  
  /// Toggle order notifications
  Future<void> toggleOrdersNotifications(bool value) async {
    isSavingSettings.value = true;
    try {
      await _safeServiceCall((service) => service.toggleOrders(value));
      ordersNotificationsEnabled.value = value;
    } finally {
      isSavingSettings.value = false;
    }
  }
  
  /// Toggle offer notifications
  Future<void> toggleOffersNotifications(bool value) async {
    isSavingSettings.value = true;
    try {
      await _safeServiceCall((service) => service.toggleOffers(value));
      offersNotificationsEnabled.value = value;
    } finally {
      isSavingSettings.value = false;
    }
  }
  
  /// Toggle payment notifications
  Future<void> togglePaymentsNotifications(bool value) async {
    isSavingSettings.value = true;
    try {
      await _safeServiceCall((service) => service.togglePayments(value));
      paymentsNotificationsEnabled.value = value;
    } finally {
      isSavingSettings.value = false;
    }
  }
  
  /// Toggle general notifications
  Future<void> toggleGeneralNotifications(bool value) async {
    isSavingSettings.value = true;
    try {
      await _safeServiceCall((service) => service.toggleGeneral(value));
      generalNotificationsEnabled.value = value;
    } finally {
      isSavingSettings.value = false;
    }
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

  /// Open device notification settings
  Future<void> openNotificationSettings() async {
    try {
      await ph.openAppSettings();
      // Re-check permission after user returns from settings
      await Future.delayed(const Duration(seconds: 1));
      await checkNotificationPermission();
    } catch (e) {
      print('[Notification] Error opening settings: $e');
      Get.snackbar(
        'Error', 
        'Could not open notification settings. Please open manually.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    }
  }
}

