import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';
import '../utils/getx_registry.dart';

/// Download sticker ZIP, then add to WhatsApp (old working flow).
class StickerDownloadDialog extends StatefulWidget {
  final String productName;
  final String downloadUrl;
  final int itemId;
  final int? orderId;
  final int? productId;
  final Function()? onDownloadComplete;
  final Function()? onWhatsAppComplete;

  const StickerDownloadDialog({
    super.key,
    required this.productName,
    required this.downloadUrl,
    required this.itemId,
    this.orderId,
    this.productId,
    this.onDownloadComplete,
    this.onWhatsAppComplete,
  });

  @override
  State<StickerDownloadDialog> createState() => _StickerDownloadDialogState();
}

class _StickerDownloadDialogState extends State<StickerDownloadDialog> {
  bool _isDownloading = false;
  bool _isAddingToWhatsApp = false;
  double _downloadProgress = 0.0;
  String? _localFilePath;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: ScreenSize.widthPercent(90),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppColors.textWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(ScreenSize.spacingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF25D366),
                              Colors.green.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.sticky_note_2,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: ScreenSize.spacingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sticker Pack',
                              style: TextStyle(
                                fontSize: ScreenSize.textMedium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: ScreenSize.spacingExtraSmall),
                            Text(
                              widget.productName,
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  if (_isDownloading) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(ScreenSize.spacingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.download,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: ScreenSize.spacingSmall),
                              Text(
                                'Downloading sticker pack...',
                                style: TextStyle(
                                  fontSize: ScreenSize.textSmall,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ScreenSize.spacingSmall),
                          LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ScreenSize.spacingLarge),
                  ],
                  if (_localFilePath != null && !_isDownloading) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(ScreenSize.spacingMedium),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.download_done,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: ScreenSize.spacingSmall),
                          Text(
                            'Download complete',
                            style: TextStyle(
                              fontSize: ScreenSize.textSmall,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ScreenSize.spacingLarge),
                  ],
                  if (_localFilePath == null)
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadStickerPack,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.download, size: 18),
                      label: Text(
                        _isDownloading ? 'Downloading...' : 'Download',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(
                          vertical: ScreenSize.spacingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isAddingToWhatsApp ? null : _addToWhatsApp,
                      icon: _isAddingToWhatsApp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Image.asset(
                              'assets/whatsapp.png',
                              width: 20,
                              height: 20,
                            ),
                      label: Text(
                        _isAddingToWhatsApp
                            ? 'Adding...'
                            : 'ADD to whatsapp',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(
                          vertical: ScreenSize.spacingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isAddingToWhatsApp)
            Container(
              width: ScreenSize.widthPercent(90),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Adding to WhatsApp...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ScreenSize.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadStickerPack() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final controller = GetXRegistry.profile();
      final savePath = await controller.downloadDigitalProductToDevice(
        widget.itemId,
        widget.productName,
        orderId: widget.orderId,
        productId: widget.productId,
        isSticker: true,
        productType: 'sticker',
      );

      if (savePath != null && savePath.isNotEmpty) {
        setState(() {
          _isDownloading = false;
          _localFilePath = savePath;
          _downloadProgress = 1.0;
        });
        widget.onDownloadComplete?.call();
        Get.snackbar(
          'Download Complete',
          'Sticker pack downloaded successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        throw Exception('Download failed - no file path returned');
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      Get.snackbar(
        'Download Failed',
        'Could not download sticker pack: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _addToWhatsApp() async {
    if (_localFilePath == null) return;

    setState(() => _isAddingToWhatsApp = true);

    try {
      final controller = GetXRegistry.profile();
      await controller.unzipAndSaveStickersToGallery(
        _localFilePath!,
        widget.productName,
        skipPreview: true,
        onComplete: () {
          if (mounted) setState(() => _isAddingToWhatsApp = false);
          widget.onWhatsAppComplete?.call();
        },
      );

      Get.snackbar(
        'Stickers Ready!',
        'Stickers processed. Check WhatsApp or your gallery.',
        backgroundColor: const Color(0xFF25D366),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (mounted) setState(() => _isAddingToWhatsApp = false);
      if (e.toString().contains('handleStickerPackPreviewResult') ||
          e.toString().contains('Unable to add to WhatsApp')) {
        return;
      }
      Get.snackbar(
        'Save Failed',
        'Could not save stickers: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
