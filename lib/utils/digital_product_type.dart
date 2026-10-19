import '../watch_faces/watch_face_product_ids.dart';
import '../watch_faces/watch_face_order_helper.dart';

/// Detects digital product kind: sticker, audio, video, watch face, or other.
class DigitalProductType {
  static const int categoryVideo = 13;
  static const int categoryAudio = 12;
  static const int categorySticker = 15;

  static int? _categoryId(Map<String, dynamic>? product) {
    if (product == null) return null;
    final raw = product['category_id'] ??
        (product['category'] is Map ? product['category']['id'] : null);
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  static bool isWatchFaceProduct(Map<String, dynamic>? product) {
    if (product == null) return false;
    final raw = product['product_id'] ?? product['id'];
    final id = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    return WatchFaceProductIds.isWatchFaceProduct(id);
  }

  static bool isDigitalProduct(Map<String, dynamic>? product) {
    if (product == null) return false;
    if (isWatchFaceProduct(product)) return true;
    if (product['is_digital'] == true || product['is_digital'] == 1) {
      return true;
    }
    if (product['is_sticker_pack'] == true || product['is_sticker_pack'] == 1) {
      return true;
    }
    final catId = _categoryId(product);
    if (catId == categoryAudio ||
        catId == categoryVideo ||
        catId == categorySticker) {
      return true;
    }
    final media = resolveMediaType(product);
    if (media == 'audio' || media == 'video' || media == 'sticker') {
      return true;
    }
    final productType =
        product['product_type']?.toString().toLowerCase() ?? '';
    if (productType == 'audio' ||
        productType == 'video' ||
        productType == 'sticker' ||
        productType == 'sticker_pack') {
      return true;
    }
    final path = _digitalPath(product);
    if (path.isNotEmpty && (_isAudioPath(path) || _isVideoPath(path))) {
      return true;
    }
    return false;
  }

  static String resolveMediaType(Map<String, dynamic>? product) {
    if (product == null) return 'none';

    final mediaType = product['media_type']?.toString().toLowerCase() ?? '';
    final path = _digitalPath(product);
    final catId = _categoryId(product);

    if (mediaType == 'audio' ||
        catId == categoryAudio ||
        _isAudioPath(path)) {
      return 'audio';
    }
    if (mediaType == 'video' ||
        catId == categoryVideo ||
        _isVideoPath(path)) {
      return 'video';
    }
    if (mediaType == 'sticker' || mediaType == 'sticker_pack') {
      return 'sticker';
    }

    final productType = product['product_type']?.toString().toLowerCase() ?? '';
    if (productType == 'audio') return 'audio';
    if (productType == 'video') return 'video';
    if (productType == 'sticker_pack' || productType == 'sticker') {
      return 'sticker';
    }

    return mediaType.isEmpty ? 'none' : mediaType;
  }

  /// WhatsApp export only for sticker packs — never audio/video.
  static bool isStickerPack(Map<String, dynamic>? product) {
    if (product == null) return false;

    final kind = resolveMediaType(product);
    if (kind == 'audio' || kind == 'video') return false;

    if (product['is_sticker_pack'] == true || product['is_sticker_pack'] == 1) {
      return true;
    }
    if (_categoryId(product) == categorySticker) return true;

    final productType = product['product_type']?.toString().toLowerCase() ?? '';
    return productType == 'sticker_pack' || productType == 'sticker';
  }

  static bool isAudio(Map<String, dynamic>? product) =>
      resolveMediaType(product) == 'audio';

  static bool isVideo(Map<String, dynamic>? product) =>
      resolveMediaType(product) == 'video';

  /// Digital products (sticker / audio / video / any is_digital) — no cart.
  static bool isDigitalNoCart(Map<String, dynamic>? product) {
    if (product == null) return false;
    if (isDigitalProduct(product)) return true;
    return isStickerPack(product) || isAudio(product) || isVideo(product);
  }

  static String _digitalPath(Map<String, dynamic> product) {
    final raw = product['digital_file_path'];
    if (raw == null) return '';
    if (raw is List && raw.isNotEmpty) {
      return raw.first.toString().toLowerCase();
    }
    final str = raw.toString().toLowerCase();
    if (str.startsWith('[')) {
      try {
        final decoded = raw;
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first.toString().toLowerCase();
        }
      } catch (_) {}
    }
    return str;
  }

  static bool _isAudioPath(String path) {
    return path.contains('.mp3') ||
        path.contains('.wav') ||
        path.contains('.m4a') ||
        path.contains('.aac');
  }

  static bool _isVideoPath(String path) {
    return path.contains('.mp4') ||
        path.contains('.mov') ||
        path.contains('.webm') ||
        path.contains('.m4v') ||
        path.contains('.avi');
  }

  static bool hasPhysicalItemsInOrder(
    Map<String, dynamic> order, {
    List<dynamic>? items,
  }) {
    final list = items ?? order['items'] as List? ?? [];
    if (list.isNotEmpty) {
      return list.any((raw) {
        if (raw is! Map) return false;
        return !isDigitalProduct(Map<String, dynamic>.from(raw));
      });
    }
    if (order['has_digital'] == true && order['has_physical'] != true) {
      return false;
    }
    return order['has_physical'] == true;
  }

  static bool isDigitalOnlyOrder(
    Map<String, dynamic> order, {
    List<dynamic>? items,
  }) {
    final hasDigital = order['has_digital'] == true || order['has_digital'] == 1;
    final hasPhysical = order['has_physical'] == true || order['has_physical'] == 1;
    if (hasDigital && !hasPhysical) return true;

    final list = items ?? order['items'] as List? ?? [];
    if (list.isEmpty) {
      return hasDigital && !hasPhysical;
    }
    return list.every(
      (raw) => raw is Map && isDigitalProduct(Map<String, dynamic>.from(raw)),
    );
  }

  static bool isOrderPaid(Map<String, dynamic> order) {
    final paymentStatus =
        (order['payment_status'] ?? '').toString().toLowerCase();
    final orderStatus = (order['status'] ?? '').toString().toLowerCase();
    return paymentStatus == 'paid' ||
        orderStatus == 'completed' ||
        orderStatus == 'processing' ||
        orderStatus == 'paid';
  }

  static bool hasDigitalItemsInOrder(
    Map<String, dynamic> order, {
    List<dynamic>? items,
  }) {
    final list = items ?? order['items'] as List? ?? [];
    if (list.isNotEmpty) {
      return list.any(
        (raw) => raw is Map && isDigitalProduct(Map<String, dynamic>.from(raw)),
      );
    }
    return order['has_digital'] == true || order['has_digital'] == 1;
  }

  /// True when order is sticker / audio / video / any digital purchase.
  static bool isDigitalOrder(
    Map<String, dynamic> order, {
    List<dynamic>? items,
  }) {
    if (WatchFaceOrderHelper.isWatchFaceOrder(order, items: items)) return true;
    if (isDigitalOnlyOrder(order, items: items)) return true;
    if (hasDigitalItemsInOrder(order, items: items) &&
        !hasPhysicalItemsInOrder(order, items: items)) {
      return true;
    }
    final hasDigital = order['has_digital'] == true || order['has_digital'] == 1;
    final hasPhysical = order['has_physical'] == true || order['has_physical'] == 1;
    if (hasDigital && !hasPhysical) return true;
    final ship = order['shipping_address'];
    if (hasDigitalItemsInOrder(order, items: items) &&
        !(ship is Map && ship.isNotEmpty)) {
      return true;
    }
    return false;
  }

  /// Status label for order list — digital never shows pending/shipped.
  static String displayOrderStatus(
    Map<String, dynamic> order, {
    List<dynamic>? items,
  }) {
    if (isDigitalOrder(order, items: items)) {
      return 'paid';
    }
    return (order['status'] ?? 'pending').toString().toLowerCase();
  }

  /// Cancel only for physical orders still in fulfilment — never digital purchases.
  static bool canCancelOrder(
    Map<String, dynamic> order, {
    List<dynamic>? items,
  }) {
    if (isDigitalOrder(order, items: items)) return false;
    if (hasDigitalItemsInOrder(order, items: items)) return false;
    if (!hasPhysicalItemsInOrder(order, items: items)) return false;
    final status = (order['status'] ?? '').toString().toLowerCase();
    return status == 'pending' ||
        status == 'confirmed' ||
        status == 'processing';
  }

  /// Physical orders: delivery status. Digital-only: "Paid" — no pending/shipped.
  static ({bool show, String label}) orderFulfillmentBadge(
    Map<String, dynamic> order, {
    required bool hasPhysicalItems,
    List<dynamic>? items,
  }) {
    if (isDigitalOrder(order, items: items) || !hasPhysicalItems) {
      return (show: true, label: 'paid');
    }
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    return (show: true, label: status);
  }
}
