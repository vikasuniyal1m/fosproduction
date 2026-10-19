import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_colors.dart';
import 'controllers/watch_faces_controller.dart';
import 'data/watch_faces_repository.dart';
import 'models/watch_face_model.dart';
import 'services/watch_face_installer_service.dart';
import 'watch_face_install_helper.dart';
import 'watch_face_product_ids.dart';
import 'watch_faces_config.dart';

/// Links paid store orders ↔ catalog watch faces.
class WatchFaceOrderHelper {
  WatchFaceOrderHelper._();

  static final _repository = WatchFacesRepository();
  static Map<String, String>? _previewByFaceId;
  static Map<String, double>? _priceByFaceId;
  static List<WatchFace>? _catalog;

  static bool isWatchFaceProductId(dynamic raw) {
    final id = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    return WatchFaceProductIds.isWatchFaceProduct(id);
  }

  static bool isWatchFaceOrder(
    Map<String, dynamic> order, {
    List<dynamic>? items,
  }) {
    if (resolveFaceId(
          orderNotes: order['order_notes']?.toString(),
          item: _firstItemMap(items ?? order['items']),
        ) !=
        null) {
      return true;
    }
    final list = items ?? order['items'] as List? ?? [];
    for (final raw in list) {
      if (raw is Map && isWatchFaceProductId(raw['product_id'])) return true;
    }
    return false;
  }

  static Map<String, dynamic>? _firstItemMap(dynamic items) {
    if (items is! List || items.isEmpty) return null;
    final raw = items.first;
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static String? parseFaceIdFromNotes(String? notes) {
    if (notes == null || notes.isEmpty) return null;
    final match = RegExp(r'watch_face_id:([^\s\n]+)').firstMatch(notes);
    return match?.group(1)?.trim();
  }

  static String? extractTitleFromProductName(String? name) {
    if (name == null || name.isEmpty) return null;
    final match =
        RegExp(r'Watch Face\s*[·•\-:]\s*(.+)', caseSensitive: false)
            .firstMatch(name);
    return match?.group(1)?.trim();
  }

  static String? faceIdFromProductName(String? name) {
    final title = extractTitleFromProductName(name);
    if (title == null || _catalog == null) return null;
    final lower = title.toLowerCase();
    for (final face in _catalog!) {
      if (face.title.toLowerCase() == lower) return face.id;
    }
    return null;
  }

  static String? resolveFaceId({
    String? orderNotes,
    Map<String, dynamic>? item,
  }) {
    final fromNotes = parseFaceIdFromNotes(orderNotes);
    if (fromNotes != null && fromNotes.isNotEmpty) return fromNotes;

    final fromItem = item?['watch_face_id']?.toString();
    if (fromItem != null && fromItem.isNotEmpty) return fromItem;

    return faceIdFromProductName(item?['product_name']?.toString());
  }

  static bool isAndroidFaceId(String? faceId) =>
      faceId != null && faceId.startsWith('android-');

  static bool isIosFaceId(String? faceId) =>
      faceId != null && faceId.startsWith('ios-');

  static WatchPlatform get currentPlatform {
    if (!kIsWeb && Platform.isAndroid) return WatchPlatform.android;
    return WatchPlatform.ios;
  }

  static bool isForCurrentPlatform(String? faceId) {
    if (faceId == null || faceId.isEmpty) return true;
    if (kIsWeb) return true;
    if (Platform.isAndroid) return isAndroidFaceId(faceId);
    if (Platform.isIOS) return isIosFaceId(faceId);
    return true;
  }

  static bool isWatchFaceOrderForCurrentPlatform(Map<String, dynamic> order) {
    final faceId = resolveFaceId(
      orderNotes: order['order_notes']?.toString(),
      item: _firstItemMap(order['items']),
    );
    if (faceId == null) return true;
    return isForCurrentPlatform(faceId);
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

  static Future<void> ensureCatalogLoaded() async {
    if (_catalog != null) return;
    _catalog = await _repository.loadAll();
    _previewByFaceId = {
      for (final face in _catalog!) face.id: face.previewImage,
    };
    _priceByFaceId = {
      for (final face in _catalog!)
        face.id: face.price ?? WatchFacesConfig.defaultPrice,
    };
  }

  static String? previewAssetForFaceId(String? faceId) {
    if (faceId == null || faceId.isEmpty) return null;
    return _previewByFaceId?[faceId];
  }

  static double? catalogPriceForFaceId(String? faceId) {
    if (faceId == null || faceId.isEmpty) return null;
    return _priceByFaceId?[faceId];
  }

  static Future<WatchFace?> findByFaceId(String faceId) async {
    await ensureCatalogLoaded();
    for (final face in _catalog!) {
      if (face.id == faceId) return face;
    }
    return null;
  }

  static void applyWatchFacePreviewToItems(
    List<Map<String, dynamic>> items,
    String? orderNotes,
  ) {
    final faceId = resolveFaceId(
      orderNotes: orderNotes,
      item: items.isNotEmpty ? items.first : null,
    );
    if (faceId == null) return;
    final preview = previewAssetForFaceId(faceId);
    for (final item in items) {
      item['watch_face_id'] = faceId;
      if (preview != null && preview.isNotEmpty) {
        item['watch_face_preview'] = preview;
        item['image'] = preview;
      }
      item['is_digital'] = true;
      item['is_sticker_pack'] = false;
      item['is_sticker'] = false;
      item['media_type'] = 'watch_face';
    }
  }

  static void applyWatchFacePricing(
    List<Map<String, dynamic>> items,
    String? orderNotes,
    double orderTotal,
  ) {
    final faceId = resolveFaceId(
      orderNotes: orderNotes,
      item: items.isNotEmpty ? items.first : null,
    );
    if (faceId == null) return;

    final catalogPrice = catalogPriceForFaceId(faceId);
    final unitPrice = catalogPrice ??
        (orderTotal > 0 && items.length == 1 ? orderTotal : null);
    if (unitPrice == null || unitPrice <= 0) return;

    for (final item in items) {
      final qty = item['quantity'] is int
          ? item['quantity'] as int
          : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      item['price'] = unitPrice;
      item['total'] = unitPrice * qty;
    }
  }

  static Future<void> enrichWatchFaceOrder(Map<String, dynamic> order) async {
    if (!isWatchFaceOrder(order)) return;
    await ensureCatalogLoaded();
    final notes = orderNotesFrom(order);
    final items = (order['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();
    applyWatchFacePreviewToItems(items, notes);
    final total = _parseAmount(
      order['total_amount'] ?? order['total'] ?? order['grand_total'],
    );
    applyWatchFacePricing(items, notes, total);
    order['items'] = items;
  }

  static double _parseAmount(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static Future<WatchFace?> resolveForOrderItem({
    required dynamic productId,
    String? orderNotes,
    Map<String, dynamic>? item,
  }) async {
    final faceId = resolveFaceId(orderNotes: orderNotes, item: item);
    if (faceId != null && !isForCurrentPlatform(faceId)) return null;

    await ensureCatalogLoaded();

    if (faceId != null && faceId.isNotEmpty) {
      return findByFaceId(faceId);
    }

    if (isWatchFaceProductId(productId) && item != null) {
      final fromName = faceIdFromProductName(item['product_name']?.toString());
      if (fromName != null) return findByFaceId(fromName);
    }
    return null;
  }

  static String orderNotesFrom(Map<String, dynamic> order) {
    return order['order_notes']?.toString() ??
        order['notes']?.toString() ??
        order['order_note']?.toString() ??
        '';
  }

  static Future<void> installFromOrder(
    Map<String, dynamic> order,
    Map<String, dynamic> item,
  ) async {
    final notes = orderNotesFrom(order);
    final faceId = resolveFaceId(orderNotes: notes, item: item);
    if (faceId != null && !isForCurrentPlatform(faceId)) {
      Get.snackbar(
        'Wrong device',
        isAndroidFaceId(faceId)
            ? 'This watch face installs on Android only.'
            : 'This watch face installs on iPhone only.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.textPrimary,
        colorText: AppColors.textWhite,
      );
      return;
    }

    final face = await resolveForOrderItem(
      productId: item['product_id'],
      orderNotes: notes,
      item: item,
    );
    if (face == null) {
      Get.snackbar(
        'Watch Faces',
        'Could not load this watch face. Try again from Watch Faces.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (Get.isRegistered<WatchFacesController>()) {
      await Get.find<WatchFacesController>().markFacePurchased(face.id);
    }

    await installFaceWithFeedback(
      WatchFaceInstallerService(),
      face,
    );
  }

  static Widget buildPreviewImage(
    Map<String, dynamic> item, {
    required double size,
    String cacheKeyPrefix = 'order_preview',
  }) {
    final asset = item['watch_face_preview']?.toString() ?? '';
    if (asset.startsWith('assets/')) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.watch,
            size: size * 0.45,
            color: AppColors.secondary,
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.watch,
        size: size * 0.45,
        color: AppColors.secondary,
      ),
    );
  }
}
