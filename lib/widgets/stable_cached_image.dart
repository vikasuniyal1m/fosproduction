import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Cached image without spinner flicker on scroll / navigation rebuild.
class StableCachedImage extends StatelessWidget {
  final String imageUrl;
  final String? cacheKey;
  final BoxFit fit;
  final Color placeholderColor;
  final Color? errorIconColor;
  final double? errorIconSize;

  const StableCachedImage({
    super.key,
    required this.imageUrl,
    this.cacheKey,
    this.fit = BoxFit.cover,
    this.placeholderColor = AppColors.backgroundGrey,
    this.errorIconColor,
    this.errorIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey ?? imageUrl,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      placeholder: (_, __) => ColoredBox(color: placeholderColor),
      errorWidget: (_, __, ___) => ColoredBox(
        color: placeholderColor,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            color: errorIconColor ?? AppColors.textTertiary,
            size: errorIconSize ?? 24,
          ),
        ),
      ),
    );
  }
}
