import 'package:get/get.dart';
import 'getx_registry.dart';

/// Open product details with list preview so the page never blocks on first paint.
class ProductDetailsNavigation {
  ProductDetailsNavigation._();

  static int? parseId(dynamic args) {
    if (args is int) return args;
    if (args is String) return int.tryParse(args);
    if (args is Map) {
      final raw = args['id'] ?? args['product_id'];
      if (raw is int) return raw;
      return int.tryParse(raw?.toString() ?? '');
    }
    if (args != null) return int.tryParse(args.toString());
    return null;
  }

  static Map<String, dynamic>? parsePreview(dynamic args) {
    if (args is Map && args['preview'] is Map) {
      return Map<String, dynamic>.from(args['preview'] as Map);
    }
    return null;
  }

  /// List/card item → minimal detail map for instant UI.
  static Map<String, dynamic> previewToDetail(Map<String, dynamic> item) {
    final image = item['image']?.toString() ?? '';
    final rawPrice = item['sale_price'] ?? item['price'] ?? 0.0;
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0.0;
    final rawOriginal = item['originalPrice'] ??
        (item['sale_price'] != null ? item['price'] : null);
    double? originalPrice;
    if (rawOriginal != null) {
      originalPrice = rawOriginal is num
          ? rawOriginal.toDouble()
          : double.tryParse(rawOriginal.toString());
    }

    return {
      'id': item['id'],
      'name': item['name'] ?? '',
      'price': price,
      'originalPrice': originalPrice,
      'rating': item['rating'] is double
          ? item['rating'] as double
          : double.tryParse(item['rating']?.toString() ?? '0') ?? 0.0,
      'reviews': item['reviews'] ?? item['review_count'] ?? 0,
      'description': item['description'] ?? item['short_description'] ?? '',
      'images': image.isNotEmpty ? [image] : <String>[],
      'sizes': item['sizes'] is List ? item['sizes'] : <dynamic>[],
      'colors': item['colors'] is List ? item['colors'] : <dynamic>[],
      'inStock': item['inStock'] ?? item['in_stock'] ?? true,
      'stock': item['stock'] ?? item['stock_quantity'] ?? 0,
      'category_id': item['category_id'] ??
          (item['category'] is Map ? item['category']['id'] : null),
      'is_digital': item['is_digital'] == true || item['is_digital'] == 1,
      'is_sticker_pack':
          item['is_sticker_pack'] == true || item['is_sticker_pack'] == 1,
      'total_stickers': item['total_stickers'] ?? 0,
      'stickers_preview':
          item['stickers_preview'] is List ? item['stickers_preview'] : [],
      'digital_file_path': item['digital_file_path'],
      'media_type': item['media_type']?.toString() ?? '',
      'video_url': item['video_url']?.toString() ?? '',
      'banner': item['banner'],
    };
  }

  static void go({
    required int id,
    Map<String, dynamic>? preview,
  }) {
    if (id <= 0) return;
    final controller = GetXRegistry.product();
    controller.openProduct(id, preview: preview);
    Get.toNamed(
      '/product-details',
      arguments: {
        'id': id,
        if (preview != null) 'preview': preview,
      },
    );
  }
}
