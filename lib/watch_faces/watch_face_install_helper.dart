import 'package:get/get.dart';

import '../utils/app_colors.dart';
import 'controllers/watch_faces_controller.dart';
import 'models/watch_face_model.dart';
import 'services/watch_face_installer_service.dart';
import 'watch_faces_config.dart';

Future<void> installFaceWithFeedback(
  WatchFaceInstallerService installer,
  WatchFace face, {
  WatchFacesController? purchaseController,
}) async {
  final purchases = purchaseController ??
      (Get.isRegistered<WatchFacesController>()
          ? Get.find<WatchFacesController>()
          : null);

  if (WatchFacesConfig.isPayEnabled &&
      face.requiresPurchase &&
      purchases != null &&
      !purchases.canInstall(face)) {
    if (!purchases.isPurchased(face)) {
      final verified = await purchases.verifyPurchaseForFace(face);
      if (!verified) {
        Get.snackbar(
          'Purchase required',
          'Pay for this fruit watch face to unlock Install.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accent,
          colorText: AppColors.textBlack,
        );
        return;
      }
    }
    if (!purchases.canInstall(face)) {
      Get.snackbar(
        'Coming soon',
        'Install will be available when this face is published.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accent,
        colorText: AppColors.textBlack,
      );
      return;
    }
  }

  if (!installer.isSupportedOnThisDevice(face)) {
    Get.snackbar(
      face.isApple ? 'Apple Watch only' : 'Android only',
      face.isApple
          ? 'Apple Watch faces can only be installed on an iPhone.'
          : 'Galaxy / Wear OS faces can only be installed on Android.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.textPrimary,
      colorText: AppColors.textWhite,
    );
    return;
  }

  if (!face.isInstallable) {
    Get.snackbar(
      'Coming soon',
      'This watch face will be available in the store soon.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.accent,
      colorText: AppColors.textBlack,
    );
    return;
  }

  Get.snackbar(
    'Please wait',
    face.isApple
        ? (face.downloadUrl != null && face.downloadUrl!.isNotEmpty
            ? 'Downloading ${face.title}…'
            : 'Installing ${face.title}…')
        : (face.downloadUrl != null && face.downloadUrl!.isNotEmpty
            ? 'Downloading ${face.title}…'
            : 'Opening store…'),
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(milliseconds: 800),
    backgroundColor: AppColors.primary,
    colorText: AppColors.textWhite,
  );

  final result = await installer.install(face);

  Get.closeAllSnackbars();
  Get.snackbar(
    result.success ? 'Success' : 'Could not install',
    result.message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: result.success ? AppColors.secondary : AppColors.pinkAccent,
    colorText: AppColors.textWhite,
    duration: const Duration(seconds: 4),
  );
}

Future<void> payForFaceWithFeedback(
  WatchFace face,
  WatchFacesController controller,
) async {
  await controller.payForFace(face);
}
