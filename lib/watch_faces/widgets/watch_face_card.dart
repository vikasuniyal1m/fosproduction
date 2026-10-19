import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/screen_size.dart';
import '../models/watch_face_model.dart';
import '../watch_faces_config.dart';
import 'platform_badge.dart';

class WatchFaceCard extends StatelessWidget {
  const WatchFaceCard({
    super.key,
    required this.face,
    required this.onTap,
    required this.onPrimaryAction,
    required this.isPurchased,
    required this.showInstall,
  });

  final WatchFace face;
  final VoidCallback onTap;
  final VoidCallback onPrimaryAction;
  final bool isPurchased;
  final bool showInstall;

  String get _primaryLabel {
    if (showInstall) return 'Install';
    if (face.requiresPurchase && !isPurchased) {
      final p = face.price;
      return p != null ? 'Pay \$${p.toStringAsFixed(2)}' : 'Pay to unlock';
    }
    return 'Coming soon';
  }

  @override
  Widget build(BuildContext context) {
    final enabled = showInstall ||
        (face.requiresPurchase && !isPurchased && (face.productId ?? 0) > 0) ||
        (!face.requiresPurchase && face.isInstallable);

    return Material(
      color: AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Preview(face: face),
                  if (face.isPremium && !isPurchased)
                    const Positioned(top: 8, right: 8, child: PremiumBadge()),
                  if (isPurchased)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Owned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: PlatformBadge(platform: face.platform, compact: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ScreenSize.paddingSmall,
                ScreenSize.spacingSmall,
                ScreenSize.paddingSmall,
                ScreenSize.paddingSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    face.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    face.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: enabled ? onPrimaryAction : null,
                      icon: Icon(
                        showInstall ? Icons.watch : Icons.payment,
                        size: 18,
                      ),
                      label: Text(_primaryLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: showInstall
                            ? AppColors.primary
                            : AppColors.accent,
                        foregroundColor: AppColors.textBlack,
                        disabledBackgroundColor: AppColors.border,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.face});

  final WatchFace face;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      face.previewImage,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        final color =
            face.isApple ? const Color(0xFF0A84FF) : AppColors.secondary;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.8), AppColors.primaryDark],
            ),
          ),
          child: const Center(
            child: Icon(Icons.watch, size: 48, color: Colors.white70),
          ),
        );
      },
    );
  }
}
