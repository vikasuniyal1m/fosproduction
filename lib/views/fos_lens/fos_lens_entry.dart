import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/cache_manager.dart';

/// Shows gallery / camera choices and opens the FOS Lens editor with the chosen image.
Future<void> showFosLensImageSourceSheet(BuildContext context) async {
  if (!CacheManager.isLoggedIn()) {
    Get.snackbar(
      'Login Required',
      'Please login to use FOS Lens.',
      snackPosition: SnackPosition.BOTTOM,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      AppRoutes.toLogin();
    });
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'FOS Lens',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 2400,
                    imageQuality: 92,
                  );
                  if (file == null) return;
                  AppRoutes.toFosLensEditor(file.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    maxWidth: 2400,
                    imageQuality: 92,
                  );
                  if (file == null) return;
                  if (!File(file.path).existsSync()) return;
                  AppRoutes.toFosLensEditor(file.path);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
