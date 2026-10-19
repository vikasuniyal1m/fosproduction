import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/screen_size.dart';
import '../controllers/watch_faces_controller.dart';
import '../data/watch_faces_repository.dart';
import '../models/watch_face_model.dart';
import '../services/watch_face_installer_service.dart';
import '../watch_face_install_helper.dart';
import '../watch_faces_config.dart';
import '../watch_face_order_helper.dart';
import '../widgets/watch_face_card.dart';
import 'watch_face_detail_screen.dart';

/// Device-aware watch face gallery (Apple on iOS, Galaxy/Wear on Android).
class WatchFacesScreen extends StatefulWidget {
  const WatchFacesScreen({super.key});

  @override
  State<WatchFacesScreen> createState() => _WatchFacesScreenState();
}

class _WatchFacesScreenState extends State<WatchFacesScreen> {
  final _repository = WatchFacesRepository();
  final _installer = WatchFaceInstallerService();
  bool _featureDisabled = false;
  late final WatchFacesController _purchaseController;

  late Future<List<WatchFace>> _facesFuture;
  late WatchPlatform _platform;
  late String _title;
  late String _otherPlatformNote;

  @override
  void initState() {
    super.initState();
    if (!WatchFacesConfig.isFeatureEnabled) {
      _featureDisabled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (Get.key.currentState?.canPop() ?? false)) Get.back();
      });
      return;
    }
    _purchaseController = Get.isRegistered<WatchFacesController>()
        ? Get.find<WatchFacesController>()
        : Get.put(WatchFacesController(repository: _repository));
    if (!kIsWeb && Platform.isIOS) {
      _platform = WatchPlatform.ios;
      _title = 'FOS Watch Faces';
      _otherPlatformNote =
          'Galaxy / Wear OS faces are also available when you open this app on Android.';
    } else if (!kIsWeb && Platform.isAndroid) {
      _platform = WatchPlatform.android;
      _title = 'FOS Watch Faces';
      _otherPlatformNote =
          'Apple Watch faces are also available when you open this app on iPhone.';
    } else {
      _platform = WatchPlatform.ios;
      _title = 'FOS Watch Faces';
      _otherPlatformNote = '';
    }
    _facesFuture = _loadFaces();
    _facesFuture.then((faces) {
      if (mounted) _refreshPurchasesInBackground(faces);
    });
  }

  Future<List<WatchFace>> _loadFaces() async {
    await WatchFaceOrderHelper.ensureCatalogLoaded();
    return _repository.loadByPlatform(_platform);
  }

  void _refreshPurchasesInBackground(List<WatchFace> faces) {
    unawaited(_purchaseController.refreshPurchaseState(faces));
  }

  void _reload() {
    setState(() {
      _facesFuture = _loadFaces();
    });
  }

  Future<void> _openDetail(WatchFace face) async {
    await Get.to(
      () => WatchFaceDetailScreen(
        face: face,
        installer: _installer,
        purchaseController: _purchaseController,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _onPrimaryAction(WatchFace face) async {
    if (_purchaseController.showInstallAction(face)) {
      await installFaceWithFeedback(
        _installer,
        face,
        purchaseController: _purchaseController,
      );
      if (mounted) setState(() {});
      return;
    }
    if (face.requiresPurchase && !_purchaseController.isPurchased(face)) {
      await payForFaceWithFeedback(face, _purchaseController);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_featureDisabled) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: FutureBuilder<List<WatchFace>>(
        future: _facesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: 'Could not load watch faces.\n${snapshot.error}',
              onRetry: _reload,
            );
          }
          final faces = snapshot.data ?? const [];
          if (faces.isEmpty) {
            return Center(
              child: Text(
                'No watch faces for your device yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    ScreenSize.paddingMedium,
                    0,
                    ScreenSize.paddingMedium,
                    ScreenSize.spacingSmall,
                  ),
                  child: _PlatformHeader(platform: _platform),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.paddingMedium,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: ScreenSize.isTablet ? 280 : 220,
                    mainAxisExtent: ScreenSize.isTablet ? 340 : 300,
                    crossAxisSpacing: ScreenSize.spacingMedium,
                    mainAxisSpacing: ScreenSize.spacingMedium,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final face = faces[index];
                      return Obx(() {
                        final purchased =
                            _purchaseController.isPurchased(face);
                        final showInstall =
                            _purchaseController.showInstallAction(face);
                        return WatchFaceCard(
                          face: face,
                          isPurchased: purchased,
                          showInstall: showInstall,
                          onTap: () => _openDetail(face),
                          onPrimaryAction: () => _onPrimaryAction(face),
                        );
                      });
                    },
                    childCount: faces.length,
                  ),
                ),
              ),
              if (_otherPlatformNote.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(ScreenSize.paddingMedium),
                    child: Text(
                      _otherPlatformNote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: ScreenSize.spacingLarge),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlatformHeader extends StatelessWidget {
  const _PlatformHeader({required this.platform});

  final WatchPlatform platform;

  @override
  Widget build(BuildContext context) {
    final isApple = platform == WatchPlatform.ios;
    return Container(
      padding: EdgeInsets.all(ScreenSize.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isApple
              ? [
                  const Color(0xFF0A84FF).withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.08),
                ]
              : [
                  AppColors.secondary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ScreenSize.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isApple ? Icons.watch : Icons.watch_outlined,
            color: isApple ? const Color(0xFF0A84FF) : AppColors.secondary,
            size: 36,
          ),
          SizedBox(width: ScreenSize.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApple ? 'Apple Watch' : 'Galaxy / Wear OS',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  WatchFacesConfig.bypassPurchaseForTesting
                      ? (isApple
                          ? 'Tap Install on any face to add it to your paired Apple Watch.'
                          : 'Tap Install on any face via Galaxy Wearable.')
                      : (isApple
                          ? 'Pay for a fruit face, then tap Install on your iPhone with a paired Apple Watch.'
                          : 'Pay to unlock, then tap Install on your Galaxy / Wear OS watch.'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ScreenSize.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.pinkAccent),
            SizedBox(height: ScreenSize.spacingMedium),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: ScreenSize.spacingMedium),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
