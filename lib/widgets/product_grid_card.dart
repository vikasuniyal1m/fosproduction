import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/digital_product_type.dart';
import '../utils/screen_size.dart';
import 'favorite_button.dart';
import 'stable_cached_image.dart';

/// Shared product image — white bg, BoxFit.contain, home + grid same rules.
class ProductCardImage extends StatelessWidget {
  final Map<String, dynamic> product;
  final String cacheKeyPrefix;

  const ProductCardImage({
    super.key,
    required this.product,
    this.cacheKeyPrefix = 'product',
  });

  static const Color _bg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final cacheKey = '${cacheKeyPrefix}_${product['id']}';
    final isDigital =
        product['is_digital'] == true || product['is_digital'] == 1;
    final isSticker = DigitalProductType.isStickerPack(product);
    final isVideo = isDigital && DigitalProductType.isVideo(product);
    final isAudio = isDigital && DigitalProductType.isAudio(product);
    final banner = product['banner']?.toString().trim() ?? '';
    final rawImage = product['image']?.toString().trim() ?? '';
    final imageUrl =
        rawImage.isNotEmpty ? rawImage.replaceAll('\\/', '/') : '';

    Widget image;

    if (isSticker || (!isVideo && !isAudio)) {
      final url = imageUrl.isNotEmpty ? imageUrl : banner;
      image = url.isNotEmpty
          ? StableCachedImage(
              imageUrl: url,
              cacheKey: cacheKey,
              fit: BoxFit.contain,
              placeholderColor: _bg,
            )
          : _placeholder(Icons.sticky_note_2_outlined);
    } else if (isAudio) {
      final url = banner.isNotEmpty ? banner : imageUrl;
      image = url.isNotEmpty
          ? StableCachedImage(
              imageUrl: url,
              cacheKey: banner.isNotEmpty ? '${cacheKey}_banner' : cacheKey,
              fit: BoxFit.contain,
              placeholderColor: _bg,
            )
          : _placeholder(Icons.audiotrack);
    } else if (isVideo) {
      final url = banner.isNotEmpty ? banner : imageUrl;
      image = url.isNotEmpty
          ? StableCachedImage(
              imageUrl: url,
              cacheKey: banner.isNotEmpty ? '${cacheKey}_banner' : cacheKey,
              fit: BoxFit.contain,
              placeholderColor: _bg,
            )
          : _placeholder(Icons.videocam);
    } else {
      image = imageUrl.isNotEmpty
          ? StableCachedImage(
              imageUrl: imageUrl,
              cacheKey: cacheKey,
              fit: BoxFit.contain,
              placeholderColor: _bg,
            )
          : _placeholder(Icons.image_not_supported);
    }

    return ColoredBox(
      color: _bg,
      child: SizedBox.expand(child: image),
    );
  }

  Widget _placeholder(IconData icon) {
    return Center(
      child: Icon(icon, color: AppColors.textTertiary, size: 40),
    );
  }
}

/// Grid product card — same image rules as home horizontal cards.
class ProductGridCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? '';
    final regularPrice = (product['price'] ?? 0.0) as num;
    final salePrice = product['sale_price'] as num?;
    final displayPrice = (salePrice ?? regularPrice).toDouble();
    final rating = (product['rating'] ?? 0.0) as double;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(ScreenSize.productCardBorderRadius),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(ScreenSize.productCardBorderRadius),
                    ),
                    child: ProductCardImage(
                      product: product,
                      cacheKeyPrefix: 'grid_product',
                    ),
                  ),
                  Positioned(
                    top: ScreenSize.screenWidth >= 768 ? 5 : 4,
                    right: ScreenSize.screenWidth >= 768 ? 5 : 4,
                    child: FavoriteButton(
                      productId: product['id'],
                      onToggle: onFavoriteToggle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.paddingSmall,
                  vertical: ScreenSize.spacingXSmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          '\$${displayPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: ScreenSize.textSmall,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (rating > 0) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            size: ScreenSize.iconExtraSmall,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: ScreenSize.textExtraSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
