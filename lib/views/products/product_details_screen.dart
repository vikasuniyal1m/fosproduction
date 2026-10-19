import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../services/api_endpoints.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../utils/getx_registry.dart';
import '../../routes/app_routes.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/silent_loading.dart';
import '../../utils/digital_product_type.dart';
import '../../widgets/stable_cached_image.dart';
import '../../utils/product_details_navigation.dart';
import '../../services/media_preview_pool.dart';
import '../../widgets/video_preview_widget.dart';
import '../../widgets/cached_video_preview_widget.dart';
import '../../widgets/cached_audio_preview_widget.dart';
import 'digital_preview_player_screen.dart';

/// Product Details Screen
/// Shows product details, images, reviews, and related products
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductController controller = GetXRegistry.product();
  bool _isDownloading = false;
  bool _hasShownPurchasePrompt = false; // Flag to prevent multiple popup calls
  int? _warmedStickerProductId;
  dynamic _lastStickerProductId;
  PageController? _stickerHeroPageController;
  String? _stickerHeroSig;
  Worker? _stickerWarmWorker;

  @override
  void initState() {
    super.initState();
    _hasShownPurchasePrompt = false;
    _stickerWarmWorker = ever(controller.productObs, (p) {
      final id = p?['id'];
      if (id != _lastStickerProductId) {
        _lastStickerProductId = id;
        _warmedStickerProductId = null;
        _stickerHeroSig = null;
        _stickerHeroPageController?.dispose();
        _stickerHeroPageController = null;
        controller.selectedStickerIndex.value = 0;
      }
      _scheduleStickerWarmCache();
    });
  }

  String _stickerImageCacheKey(dynamic productId, String url) {
    final normalized = url.trim();
    final hash =
        sha256.convert(utf8.encode(normalized)).toString().substring(0, 16);
    return 'sticker_p${productId}_$hash';
  }

  ImageProvider _stickerImageProvider(dynamic productId, String url) {
    return CachedNetworkImageProvider(
      url,
      cacheKey: _stickerImageCacheKey(productId, url),
    );
  }

  void _scheduleStickerWarmCache() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _warmStickerImageCache();
    });
  }

  void _warmStickerImageCache() {
    final product = controller.product;
    if (product == null ||
        !DigitalProductType.isStickerPack(product)) {
      return;
    }
    final productId = product['id'];
    if (productId == _warmedStickerProductId) return;
    _warmedStickerProductId = productId is int
        ? productId
        : int.tryParse(productId?.toString() ?? '');

    final purchased = controller.digitalHasPurchased.value;
    final unlocked = _unlockedStickers(controller, purchased);
    final all = _stickerItems(controller);
    final ordered = [
      ...unlocked,
      ...all.where(
        (s) => !unlocked.any(
          (u) => u['image_url']?.toString() == s['image_url']?.toString(),
        ),
      ),
    ];
    for (final sticker in ordered) {
      final url = sticker['image_url']?.toString() ?? '';
      if (url.isEmpty) continue;
      precacheImage(_stickerImageProvider(productId, url), context);
    }
  }

  @override
  void dispose() {
    _stickerWarmWorker?.dispose();
    _stickerHeroPageController?.dispose();
    _stickerHeroPageController = null;
    _stickerHeroSig = null;
    _warmedStickerProductId = null;
    _hasShownPurchasePrompt = false;
    super.dispose();
  }

  List<Map<String, dynamic>> _stickerItems(ProductController c) {
    final raw = c.product?['stickers_preview'] as List? ?? [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  bool _isStickerUnlocked(Map<String, dynamic> sticker, bool purchased) =>
      purchased || sticker['is_preview'] == true;

  List<Map<String, dynamic>> _unlockedStickers(
    ProductController c,
    bool purchased,
  ) =>
      _stickerItems(c).where((s) => _isStickerUnlocked(s, purchased)).toList();

  void _selectStickerPreview(
    ProductController c,
    Map<String, dynamic> sticker,
    bool purchased,
  ) {
    if (!_isStickerUnlocked(sticker, purchased)) return;
    final unlocked = _unlockedStickers(c, purchased);
    final idx = unlocked.indexWhere(
      (s) => s['image_url']?.toString() == sticker['image_url']?.toString(),
    );
    if (idx < 0) return;
    c.selectedStickerIndex.value = idx;
    if (_stickerHeroPageController?.hasClients == true) {
      _stickerHeroPageController!.jumpToPage(idx);
    }
  }

  PageController _stickerHeroController(
    int productId,
    int itemCount,
    bool purchased,
  ) {
    final safeCount = itemCount < 1 ? 1 : itemCount;
    final initial =
        controller.selectedStickerIndex.value.clamp(0, safeCount - 1);
    final sig = '${productId}_${safeCount}_$purchased';
    if (_stickerHeroSig != sig || _stickerHeroPageController == null) {
      _stickerHeroPageController?.dispose();
      _stickerHeroPageController = PageController(initialPage: initial);
      _stickerHeroSig = sig;
    }
    return _stickerHeroPageController!;
  }

  Widget _stickerImage(
    String imageUrl,
    dynamic productId, {
    BoxFit fit = BoxFit.contain,
    bool isThumb = false,
  }) {
    final normalized = imageUrl.trim();
    return Image(
      key: ValueKey(_stickerImageCacheKey(productId, normalized)),
      image: _stickerImageProvider(productId, normalized),
      fit: fit,
      gaplessPlayback: !isThumb,
      filterQuality: isThumb ? FilterQuality.low : FilterQuality.medium,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: AppColors.backgroundGrey,
        child: Icon(Icons.sticky_note_2, color: AppColors.textTertiary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: ScreenSize.buttonHeightLarge,
          automaticallyImplyLeading: false,
          title: Text(
            'Product Details',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              color: AppColors.textWhite,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, 
                      size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : ScreenSize.iconMedium,
                      color: AppColors.textWhite),
            onPressed: () => Get.back(),
          ),
          actions: [
            if (!_isDigitalProduct(controller))
              Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: IconButton(
                  key: ValueKey(controller.isFavorite.value),
                  icon: Icon(
                    controller.isFavorite.value ? Icons.favorite : Icons.favorite_border,
                    color: controller.isFavorite.value ? AppColors.accent : AppColors.textWhite,
                    size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : ScreenSize.iconMedium,
                  ),
                  onPressed: controller.toggleFavorite,
                ),
              )),
            IconButton(
              icon: Icon(Icons.share, 
                        size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : ScreenSize.iconMedium,
                        color: AppColors.textWhite),
              onPressed: () => _shareProduct(controller),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              Obx(() {
                if (controller.productObs.value == null) {
                  return const SizedBox.shrink();
                }
                return CustomScrollView(
            slivers: [
              // Product Image Carousel
              SliverToBoxAdapter(
                child: _buildImageCarousel(controller),
              ),

              // Product Info
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name & Price
                    _buildProductHeader(controller),

                    // Stock Status & Discount Badge
                    _buildProductBadges(controller),
                    SizedBox(height: ScreenSize.spacingSmall),

                    // Digital product: list music, preview 5–10 sec, pay for lifetime download
                    if (_isDigitalProduct(controller)) ...[
                      _buildDigitalProductSection(controller),
                      SizedBox(height: ScreenSize.spacingSmall),
                    ],

                    // Size Selection
                    if (controller.product!['sizes'] != null &&
                        (controller.product!['sizes'] as List).isNotEmpty)
                      _buildSizeSelection(controller),

                    // Color Selection
                    if (controller.product!['colors'] != null &&
                        (controller.product!['colors'] as List).isNotEmpty)
                      _buildColorSelection(controller),

                    // Quantity & Price Row (no quantity for digital – always 1)
                    _buildQuantityAndPrice(controller),
                    SizedBox(height: ScreenSize.spacingSmall),

                    // Shipping & Return Info (only for physical products)
                    if (!_isDigitalProduct(controller)) ...[
                      _buildShippingInfo(controller),
                      SizedBox(height: ScreenSize.spacingSmall),
                    ],
                  ],
                ),
              ),

              // Professional Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _ProductDetailsTabDelegate(
                  child: Container(
                    color: AppColors.background,
                    child: _buildProductTabs(controller),
                  ),
                ),
              ),

              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  children: [
                    _buildTabContent1(controller),
                    _buildTabContent2(controller),
                    _buildTabContent3(controller),
                  ],
                ),
              ),
            ],
          );
              }),
              Obx(() {
                if (!controller.isLoading.value ||
                    controller.productObs.value != null) {
                  return const SizedBox.shrink();
                }
                return const ColoredBox(
                  color: AppColors.background,
                  child: LoadingWidget(),
                );
              }),
            ],
          ),
        ),
        bottomNavigationBar: Obx(() => _buildBottomBar(controller)),
      ),
    );
  }

  Widget _buildTabContent1(ProductController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          _buildDescription(controller),
          SizedBox(height: ScreenSize.spacingSmall),
          // Specifications
          _buildSpecifications(controller),
        ],
      ),
    );
  }

  Widget _buildTabContent2(ProductController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: _buildReviewsSection(controller),
    );
  }

  Widget _buildTabContent3(ProductController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: _buildRelatedProducts(controller),
    );
  }

  Widget _buildProductTabs(ProductController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.3), width: 1)),
      ),
      child: TabBar(
        tabs: [
          Tab(
            child: Text(
              'Description',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : ScreenSize.textSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Tab(
            child: Text(
              'Reviews',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : ScreenSize.textSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Tab(
            child: Text(
              'Related',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : ScreenSize.textSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : ScreenSize.textSmall,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : ScreenSize.textSmall,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingSmall),
      ),
    );
  }

  Widget _buildImageCarousel(ProductController controller) {
    final height = ScreenSize.screenWidth >= 1000
        ? ScreenSize.heightPercent(45)
        : (ScreenSize.screenWidth >= 768 ? ScreenSize.heightPercent(40) : ScreenSize.heightPercent(35));

    if (DigitalProductType.isStickerPack(controller.product) &&
        _stickerItems(controller).isNotEmpty) {
      return _buildStickerHeroCarousel(controller, height);
    }
    
    return Obx(() {
      final playbackUrl = controller.playbackVideoUrl;
      final isDigitalVideo = _isDigitalProduct(controller) &&
          DigitalProductType.isVideo(controller.product!) &&
          playbackUrl != null &&
          playbackUrl.isNotEmpty;
      final durationSeconds = controller.digitalPreviewDurationSeconds.value;
      
      if (isDigitalVideo) {
        final productId = controller.product?['id'] ?? 0;
        return SizedBox(
          height: height,
          child: _DigitalVideoTopArea(
            key: ValueKey('dv_${productId}_$playbackUrl'),
            previewUrl: playbackUrl,
            durationSeconds: durationSeconds,
            onPayPressed: () => controller.goToPayDigitalProduct(),
            isPurchased: controller.digitalHasPurchased.value,
          ),
        );
      }

      final images = controller.product!['images'] as List? ?? [];
      final imageCount = images.isEmpty ? 1 : images.length;

      return SizedBox(
        height: height,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: imageCount,
              onPageChanged: (index) {
                controller.selectedImageIndex.value = index;
              },
              itemBuilder: (context, index) {
                final product = controller.product!;
                final isDigital = product['is_digital'] == true || product['is_digital'] == 1;
                final mediaType = (product['media_type']?.toString() ?? controller.digitalPreviewMediaType.value).toLowerCase();
                final isVideo = isDigital && (mediaType == 'video' || _isVideoByDigitalPath(product));
                final isAudio = isDigital && mediaType == 'audio';

                // Fallback: detect audio by file extension if media_type is not set
                final digitalFilePath = product['digital_file_path']?.toString() ?? '';
                final isAudioByExtension = digitalFilePath.toLowerCase().contains('.mp3') ||
                                           digitalFilePath.toLowerCase().contains('.wav') ||
                                           digitalFilePath.toLowerCase().contains('.m4a') ||
                                           digitalFilePath.toLowerCase().contains('.aac');
                final finalIsAudio = isAudio || (isDigital && isAudioByExtension);

                print('[ProductDetails] isDigital: $isDigital, mediaType: $mediaType, isAudio: $isAudio, isAudioByExtension: $isAudioByExtension, finalIsAudio: $finalIsAudio');

                if (isVideo && index == 0) {
                  final playbackUrl = controller.playbackVideoUrl;
                  if (playbackUrl != null && playbackUrl.isNotEmpty) {
                    return Container(
                      color: Colors.black,
                      child: _buildVideoPlayer(playbackUrl, controller),
                    );
                  }
                }

                // Images / banner when no playable video URL yet
                final imageUrl = images.isNotEmpty
                    ? (images[index] is String ? images[index] : images[index]?.toString() ?? '')
                    : controller.product!['image']?.toString() ?? '';
                final url = imageUrl.toString().trim();
                return ColoredBox(
                  color: Colors.white,
                  child: url.isEmpty
                      ? Center(
                          child: Icon(
                            isVideo ? Icons.videocam : (finalIsAudio ? Icons.audiotrack : Icons.image_not_supported),
                            size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconExtraLarge :
                                   (ScreenSize.screenWidth >= 768 ? ScreenSize.iconLarge : ScreenSize.iconExtraLarge),
                            color: AppColors.textTertiary,
                          ),
                        )
                      : finalIsAudio
                          ? _buildAudioPlayer(url, product, controller)
                          : SizedBox.expand(
                              child: StableCachedImage(
                                imageUrl: url,
                                cacheKey:
                                    'detail_${controller.product!['id']}_$index',
                                fit: BoxFit.contain,
                                placeholderColor: Colors.white,
                                errorIconSize:
                                    ScreenSize.screenWidth >= 1000
                                        ? ScreenSize.iconExtraLarge
                                        : (ScreenSize.screenWidth >= 768
                                            ? ScreenSize.iconLarge
                                            : ScreenSize.iconExtraLarge),
                              ),
                            ),
                );
              },
            ),
            // Image indicators
            if (controller.product!['images'] != null && 
                (controller.product!['images'] as List).length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Builder(
                  builder: (context) {
                    final images = controller.product!['images'] as List? ?? [];
                    final imageCount = images.isEmpty ? 1 : images.length;
                    if (imageCount <= 1) return const SizedBox.shrink();
                    return Obx(() {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(imageCount, (index) {
                            final isSelected = controller.selectedImageIndex.value == index;
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: ScreenSize.spacingTiny),
                              width: ScreenSize.screenWidth >= 1000 ? 24 : (ScreenSize.screenWidth >= 768 ? 22 : 20),
                              height: ScreenSize.screenWidth >= 1000 ? 8 : (ScreenSize.screenWidth >= 768 ? 7 : 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.textWhite
                                    : AppColors.textWhite.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 4 : 3),
                              ),
                            );
                          }),
                        ),
                      );
                    });
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildProductHeader(ProductController controller) {
    final product = controller.product!;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ScreenSize.spacingMedium,
        ScreenSize.spacingMedium,
        ScreenSize.spacingMedium,
        ScreenSize.spacingTiny,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product['name'] ?? '',
                  style: TextStyle(
                    fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.headingMedium : 
                           (ScreenSize.screenWidth >= 768 ? ScreenSize.headingSmall : ScreenSize.headingSmall),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingTiny),
          
          // Rating
          Row(
            children: [
              Icon(Icons.star, 
                    size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconSmall : 
                           (ScreenSize.screenWidth >= 768 ? ScreenSize.iconExtraSmall : ScreenSize.iconExtraSmall), 
                    color: AppColors.accent),
              SizedBox(width: ScreenSize.spacingTiny),
              Text(
                '${product['rating'] ?? 0.0}',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : 
                         (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 4),
              Text(
                  '(${product['reviews'] ?? 0} reviews)',
                  style: TextStyle(
                    fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : 
                           (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall),
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingTiny),
          
          // Price
          Row(
            children: [
              Text(
                '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textLarge : 
                         (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (product['originalPrice'] != null &&
                  product['originalPrice'] > product['price'])
                Padding(
                  padding: EdgeInsets.only(left: ScreenSize.spacingSmall),
                  child: Text(
                    '\$${product['originalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textExtraSmall : 
                             (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall),
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Digital product: list music, preview 5–10 sec, pay with Stripe for lifetime MP3/MP4 download.
  /// Also handles sticker packs as digital products with sticker download flow.
  Widget _buildDigitalProductSection(ProductController controller) {
    return Obx(() {
      final hasPurchased = controller.digitalHasPurchased.value;
      final previewUrl = controller.digitalPreviewUrl.value;
      final previewSec = controller.digitalPreviewDurationSeconds.value;
      final previewLoading = controller.digitalPreviewLoading.value;
      final productName = controller.product!['name'] ?? '';
      final isStickerPack =
          DigitalProductType.isStickerPack(controller.product!);
      final totalStickers = controller.product!['total_stickers'] ?? 0;

      String actualMediaType =
          DigitalProductType.resolveMediaType(controller.product!);
      if (actualMediaType == 'none' || actualMediaType == 'sticker') {
        final previewType = controller.digitalPreviewMediaType.value;
        if (previewType == 'audio' || previewType == 'video') {
          actualMediaType = previewType;
        } else if (!isStickerPack) {
          actualMediaType = previewType;
        }
      }

      // Debug print
      print('[ProductDetails] Digital product section - hasPurchased: $hasPurchased, orderItemId: ${controller.digitalOrderItemId.value}, actualMediaType: $actualMediaType');

      return Container(
        margin: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium),
        padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildDigitalProductTypeIcon(isStickerPack, controller),
              ],
            ),
            // SizedBox(height: ScreenSize.spacingSmall),
            // // List this product as the one track
            // Text(
            //   isStickerPack ? '$productName ($totalStickers stickers)' : productName,
            //   style: TextStyle(
            //     fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
            //     color: AppColors.textPrimary,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            SizedBox(height: ScreenSize.spacingSmall),

            if (isStickerPack) ...[
              if (totalStickers > 0)
                Text(
                  'This pack contains $totalStickers stickers',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (totalStickers > 0) SizedBox(height: ScreenSize.spacingSmall),
              _buildStickerPreviewCarousel(controller, hasPurchased),
              SizedBox(height: ScreenSize.spacingSmall),
            ],

            // Show lifetime access badge if purchased
            if (hasPurchased) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'Lifetime Access - You Own This',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ScreenSize.spacingSmall),
            ],

            // Preview info (only if not purchased and preview available)
            if (!hasPurchased && !isStickerPack) ...[
              if (previewUrl.isNotEmpty) ...[
                Text(
                  'Preview ($previewSec sec) – then pay to unlock & download',
                  style: TextStyle(
                    fontSize: ScreenSize.textExtraSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingSmall),
              ] else ...[
                // No preview available case
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No preview available – purchase to access full content',
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ScreenSize.spacingSmall),
              ],
            ],

            // Sticker pack info
            // if (isStickerPack) ...[
            //   Text(
            //     'This pack contains $totalStickers stickers',
            //     style: TextStyle(
            //       fontSize: ScreenSize.textSmall,
            //       color: AppColors.textPrimary,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            //   SizedBox(height: ScreenSize.spacingSmall),
            // ],

            // Loading state (skip for sticker packs that already have previews)
            if (previewLoading &&
                !(isStickerPack &&
                    _stickerItems(controller).isNotEmpty)) ...[
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading preview...',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ScreenSize.spacingSmall),
            ],

            // Download section (only if purchased)
            if (hasPurchased) ...[
              Container(
                padding: EdgeInsets.all(ScreenSize.spacingSmall),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 Download your digital product anytime:',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Download directly from product details (same as My Orders)
                    if (controller.digitalOrderItemId.value != null)
                      // ElevatedButton.icon(
                      //   onPressed: _isDownloading ? null : () => _downloadDigitalFromProductDetails(controller),
                      //   icon: _isDownloading
                      //       ? SizedBox(
                      //           width: 18,
                      //           height: 18,
                      //           child: CircularProgressIndicator(
                      //             strokeWidth: 2,
                      //             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      //           ),
                      //         )
                      //       : Icon(Icons.download, size: 18, color: Colors.white),
                      //   label: Text(
                      //     _isDownloading
                      //         ? 'Downloading...'
                      //         : (isStickerPack
                      //             ? 'Download Sticker Pack (ZIP)'
                      //             : (actualMediaType == 'audio'
                      //                 ? 'Download MP3'
                      //                 : 'Download MP4')),
                      //     style: TextStyle(fontSize: ScreenSize.textExtraSmall, color: Colors.white),
                      //   ),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: AppColors.primary,
                      //     foregroundColor: Colors.white,
                      //     minimumSize: Size(double.infinity, ScreenSize.buttonHeightSmall),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                      //     ),
                      //   ),
                      // ),

                    // Play button for audio/video products (not stickers)
                    if (!isStickerPack && controller.digitalOrderItemId.value != null) ...[
                      SizedBox(height: ScreenSize.spacingSmall),
                      ElevatedButton.icon(
                        onPressed: () => _playDigitalFromProductDetails(controller),
                        icon: Icon(
                          actualMediaType == 'audio'
                              ? Icons.play_arrow
                              : Icons.play_circle_outline,
                          size: 18,
                          color: Colors.white
                        ),
                        label: Text(
                          actualMediaType == 'audio'
                              ? 'Play Audio'
                              : 'Play Video',
                          style: TextStyle(fontSize: ScreenSize.textExtraSmall, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // Different color for play button
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, ScreenSize.buttonHeightSmall),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                          ),
                        ),
                      ),
                    ],

                    // Add to WhatsApp button for sticker packs (only if purchased)
                    if (isStickerPack && controller.digitalOrderItemId.value != null) ...[
                      SizedBox(height: ScreenSize.spacingSmall),
                      ElevatedButton.icon(
                        onPressed: () => _triggerStickerExport(controller),
                        icon: Image.asset('assets/whatsapp.png', width: 20, height: 20),
                        label: Text(
                          'Add to WhatsApp',
                          style: TextStyle(fontSize: ScreenSize.textExtraSmall, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, ScreenSize.buttonHeightSmall),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                          ),
                        ),
                      ),
                    ],

                    // Additional download info
                    SizedBox(height: 8),
                    Text(
                      '• Download as many times as you want\n• Files are saved to your device\n• Access from any page, anytime',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                isStickerPack
                    ? 'Pay once with Stripe – get access to download this sticker pack.'
                    : (actualMediaType == 'audio'
                        ? 'Pay once with Stripe – get access to download MP3.'
                        : 'Pay once with Stripe – get access to download MP4.'),
                style: TextStyle(
                  fontSize: ScreenSize.textExtraSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              // For video products, show reply button next to pay button
              if (actualMediaType == 'video')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.goToPayDigitalProduct(),
                        icon: Icon(Icons.payment, size: 18, color: Colors.white),
                        label: Text(
                          'Pay with stripe - Unlock Download',
                          style: TextStyle(fontSize: ScreenSize.textSmall, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    // SizedBox(width: 8),
                    // Expanded(
                    //   child: ElevatedButton.icon(
                    //     onPressed: () {
                    //       // Replay the preview
                    //       _hasShownPurchasePrompt = false;
                    //       setState(() {});
                    //     },
                    //     icon: Icon(Icons.replay, size: 18, color: Colors.white),
                    //     label: Text(
                    //       'Reply',
                    //       style: TextStyle(fontSize: ScreenSize.textSmall, color: Colors.white, fontWeight: FontWeight.w600),
                    //     ),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.orange,
                    //       foregroundColor: Colors.white,
                    //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    //       minimumSize: Size.zero,
                    //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //     ),
                    //   ),
                    // ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: () => controller.goToPayDigitalProduct(),
                  icon: Icon(Icons.payment, size: 18, color: Colors.white),
                  label: Text(
                    'Pay with Stripe – unlock download',
                    style: TextStyle(fontSize: ScreenSize.textSmall, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }

  static String _downloadLocationMessage(String savePath) {
    // Return the full exact file path so the user can easily locate it manually.
    return savePath.replaceAll(r'\', '/');
  }

  /// Check if a valid sticker ZIP already exists for this product
  Future<bool> _checkStickerFileExists(ProductController controller) async {
    final orderItemId = controller.digitalOrderItemId.value;
    if (orderItemId == null) return false;
    final productName = controller.product?['name']?.toString() ?? 'Sticker Pack';
    final productId = controller.product?['id'] is int
        ? controller.product!['id'] as int
        : int.tryParse(controller.product?['id']?.toString() ?? '');
    final profileController = GetXRegistry.profile();
    final path = await profileController.findValidStickerZipPath(
      productName: productName,
      productId: productId,
      orderItemId: orderItemId,
    );
    return path != null && path.isNotEmpty;
  }

  /// Download digital product to device from product details (same flow as My Orders).
  /// Handles both regular digital products and sticker packs.
  Future<void> _downloadDigitalFromProductDetails(ProductController controller) async {
    // Set loading state
    setState(() {
      _isDownloading = true;
    });
    
    final orderItemId = controller.digitalOrderItemId.value;
    if (orderItemId == null) {
      Get.snackbar('Error', 'Download not available. Try from My Orders.', snackPosition: SnackPosition.BOTTOM);
      setState(() {
        _isDownloading = false;
      });
      return;
    }
    final productName = controller.product?['name']?.toString() ?? 'Digital product';
    final isStickerPack = controller.product?['is_sticker_pack'] == true;
    final productId = controller.product?['id'];
    
    final profileController = Get.put(ProfileController());

    // For stickers, use sticker download API
    // For stickers, use the unified digital download API which automatically generates a zip
    if (isStickerPack) {
      try {
        final savePath = await profileController.downloadDigitalProductToDevice(
          orderItemId,
          productName,
        );
        if (savePath != null && savePath.isNotEmpty) {
          try {
            await profileController.unzipAndSaveStickersToGallery(
              savePath,
              productName,
            );
          } catch (e) {
            debugPrint('[ProductDetails] Auto-unzip failed: $e');
          }
          final location = _downloadLocationMessage(savePath);
          Get.snackbar(
            'Download complete',
            'File saved at:\n$location',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: AppColors.textWhite,
            duration: const Duration(seconds: 10),
            margin: const EdgeInsets.all(12),
          );
        }
        return;
      } catch (e) {
        debugPrint('[ProductDetails] Sticker download failed: $e');
        Get.snackbar(
          'Error',
          'Failed to download sticker pack: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        setState(() => _isDownloading = false);
      }
    }

    // For regular digital products (MP3/MP4)
    try {
      final savePath = await profileController.downloadDigitalProductToDevice(orderItemId, productName);
      if (savePath != null && savePath.isNotEmpty) {
        final location = _downloadLocationMessage(savePath);
        Get.snackbar(
          'Download complete',
          'File explicitly saved at:\n$location\n\nYou can access it through your device storage.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 10),
          margin: const EdgeInsets.all(12),
        );
      }
    } catch (e) {
      debugPrint('[ProductDetails] Download to device failed: $e');
      final url = await profileController.getDigitalDownloadUrl(orderItemId);
      if (url != null && url.isNotEmpty) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            Get.snackbar('Opened in browser', 'You can download from there.', snackPosition: SnackPosition.BOTTOM);
          }
        } catch (_) {
          Get.snackbar('Error', 'Failed to download: $e');
        }
      } else {
        Get.snackbar('Error', 'Failed to download: $e');
      }
    } finally {
      // Remove loading state
      setState(() {
        _isDownloading = false;
      });
    }
  }

  /// Trigger sticker export (unzip + WhatsApp) for already-purchased sticker packs.
  /// Looks for the ZIP file in the DigitalDownloads folder.
  Future<void> _triggerStickerExport(ProductController controller) async {
    final productName = controller.product?['name']?.toString() ?? 'Sticker Pack';
    final profileController = Get.find<ProfileController>();

    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/DigitalDownloads');
    final safeName = productName.replaceAll(RegExp(r'[^\w\s\-.]'), '_').replaceAll(RegExp(r'\s+'), '_');
    final fileName = '${safeName}_Stickers.zip';
    final savePath = '${downloadDir.path}/$fileName';

    if (File(savePath).existsSync()) {
      debugPrint('[ProductDetails] Existing ZIP found at $savePath. Triggering export...');
      await profileController.unzipAndSaveStickersToGallery(savePath, productName);
    } else {
      debugPrint('[ProductDetails] ZIP not found at $savePath. Re-downloading...');
      await _downloadDigitalFromProductDetails(controller);
    }
  }

  /// Share sticker pack to all social media apps (WhatsApp, Instagram, Facebook, etc.)
  /// Uses the system's native share sheet to show all available apps.
  Future<void> _shareStickerPackToAllApps(ProductController controller) async {
    final productName = controller.product?['name']?.toString() ?? 'Sticker Pack';
    final profileController = GetXRegistry.profile();
    final productId = controller.product?['id'] is int
        ? controller.product!['id'] as int
        : int.tryParse(controller.product?['id']?.toString() ?? '');
    final orderItemId = controller.digitalOrderItemId.value;
    if (orderItemId == null) {
      Get.snackbar('Error', 'Download not available', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final savePath = await profileController.ensureValidStickerZip(
      orderItemId: orderItemId,
      productName: productName,
      productId: productId,
    );
    if (savePath == null || savePath.isEmpty) {
      Get.snackbar('Error', 'Could not find sticker pack file to share',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    try {
      debugPrint('[ProductDetails] Sharing sticker pack from $savePath');
      
      // Use Share.shareXFiles to open the system share sheet with all available apps
      await Share.shareXFiles(
        [XFile(savePath)],
        text: 'Check out this sticker pack: $productName!',
        subject: 'Sticker Pack: $productName',
      );
      
      debugPrint('[ProductDetails] Share sheet opened successfully');
    } catch (e) {
      debugPrint('[ProductDetails] Error sharing sticker pack: $e');
      Get.snackbar('Error', 'Failed to share: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Play digital product (audio/video) from product details - Same as order details
  Future<void> _playDigitalFromProductDetails(ProductController controller) async {
    final orderItemId = controller.digitalOrderItemId.value;
    if (orderItemId == null) {
      return;
    }

    final productName =
        controller.product?['name']?.toString() ?? 'Digital product';
    final productImageUrl = controller.product?['images']?.isNotEmpty == true
        ? controller.product!['images'][0]
        : controller.product?['image']?.toString();

    await controller.playPurchasedDigitalProduct(
      orderItemId,
      productName,
      productImageUrl,
    );
  }

  /// Open in-app preview: for video show product photo + 10 sec timer; for audio play clip. Then pay & download popup.
  void _openInAppPreview(ProductController controller) {
    final url = controller.digitalPreviewUrl.value;
    if (url.isEmpty) {
      Get.snackbar('Error', 'Preview not available');
      return;
    }
    String? productImageUrl;
    final images = controller.product?['images'] as List?;
    if (images != null && images.isNotEmpty) {
      productImageUrl = images[0] is String ? images[0] as String : images[0]?.toString();
    }
    if (productImageUrl == null || productImageUrl.isEmpty) {
      productImageUrl = controller.product?['image']?.toString();
    }
    Get.to(
      () => DigitalPreviewPlayerScreen(
        previewUrl: url,
        mediaType: controller.digitalPreviewMediaType.value,
        durationSeconds: controller.digitalPreviewDurationSeconds.value,
        onPayPressed: () => controller.goToPayDigitalProduct(),
        productName: controller.product?['name']?.toString(),
        productImageUrl: productImageUrl,
      ),
    );
  }

  Widget _buildStickerHeroPage(
    Map<String, dynamic> sticker,
    int productId,
  ) {
    final imageUrl = sticker['image_url']?.toString() ?? '';
    return ColoredBox(
      key: ValueKey(_stickerImageCacheKey(productId, imageUrl)),
      color: Colors.white,
      child: imageUrl.isEmpty
          ? Center(
              child: Icon(Icons.sticky_note_2,
                  size: 48, color: AppColors.textTertiary),
            )
          : SizedBox.expand(
              child: _stickerImage(imageUrl, productId, fit: BoxFit.contain),
            ),
    );
  }

  /// Large hero preview — only unlocked stickers, synced with bottom carousel.
  Widget _buildStickerHeroCarousel(ProductController controller, double height) {
    return Obx(() {
      final hasPurchased = controller.digitalHasPurchased.value;
      final unlocked = _unlockedStickers(controller, hasPurchased);
      if (unlocked.isEmpty) {
        return SizedBox(
          height: height,
          child: ColoredBox(
            color: AppColors.backgroundGrey,
            child: Center(
              child: Icon(Icons.sticky_note_2,
                  size: 48, color: AppColors.textTertiary),
            ),
          ),
        );
      }

      final productId = controller.product?['id'] is int
          ? controller.product!['id'] as int
          : int.tryParse(controller.product?['id']?.toString() ?? '0') ?? 0;
      final pageController =
          _stickerHeroController(productId, unlocked.length, hasPurchased);
      final selected = controller.selectedStickerIndex.value
          .clamp(0, unlocked.length - 1);

      _scheduleStickerWarmCache();

      return SizedBox(
        height: height,
        child: Stack(
          children: [
            RepaintBoundary(
              child: PageView(
                controller: pageController,
                onPageChanged: (i) =>
                    controller.selectedStickerIndex.value = i,
                children: [
                  for (var i = 0; i < unlocked.length; i++)
                    _buildStickerHeroPage(unlocked[i], productId),
                ],
              ),
            ),
            if (unlocked.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(unlocked.length, (i) {
                    return Container(
                      width: i == selected ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == selected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Horizontal sticker carousel — tap unlocked preview to show on top.
  Widget _buildStickerPreviewCarousel(
    ProductController controller,
    bool hasPurchased,
  ) {
    final stickers = _stickerItems(controller);
    if (stickers.isEmpty) return const SizedBox.shrink();

    final unlockedCount = _unlockedStickers(controller, hasPurchased).length;
    final productId = controller.product?['id'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasPurchased
              ? 'All ${stickers.length} stickers'
              : 'Preview ($unlockedCount of ${stickers.length} unlocked — tap to view)',
          style: TextStyle(
            fontSize: ScreenSize.textExtraSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: ScreenSize.isTablet ? 88 : 72,
          child: Obx(() {
            final selectedUrl = () {
              final unlocked = _unlockedStickers(controller, hasPurchased);
              final idx = controller.selectedStickerIndex.value
                  .clamp(0, unlocked.isEmpty ? 0 : unlocked.length - 1);
              if (unlocked.isEmpty) return '';
              return unlocked[idx]['image_url']?.toString() ?? '';
            }();

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              cacheExtent: 400,
              itemCount: stickers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sticker = stickers[index];
                final imageUrl = sticker['image_url']?.toString() ?? '';
                final unlocked = _isStickerUnlocked(sticker, hasPurchased);
                final isSelected = unlocked && imageUrl == selectedUrl;

                return GestureDetector(
                  key: ValueKey(
                    'sticker_row_${productId}_${sticker['image_url']}',
                  ),
                  onTap: unlocked
                      ? () => _selectStickerPreview(
                            controller, sticker, hasPurchased)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: ScreenSize.isTablet ? 80 : 64,
                    height: ScreenSize.isTablet ? 80 : 64,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(
                          ScreenSize.isTablet ? 12 : 8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (unlocked
                                ? AppColors.border
                                : AppColors.primary.withOpacity(0.4)),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          ScreenSize.isTablet ? 12 : 8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            _stickerImage(
                              imageUrl,
                              productId,
                              fit: BoxFit.cover,
                              isThumb: true,
                            )
                          else
                            Icon(Icons.sticky_note_2,
                                size: 24, color: AppColors.textTertiary),
                          if (!unlocked)
                            Container(
                              color: Colors.white.withOpacity(0.65),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Center(
                                  child: Icon(Icons.lock,
                                      size: 18, color: AppColors.primary),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        if (!hasPurchased) ...[
          const SizedBox(height: 8),
          Text(
            'Pay to unlock all ${stickers.length} stickers',
            style: TextStyle(
              fontSize: ScreenSize.textExtraSmall,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSizeSelection(ProductController controller) {
    final sizes = controller.product!['sizes'] as List? ?? [];
    if (sizes.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Size',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Obx(() {
            final selectedIndex = controller.selectedSizeIndex.value;
            return Wrap(
              spacing: ScreenSize.spacingSmall,
              children: List.generate(sizes.length, (index) {
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => controller.selectSize(index),
                  child: Container(
                    width: ScreenSize.heightPercent(4.5),
                    height: ScreenSize.heightPercent(4.5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      sizes[index].toString(),
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildColorSelection(ProductController controller) {
    final colors = controller.product!['colors'] as List? ?? [];
    if (colors.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Obx(() {
            final selectedIndex = controller.selectedColorIndex.value;
            return Wrap(
              spacing: ScreenSize.spacingSmall,
              children: List.generate(colors.length, (index) {
                final isSelected = selectedIndex == index;
                final color = colors[index];
                final colorCode = color is Map 
                    ? (color['code'] ?? color['name'] ?? '#000000')
                    : (color?.toString() ?? '#000000');
                
                return GestureDetector(
                  onTap: () => controller.selectColor(index),
                  child: Container(
                    width: ScreenSize.heightPercent(4.5),
                    height: ScreenSize.heightPercent(4.5),
                    decoration: BoxDecoration(
                      color: _parseColor(colorCode),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildQuantityAndPrice(ProductController controller) {
    final product = controller.product!;
    final isDigital = product['is_digital'] == true || product['is_digital'] == 1;
    final hasDiscount = product['originalPrice'] != null &&
                       product['originalPrice'] > product['price'];
    final discountPercent = hasDiscount 
        ? ((product['originalPrice'] - product['price']) / product['originalPrice'] * 100).round()
        : 0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingTiny),
      child: Row(
        children: [
          // Quantity Section (only for physical products; digital = 1, no selector)
          if (!isDigital)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: ScreenSize.textExtraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 14),
                        onPressed: controller.decreaseQuantity,
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                      ),
                      Obx(() => Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${controller.quantity.value}',
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )),
                      IconButton(
                        icon: Icon(Icons.add, size: 14),
                        onPressed: controller.increaseQuantity,
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (!isDigital) SizedBox(width: ScreenSize.spacingMedium),
          
          // Price Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  Text(
                    '\$${product['originalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraSmall,
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: ScreenSize.textLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (hasDiscount && discountPercent > 0)
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 2),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductBadges(ProductController controller) {
    final product = controller.product!;
    final inStock = product['inStock'] ?? true;
    final stock = product['stock'] ?? 0;
    final isDigital = product['is_digital'] == true || product['is_digital'] == 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          // Digital product badge
          // if (isDigital)
          //   Container(
          //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //     decoration: BoxDecoration(
          //       color: AppColors.primary.withOpacity(0.12),
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(Icons.download, size: 12, color: AppColors.primary),
          //         SizedBox(width: 4),
          //         // Text(
          //         //   'Digital – download after payment',
          //         //   style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
          //         // ),
          //       ],
          //     ),
          //   ),

          // Brand Badge (if available)
          if (product['brand'] != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1,
                ),
              ),
              child: Text(
                product['brand'] is Map
                    ? (product['brand']['name'] ?? 'Brand')
                    : product['brand'].toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildShippingInfo(ProductController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingTiny),
      child: Container(
        padding: EdgeInsets.all(ScreenSize.spacingTiny),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.local_shipping,
              title: 'Free Shipping',
              subtitle: 'On orders above \$50',
            ),
            SizedBox(height: 2),
            Divider(height: 1, color: AppColors.border),
            SizedBox(height: 2),
            _buildInfoRow(
              icon: Icons.assignment_return,
              title: 'Easy Returns',
              subtitle: '30 days return policy',
            ),
            SizedBox(height: 2),
            Divider(height: 1, color: AppColors.border),
            SizedBox(height: 2),
            _buildInfoRow(
              icon: Icons.verified,
              title: 'Authentic Products',
              subtitle: '100% genuine guarantee',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSpecifications(ProductController controller) {
    final product = controller.product!;
    final specs = <String, String>{};
    
    if (product['weight'] != null) {
      specs['Weight'] = '${product['weight']} kg';
    }
    if (product['dimensions'] != null) {
      specs['Dimensions'] = product['dimensions'].toString();
    }
    if (product['material'] != null) {
      specs['Material'] = product['material'].toString();
    }
    if (product['warranty'] != null) {
      specs['Warranty'] = product['warranty'].toString();
    }
    if (product['sku'] != null) {
      specs['SKU'] = product['sku'].toString();
    }
    
    if (specs.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingTiny),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: specs.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: ScreenSize.textExtraSmall,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDescription(ProductController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            controller.product!['description'] ?? '',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewsSection(ProductController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Reviews',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Obx(() => Text(
                    '${controller.reviews.length} ${controller.reviews.length == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  )),
                ],
              ),
              TextButton.icon(
                onPressed: controller.writeReview,
                icon: Icon(Icons.edit, size: 14, color: AppColors.primary),
                label: Text(
                  'Write Review',
                  style: TextStyle(
                    fontSize: ScreenSize.textExtraSmall,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Obx(() {
            print('[UI] Reviews section rebuild, count: ${controller.reviews.length}');
            if (controller.reviews.isEmpty) {
              return Container(
                padding: EdgeInsets.all(ScreenSize.spacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.reviews_outlined,
                      size: 32,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Be the first to review this product',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...controller.reviews.take(3).map((review) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _buildReviewCard(controller, review),
                )),
                if (controller.reviews.length > 3)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full reviews screen
                      Get.snackbar('Info', 'View all reviews coming soon');
                    },
                    child: Text(
                      'View All ${controller.reviews.length} Reviews',
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildReviewCard(ProductController controller, Map<String, dynamic> review) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  (review['userName']?[0] ?? 'U').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review['rating'] ?? 0).floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 12,
                            color: AppColors.accent,
                          );
                        }),
                        SizedBox(width: 8),
                        Text(
                          review['date'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (review['status'] == 'pending') ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['title'] != null && review['title'].toString().isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              review['title'],
              style: TextStyle(
                fontSize: ScreenSize.textExtraSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          SizedBox(height: 2),
          Text(
            review['comment'] ?? '',
            style: TextStyle(
              fontSize: ScreenSize.textExtraSmall,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
          if (review['images'] != null && (review['images'] as List).isNotEmpty) ...[
            SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (review['images'] as List).map((image) {
                final imgUrl = image?.toString().trim() ?? '';
                return GestureDetector(
                  onTap: () {
                    // TODO: Show image in full screen
                    Get.snackbar('Info', 'Image preview coming soon');
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: imgUrl.isEmpty
                        ? Container(
                            width: 40,
                            height: 40,
                            color: AppColors.backgroundGrey,
                            child: Icon(Icons.image, size: 12, color: AppColors.textTertiary),
                          )
                        : CachedNetworkImage(
                      imageUrl: imgUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 40,
                        height: 40,
                        color: AppColors.backgroundGrey,
                        child: Icon(Icons.image, size: 12, color: AppColors.textTertiary),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 40,
                        height: 40,
                        color: AppColors.backgroundGrey,
                        child: Icon(Icons.image_not_supported, size: 12, color: AppColors.textTertiary),
                      ),
                    )),
                  );

              }).toList(),
            ),
          ],
          SizedBox(height: 4),
          // Like and Report buttons
          Row(
            children: [
              // Like button
              InkWell(
                onTap: () => controller.toggleReviewLike(review['id']),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review['is_liked'] == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 14,
                      color: review['is_liked'] == true ? AppColors.primary : AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${review['like_count'] ?? 0}',
                      style: TextStyle(
                        fontSize: 10,
                        color: review['is_liked'] == true ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: review['is_liked'] == true ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Report button
              InkWell(
                onTap: () => _showReportDialog(controller, review['id']),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showReportDialog(ProductController controller, int reviewId) {
    final descriptionController = TextEditingController();
    String selectedReason = 'other';
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.all(ScreenSize.spacingMedium),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Review',
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Why are you reporting this review?',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  ...['spam', 'inappropriate', 'fake', 'offensive', 'other'].map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason[0].toUpperCase() + reason.substring(1), style: TextStyle(fontSize: ScreenSize.textSmall)),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value!;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Additional details (optional)',
                      labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
                    maxLines: 2,
                    style: TextStyle(fontSize: ScreenSize.textSmall),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel', style: TextStyle(fontSize: ScreenSize.textSmall)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          controller.reportReview(
                            reviewId,
                            selectedReason,
                            description: descriptionController.text.isEmpty ? null : descriptionController.text,
                          );
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textWhite,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: Text('Report', style: TextStyle(fontSize: ScreenSize.textSmall)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Share product on social media
  void _shareProduct(ProductController controller) {
    final product = controller.product;
    if (product == null) return;
    
    final productName = product['name'] ?? 'Product';
    final productPrice = product['sale_price'] ?? product['price'] ?? 0;
    // final productUrl = 'https://ecommercepanel.templateforwebsites.com/product/${product['id']}';
    final productUrl = 'http://admin.fosproductions.org/product/${product['id']}';

    final shareText = '''
Check out this amazing product!

$productName
Price: \$$productPrice

$productUrl
''';
    
    Share.share(
      shareText,
      subject: productName,
    );
  }
  
  Widget _buildRelatedProducts(ProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You May Also Like',
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (controller.relatedProducts.length > 4)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to see all related products
                    Get.snackbar('Info', 'View all related products coming soon');
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraSmall,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Obx(() {
          if (controller.relatedProducts.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium),
              child: Container(
                padding: EdgeInsets.all(ScreenSize.spacingSmall),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No related products found',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            height: ScreenSize.heightPercent(20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium),
              itemCount: controller.relatedProducts.length,
              itemBuilder: (context, index) {
                final product = controller.relatedProducts[index];
                return GestureDetector(
                  onTap: () {
                    ProductDetailsNavigation.go(
                      id: product['id'] is int
                          ? product['id'] as int
                          : int.tryParse(product['id'].toString()) ?? 0,
                      preview: Map<String, dynamic>.from(product),
                    );
                  },
                  child: Container(
                    width: ScreenSize.widthPercent(30),
                    margin: EdgeInsets.only(right: ScreenSize.spacingSmall),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(ScreenSize.tileBorderRadius),
                              ),
                              child: () {
                                final img = (product['image']?.toString() ?? '').trim();
                                return img.isEmpty
                                    ? Container(
                                        color: AppColors.backgroundGrey,
                                        height: ScreenSize.heightPercent(12),
                                        child: Icon(Icons.image_not_supported, size: 16, color: AppColors.textTertiary),
                                      )
                                    : SizedBox(
                                      width: double.infinity,
                                      height: ScreenSize.heightPercent(12),
                                      child: StableCachedImage(
                                        imageUrl: img,
                                        cacheKey: 'related_${product['id']}',
                                        fit: BoxFit.contain,
                                      ),
                                    );
                              }(),
                            ),
                            if (product['rating'] != null && (product['rating'] as double) > 0)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 8,
                                        color: AppColors.textWhite,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        product['rating'].toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    product['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(
                                    fontSize: ScreenSize.textExtraSmall,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildBottomBar(ProductController controller) {
    controller.isLoading.value; // Obx ko trigger – loading khatam hone par bottom bar dubara build
    final isDigital = _isDigitalProduct(controller);
    // Digital: no Add to Cart / Buy Now in bottom bar – purchase only via preview "Pay & Download"
    if (isDigital) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Obx(() => OutlinedButton(
                onPressed: controller.isAddingToCart.value ? null : controller.addToCart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: ScreenSize.screenWidth >= 1000 ? 1.5 : 1),
                  padding: EdgeInsets.symmetric(vertical: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 12 : (ScreenSize.screenWidth >= 768 ? 10 : 8)),
                  ),
                ),
                child: controller.isAddingToCart.value
                    ? SizedBox(
                        width: ScreenSize.screenWidth >= 1000 ? 18 : (ScreenSize.screenWidth >= 768 ? 16 : 14),
                        height: ScreenSize.screenWidth >= 1000 ? 18 : (ScreenSize.screenWidth >= 768 ? 16 : 14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )),
            ),
            SizedBox(width: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
            Expanded(
              child: ElevatedButton(
                onPressed: controller.buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: EdgeInsets.symmetric(vertical: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : ScreenSize.spacingSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 12 : (ScreenSize.screenWidth >= 768 ? 10 : 8)),
                  ),
                ),
                child: Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.textPrimary;
    }
  }

  /// API kabhi is_digital true, kabhi 1 bhejta hai – dono pe digital maan lo
  bool _isVideoByDigitalPath(Map<String, dynamic> product) {
    final path = product['digital_file_path']?.toString().toLowerCase() ?? '';
    return path.contains('.mp4') ||
        path.contains('.webm') ||
        path.contains('.mov') ||
        path.contains('.m4v') ||
        path.contains('.avi');
  }

  bool _isDigitalProduct(ProductController controller) {
    final v = controller.product?['is_digital'];
    return v == true || v == 1;
  }

  /// Build video player for video products with 12-second preview and caching
  Widget _buildVideoPlayer(String videoUrl, ProductController controller) {
    final actualVideoUrl =
        controller.playbackVideoUrl ?? videoUrl.trim();

    if (actualVideoUrl.isEmpty ||
        !ProductController.isVideoMediaUrl(actualVideoUrl)) {
      if (controller.isLoading.value ||
          controller.digitalPreviewLoading.value) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Video not available',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    final productId = controller.product?['id'] ?? 0;
    return CachedVideoPreviewWidget(
      key: ValueKey('video_preview_${productId}_$actualVideoUrl'),
      videoUrl: actualVideoUrl,
      autoPlay: true,
      previewDuration: const Duration(seconds: 12),
      onPreviewEnd: () {
        // Show purchase prompt or navigate to payment (only once)
        if (!_hasShownPurchasePrompt) {
          _hasShownPurchasePrompt = true;
          _showVideoPurchasePrompt(controller);
        }
      },
    );
  }

  /// Build audio player for audio products with 12-second preview and caching
  Widget _buildAudioPlayer(String audioUrl, Map<String, dynamic> product, ProductController controller) {
    // Get the actual audio URL from product data if available
    String actualAudioUrl = '';
    print('[Audio Player] Initial audioUrl parameter: $audioUrl');

    // First try to get audio from digital_file_path
    if (product['digital_file_path'] != null) {
      final digitalFilePath = product['digital_file_path'].toString();
      print('[Audio Player] digital_file_path: $digitalFilePath');

      if (digitalFilePath.startsWith('[')) {
        try {
          final List<dynamic> files = json.decode(digitalFilePath);
          if (files.isNotEmpty) {
            actualAudioUrl = '${ApiService.imageBaseUrl}digital_products/${files.first.toString()}';
            print('[Audio Player] Parsed array, actualAudioUrl: $actualAudioUrl');
          }
        } catch (e) {
          print('[Audio Player] Error parsing digital_file_path: $e');
        }
      } else {
        actualAudioUrl = '${ApiService.imageBaseUrl}digital_products/$digitalFilePath';
        print('[Audio Player] Parsed string, actualAudioUrl: $actualAudioUrl');
      }
    }

    // If still empty, try the parameter (but only if it looks like an audio file)
    if (actualAudioUrl.isEmpty && audioUrl.isNotEmpty) {
      final lowerUrl = audioUrl.toLowerCase();
      if (lowerUrl.contains('.mp3') || lowerUrl.contains('.wav') || lowerUrl.contains('.m4a') || lowerUrl.contains('.aac')) {
        actualAudioUrl = audioUrl;
        print('[Audio Player] Using parameter audioUrl: $actualAudioUrl');
      }
    }

    print('[Audio Player] Final actualAudioUrl: $actualAudioUrl');
    print('[Audio Player] isPurchased: ${controller.digitalHasPurchased.value}');

    // Get product image URL for background
    String? productImageUrl;
    final images = product['images'] as List?;
    if (images != null && images.isNotEmpty) {
      productImageUrl = images[0] is String ? images[0] as String : images[0]?.toString();
    }
    if (productImageUrl == null || productImageUrl.isEmpty) {
      productImageUrl = product['image']?.toString();
    }

    if (actualAudioUrl.isEmpty) {
      print('[Audio Player] No audio URL available, showing placeholder');
      // Fallback to placeholder if no audio URL
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Audio not available',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return CachedAudioPreviewWidget(
      audioUrl: actualAudioUrl,
      autoPlay: true,
      previewDuration: const Duration(seconds: 12),
      isPurchased: controller.digitalHasPurchased.value,
      productImageUrl: productImageUrl,
      onPreviewEnd: () {
        // Show purchase prompt or navigate to payment (only once)
        if (!_hasShownPurchasePrompt) {
          _hasShownPurchasePrompt = true;
          _showAudioPurchasePrompt(product);
        }
      },
    );
  }

  /// Show video purchase prompt when preview ends
  void _showVideoPurchasePrompt(ProductController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Preview Ended'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Purchase this video to watch the full content',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Price: \$${controller.product?['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.goToPayDigitalProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Purchase Now'),
          ),
        ],
      ),
    );
  }

  /// Show audio purchase prompt when preview ends
  void _showAudioPurchasePrompt(Map<String, dynamic> product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Preview Ended'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Purchase this audio to listen to the full content',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Price: \$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Get the controller and go to payment
              final controller = GetXRegistry.product();
              controller.goToPayDigitalProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Purchase Now'),
          ),
        ],
      ),
    );
  }

  /// Build icon for digital product type
  Widget _buildDigitalProductTypeIcon(bool isStickerPack, ProductController controller) {
    IconData iconData;
    Color iconColor;
    
    if (isStickerPack) {
      iconData = Icons.sticky_note_2;
      iconColor = Colors.orange;
    } else if (DigitalProductType.isAudio(controller.product) ||
        controller.digitalPreviewMediaType.value == 'audio') {
      iconData = Icons.audiotrack;
      iconColor = Colors.blue;
    } else {
      iconData = Icons.videocam;
      iconColor = Colors.red;
    }
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: ScreenSize.screenWidth >= 1000 ? 24 : (ScreenSize.screenWidth >= 768 ? 22 : 20),
        color: iconColor,
      ),
    );
  }

  /// Build label text for digital product type
  Widget _buildDigitalProductTypeLabel(bool isStickerPack, ProductController controller) {
    String labelText;
    Color labelColor;
    
    if (isStickerPack) {
      labelText = 'Sticker Pack';
      labelColor = Colors.orange;
    } else if (controller.digitalPreviewMediaType.value == 'audio') {
      labelText = 'Audio (MP3)';
      labelColor = Colors.blue;
    } else {
      labelText = 'Video (MP4)';
      labelColor = Colors.red;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: labelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: labelColor.withOpacity(0.3)),
      ),
      child: Text(
        labelText,
        style: TextStyle(
          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textExtraSmall),
          fontWeight: FontWeight.bold,
          color: labelColor,
        ),
      ),
    );
  }
}

/// SliverPersistentHeader delegate for product details tabs
class _ProductDetailsTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _ProductDetailsTabDelegate({required this.child});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_ProductDetailsTabDelegate oldDelegate) {
    return false;
  }
}

/// Top-area video player for digital video product (red circle area).
/// Plays for [durationSeconds] then stops until payment – no loop.
class _DigitalVideoTopArea extends StatefulWidget {
  final String previewUrl;
  final int durationSeconds;
  final VoidCallback onPayPressed;
  final bool isPurchased;

  const _DigitalVideoTopArea({
    super.key,
    required this.previewUrl,
    this.durationSeconds = 15,
    required this.onPayPressed,
    this.isPurchased = false,
  });

  @override
  State<_DigitalVideoTopArea> createState() => _DigitalVideoTopAreaState();
}

class _DigitalVideoTopAreaState extends State<_DigitalVideoTopArea> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _previewEnded = false;
  bool _isPlaying = false;
  Timer? _limitTimer;

  void _onVideoUpdate() {
    if (!mounted || _controller == null) return;
    setState(() => _isPlaying = _controller!.value.isPlaying);
  }

  @override
  void initState() {
    super.initState();
    if (widget.previewUrl.isNotEmpty) _initVideo();
  }

  @override
  void didUpdateWidget(covariant _DigitalVideoTopArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewUrl != widget.previewUrl) {
      _swapVideo(oldWidget.previewUrl);
    }
  }

  Future<void> _swapVideo(String oldUrl) async {
    _limitTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_onVideoUpdate);
      MediaPreviewPool.instance.releaseVideo(oldUrl);
      _controller = null;
    }
    setState(() {
      _initialized = false;
      _previewEnded = false;
      _isPlaying = false;
    });
    if (widget.previewUrl.isNotEmpty) {
      await _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      _controller =
          await MediaPreviewPool.instance.acquireVideo(widget.previewUrl);
      if (mounted) {
        setState(() => _initialized = true);
        _controller!.play();
        setState(() => _isPlaying = true);
        _controller!.addListener(_onVideoUpdate);
        // Only stop video after preview duration if NOT purchased
        if (!widget.isPurchased) {
          _limitTimer = Timer(Duration(seconds: widget.durationSeconds), () {
            if (!mounted) return;
            _controller?.pause();
            setState(() {
              _previewEnded = true;
              _isPlaying = false;
            });
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_onVideoUpdate);
      MediaPreviewPool.instance.releaseVideo(widget.previewUrl);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewUrl.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (!_initialized || _controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          // Play/Pause button overlay
          if (!_previewEnded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  });
                },
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          if (_previewEnded && !widget.isPurchased)
            Container(
              color: Colors.black54,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingMedium),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 48, color: Colors.white70),
                      SizedBox(height: 12),
                      Text(
                        'Preview ended (${widget.durationSeconds} sec)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ScreenSize.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pay to unlock full video',
                        style: TextStyle(color: Colors.white70, fontSize: ScreenSize.textSmall),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              if (_controller != null) {
                                await _controller!.seekTo(Duration.zero);
                                _limitTimer?.cancel();
                                setState(() => _previewEnded = false);
                                _controller!.play();
                                // Restart timer for preview duration
                                if (!widget.isPurchased) {
                                  _limitTimer = Timer(Duration(seconds: widget.durationSeconds), () {
                                    if (!mounted) return;
                                    _controller?.pause();
                                    setState(() => _previewEnded = true);
                                  });
                                }
                              }
                            },
                            icon: Icon(Icons.replay, size: 18),
                            label: Text('Replay'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white, width: 1.5),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: widget.onPayPressed,
                            icon: Icon(Icons.payment, size: 20),
                            label: Text('Pay & Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}