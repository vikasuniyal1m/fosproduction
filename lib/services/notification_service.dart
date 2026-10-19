import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/profile_controller.dart';
import '../utils/app_colors.dart';
import '../utils/cache_manager.dart';
import '../utils/data_cache.dart';
import '../utils/notification_message_utils.dart';
import '../utils/product_details_navigation.dart';
import '../widgets/in_app_notification_banner.dart';
import 'api_service.dart';
import 'api_endpoints.dart';

/*
/// Background message handler for Firebase
/// Must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // TODO: Re-enable after fixing Firebase configuration issue
  print('[FCM] Firebase background handler temporarily disabled');
  // await Firebase.initializeApp();
  print('[FCM] Background message received: ${message.messageId}');
  print('[FCM] Title: ${message.notification?.title}');
  print('[FCM] Body: ${message.notification?.body}');
  print('[FCM] Data: ${message.data}');
}
*/

/// Notification Service
/// Handles all notification functionality including:
/// - Firebase Cloud Messaging (Push Notifications)
/// - Local notifications
/// - Real-time notification polling
/// - Device token registration
class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  // Firebase Messaging instance
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // API Service
  final ApiService _apiService = ApiService();
  
  // Real-time polling timer
  Timer? _pollingTimer;
  bool _isAppInForeground = true;
  bool _baselineEstablished = false;
  final Set<int> _seenNotificationIds = <int>{};
  static const String _seenIdsCacheKey = 'notification_seen_ids';
  
  // Observable notification count
  final RxInt unreadCount = 0.obs;
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasEverLoaded = false.obs;
  
  // Notification types filter
  final RxString selectedFilter = 'all'.obs;
  
  // Notification settings
  final RxBool pushEnabled = true.obs;
  final RxBool emailEnabled = true.obs;
  final RxBool smsEnabled = false.obs;
  final RxBool ordersEnabled = true.obs;
  final RxBool offersEnabled = true.obs;
  final RxBool paymentsEnabled = true.obs;
  final RxBool generalEnabled = true.obs;

  /// Initialize notification service
  Future<NotificationService> init() async {
    print('[NotificationService] Initializing...');
    
    // Initialize Firebase
    await _initializeFirebase();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    await _requestDeviceNotificationPermission();
    _loadSeenNotificationIds();
    
    // Setup Firebase messaging
    // TODO: Re-enable after fixing Firebase configuration issue
    print('[NotificationService] Firebase messaging setup temporarily disabled');
    // await _setupFirebaseMessaging();
    
    // Load notification settings from cache
    await _loadSettings();
    _loadCachedNotifications();
    
    // Register device token with backend
    // TODO: Re-enable after fixing Firebase configuration issue
    print('[NotificationService] Device token registration temporarily disabled');
    // await _registerDeviceToken();
    
    // Start real-time polling
    startRealTimeUpdates();
    
    print('[NotificationService] Initialization complete');
    return this;
  }

  /// Initialize Firebase
  Future<void> _initializeFirebase() async {
    // TODO: Re-enable after fixing Firebase configuration issue
    print('[NotificationService] Firebase initialization temporarily disabled');
    // try {
    //   await Firebase.initializeApp();
    //   print('[NotificationService] Firebase initialized');
    // } catch (e) {
    //   print('[NotificationService] Firebase already initialized or error: $e');
    // }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );
    
    // Create notification channels for Android
    await _createNotificationChannels();
    
    print('[NotificationService] Local notifications initialized');
  }
  
  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;
    
    // Download progress channel
    final downloadChannel = AndroidNotificationChannel(
      'download_channel',
      'Downloads',
      description: 'Shows download progress for digital products',
      importance: Importance.low,
      showBadge: true,
      enableLights: false,
      enableVibration: false,
    );
    
    // High importance channel for general notifications
    final highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      showBadge: true,
      enableLights: true,
      enableVibration: true,
    );
    
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'default_channel',
      'Default Notifications',
      description: 'Default notification channel for general notifications.',
      importance: Importance.defaultImportance,
      showBadge: true,
      enableLights: false,
      enableVibration: true,
    );
    
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(downloadChannel);
        await androidPlugin.createNotificationChannel(highImportanceChannel);
        await androidPlugin.createNotificationChannel(defaultChannel);
        print('[NotificationService] Android notification channels created');
      }
    } catch (e) {
      print('[NotificationService] Error creating notification channels: $e');
    }
  }

  /*  
  /// Setup Firebase Cloud Messaging
  Future<void> _setupFirebaseMessaging() async {
    // Request permission
    await _requestPermission();
    
    // Set foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Listen to message opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Get initial message (app was terminated)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
    
    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
    
    print('[NotificationService] Firebase messaging setup complete');
  }
  */

  /*
  /// Request notification permissions
  Future<bool> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    print('[NotificationService] Notification permission: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
  */

  /*
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('[FCM] Foreground message received');
    print('[FCM] Title: ${message.notification?.title}');
    print('[FCM] Body: ${message.notification?.body}');
    print('[FCM] Data: ${message.data}');
    
    // Show local notification
    _showLocalNotification(message);
    
    // Refresh notifications list
    fetchNotifications();
    
    // Update unread count
    _updateUnreadCount();
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('[FCM] Message opened app: ${message.data}');
    _handleNotificationData(message.data);
  }

  /// Handle initial message when app was terminated
  void _handleInitialMessage(RemoteMessage message) {
    print('[FCM] Initial message: ${message.data}');
    // Delay to allow app to fully initialize
    Future.delayed(const Duration(seconds: 2), () {
      _handleNotificationData(message.data);
    });
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    print('[FCM] Token refreshed: $token');
    await _registerDeviceToken(token: token);
  }
  */

  /*
  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        contentTitle: notification.title,
        summaryText: 'New notification',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }
  */

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationData(data);
    }
  }

  void _openNotificationTarget(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'general';
    final data = item['data'] is Map
        ? Map<String, dynamic>.from(item['data'] as Map)
        : <String, dynamic>{};
    final rawMessage = item['message']?.toString();
    final productId = data['product_id'] ??
        NotificationMessageUtils.parseProductId(rawMessage);
    final orderId =
        data['order_id'] ?? NotificationMessageUtils.parseOrderId(rawMessage);

    _handleNotificationData({
      'type': type,
      if (productId != null) 'product_id': productId,
      if (orderId != null) 'order_id': orderId,
    });
  }

  /// Handle notification data and navigate accordingly
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'general';
    final productId = data['product_id'];
    final orderId = data['order_id'];

    if (productId != null) {
      final id =
          productId is int ? productId : int.tryParse(productId.toString());
      if (id != null && id > 0) {
        ProductDetailsNavigation.go(id: id);
        return;
      }
    }

    switch (type) {
      case 'order_confirmation':
      case 'order_status_update':
      case 'orders':
      case 'order':
        if (orderId != null) {
          final id =
              orderId is int ? orderId : int.tryParse(orderId.toString());
          if (id != null && id > 0) {
            Get.toNamed('/order-details', arguments: {'orderId': id});
            return;
          }
        }
        Get.toNamed('/orders');
        break;
      case 'offers':
      case 'offer':
      case 'promotional':
        Get.toNamed('/home');
        break;
      case 'payments':
      case 'payment':
        Get.toNamed('/orders');
        break;
      case 'download_complete':
        _openDownloadedFile(data);
        break;
      default:
        Get.toNamed('/notifications');
    }
  }

  /// Open a downloaded file from notification
  Future<void> _openDownloadedFile(Map<String, dynamic> data) async {
    try {
      final filePath = data['file_path'] as String?;
      final fileName = data['file_name'] as String? ?? 'Downloaded File';
      final mimeType = data['mime_type'] as String?;
      final productType = data['product_type'] as String?;
      
      print('[NotificationTap] ========== NOTIFICATION TAP ==========');
      print('[NotificationTap] filePath: $filePath');
      print('[NotificationTap] fileName: $fileName');
      print('[NotificationTap] mimeType: $mimeType');
      print('[NotificationTap] productType: $productType');
      print('[NotificationTap] full data: $data');
      
      if (filePath == null || filePath.isEmpty) {
        // Get.snackbar('Error', 'File path not found');
        return;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        // Get.snackbar('Error', 'File not found: $fileName');
        return;
      }

      // Determine file type
      final nameLower = fileName.toLowerCase();
      final typeLower = productType?.toLowerCase() ?? '';
      final isAudio = typeLower == 'audio' ||
          mimeType?.startsWith('audio/') == true ||
          nameLower.endsWith('.mp3') ||
          nameLower.endsWith('.wav') ||
          nameLower.endsWith('.m4a');
      final isVideo = typeLower == 'video' ||
          mimeType?.startsWith('video/') == true ||
          nameLower.endsWith('.mp4') ||
          nameLower.endsWith('.mov') ||
          nameLower.endsWith('.webm');
      final isSticker = !isAudio &&
          !isVideo &&
          (typeLower == 'sticker' ||
              typeLower == 'sticker_pack' ||
              nameLower.endsWith('.zip'));
      
      print('[NotificationTap] isAudio: $isAudio, isVideo: $isVideo, isSticker: $isSticker');

      if (isAudio || isVideo) {
        print('[NotificationTap] Opening as Audio/Video');
        // For audio/video: Try to open with system app, fall back to share dialog
        try {
          final result = await OpenFile.open(filePath, type: mimeType);
          if (result.type == ResultType.noAppToOpen) {
            // Get.snackbar('No App Found', 'No app found to open this file. Please install a media player.');
          } else if (result.type != ResultType.done) {
            // Get.snackbar('Error', 'Could not open file: ${result.message}');
          }
        } on MissingPluginException catch (e) {
          print('[NotificationService] OpenFile plugin not available: $e');
          // Fall back to share dialog
          _showShareDialog(filePath, fileName);
        } catch (e) {
          print('[NotificationService] Error opening file: $e');
          _showShareDialog(filePath, fileName);
        }
      } else if (isSticker) {
        print('[NotificationTap] Opening as Sticker - showing WhatsApp dialog');
        // For stickers: Show WhatsApp sticker dialog with Add to WhatsApp option
        _showStickerWhatsAppDialog(filePath, fileName);
      } else {
        print('[NotificationTap] Unknown type - showing share dialog');
        // Unknown type: Show share dialog
        _showShareDialog(filePath, fileName);
      }
    } catch (e) {
      print('[NotificationService] Error opening downloaded file: $e');
      // Get.snackbar('Error', 'Could not open file: $e');
    }
  }

  /// Show share dialog for file
  void _showShareDialog(String filePath, String fileName) {
    Get.dialog(
      AlertDialog(
        title: const Text('Download Complete'),
        content: Text('What would you like to do with $fileName?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              // Share the file
              try {
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text: 'Downloaded: $fileName',
                );
              } catch (e) {
                Get.snackbar('Error', 'Could not share file: $e');
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  /// Show WhatsApp sticker dialog for sticker downloads
  void _showStickerWhatsAppDialog(String filePath, String fileName) {
    // Delay slightly to ensure we're not in the middle of any navigation
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.dialog(
        AlertDialog(
          title: const Text('🎨 Sticker Pack Ready'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sticky_note_2, size: 64, color: Color(0xFF25D366)),
              const SizedBox(height: 16),
              Text(
                'Your sticker pack is ready!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add these stickers to WhatsApp to use them in your chats.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Get.back();
                // Trigger the actual WhatsApp sticker extraction and add flow
                final profileController = Get.put(ProfileController());
                await profileController.unzipAndSaveStickersToGallery(filePath, fileName.replaceAll('.zip', ''));
              },
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text('Add to WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp green
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    });
  }

  /*
  /// Register device token with backend
  Future<void> _registerDeviceToken({String? token}) async {
    try {
      final fcmToken = token ?? await _firebaseMessaging.getToken();
      if (fcmToken == null) {
        print('[NotificationService] Failed to get FCM token');
        return;
      }

      print('[NotificationService] Registering FCM token: ${fcmToken.substring(0, 20)}...');

      // Get device info
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceType = Platform.isIOS ? 'ios' : 'android';

      final response = await _apiService.post(
        ApiEndpoints.notificationRegisterToken,
        data: {
          'device_token': fcmToken,
          'device_type': deviceType,
          'device_id': null,
          'app_version': packageInfo.version,
        },
      );

      final result = ApiService.handleResponse(response);
      print('[NotificationService] Token registered: $result');
    } catch (e) {
      print('[NotificationService] Failed to register token: $e');
    }
  }
  */

  /// Load notification settings from cache and backend
  Future<void> _loadSettings() async {
    // Load from cache
    pushEnabled.value = CacheManager.isNotificationsEnabled();
    
    // Load from backend
    try {
      final response = await _apiService.get(ApiEndpoints.notificationsList);
      final result = ApiService.handleResponse(response);
      
      if (result['settings'] != null) {
        final settings = result['settings'];
        pushEnabled.value = settings['push_enabled'] ?? true;
        emailEnabled.value = settings['email_enabled'] ?? true;
        smsEnabled.value = settings['sms_enabled'] ?? false;
        ordersEnabled.value = settings['orders_enabled'] ?? true;
        offersEnabled.value = settings['offers_enabled'] ?? true;
        paymentsEnabled.value = settings['payments_enabled'] ?? true;
        generalEnabled.value = settings['general_enabled'] ?? true;
      }
    } catch (e) {
      print('[NotificationService] Failed to load settings: $e');
    }
  }

  /// Save notification settings to backend
  Future<bool> saveSettings() async {
    try {
      // Save to cache
      await CacheManager.setNotificationsEnabled(pushEnabled.value);

      // Save to backend
      final response = await _apiService.post(
        ApiEndpoints.notificationSettings,
        data: {
          'push_enabled': pushEnabled.value,
          'email_enabled': emailEnabled.value,
          'sms_enabled': smsEnabled.value,
          'orders_enabled': ordersEnabled.value,
          'offers_enabled': offersEnabled.value,
          'payments_enabled': paymentsEnabled.value,
          'general_enabled': generalEnabled.value,
        },
      );

      final result = ApiService.handleResponse(response);
      print('[NotificationService] Settings saved: $result');
      return true;
    } catch (e) {
      print('[NotificationService] Failed to save settings: $e');
      return false;
    }
  }

  /// Foreground vs background — adjusts poll speed and alert style.
  void setAppForeground(bool foreground) {
    _isAppInForeground = foreground;
    if (CacheManager.isLoggedIn()) {
      startRealTimeUpdates();
    }
  }

  Future<void> _requestDeviceNotificationPermission() async {
    if (kIsWeb) return;
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (e) {
      print('[NotificationService] Permission request skipped: $e');
    }
  }

  void _loadSeenNotificationIds() {
    final raw = CacheManager.getData<List>(_seenIdsCacheKey);
    if (raw == null) return;
    for (final id in raw) {
      final parsed = int.tryParse(id.toString());
      if (parsed != null) _seenNotificationIds.add(parsed);
    }
  }

  Future<void> _persistSeenNotificationIds() async {
    await CacheManager.saveData(
      _seenIdsCacheKey,
      _seenNotificationIds.toList(),
    );
  }

  Duration get _pollInterval => _isAppInForeground
      ? const Duration(seconds: 8)
      : const Duration(seconds: 30);

  /// Force an immediate check (no waiting for the next timer tick).
  Future<void> pollNow() => _pollAndDetectNew();

  /// Start real-time notification updates (polling — no Firebase).
  void startRealTimeUpdates({Duration? interval}) {
    if (!CacheManager.isLoggedIn()) {
      print('[NotificationService] User not logged in, skipping real-time updates');
      return;
    }

    final pollEvery = interval ?? _pollInterval;
    print('[NotificationService] Starting polling every ${pollEvery.inSeconds}s');

    stopRealTimeUpdates();
    _pollOnce();
    _pollingTimer = Timer.periodic(pollEvery, (timer) {
      if (!CacheManager.isLoggedIn()) {
        timer.cancel();
        _pollingTimer = null;
        return;
      }
      _pollOnce();
    });
  }

  Future<void> _pollOnce() async {
    if (!CacheManager.isLoggedIn()) return;
    await _pollAndDetectNew();
  }

  Future<void> _pollAndDetectNew() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.notificationsList,
        queryParameters: {'page': 1, 'limit': 25},
      );
      final result = ApiService.handleResponse(response);
      final list = (result['notifications'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final countRaw = result['unread_count'] ?? 0;
      final unread = countRaw is int
          ? countRaw
          : int.tryParse(countRaw.toString()) ?? 0;

      unreadCount.value = unread;
      notifications.value = list;
      if (list.isNotEmpty) {
        hasEverLoaded.value = true;
        await DataCache.saveList(DataCache.notifications, list);
      }

      final newcomers = <Map<String, dynamic>>[];
      for (final item in list) {
        final id = item['id'] is int
            ? item['id'] as int
            : int.tryParse(item['id']?.toString() ?? '');
        if (id == null) continue;

        final isRead =
            item['is_read'] == true || item['is_read'] == 1;
        final isNewUnread = !isRead && !_seenNotificationIds.contains(id);

        if (isNewUnread && _baselineEstablished) {
          newcomers.add(item);
        }
        _seenNotificationIds.add(id);
      }

      if (!_baselineEstablished) {
        _baselineEstablished = true;
      }

      if (newcomers.isNotEmpty) {
        await _persistSeenNotificationIds();
        for (final item in newcomers) {
          await _presentNewNotification(item);
        }
      }
    } catch (e) {
      print('[NotificationService] Poll failed: $e');
    }
  }

  Future<void> _presentNewNotification(Map<String, dynamic> item) async {
    final title = item['title']?.toString() ?? 'FOS Productions';
    final message = NotificationMessageUtils.displayText(
      item['message']?.toString(),
    );
    final type = item['type']?.toString() ?? 'general';
    final id = item['id'];
    final data = item['data'] is Map
        ? Map<String, dynamic>.from(item['data'] as Map)
        : <String, dynamic>{};
    final payload = jsonEncode({
      'type': type,
      'notification_id': id,
      ...data,
    });

    if (_isAppInForeground) {
      InAppNotificationBanner.show(
        title: title,
        message: message,
        icon: _iconForType(type),
        onTap: () => _openNotificationTarget(item),
      );
    } else {
      await _showPollingLocalNotification(
        id is int ? id : id.hashCode,
        title,
        message,
        payload,
      );
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'orders':
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'offers':
      case 'offer':
      case 'promotional':
        return Icons.new_releases_outlined;
      case 'payments':
      case 'payment':
        return Icons.payment_outlined;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Future<void> _showPollingLocalNotification(
    int id,
    String title,
    String body,
    String payload,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Order updates and alerts from FOS Productions.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'FOS Productions',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Stop real-time updates
  void stopRealTimeUpdates() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
      print('[NotificationService] Stopped real-time updates');
    }
  }

  void _loadCachedNotifications() {
    final cached = DataCache.loadList(DataCache.notifications);
    if (cached != null && cached.isNotEmpty) {
      notifications.value = cached;
      hasEverLoaded.value = true;
    }
  }

  /// Fetch notifications from backend
  Future<void> fetchNotifications({
    int page = 1,
    int limit = 20,
    bool silent = false,
  }) async {
    if (isLoading.value) return;

    final hasCache = page == 1 && notifications.isNotEmpty;
    if (!silent && !hasCache) {
      isLoading.value = true;
    }

    try {
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (selectedFilter.value != 'all') {
        queryParams['type'] = selectedFilter.value;
      }

      final response = await _apiService.get(
        ApiEndpoints.notificationsList,
        queryParameters: queryParams,
      );

      final result = ApiService.handleResponse(response);
      final List<dynamic> notificationList = result['notifications'] ?? [];
      
      if (page == 1) {
        notifications.value = notificationList.cast<Map<String, dynamic>>();
      } else {
        notifications.addAll(notificationList.cast<Map<String, dynamic>>());
      }
      if (notifications.isNotEmpty) {
        hasEverLoaded.value = true;
        await DataCache.saveList(DataCache.notifications, notifications.toList());
      }

      print('[NotificationService] Fetched ${notificationList.length} notifications');
    } catch (e) {
      print('[NotificationService] Failed to fetch notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Public method to refresh unread count
  Future<void> refreshUnreadCount() async {
    await _updateUnreadCount();
  }

  /// Update unread count with retry logic and better error handling
  Future<void> _updateUnreadCount({int retryCount = 0}) async {
    const maxRetries = 2;
    const retryDelay = Duration(seconds: 2);
    
    try {
      print('[NotificationService] Updating unread count...');
      
      // Add timeout to prevent hanging requests
      final response = await _apiService.get(
        ApiEndpoints.notificationUnreadCount,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', const Duration(seconds: 10));
        },
      );
      
      final result = ApiService.handleResponse(response);
      final count = result['unread_count'] ?? 0;
      
      print('[NotificationService] Unread count updated: $count');
      unreadCount.value = count;
      
      // Update iOS badge - Note: Badge update handled by Firebase Messaging
      // iOS badge will be updated automatically when notifications are received
      print('[NotificationService] Badge count: $count');
      
    } on SocketException catch (e) {
      print('[NotificationService] Network error: $e');
      
      // Retry logic for network issues
      if (retryCount < maxRetries) {
        print('[NotificationService] Retrying unread count update (${retryCount + 1}/$maxRetries)');
        await Future.delayed(retryDelay);
        return _updateUnreadCount(retryCount: retryCount + 1);
      } else {
        print('[NotificationService] Max retries reached for unread count');
      }
      
    } on TimeoutException catch (e) {
      print('[NotificationService] Timeout error: $e');
      
      // Retry logic for timeout
      if (retryCount < maxRetries) {
        print('[NotificationService] Retrying unread count update after timeout (${retryCount + 1}/$maxRetries)');
        await Future.delayed(retryDelay);
        return _updateUnreadCount(retryCount: retryCount + 1);
      } else {
        print('[NotificationService] Max retries reached for unread count due to timeout');
      }
      
    } on DioException catch (e) {
      print('[NotificationService] DioException: ${e.type} - ${e.message}');
      
      // Don't retry for client errors (4xx)
      if (e.type == DioExceptionType.badResponse && 
          e.response?.statusCode != null && 
          e.response!.statusCode! >= 400 && 
          e.response!.statusCode! < 500) {
        print('[NotificationService] Client error, not retrying');
      } else if (retryCount < maxRetries) {
        print('[NotificationService] Retrying unread count update (${retryCount + 1}/$maxRetries)');
        await Future.delayed(retryDelay);
        return _updateUnreadCount(retryCount: retryCount + 1);
      } else {
        print('[NotificationService] Max retries reached for unread count');
      }
      
    } catch (e) {
      print('[NotificationService] Unexpected error updating unread count: $e');
      print('[NotificationService] Error type: ${e.runtimeType}');
      
      // For unknown errors, try once more
      if (retryCount < maxRetries) {
        print('[NotificationService] Retrying unread count update (${retryCount + 1}/$maxRetries)');
        await Future.delayed(retryDelay);
        return _updateUnreadCount(retryCount: retryCount + 1);
      }
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.notificationMarkRead,
        data: {'notification_id': notificationId},
      );

      final result = ApiService.handleResponse(response);
      
      // Update local list
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['is_read'] = true;
        notifications.refresh();
      }
      
      // Update unread count
      _updateUnreadCount();
      
      return true;
    } catch (e) {
      print('[NotificationService] Failed to mark as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.post(ApiEndpoints.notificationReadAll);
      final result = ApiService.handleResponse(response);
      
      // Update local list
      for (var notification in notifications) {
        notification['is_read'] = true;
      }
      notifications.refresh();
      
      // Update unread count
      unreadCount.value = 0;
      
      return true;
    } catch (e) {
      print('[NotificationService] Failed to mark all as read: $e');
      return false;
    }
  }

  /// Clear all notifications
  Future<bool> clearAll() async {
    try {
      final response = await _apiService.delete(ApiEndpoints.notificationsList);
      final result = ApiService.handleResponse(response);
      
      notifications.clear();
      unreadCount.value = 0;
      
      return true;
    } catch (e) {
      print('[NotificationService] Failed to clear notifications: $e');
      return false;
    }
  }

  /// Set notification filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
    fetchNotifications(page: 1);
  }

  /// Toggle push notifications
  Future<void> togglePush(bool value) async {
    pushEnabled.value = value;
    await saveSettings();
    
    // TODO: Re-enable after fixing Firebase configuration issue
    print('[NotificationService] Firebase topic subscription temporarily disabled');
    /*
    if (value) {
      await _firebaseMessaging.subscribeToTopic('all_users');
    } else {
      await _firebaseMessaging.unsubscribeFromTopic('all_users');
    }
    */
  }

  /// Toggle email notifications
  Future<void> toggleEmail(bool value) async {
    emailEnabled.value = value;
    await saveSettings();
  }

  /// Toggle SMS notifications
  Future<void> toggleSms(bool value) async {
    smsEnabled.value = value;
    await saveSettings();
  }

  /// Toggle order notifications
  Future<void> toggleOrders(bool value) async {
    ordersEnabled.value = value;
    await saveSettings();
  }

  /// Toggle offer notifications
  Future<void> toggleOffers(bool value) async {
    offersEnabled.value = value;
    await saveSettings();
  }

  /// Toggle payment notifications
  Future<void> togglePayments(bool value) async {
    paymentsEnabled.value = value;
    await saveSettings();
  }

  /// Toggle general notifications
  Future<void> toggleGeneral(bool value) async {
    generalEnabled.value = value;
    await saveSettings();
  }

  /// Get filtered notifications
  List<Map<String, dynamic>> get filteredNotifications {
    if (selectedFilter.value == 'all') {
      return notifications;
    }
    return notifications.where((n) => n['type'] == selectedFilter.value).toList();
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.notificationsList}/$notificationId',
      );

      final result = ApiService.handleResponse(response);
      
      // Remove from local list
      notifications.removeWhere((n) => n['id'] == notificationId);
      
      // Update unread count
      _updateUnreadCount();
      
      return true;
    } catch (e) {
      print('[NotificationService] Failed to delete notification: $e');
      return false;
    }
  }

  // ============================================================================
  // DOWNLOAD NOTIFICATIONS
  // ============================================================================
  
  /// Show download progress notification
  Future<void> showDownloadProgressNotification({
    required int downloadId,
    required String fileName,
    required int progress,
    required int total,
  }) async {
    final percentage = total > 0 ? (progress / total * 100).round() : 0;
    
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Shows download progress for digital products',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: true,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: total,
      progress: progress,
      indeterminate: progress == 0,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      color: Colors.black,
      colorized: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      downloadId,
      'Downloading $fileName',
      '$percentage% • $progress / $total KB',
      notificationDetails,
      payload: jsonEncode({'type': 'download_progress', 'id': downloadId}),
    );
  }

  /// Show download completed notification
  Future<void> showDownloadCompleteNotification({
    required int downloadId,
    required String fileName,
    required String filePath,
    String? mimeType,
    String? productType, // audio, video, sticker
  }) async {
    // Determine notification title and message based on product type
    String title;
    String message;
    
    switch (productType?.toLowerCase()) {
      case 'audio':
        title = '🎵 Audio Download Complete';
        message = 'Tap to open in your music app';
        break;
      case 'video':
        title = '🎬 Video Download Complete';
        message = 'Your video "$fileName" is ready to watch';
        break;
      case 'sticker':
        title = '🎨 Sticker Pack Ready';
        message = 'Your stickers "$fileName" are ready to use';
        break;
      default:
        // Fall back to mime type detection
        if (mimeType?.startsWith('audio/') == true) {
          title = '🎵 Audio Download Complete';
          message = 'Your audio "$fileName" is ready to play';
        } else if (mimeType?.startsWith('video/') == true) {
          title = '🎬 Video Download Complete';
          message = 'Your video "$fileName" is ready to watch';
        } else if (fileName.toLowerCase().endsWith('.zip') || fileName.toLowerCase().contains('sticker')) {
          title = '🎨 Sticker Pack Ready';
          message = 'Your stickers "$fileName" are ready to use';
        } else {
          title = 'Download Complete';
          message = fileName;
        }
    }
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Shows completed downloads',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      ongoing: false,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          'open',
          'Open',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'share',
          'Share',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      categoryIdentifier: 'download_complete',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      downloadId,
      title,
      message,
      notificationDetails,
      payload: jsonEncode({
        'type': 'download_complete',
        'file_path': filePath,
        'file_name': fileName,
        'mime_type': mimeType,
        'product_type': productType,
      }),
    );
  }

  /// Show download error notification
  Future<void> showDownloadErrorNotification({
    required int downloadId,
    required String fileName,
    required String error,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Shows download errors',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      downloadId,
      'Download Failed',
      'Could not download $fileName: $error',
      notificationDetails,
      payload: jsonEncode({'type': 'download_error', 'id': downloadId}),
    );
  }

  /// Cancel download notification
  Future<void> cancelDownloadNotification(int downloadId) async {
    await _localNotifications.cancel(downloadId);
  }

  @override
  void onClose() {
    print('[NotificationService] Closing service and cleaning up resources');
    
    // Clean up resources
    stopRealTimeUpdates();
    
    // Clear observables
    unreadCount.close();
    notifications.close();
    isLoading.close();
    selectedFilter.close();
    pushEnabled.close();
    emailEnabled.close();
    smsEnabled.close();
    ordersEnabled.close();
    offersEnabled.close();
    paymentsEnabled.close();
    generalEnabled.close();
    
    super.onClose();
  }
}
