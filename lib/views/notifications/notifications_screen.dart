import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/notification_service.dart';
import '../../utils/getx_registry.dart';
import '../../utils/app_colors.dart';
import '../../utils/screen_size.dart';
import '../../utils/notification_message_utils.dart';
import '../../utils/product_details_navigation.dart';
import '../../utils/silent_loading.dart';

/// Notification Model
class NotificationItem {
  final int id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'order', 'offer', 'general', 'payment'
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'general',
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawMessage = json['message']?.toString() ?? '';
    final meta = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : NotificationMessageUtils.parseMeta(rawMessage);

    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: NotificationMessageUtils.displayText(rawMessage),
      timestamp: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      type: NotificationMessageUtils.normalizeType(json['type']?.toString()),
      data: meta.isNotEmpty ? meta : null,
    );
  }
}

/// Notifications Screen
/// Displays a list of user notifications with real-time updates
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;

  NotificationService? get _notificationService => GetXRegistry.notificationServiceOrNull();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _notificationService?.fetchNotifications(page: 1, silent: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _notificationService != null && !_notificationService!.isLoading.value) {
        _loadMore();
      }
    }
  }

  Future<void> _loadMore() async {
    final service = _notificationService;
    if (service == null) return;
    _isLoadingMore = true;
    _currentPage++;
    await service.fetchNotifications(page: _currentPage);
    _isLoadingMore = false;
  }

  Future<void> _refresh() async {
    final service = _notificationService;
    if (service == null) return;
    _currentPage = 1;
    await service.fetchNotifications(page: 1, silent: true);
  }

  List<NotificationItem> _getAllNotifications() {
    final service = _notificationService;
    if (service == null) return [];
    return service.notifications.map((n) => NotificationItem.fromJson(n)).toList();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final service = _notificationService;
    if (service == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notifications', style: TextStyle(fontSize: ScreenSize.headingMedium)),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.textWhite),
            onPressed: () => Get.toNamed('/notification-settings'),
            tooltip: 'Notification Settings',
          ),
          Obx(() => service.notifications.isNotEmpty
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.textWhite),
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    _markAllAsRead();
                  } else if (value == 'clear_all') {
                    _clearAllNotifications();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear all'),
                      ],
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (SilentLoading.blockUi(
          isLoading: service.isLoading.value,
          hasContent: service.hasEverLoaded.value ||
              service.notifications.isNotEmpty,
        )) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = _getAllNotifications();

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(ScreenSize.spacingMedium),
            itemCount: notifications.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == notifications.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final notification = notifications[index];
              return _buildNotificationTile(notification);
            },
          ),
        );
      }),
    );
  }

  /// Build empty state when no notifications
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: ScreenSize.screenWidth * 0.2,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'You\'re all caught up!\nWe\'ll notify you when something new arrives.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/notification-settings'),
            icon: Icon(Icons.settings),
            label: Text('Notification Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: EdgeInsets.symmetric(
                horizontal: ScreenSize.spacingLarge,
                vertical: ScreenSize.spacingMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Build notification tile
  Widget _buildNotificationTile(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: ScreenSize.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        ),
        child: Icon(
          Icons.delete,
          color: AppColors.textWhite,
          size: 24,
        ),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: Container(
        margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.cardBackground : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          border: Border.all(
            color: notification.isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: ListTile(
        contentPadding: EdgeInsets.all(ScreenSize.spacingMedium),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationTypeColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getNotificationTypeIcon(notification.type),
            color: _getNotificationTypeColor(notification.type),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
      ),
    ),
  );
}

  /// Get notification type icon
  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'offer':
        return Icons.local_offer_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'system':
        return Icons.info_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Get notification type color
  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.success;
      case 'offer':
        return AppColors.warning;
      case 'payment':
        return AppColors.info;
      case 'system':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  /// Format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationItem notification) async {
    // Mark as read
    await _notificationService?.markAsRead(notification.id);

    // Navigate based on type
    switch (notification.type) {
      case 'order':
        final orderId = notification.data?['order_id'];
        if (orderId != null) {
          Get.toNamed('/order-details', arguments: {'orderId': orderId});
        } else {
          Get.toNamed('/orders');
        }
        break;
      case 'offer':
        final productId = notification.data?['product_id'];
        if (productId != null) {
          final id = productId is int
              ? productId
              : int.tryParse(productId.toString());
          if (id != null && id > 0) {
            ProductDetailsNavigation.go(id: id);
            break;
          }
        }
        Get.toNamed('/home');
        break;
      case 'payment':
        Get.toNamed('/orders');
        break;
      default:
        final productId = notification.data?['product_id'];
        if (productId != null) {
          final id = productId is int
              ? productId
              : int.tryParse(productId.toString());
          if (id != null && id > 0) {
            ProductDetailsNavigation.go(id: id);
            break;
          }
        }
        break;
    }
  }

  /// Delete notification
  Future<void> _deleteNotification(int notificationId) async {
    final success = await _notificationService?.deleteNotification(notificationId) ?? false;
    if (success) {
      Get.snackbar(
        'Deleted',
        'Notification removed',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
  }

  /// Mark all notifications as read
  Future<void> _markAllAsRead() async {
    final success = await _notificationService?.markAllAsRead() ?? false;
    if (success) {
      Get.snackbar(
        'Success',
        'All notifications marked as read',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.9),
        colorText: AppColors.textWhite,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Clear all notifications
  void _clearAllNotifications() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await _notificationService?.clearAll() ?? false;
              if (success) {
                Get.snackbar(
                  'Success',
                  'All notifications cleared',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success.withOpacity(0.9),
                  colorText: AppColors.textWhite,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
