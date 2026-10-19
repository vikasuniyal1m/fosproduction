import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/cache_manager.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/silent_loading.dart';

/// Gallery Screen
/// Displays FOS Lens images saved by the user
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final RxBool isLoading = false.obs;
  final RxList<File> galleryImages = <File>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  /// Load images from gallery
  Future<void> _loadGalleryImages() async {
    try {
      if (galleryImages.isEmpty) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      // Try to get images from Pictures directory first
      final directory = await getApplicationDocumentsDirectory();
      final fosLensDir = Directory('${directory.path}/FOS_LENS');
      
      if (await fosLensDir.exists()) {
        final files = await fosLensDir.list().toList();
        final imageFiles = files.whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith(('.png')))
            .toList();
        
        galleryImages.assignAll(imageFiles);
      } else {
        // If no custom directory, try to get recent images from gallery
        // This is a fallback - in production, you might want to use a proper media store API
        errorMessage.value = 'No FOS Lens images found. Images are saved to your device gallery.';
      }
    } catch (e) {
      errorMessage.value = 'Error loading gallery: ${e.toString()}';
      debugPrint('Gallery error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh gallery
  Future<void> _refreshGallery() async {
    await _loadGalleryImages();
  }

  /// Delete image
  Future<void> _deleteImage(File imageFile) async {
    try {
      await imageFile.delete();
      galleryImages.remove(imageFile);
      Get.snackbar(
        'Success',
        'Image deleted successfully',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete image: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    }
  }

  /// Download image to device gallery
  Future<void> _downloadImage(File imageFile) async {
    try {
      await Gal.putImage(imageFile.path);
      Get.snackbar(
        'Success',
        'Image downloaded to device gallery',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download image: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    }
  }

  /// Share image
  Future<void> _shareImage(File imageFile) async {
    try {
      // Import share functionality when needed
      final shareXFile = XFile(imageFile.path);
      await Share.shareXFiles([shareXFile], text: 'Shared from FOS Lens');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share image: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    }
  }

  /// Show full image view with options
  void _showFullImageView(File imageFile, int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Full screen image
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.background,
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.textSecondary,
                          size: 64,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Top bar with close button
            Positioned(
              top: 40,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Bottom action bar
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Download button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _downloadImage(imageFile);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download,
                            color: AppColors.success,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Download',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'FOS Lens Gallery',
          style: TextStyle(
            fontSize: ScreenSize.headingMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: ScreenSize.iconMedium,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: ScreenSize.iconMedium,
            ),
            onPressed: _refreshGallery,
          ),
        ],
      ),
      body: Obx(() {
        if (SilentLoading.blockUi(
          isLoading: isLoading.value,
          hasContent: galleryImages.isNotEmpty,
        )) {
          return const LoadingWidget();
        }

        if (errorMessage.value.isNotEmpty && galleryImages.isEmpty) {
          return _buildEmptyState();
        }

        if (galleryImages.isEmpty) {
          return _buildEmptyGallery();
        }

        return _buildGalleryGrid();
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ScreenSize.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            // Text(
            //   'Gallery Error',
            //   style: TextStyle(
            //     fontSize: ScreenSize.headingLarge,
            //     fontWeight: FontWeight.bold,
            //     color: AppColors.textPrimary,
            //   ),
            // ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            // ElevatedButton.icon(
            //   onPressed: _refreshGallery,
            //   icon: const Icon(Icons.refresh),
            //   label: const Text('Retry'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.primary,
            //     foregroundColor: AppColors.textWhite,
            //     padding: EdgeInsets.symmetric(
            //       horizontal: ScreenSize.spacingLarge,
            //       vertical: ScreenSize.spacingMedium,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGallery() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ScreenSize.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ScreenSize.spacingXLarge),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            Text(
              'No FOS Lens Images',
              style: TextStyle(
                fontSize: ScreenSize.headingLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              'Your FOS Lens creations will appear here after you save them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            Text(
              'Images are saved to your device gallery automatically after payment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return RefreshIndicator(
      onRefresh: _refreshGallery,
      child: Padding(
        padding: EdgeInsets.all(ScreenSize.spacingSmall),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: ScreenSize.spacingSmall,
            mainAxisSpacing: ScreenSize.spacingSmall,
            childAspectRatio: 1.0,
          ),
          itemCount: galleryImages.length,
          itemBuilder: (context, index) {
            final imageFile = galleryImages[index];
            return _buildImageCard(imageFile, index);
          },
        ),
      ),
    );
  }

  Widget _buildImageCard(File imageFile, int index) {
    return GestureDetector(
      onTap: () => _showFullImageView(imageFile, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.file(
                imageFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.background,
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.textSecondary,
                      size: ScreenSize.iconLarge,
                    ),
                  );
                },
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
                            
              // Image info
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.spacingXSmall,
                    vertical: ScreenSize.spacingTiny,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FOS Lens #${index + 1}',
                    style: TextStyle(
                      fontSize: ScreenSize.textExtraSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this FOS Lens image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteImage(imageFile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
