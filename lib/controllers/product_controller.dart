import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/app_colors.dart';
import '../utils/cache_manager.dart';
import '../utils/data_cache.dart';
import '../utils/product_details_navigation.dart';
import '../utils/digital_product_type.dart';
import '../routes/app_routes.dart';
import '../utils/getx_registry.dart';
import '../views/products/full_audio_player_screen.dart';
import '../views/products/full_video_player_screen.dart';
import '../widgets/add_to_cart_success_sheet.dart';
import '../widgets/review_dialog.dart';
import '../services/media_preview_pool.dart';
import 'cart_controller.dart';
import 'wishlist_controller.dart';

/// Product Controller
/// Handles product details logic
class ProductController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxInt selectedImageIndex = 0.obs;
  /// Index into unlocked sticker previews (hero carousel).
  final RxInt selectedStickerIndex = 0.obs;
  final RxInt quantity = 1.obs;
  final RxBool isFavorite = false.obs;
  final RxInt selectedSizeIndex = 0.obs;
  final RxInt selectedColorIndex = 0.obs;
  final ApiService _apiService = ApiService();
  
  final Rxn<Map<String, dynamic>> _product = Rxn<Map<String, dynamic>>();
  Rxn<Map<String, dynamic>> get productObs => _product;
  Map<String, dynamic>? get product => _product.value;
  set product(Map<String, dynamic>? value) => _product.value = value;

  final RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> relatedProducts = <Map<String, dynamic>>[].obs;

  /// Digital product: has user paid for this product (lifetime download access)?
  final RxBool digitalHasPurchased = false.obs;
  /// When has_purchased, order_item_id for download API (so user can download from product details).
  final Rxn<int> digitalOrderItemId = Rxn<int>();
  /// Digital product: preview URL for 5–10 sec listen/watch (no auth required).
  final RxString digitalPreviewUrl = ''.obs;
  /// Preview duration in seconds (e.g. 10).
  final RxInt digitalPreviewDurationSeconds = 10.obs;
  /// 'video' or 'audio' for in-app preview player.
  final RxString digitalPreviewMediaType = 'video'.obs;
  final RxBool digitalPreviewLoading = false.obs;
  int? _digitalPreviewProductId;
  Future<void>? _digitalMediaLoadFuture;
  int? _digitalMediaLoadProductId;

  @override
  void onInit() {
    super.onInit();
    final productId = ProductDetailsNavigation.parseId(Get.arguments);
    final preview = ProductDetailsNavigation.parsePreview(Get.arguments);
    if (productId != null && productId > 0) {
      openProduct(productId, preview: preview);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
    }
  }

  bool _isSameProductId(dynamic a, int b) {
    if (a == null) return false;
    if (a is int) return a == b;
    return int.tryParse(a.toString()) == b;
  }

  int? _currentProductId() {
    final id = product?['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  void _clearDigitalPreviewForSwitch() {
    digitalPreviewUrl.value = '';
    digitalPreviewMediaType.value = 'video';
    digitalPreviewLoading.value = false;
    _digitalPreviewProductId = null;
    _digitalMediaLoadFuture = null;
    _digitalMediaLoadProductId = null;
  }

  void _seedVideoPreviewFromProduct(int productId) {
    if (product == null) return;
    if (!DigitalProductType.isVideo(product!)) return;
    if (digitalPreviewUrl.value.isNotEmpty &&
        _digitalPreviewProductId == productId) {
      return;
    }
    _tryDigitalFileFallback(productId);
    _prefetchVideoInBackground();
  }

  /// Warm disk cache + player pool so video starts faster.
  void _prefetchVideoInBackground() {
    final productId = _currentProductId();
    final url = playbackVideoUrl;
    if (productId == null || url == null || url.isEmpty) return;
    unawaited(MediaPreviewPool.instance.ensureVideoCached(url));
    unawaited(
      MediaPreviewPool.instance.acquireVideo(url).then((controller) {
        if (_currentProductId() == productId && playbackVideoUrl == url) {
          MediaPreviewPool.instance.releaseVideo(url);
        }
        return controller;
      }),
    );
  }

  /// Instant UI from cache/list preview, then silent API refresh.
  void openProduct(int productId, {Map<String, dynamic>? preview}) {
    if (_isSameProductId(product?['id'], productId) && product != null) {
      isLoading.value = false;
      _applyPurchaseStateFromCache(productId);
      loadProductDetails(productId, silent: true);
      return;
    }

    Map<String, dynamic>? instant;
    final cached = DataCache.loadMap(DataCache.productDetail(productId));
    final cachedProduct = cached?['product'];
    if (cachedProduct is Map && cachedProduct.isNotEmpty) {
      instant = Map<String, dynamic>.from(cachedProduct);
    } else if (preview != null) {
      instant = ProductDetailsNavigation.previewToDetail(preview);
    }

    selectedImageIndex.value = 0;
    selectedStickerIndex.value = 0;
    quantity.value = 1;
    reviews.clear();
    relatedProducts.clear();
    _clearDigitalPreviewForSwitch();

    // Purchase state from local map / detail cache — never flash "Buy" if already owned
    _applyPurchaseStateFromCache(productId);

    if (instant != null) {
      product = instant;
      if (preview != null) {
        isFavorite.value = preview['isFavorite'] == true;
      }
      final mt = DigitalProductType.resolveMediaType(instant);
      if (mt == 'audio' || mt == 'video') {
        digitalPreviewMediaType.value = mt;
      }
      if (cached != null) {
        _applyCachedProduct(productId);
      }
      _seedVideoPreviewFromProduct(productId);
      _prefetchVideoInBackground();
      isLoading.value = false;
    } else {
      product = null;
      isLoading.value = true;
    }

    loadProductDetails(productId, silent: product != null);
  }

  /// Apply owned state instantly from memory map + product detail cache.
  void _applyPurchaseStateFromCache(int productId) {
    final fromMap = DataCache.purchaseStatus(productId);
    if (fromMap.purchased) {
      digitalHasPurchased.value = true;
      if (fromMap.orderItemId != null) {
        digitalOrderItemId.value = fromMap.orderItemId;
      }
      return;
    }

    final cached = DataCache.loadMap(DataCache.productDetail(productId));
    if (cached?['digitalHasPurchased'] == true) {
      digitalHasPurchased.value = true;
      final oid = cached!['digitalOrderItemId'];
      digitalOrderItemId.value =
          oid is int ? oid : int.tryParse(oid?.toString() ?? '');
      return;
    }

    digitalHasPurchased.value = false;
    digitalOrderItemId.value = null;
  }

  /// Call right after payment success — UI updates before API round-trip.
  Future<void> applyDigitalPurchase({int? orderItemId}) async {
    if (product == null) return;
    final productId = product!['id'] is int
        ? product!['id'] as int
        : int.tryParse(product!['id']?.toString() ?? '');
    if (productId == null || productId <= 0) return;

    digitalHasPurchased.value = true;
    if (orderItemId != null) digitalOrderItemId.value = orderItemId;
    product!['has_purchased'] = true;
    if (orderItemId != null) product!['order_item_id'] = orderItemId;

    await DataCache.markDigitalPurchased(productId, orderItemId: orderItemId);
    _tryDigitalFileFallback(productId);
    _digitalPreviewProductId = productId;
    await _saveProductCache(productId);
  }
  
  void _applyCachedProduct(int productId) {
    final cached = DataCache.loadMap(DataCache.productDetail(productId));
    if (cached == null) return;
    final cachedProduct = cached['product'];
    if (cachedProduct is! Map || cachedProduct.isEmpty) return;
    final cachedId = cachedProduct['id'];
    if (!_isSameProductId(cachedId, productId)) return;
    product = Map<String, dynamic>.from(cachedProduct);
    if (cached['reviews'] is List) {
      reviews.value = (cached['reviews'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (cached['relatedProducts'] is List) {
      relatedProducts.value = (cached['relatedProducts'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    isFavorite.value = cached['isFavorite'] == true;

    _applyPurchaseStateFromCache(productId);

    final cachedPreview = cached['digitalPreviewUrl']?.toString() ?? '';
    if (cachedPreview.isNotEmpty) {
      digitalPreviewUrl.value = cachedPreview;
      digitalPreviewMediaType.value =
          cached['digitalPreviewMediaType']?.toString() ?? 'video';
      digitalPreviewDurationSeconds.value = int.tryParse(
            cached['digitalPreviewDurationSeconds']?.toString() ?? '10',
          ) ??
          10;
      _digitalPreviewProductId = productId;
    }
  }

  Future<void> _saveProductCache(int productId) async {
    if (product == null) return;
    if (digitalHasPurchased.value) {
      await DataCache.markDigitalPurchased(
        productId,
        orderItemId: digitalOrderItemId.value,
      );
    }
    final previewForCache = _digitalPreviewProductId == productId
        ? digitalPreviewUrl.value
        : '';
    await DataCache.saveMap(DataCache.productDetail(productId), {
      'product': product,
      'reviews': reviews.toList(),
      'relatedProducts': relatedProducts.toList(),
      'isFavorite': isFavorite.value,
      'digitalPreviewUrl': previewForCache,
      'digitalPreviewMediaType': digitalPreviewMediaType.value,
      'digitalPreviewDurationSeconds': digitalPreviewDurationSeconds.value,
      'digitalHasPurchased': digitalHasPurchased.value,
      'digitalOrderItemId': digitalOrderItemId.value,
    });
  }

  bool _isDigitalPreviewReady(int productId) =>
      _digitalPreviewProductId == productId &&
      digitalPreviewUrl.value.isNotEmpty;

  /// Load full product details from API (silent when preview/cache already shown).
  Future<void> loadProductDetails(int productId, {bool silent = false}) async {
    if (!silent) {
      _applyCachedProduct(productId);
      if (product == null) {
        isLoading.value = true;
      }
    }
    try {
      // Load product details
      final response = await _apiService.get(
        ApiEndpoints.productDetails,
        queryParameters: {'id': productId.toString()},
      );
      final data = ApiService.handleResponse(response);
      
      // Format product data
      // Handle images - API returns array of objects with 'url' key
      List<String> imageUrls = [];
      if (data['images'] != null && data['images'] is List) {
        for (var img in data['images']) {
          if (img is Map && img['url'] != null) {
            imageUrls.add(_getImageUrl(img['url'].toString()));
          } else if (img is String) {
            imageUrls.add(_getImageUrl(img));
          }
        }
      }
      // If no images from images array, use main image
      if (imageUrls.isEmpty && data['image'] != null) {
        imageUrls.add(_getImageUrl(data['image'].toString()));
      }

      final isStickerApi = DigitalProductType.isStickerPack({
        'is_sticker_pack': data['is_sticker_pack'],
        'category_id': data['category_id'] ??
            (data['category'] is Map ? data['category']['id'] : null),
        'media_type': data['media_type'],
        'digital_file_path': data['digital_file_path'],
        'product_type': data['product_type'],
      });
      // Non-sticker: merge sticker URLs into image carousel if present
      if (!isStickerApi && data['stickers_preview'] is List) {
        for (final sticker in data['stickers_preview'] as List) {
          if (sticker is Map) {
            final url = sticker['image_url']?.toString() ?? '';
            if (url.isNotEmpty && !imageUrls.contains(url)) {
              imageUrls.add(_getImageUrl(url));
            }
          }
        }
      }
      
      // Handle variants - API returns variants as object with 'size', 'color', etc.
      List<String> sizes = [];
      List<Map<String, dynamic>> colors = [];
      if (data['variants'] != null && data['variants'] is Map) {
        final variants = data['variants'] as Map;
        if (variants['size'] != null && variants['size'] is List) {
          sizes = (variants['size'] as List).map((v) {
            if (v is Map) return v['value']?.toString() ?? '';
            return v.toString();
          }).where((s) => s.isNotEmpty).toList();
        }
        if (variants['color'] != null && variants['color'] is List) {
          colors = (variants['color'] as List).map((v) {
            if (v is Map) {
              return {
                'name': v['value']?.toString() ?? '',
                'code': v['value']?.toString() ?? '#000000',
              };
            }
            return {
              'name': v.toString(),
              'code': '#000000',
            };
          }).toList();
        }
      }
      
      final apiStickers = data['stickers_preview'] is List
          ? data['stickers_preview'] as List
          : <dynamic>[];
      // Never reuse previous product's stickers — each product only its own pack.
      final stickersPreview = List<dynamic>.from(apiStickers);
      final apiTotal = data['total_stickers'];
      final totalStickers = apiTotal != null
          ? int.tryParse(apiTotal.toString()) ?? 0
          : stickersPreview.length;

      product = {
        'id': data['id'],
        'name': data['name'] ?? '',
        'price': double.tryParse((data['sale_price'] ?? data['price'] ?? '0').toString()) ?? 0.0,
        'originalPrice': data['sale_price'] != null 
            ? double.tryParse(data['price']?.toString() ?? '0') ?? 0.0 
            : null,
        'rating': double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
        'reviews': int.tryParse(data['review_count']?.toString() ?? '0') ?? 0,
        'description': data['description'] ?? data['short_description'] ?? '',
        'images': imageUrls.isNotEmpty ? imageUrls : [data['image'] != null ? _getImageUrl(data['image'].toString()) : ''],
        'sizes': sizes,
        'colors': colors,
        'inStock': data['is_digital'] == true
            ? true
            : (data['in_stock'] ?? (data['stock_quantity'] != null && (int.tryParse(data['stock_quantity'].toString()) ?? 0) > 0)),
        'stock': int.tryParse(data['stock_quantity']?.toString() ?? '0') ?? 0,
        'category_id': data['category'] != null && data['category'] is Map 
            ? data['category']['id'] 
            : data['category_id'],
        'is_digital': data['is_digital'] == true || data['is_digital'] == 1,
        'is_sticker_pack': data['is_sticker_pack'] == true || data['is_sticker_pack'] == 1,
        'total_stickers': totalStickers,
        'stickers_preview': stickersPreview,
        'digital_file_path': data['digital_file_path'],
        'media_type': (data['media_type']?.toString().isNotEmpty == true)
            ? data['media_type'].toString()
            : _mediaTypeFromDigitalPath(data['digital_file_path']?.toString()),
        'video_url': data['video_url']?.toString() ?? '',
      };
      
      _checkWishlistStatus(product!['id']);

      final secondaryLoads = <Future<void>>[];

      if (!silent || reviews.isEmpty) {
        secondaryLoads.add(loadReviews(productId));
      }
      if (data['category_id'] != null &&
          (!silent || relatedProducts.isEmpty)) {
        secondaryLoads.add(
          loadRelatedProducts(data['category_id'], productId),
        );
      }

      if (product!['is_digital'] == true) {
        quantity.value = 1;
        if (DigitalProductType.isVideo(product!)) {
          _seedVideoPreviewFromProduct(productId);
          _prefetchVideoInBackground();
        }
        final isSticker = DigitalProductType.isStickerPack(product!);
        final hasStickerPreviews =
            (product!['stickers_preview'] as List?)?.isNotEmpty == true;

        if (!silent && !_isDigitalPreviewReady(productId)) {
          final apiMediaType = product!['media_type']?.toString() ?? '';
          if (apiMediaType == 'video' || apiMediaType == 'audio') {
            digitalPreviewMediaType.value = apiMediaType;
          }
        }

        if (isSticker && hasStickerPreviews) {
          secondaryLoads.add(_loadDigitalPurchaseStatusOnly(productId));
        } else {
          secondaryLoads.add(_ensureDigitalMediaLoaded(productId));
        }
      }

      if (secondaryLoads.isNotEmpty) {
        await Future.wait(secondaryLoads);
      }

      unawaited(_saveProductCache(productId));
    } catch (e) {
      if (!silent && product == null) {
        ApiService.showErrorSnackbar(e);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh purchase only (e.g. after payment) — no duplicate preview API.
  Future<void> refreshDigitalPurchaseStatus() async {
    if (product == null || product!['is_digital'] != true) return;
    final productId = product!['id'] is int
        ? product!['id'] as int
        : int.tryParse(product!['id'].toString());
    if (productId == null || productId <= 0) return;

    final wasPurchased = digitalHasPurchased.value;
    await _loadDigitalPurchaseStatusOnly(productId);
    if (digitalHasPurchased.value && !wasPurchased) {
      _tryDigitalFileFallback(productId);
      _digitalPreviewProductId = productId;
      await _saveProductCache(productId);
    }
  }

  /// Single entry: purchase check → file path if owned → preview API only if needed.
  Future<void> _ensureDigitalMediaLoaded(int productId) async {
    if (_isDigitalPreviewReady(productId)) return;

    if (_digitalMediaLoadFuture != null &&
        _digitalMediaLoadProductId == productId) {
      return _digitalMediaLoadFuture;
    }

    _digitalMediaLoadProductId = productId;
    _digitalMediaLoadFuture = _loadDigitalMediaOnce(productId);
    try {
      await _digitalMediaLoadFuture;
      _digitalPreviewProductId = productId;
    } finally {
      if (_digitalMediaLoadProductId == productId) {
        _digitalMediaLoadFuture = null;
      }
    }
  }

  Future<void> _loadDigitalMediaOnce(int productId) async {
    digitalPreviewLoading.value = true;
    try {
      if (product?.containsKey('has_purchased') == true) {
        digitalHasPurchased.value = product!['has_purchased'] == true;
        final oid = product!['order_item_id'];
        digitalOrderItemId.value = (oid is int)
            ? oid
            : int.tryParse(oid?.toString() ?? '');
      } else {
        await _loadDigitalPurchaseStatusOnly(productId);
      }

      // Purchased → full file from digital_file_path, skip preview API
      if (digitalHasPurchased.value) {
        _tryDigitalFileFallback(productId);
        return;
      }

      // Not purchased → preview API once, then fallback
      if (digitalPreviewUrl.value.isEmpty) {
        await _fetchDigitalPreviewFromApi(productId);
      }
    } finally {
      digitalPreviewLoading.value = false;
    }
  }

  /// Load purchase status only (for when preview is already loaded)
  Future<void> _loadDigitalPurchaseStatusOnly(int productId) async {
    print('[DigitalPreview] _loadDigitalPurchaseStatusOnly productId=$productId');
    try {
      final token = CacheManager.getUserToken();
      // Hide actual token value in logs for security
      final tokenDisplay = token != null && token.isNotEmpty ? '[REDACTED]' : 'null';
      print('[DigitalPreview] Token check: token=$tokenDisplay, isEmpty=${token?.isEmpty ?? true}');
      print('[DigitalPreview] User logged in: ${CacheManager.isLoggedIn()}');
      
      if (token != null && token.isNotEmpty) {
        print('[DigitalPreview] Making API call with token');
        final purchasedResponse = await _apiService.get(
          ApiEndpoints.orderHasPurchased,
          queryParameters: {'product_id': productId.toString()},
        );
        final purchasedData = ApiService.handleResponse(purchasedResponse);
        
        print('[DigitalPreview] Raw purchase response: $purchasedData');
        print('[DigitalPreview] Response keys: ${purchasedData.keys.toList()}');
        
        final apiPurchased = purchasedData['has_purchased'] == true;
        final oid = purchasedData['order_item_id'];
        final parsedOid =
            (oid is int) ? oid : (oid != null ? int.tryParse(oid.toString()) : null);

        if (apiPurchased) {
          digitalHasPurchased.value = true;
          digitalOrderItemId.value = parsedOid;
          await DataCache.markDigitalPurchased(
            productId,
            orderItemId: parsedOid,
          );
        } else if (!DataCache.purchaseStatus(productId).purchased) {
          digitalHasPurchased.value = false;
          digitalOrderItemId.value = null;
        }
        print('[DigitalPreview] Purchase status checked: has_purchased=${digitalHasPurchased.value}, order_item_id=${digitalOrderItemId.value}');
      } else if (!DataCache.purchaseStatus(productId).purchased) {
        digitalHasPurchased.value = false;
        digitalOrderItemId.value = null;
        print('[DigitalPreview] No user token found, skipping API call and setting purchase status = false');
        print('[DigitalPreview] CacheManager.getUserToken() returned: $token');
        print('[DigitalPreview] CacheManager.isLoggedIn() returned: ${CacheManager.isLoggedIn()}');
      }
    } catch (e, st) {
      print('[DigitalPreview] _loadDigitalPurchaseStatusOnly ERROR: $e');
      print('[DigitalPreview] stackTrace: $st');
      if (!DataCache.purchaseStatus(productId).purchased) {
        digitalHasPurchased.value = false;
        digitalOrderItemId.value = null;
      }
    }
  }

  /// Preview API — only for non-purchased products.
  Future<void> _fetchDigitalPreviewFromApi(int productId) async {
    print('[DigitalPreview] fetch preview API productId=$productId');
    try {
      final previewResponse = await _apiService.get(
        ApiEndpoints.digitalPreview,
        queryParameters: {'product_id': productId.toString()},
      );
      if (previewResponse.statusCode == 200) {
        final previewData = ApiService.handleResponse(previewResponse);
        final rawUrl = previewData['preview_url']?.toString() ?? '';
        if (rawUrl.isNotEmpty) {
          _digitalPreviewProductId = productId;
          digitalPreviewUrl.value = _normalizePreviewUrl(rawUrl);
          digitalPreviewDurationSeconds.value = int.tryParse(
                previewData['preview_duration_seconds']?.toString() ?? '',
              ) ??
              15;
          digitalPreviewMediaType.value =
              (previewData['media_type']?.toString() == 'audio')
                  ? 'audio'
                  : 'video';
          return;
        }
      }
      _tryDigitalFileFallback(productId);
    } on DioException catch (e) {
      print('[DigitalPreview] Preview API skipped/failed: ${e.message}');
      _tryDigitalFileFallback(productId);
    } catch (e) {
      print('[DigitalPreview] Preview error: $e');
      _tryDigitalFileFallback(productId);
    }
  }

  /// Try to use digital_file_path as fallback when preview API fails
  void _tryDigitalFileFallback(int productId) {
    try {
      print('[DigitalPreview] Trying digital_file_path fallback for productId: $productId');
      
      if (product != null) {
        final digitalFilePath = product!['digital_file_path']?.toString();
        print('[DigitalPreview] digital_file_path: $digitalFilePath');
        
        if (digitalFilePath != null && digitalFilePath.isNotEmpty) {
          // Prefer video/audio file — new admin uploads store JSON arrays (banner + video)
          String filePath = _pickPrimaryDigitalMediaFilename(digitalFilePath);

          if (filePath.isNotEmpty) {
            final fullUrl = '${ApiService.imageBaseUrl}digital_products/$filePath';
            final lowerPath = filePath.toLowerCase();
            final isAudio = lowerPath.endsWith('.mp3') || lowerPath.endsWith('.wav') || lowerPath.endsWith('.aac') || lowerPath.endsWith('.m4a') || lowerPath.endsWith('.ogg');
            _digitalPreviewProductId = productId;
            digitalPreviewUrl.value = fullUrl;
            digitalPreviewDurationSeconds.value = 12; // Default preview duration
            digitalPreviewMediaType.value = isAudio ? 'audio' : 'video';
            print('[DigitalPreview] FALLBACK SUCCESS - Using digital_file_path: $fullUrl, mediaType: ${digitalPreviewMediaType.value}');
            return;
          }
        }
      }
      
      print('[DigitalPreview] FALLBACK FAILED - No valid digital_file_path found');
      digitalPreviewUrl.value = '';
      
    } catch (e) {
      print('[DigitalPreview] FALLBACK ERROR: $e');
      digitalPreviewUrl.value = '';
    }
  }

  /// True when URL/path points to a video file (not banner JPG).
  static bool isVideoMediaUrl(String urlOrPath) {
    if (urlOrPath.isEmpty) return false;
    final lower = urlOrPath.toLowerCase().split('?').first;
    const exts = ['.mp4', '.webm', '.mov', '.m4v', '.avi', '.mkv'];
    return exts.any((e) => lower.endsWith(e));
  }

  /// Resolved in-app video URL for the **current** product only.
  String? get playbackVideoUrl {
    final productId = _currentProductId();
    if (productId == null) return null;

    final path = product?['digital_file_path']?.toString();
    if (path != null && path.isNotEmpty) {
      final file = _pickPrimaryDigitalMediaFilename(path);
      if (file.isNotEmpty && isVideoMediaUrl(file)) {
        return '${ApiService.imageBaseUrl}digital_products/$file';
      }
    }

    if (_digitalPreviewProductId == productId) {
      final preview = digitalPreviewUrl.value.trim();
      if (preview.isNotEmpty &&
          digitalPreviewMediaType.value == 'video' &&
          isVideoMediaUrl(preview)) {
        return preview;
      }
    }

    final direct = product?['video_url']?.toString().trim() ?? '';
    if (isVideoMediaUrl(direct)) return _normalizePreviewUrl(direct);

    return null;
  }

  /// Get full image URL
  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${ApiService.imageBaseUrl}$imagePath';
  }

  /// Fix preview URL when backend returns base + path without slash (e.g. comapi -> com/api).
  /// Pick video/audio from digital_file_path (JSON array or single filename).
  String _pickPrimaryDigitalMediaFilename(String digitalFilePath) {
    const videoExts = ['mp4', 'webm', 'mov', 'm4v', 'avi', 'mkv'];
    const audioExts = ['mp3', 'm4a', 'wav', 'aac', 'ogg'];
    String? audioFile;

    List<String> files = [];
    try {
      if (digitalFilePath.trim().startsWith('[')) {
        final decoded = json.decode(digitalFilePath);
        if (decoded is List) {
          files = decoded.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
      } else {
        files = [digitalFilePath.trim()];
      }
    } catch (_) {
      final match = RegExp(
        r'([a-zA-Z0-9_\-\.]+\.(mp4|mov|avi|webm|mp3|wav|aac|m4a|ogg))',
        caseSensitive: false,
      ).firstMatch(digitalFilePath);
      if (match != null) {
        return match.group(1)!.replaceAll(RegExp(r'[\"\\[\]]'), '');
      }
      return '';
    }

    for (final raw in files) {
      final name = raw.contains('/') ? raw.split('/').last : raw;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      if (videoExts.contains(ext)) return name;
      if (audioFile == null && audioExts.contains(ext)) audioFile = name;
    }
    return audioFile ?? '';
  }

  String _mediaTypeFromDigitalPath(String? digitalFilePath) {
    if (digitalFilePath == null || digitalFilePath.isEmpty) return '';
    final file = _pickPrimaryDigitalMediaFilename(digitalFilePath);
    if (file.isEmpty) return '';
    final ext = file.split('.').last.toLowerCase();
    if (['mp4', 'webm', 'mov', 'm4v', 'avi', 'mkv'].contains(ext)) return 'video';
    if (['mp3', 'm4a', 'wav', 'aac', 'ogg'].contains(ext)) return 'audio';
    return '';
  }

  String _normalizePreviewUrl(String url) {
    if (url.isEmpty) return url;
    return url.replaceFirst('.comapi', '.com/api');
  }

  /// Load reviews
  Future<void> loadReviews(int productId) async {
    try {
      // Check if user is logged in
      final token = CacheManager.getUserToken();
      print('[LoadReviews] User token: ${token != null && token.isNotEmpty ? "Present" : "Missing"}');
      print('[LoadReviews] Loading reviews for product ID: $productId');
      
      final response = await _apiService.get(
        ApiEndpoints.reviewsList,
        queryParameters: {
          'product_id': productId.toString(),
          'limit': '20',
        },
      );
      
      print('[LoadReviews] API Response status: ${response.statusCode}');
      print('[LoadReviews] API Response data type: ${response.data.runtimeType}');
      
      final data = ApiService.handleResponse(response);
      final reviewsList = data['reviews'];
      
      print('[LoadReviews] Raw API response: ${reviewsList?.length ?? 0} reviews');
      if (reviewsList != null && reviewsList is List) {
        print('[LoadReviews] Reviews list content: $reviewsList');
      }
      
      if (reviewsList == null || reviewsList is! List) {
        print('[LoadReviews] No reviews found or invalid format');
        reviews.value = [];
        reviews.refresh();
        return;
      }
      
      // Convert List<dynamic> to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> formattedReviews = [];
      
      for (var review in reviewsList) {
        if (review is! Map) {
          print('[LoadReviews] Skipping invalid review: $review');
          continue;
        }
        
        final reviewMap = Map<String, dynamic>.from(review);
        print('[LoadReviews] Processing review ID: ${reviewMap['id']}, User: ${reviewMap['user_name']}, Status: ${reviewMap['status']}');
        
        // Format date
        String formattedDate = '';
        if (reviewMap['created_at'] != null) {
          try {
            final date = DateTime.parse(reviewMap['created_at'].toString());
            final now = DateTime.now();
            final difference = now.difference(date);
            
            if (difference.inDays == 0) {
              if (difference.inHours == 0) {
                formattedDate = '${difference.inMinutes} minutes ago';
              } else {
                formattedDate = '${difference.inHours} hours ago';
              }
            } else if (difference.inDays < 7) {
              formattedDate = '${difference.inDays} days ago';
            } else if (difference.inDays < 30) {
              formattedDate = '${(difference.inDays / 7).floor()} weeks ago';
            } else {
              formattedDate = '${date.day}/${date.month}/${date.year}';
            }
          } catch (e) {
            formattedDate = reviewMap['created_at']?.toString() ?? '';
          }
        }
        
        formattedReviews.add({
          'id': reviewMap['id'],
          'userName': reviewMap['user_name'] ?? reviewMap['name'] ?? 'Anonymous',
          'rating': double.tryParse(reviewMap['rating']?.toString() ?? '0') ?? 0.0,
          'comment': reviewMap['comment'] ?? reviewMap['review'] ?? reviewMap['title'] ?? '',
          'date': formattedDate,
          'images': reviewMap['images'] is List ? reviewMap['images'] : [],
          'title': reviewMap['title'] ?? '',
          'status': reviewMap['status'] ?? 'approved', // Include status for pending reviews
          'like_count': reviewMap['like_count'] ?? 0,
          'is_liked': reviewMap['is_liked'] ?? false,
        });
      }
      
      // Update reviews list and trigger UI refresh
      print('[LoadReviews] Formatted ${formattedReviews.length} reviews');
      print('[LoadReviews] Before update: ${reviews.length} reviews in list');
      
      // Update reviews list - use assignment to trigger Obx
      reviews.value = formattedReviews;
      // Force refresh to ensure UI updates
      reviews.refresh();
      
      print('[LoadReviews] After update: ${reviews.length} reviews in list');
      for (var i = 0; i < reviews.length; i++) {
        print('[LoadReviews] Review $i: ID=${reviews[i]['id']}, User=${reviews[i]['userName']}, Status=${reviews[i]['status']}');
      }
      
      // Force controller update to trigger UI rebuild
      update();
    } catch (e) {
      print('Error loading reviews: $e');
      reviews.value = [];
      reviews.refresh(); // Force UI update even on error
    }
  }
  
  /// Like/Unlike review
  Future<void> toggleReviewLike(int reviewId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.reviewLike,
        data: {'review_id': reviewId},
      );
      final data = ApiService.handleResponse(response);
      
      // Update review in list
      final reviewIndex = reviews.indexWhere((r) => r['id'] == reviewId);
      if (reviewIndex != -1) {
        reviews[reviewIndex]['is_liked'] = data['is_liked'] ?? false;
        reviews[reviewIndex]['like_count'] = data['like_count'] ?? 0;
        reviews.refresh();
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Report review
  Future<void> reportReview(int reviewId, String reason, {String? description}) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.reviewReport,
        data: {
          'review_id': reviewId,
          'reason': reason,
          if (description != null) 'description': description,
        },
      );
      ApiService.handleResponse(response);
      
      // Get.snackbar(
      //   'Success',
      //   'Review reported. Our team will review it.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: AppColors.success.withOpacity(0.9),
      //   colorText: AppColors.textWhite,
      // );
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Load related products
  Future<void> loadRelatedProducts(int categoryId, int excludeProductId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.productsList,
        queryParameters: {
          'category_id': categoryId.toString(),
          'limit': '4',
          'exclude_id': excludeProductId.toString(),
        },
      );
      final data = ApiService.handleResponse(response);
      final productsList = data['products'] ?? [];
      
      relatedProducts.value = productsList.map((p) => {
        'id': p['id'],
        'name': p['name'] ?? '',
        'price': double.tryParse(p['price']?.toString() ?? '0') ?? 0.0,
        'image': _getImageUrl(p['image'] ?? p['main_image'] ?? ''),
        'rating': double.tryParse(p['rating']?.toString() ?? '0') ?? 0.0,
      }).toList();
    } catch (e) {
      relatedProducts.value = [];
    }
  }
  
  /// Increase quantity
  void increaseQuantity() {
    if (product != null && quantity.value < (product!['stock'] ?? 99)) {
      quantity.value++;
    }
  }
  
  /// Decrease quantity
  void decreaseQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }
  
  /// Check wishlist status for product
  void _checkWishlistStatus(int productId) {
    try {
      final wishlistController = GetXRegistry.findOrNull<WishlistController>();
      if (wishlistController != null) {
        isFavorite.value = wishlistController.isInWishlist(productId);
      }
    } catch (e) {
      // If wishlist controller not available, default to false
      isFavorite.value = false;
    }
  }
  
  /// Toggle favorite (add/remove from wishlist) - Optimistic update for instant response
  Future<void> toggleFavorite() async {
    if (product == null) return;
    
    // Optimistic update - change UI immediately
    final previousState = isFavorite.value;
    isFavorite.value = !isFavorite.value;
    
    try {
      final wishlistController = GetXRegistry.wishlist();
      
      // Make API call in background
      final success = await wishlistController.toggleWishlist(product!['id']);
      
      if (!success) {
        // Revert if API call failed
        isFavorite.value = previousState;
        // Get.snackbar('Error', 'Failed to update wishlist. Please try again.');
      } else {
        // Sync with actual state
        isFavorite.value = wishlistController.isInWishlist(product!['id']);
        
        // Show brief feedback (shorter duration for better UX)
        if (isFavorite.value) {
          Get.snackbar('', 'Added to wishlist',
            duration: const Duration(milliseconds: 1500),
            snackPosition: SnackPosition.BOTTOM,
            margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
            backgroundColor: AppColors.success.withOpacity(0.9),
            colorText: AppColors.textWhite,
          );
        } else {
          Get.snackbar('', 'Removed from wishlist',
            duration: const Duration(milliseconds: 1500),
            snackPosition: SnackPosition.BOTTOM,
            margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
            backgroundColor: AppColors.textSecondary.withOpacity(0.9),
            colorText: AppColors.textWhite,
          );
        }
      }
    } catch (e) {
      // Revert on error
      isFavorite.value = previousState;
      // Get.snackbar('Error', 'Failed to update wishlist. Please try again.');
    }
  }
  
  /// Select size
  void selectSize(int index) {
    selectedSizeIndex.value = index;
  }
  
  /// Select color
  void selectColor(int index) {
    selectedColorIndex.value = index;
  }
  
  // Loading state for add to cart
  final RxBool isAddingToCart = false.obs;
  
  /// Add to cart
  Future<void> addToCart() async {
    if (product == null) return;
    
    // Show loading state
    isAddingToCart.value = true;
    
    try {
      final cartController = GetXRegistry.cart();
      
      // Get selected size and color
      String? size;
      String? color;
      if (product!['sizes'] != null && product!['sizes'] is List) {
        final sizes = product!['sizes'] as List;
        if (selectedSizeIndex.value < sizes.length) {
          size = sizes[selectedSizeIndex.value]?.toString();
        }
      }
      if (product!['colors'] != null && product!['colors'] is List) {
        final colors = product!['colors'] as List;
        if (selectedColorIndex.value < colors.length) {
          final colorData = colors[selectedColorIndex.value];
          if (colorData is Map) {
            color = colorData['name']?.toString();
          } else {
            color = colorData?.toString();
          }
        }
      }
      
      // Add to cart (digital = always 1)
      final qty = product!['is_digital'] == true ? 1 : quantity.value;
      final success = await cartController.addToCart(
        productId: product!['id'],
        quantity: qty,
        size: size,
        color: color,
      );
      
      if (success) {
        // Get formatted image URL
        String imageUrl = '';
        if (product!['images'] != null && (product!['images'] as List).isNotEmpty) {
          imageUrl = (product!['images'] as List)[0] ?? '';
        } else if (product!['image'] != null) {
          imageUrl = _getImageUrl(product!['image'].toString());
        }
        
        // Show beautiful success bottom sheet
        Get.bottomSheet(
          AddToCartSuccessSheet(
            product: {
              'id': product!['id'],
              'name': product!['name'] ?? 'Product',
              'image': imageUrl,
              'price': product!['price'] ?? 0,
              'sale_price': product!['sale_price'] ?? product!['price'] ?? 0,
            },
            quantity: qty,
          ),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          enableDrag: true,
        );
      }
    } catch (e) {
      // Get.snackbar(
      //   'Error',
      //   'Failed to add product to cart. Please try again.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: AppColors.error.withOpacity(0.9),
      //   colorText: AppColors.textWhite,
      // );
    } finally {
      isAddingToCart.value = false;
    }
  }
  
  /// Buy now
  Future<void> buyNow() async {
    if (product == null) return;
    
    // Check if user is logged in
    if (!CacheManager.isLoggedIn()) {
      // Get.snackbar(
      //   'Login Required',
      //   'Please login to proceed with checkout',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      // Navigate to login
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.toLogin();
      return;
    }
    
    final cartController = GetXRegistry.cart();
    
    // Get selected size and color
    String? size;
    String? color;
    if (product!['sizes'] != null && product!['sizes'] is List) {
      final sizes = product!['sizes'] as List;
      if (selectedSizeIndex.value < sizes.length) {
        size = sizes[selectedSizeIndex.value]?.toString();
      }
    }
    if (product!['colors'] != null && product!['colors'] is List) {
      final colors = product!['colors'] as List;
      if (selectedColorIndex.value < colors.length) {
        final colorData = colors[selectedColorIndex.value];
        if (colorData is Map) {
          color = colorData['name']?.toString();
        } else {
          color = colorData?.toString();
        }
      }
    }
    
    // Add to cart first (digital = always 1)
    final qty = product!['is_digital'] == true ? 1 : quantity.value;
    final success = await cartController.addToCart(
      productId: product!['id'],
      quantity: qty,
      size: size,
      color: color,
    );
    
    if (success) {
      // Navigate to checkout
      cartController.navigateToCheckout();
    }
  }

  /// From preview "Pay & Download": cart = only this product, go to checkout → Stripe. No address needed (digital-only).
  Future<void> goToPayDigitalProduct() async {
    if (product == null) return;
    if (!CacheManager.isLoggedIn()) {
      // Get.snackbar('Login Required', 'Please login to proceed with payment');
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.toLogin();
      return;
    }
    final cartController = GetXRegistry.cart();
    await cartController.clearCart();
    final success = await cartController.addToCart(
      productId: product!['id'],
      quantity: 1,
      size: null,
      color: null,
    );
    if (success) {
      final quickPayAmount = double.tryParse((product!['price'] ?? 0).toString()) ?? 0.0;
      final payResult = await AppRoutes.open(
        AppRoutes.digitalPayRedirect,
        arguments: {
          'digital_quick_pay': true,
          'quick_pay_amount': quickPayAmount,
        },
      );
      if (payResult is Map && payResult['success'] == true) {
        final oid = payResult['order_item_id'];
        final orderItemId = oid is int
            ? oid
            : int.tryParse(oid?.toString() ?? '');
        await applyDigitalPurchase(orderItemId: orderItemId);
      }
      refreshDigitalPurchaseStatus();
    } else {
      // Get.snackbar('Error', 'Could not add product. Please try again.');
    }
  }

  /// Write review - Shows review dialog
  void writeReview() {
    if (product == null) {
      // Get.snackbar('Error', 'Product information not available');
      return;
    }
    
    // Check if user is logged in
    // Note: You may need to import CacheManager to check login status
    // For now, we'll let the API handle authentication
    
    Get.dialog(
      ReviewDialogWithCallback(
        productId: product!['id'] as int,
        productName: product!['name'] ?? 'Product',
        onSubmit: (rating, title, comment) async {
          return await submitReview(
            product!['id'] as int,
            rating,
            title,
            comment,
          );
        },
      ),
    );
  }
  
  /// Submit review to API
  Future<bool> submitReview(int productId, int rating, String title, String comment) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createReview,
        data: {
          'product_id': productId,
          'rating': rating,
          'title': title,
          'comment': comment,
        },
      );
      
      // Get message from response before handleResponse (which only returns data)
      String successMessage = 'Review submitted successfully. It will be published after approval.';
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        successMessage = responseData['message'] ?? successMessage;
      }
      
      // Process response (data not needed, only message is used)
      ApiService.handleResponse(response);
      
      // Show success message
      Get.snackbar(
        'Success',
        successMessage,
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        duration: const Duration(seconds: 3),
      );
      
      // Reload reviews to show the updated/new review immediately
      if (product != null) {
        // Reload reviews immediately - don't wait for dialog to close
        // The dialog will close on its own
        try {
          print('[SubmitReview] Reloading reviews immediately...');
          await loadReviews(productId);
          print('[SubmitReview] Reviews reloaded successfully, count: ${reviews.length}');
          // Print all review IDs to debug
          for (var review in reviews) {
            print('[SubmitReview] Review ID: ${review['id']}, User: ${review['userName']}, Status: ${review['status']}');
          }
        } catch (e) {
          print('[SubmitReview] Error reloading reviews: $e');
          // Don't show error to user, just log it
        }
      }
      
      return true;
    } catch (e) {
      final errorMessage = ApiService.handleError(e);
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  /// Play purchased digital product (audio/video) - Same as order details functionality
  /// Uses orderItemId to get download URL and opens full player
  Future<void> playPurchasedDigitalProduct(int orderItemId, String productName, String? productImageUrl) async {
    print('[ProductController] playPurchasedDigitalProduct orderItemId=$orderItemId');

    final isAudio = DigitalProductType.isAudio(product) ||
        productName.toLowerCase().contains('audio') ||
        productName.toLowerCase().contains('mp3');

    if (isAudio) {
      Get.to(() => FullAudioPlayerScreen(
        audioUrl: '',
        orderItemId: orderItemId,
        filePath: '',
        productName: productName,
        productImageUrl: productImageUrl,
      ));
      return;
    }

    Get.to(() => FullVideoPlayerScreen(
      videoUrl: '',
      orderItemId: orderItemId,
      filePath: '',
      productName: productName,
      productImageUrl: productImageUrl,
    ));
  }

  /// Get secure download URL for a digital product order item
  /// Lifetime access – user can download anytime from My Orders.
  Future<String?> getDigitalDownloadUrl(int orderItemId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderDownload,
        queryParameters: {'order_item_id': orderItemId.toString()},
      );
      final data = ApiService.handleResponse(response);
      final downloadUrl = data['download_url'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        print('[ProductController] No download_url in response for orderItemId=$orderItemId');
        return null;
      }
      return downloadUrl;
    } catch (e) {
      print('[ProductController] Error getting download URL: $e');
      return null;
    }
  }
}

