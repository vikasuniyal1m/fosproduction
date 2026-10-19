import '../watch_face_product_ids.dart';
import '../watch_faces_config.dart';

/// Supported watch platforms.
enum WatchPlatform {
  ios,
  android;

  static WatchPlatform fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ios':
        return WatchPlatform.ios;
      case 'android':
        return WatchPlatform.android;
      default:
        throw FormatException('Unknown watch platform: $value');
    }
  }

  String get label =>
      this == WatchPlatform.ios ? 'Apple Watch' : 'Galaxy / Wear OS';
}

/// Immutable model describing a single distributable watch face.
class WatchFace {
  const WatchFace({
    required this.id,
    required this.title,
    required this.description,
    required this.platform,
    required this.previewImage,
    this.localFilePath,
    this.downloadUrl,
    this.androidPlayStoreUrl,
    this.galaxyStoreUrl,
    this.packageName,
    this.compatibility,
    this.isPremium = true,
    this.isPublished = true,
    this.productId,
    this.price,
  });

  final String id;
  final String title;
  final String description;
  final WatchPlatform platform;
  final String previewImage;
  final String? localFilePath;

  /// Remote .watchface on CDN (used when not bundled in the app).
  final String? downloadUrl;
  final String? androidPlayStoreUrl;
  final String? galaxyStoreUrl;
  final String? packageName;
  final String? compatibility;
  final bool isPremium;
  final bool isPublished;

  /// Backend digital product id — purchase checked via orders/has_purchased.php
  final int? productId;

  /// Display / Stripe quick-pay amount (USD or your store currency).
  final double? price;

  bool get isApple => platform == WatchPlatform.ios;

  /// All fruit faces are paid unless productId is explicitly null and isPremium false.
  bool get requiresPurchase => isPremium;
  bool get isAndroid => platform == WatchPlatform.android;

  bool get hasPlaceholderPackage =>
      packageName != null && packageName!.startsWith('com.example.');

  bool get hasWatchFaceSource =>
      downloadUrl != null && downloadUrl!.isNotEmpty;

  bool get isInstallable {
    if (hasWatchFaceSource) return true;
    if (isApple) return false;
    final hasStoreTarget = (packageName != null && packageName!.isNotEmpty) ||
        androidPlayStoreUrl != null ||
        galaxyStoreUrl != null;
    final allowPlaceholder = WatchFacesConfig.bypassPurchaseForTesting;
    return isPublished &&
        hasStoreTarget &&
        (allowPlaceholder || !hasPlaceholderPackage);
  }

  factory WatchFace.fromJson(Map<String, dynamic> json) {
    return WatchFace(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      platform: WatchPlatform.fromString(json['platform'] as String),
      previewImage: json['previewImage'] as String,
      localFilePath: json['localFilePath'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      androidPlayStoreUrl: json['androidPlayStoreUrl'] as String?,
      galaxyStoreUrl: json['galaxyStoreUrl'] as String?,
      packageName: json['packageName'] as String?,
      compatibility: json['compatibility'] as String?,
      isPremium: json['isPremium'] as bool? ?? true,
      isPublished: json['isPublished'] as bool? ?? true,
      productId: WatchFaceProductIds.resolve(
        json['id'] as String,
        _parseProductId(json['productId']),
      ),
      price: _parsePrice(json['price']),
    );
  }

  static int? _parseProductId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
