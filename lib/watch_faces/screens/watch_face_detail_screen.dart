import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/screen_size.dart';
import '../controllers/watch_faces_controller.dart';
import '../models/watch_face_model.dart';
import '../services/watch_face_installer_service.dart';
import '../watch_face_install_helper.dart';
import '../watch_faces_config.dart';
import '../widgets/platform_badge.dart';

class WatchFaceDetailScreen extends StatelessWidget {
  const WatchFaceDetailScreen({
    super.key,
    required this.face,
    required this.installer,
    required this.purchaseController,
  });

  final WatchFace face;
  final WatchFaceInstallerService installer;
  final WatchFacesController purchaseController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final purchased = purchaseController.isPurchased(face);
      final showInstall = purchaseController.showInstallAction(face);
      final supported = installer.isSupportedOnThisDevice(face);

      String primaryLabel;
      if (showInstall) {
        primaryLabel = face.isApple
            ? 'Install on Apple Watch'
            : 'Install on Galaxy Watch';
      } else if (face.requiresPurchase && !purchased) {
        final p = face.price;
        primaryLabel =
            p != null ? 'Pay \$${p.toStringAsFixed(2)} to unlock' : 'Pay to unlock';
      } else {
        primaryLabel = 'Coming soon';
      }

      final canPress = showInstall ||
          (face.requiresPurchase &&
              !purchased &&
              (face.productId ?? 0) > 0);

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            face.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        body: ListView(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Hero(
                tag: 'watch-face-${face.id}',
                child: _LargePreview(face: face),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ScreenSize.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          face.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (purchased)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'Owned',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (face.isPremium)
                        const PremiumBadge(),
                    ],
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  PlatformBadge(platform: face.platform),
                  SizedBox(height: ScreenSize.spacingMedium),
                  Text(
                    face.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingMedium),
                  _InfoTile(
                    icon: Icons.verified_outlined,
                    title: 'Compatibility',
                    value: face.compatibility ??
                        (face.isApple
                            ? 'Apple Watch with a paired iPhone'
                            : 'Wear OS 3+ / Galaxy Watch'),
                  ),
                  _InfoTile(
                    icon: face.isApple
                        ? Icons.folder_outlined
                        : Icons.watch_outlined,
                    title: 'Delivery',
                    value: face.isApple
                        ? 'Installed through Apple ClockKit (.watchface).'
                        : 'Downloaded from FOS server and installed via Galaxy Wearable (.wfs).',
                  ),
                  SizedBox(height: ScreenSize.spacingMedium),
                  if (!purchased &&
                      face.requiresPurchase &&
                      !WatchFacesConfig.bypassPurchaseForTesting)
                    const _NoticeBanner(
                      icon: Icons.lock_outline,
                      color: AppColors.accent,
                      message:
                          'Purchase this fruit watch face to unlock Install. '
                          'After payment, return here and tap Install.',
                    )
                  else if (!showInstall && purchased)
                    const _NoticeBanner(
                      icon: Icons.schedule,
                      color: AppColors.accent,
                      message:
                          'You own this face. Tap Install on this device with your watch paired.',
                    )
                  else if (!supported && purchased)
                    _UnsupportedNote(face: face),
                  SizedBox(height: ScreenSize.spacingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canPress
                          ? () {
                              if (showInstall) {
                                installFaceWithFeedback(
                                  installer,
                                  face,
                                  purchaseController: purchaseController,
                                );
                              } else {
                                payForFaceWithFeedback(
                                  face,
                                  purchaseController,
                                );
                              }
                            }
                          : null,
                      icon: Icon(
                        showInstall
                            ? (face.isApple
                                ? Icons.add_to_home_screen
                                : Icons.shop)
                            : Icons.payment,
                      ),
                      label: Text(primaryLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: showInstall
                            ? AppColors.primary
                            : AppColors.accent,
                        foregroundColor:
                            showInstall ? AppColors.textWhite : AppColors.textBlack,
                        disabledBackgroundColor: AppColors.border,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _LargePreview extends StatelessWidget {
  const _LargePreview({required this.face});

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
            child: Icon(Icons.watch, size: 96, color: Colors.white70),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedNote extends StatelessWidget {
  const _UnsupportedNote({required this.face});

  final WatchFace face;

  @override
  Widget build(BuildContext context) {
    final message = face.isApple
        ? 'This face installs only on iOS. Open the app on an iPhone with a paired Apple Watch.'
        : 'This face installs only on Android. Open the app on an Android phone paired with a Galaxy / Wear OS watch.';
    return _NoticeBanner(
      icon: Icons.info_outline,
      color: AppColors.accent,
      message: message,
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: ScreenSize.spacingSmall),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
