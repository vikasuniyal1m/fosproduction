import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../utils/digital_product_type.dart';
import '../../utils/silent_loading.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/sticker_download_dialog.dart';
import '../../watch_faces/watch_face_order_helper.dart';
import '../products/full_audio_player_screen.dart';
import '../products/full_video_player_screen.dart';

/// Order Details Screen
/// Shows complete order information including items, address, payment, etc.
class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final Rx<Set<int>> _downloadingItems = Rx<Set<int>>({});
  final RxSet<int> _whatsAppExportingItems = <int>{}.obs;
  final ValueNotifier<bool> _isWhatsAppLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.put(ProfileController())
          .getOrderDetails(widget.orderId, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    print('[OrderDetailsScreen] Building with orderId: ${widget.orderId}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print('[OrderDetailsScreen] Back button pressed - navigating to Home');
            Get.offAllNamed(AppRoutes.home);
          },
        ),
      ),
      body: Obx(() {
        final order = controller.orderDetailsFor(widget.orderId);
        if (SilentLoading.blockUi(
          isLoading: controller.isLoadingOrderDetail.value,
          hasContent: order != null,
        )) {
          return const LoadingWidget();
        }

        if (order == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: ScreenSize.iconExtraLarge * 2,
                  color: AppColors.error,
                ),
                SizedBox(height: ScreenSize.spacingLarge),
                Text(
                  'Failed to load order details',
                  style: TextStyle(
                    fontSize: ScreenSize.textLarge,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingMedium),
                ElevatedButton(
                  onPressed: () => controller.getOrderDetails(
                    widget.orderId,
                    silent: false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                  ),
                  child: Text('Retry', style: TextStyle(fontSize: ScreenSize.textMedium)),
                ),
              ],
            ),
          );
        }

        final items = order['items'] as List? ?? [];
        final shippingAddress =
            order['shipping_address'] as Map<String, dynamic>?;
        final billingAddress =
            order['billing_address'] as Map<String, dynamic>?;
        final hasPhysicalItems = DigitalProductType.hasPhysicalItemsInOrder(
          order,
          items: items,
        );
        final isDigitalOnly = DigitalProductType.isDigitalOrder(
          order,
          items: items,
        );
        final statusBadge = DigitalProductType.orderFulfillmentBadge(
          order,
          hasPhysicalItems: hasPhysicalItems,
          items: items,
        );
        final status = DigitalProductType.displayOrderStatus(
          order,
          items: items,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(ScreenSize.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeaderCard(
                order,
                status,
                hasPhysicalItems,
                statusBadge.show,
              ),
              SizedBox(height: ScreenSize.spacingMedium),
              if (items.isNotEmpty) ...[
                _buildSectionTitle('Order Items'),
                SizedBox(height: ScreenSize.spacingSmall),
                _buildOrderItems(items, controller, order),
                SizedBox(height: ScreenSize.spacingMedium),
              ],
              if (hasPhysicalItems && shippingAddress != null) ...[
                _buildSectionTitle('Shipping Address'),
                SizedBox(height: ScreenSize.spacingSmall),
                _buildAddressCard(shippingAddress, 'Shipping'),
                SizedBox(height: ScreenSize.spacingMedium),
              ],
              if (hasPhysicalItems &&
                  billingAddress != null &&
                  billingAddress != shippingAddress) ...[
                _buildSectionTitle('Billing Address'),
                SizedBox(height: ScreenSize.spacingSmall),
                _buildAddressCard(billingAddress, 'Billing'),
                SizedBox(height: ScreenSize.spacingMedium),
              ],
              _buildSectionTitle('Payment Information'),
              SizedBox(height: ScreenSize.spacingSmall),
              _buildPaymentCard(order, isDigitalOnly: isDigitalOnly),
              SizedBox(height: ScreenSize.spacingMedium),
              _buildSectionTitle('Order Summary'),
              SizedBox(height: ScreenSize.spacingSmall),
              _buildOrderSummary(order, hasPhysicalItems: hasPhysicalItems),
              SizedBox(height: ScreenSize.spacingLarge),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOrderHeaderCard(Map<String, dynamic> order, String status, bool hasPhysicalItems, bool shouldShowStatus) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Order #${order['order_number'] ?? order['id']}',
                  style: TextStyle(
                    fontSize: ScreenSize.textLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: ScreenSize.spacingSmall),
              // Only show status badge for physical products or non-pending status
              if (shouldShowStatus)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.spacingSmall,
                    vertical: ScreenSize.spacingExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                    ),
                    SizedBox(width: ScreenSize.spacingExtraSmall),
                    Text(
                      _formatStatus(status),
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'Placed on: ${_formatDate(order['created_at'])}',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
          if (hasPhysicalItems && order['tracking_number'] != null) ...[
            SizedBox(height: ScreenSize.spacingSmall),
            Row(
              children: [
                Icon(Icons.local_shipping, size: ScreenSize.iconSmall, color: AppColors.primary),
                SizedBox(width: ScreenSize.spacingSmall),
                Expanded(
                  child: Text(
                    'Tracking: ${order['tracking_number']}',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ScreenSize.textLarge,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
  
  Widget _buildOrderItems(List items, ProfileController controller, Map<String, dynamic> order) {
    final paymentStatus = (order['payment_status'] ?? '').toString().toLowerCase();
    final orderStatus = (order['status'] ?? '').toString().toLowerCase();
    // Consider order paid if payment_status is 'paid' OR if order status is 'completed'/'processing' (payment done)
    final isOrderPaid = paymentStatus == 'paid' || 
                        orderStatus == 'completed' || 
                        orderStatus == 'processing' ||
                        orderStatus == 'paid';

    // Simplified widget list to avoid infinite loops
    final widgets = <Widget>[];
    
    for (int i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      final isLast = i == items.length - 1;
      final itemMap = Map<String, dynamic>.from(item);
      final isDigital = item['is_digital'] == true || item['is_digital'] == 1;
      final productType = _getProductTypeFromName(item['product_name']?.toString());
      final isWatchFaceProduct = WatchFaceOrderHelper.isWatchFaceProductId(
            item['product_id'],
          ) ||
          WatchFaceOrderHelper.parseFaceIdFromNotes(
                order['order_notes']?.toString(),
              ) !=
              null;
      final isStickerProduct = !isWatchFaceProduct &&
          (productType == 'sticker' ||
          item['is_sticker_pack'] == true ||
          item['is_sticker'] == true ||
          item['category_id'] == 15);
      final isAudio = productType == 'audio';
      final isVideo = productType == 'video';
      final isFosLensProduct = (item['product_name']?.toString().toLowerCase().contains('fos lens') ?? false) ||
                               (item['product_name']?.toString().toLowerCase().contains('fos_lens') ?? false);
      final showWhatsApp = isStickerProduct && isOrderPaid;

      widgets.add(
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade300)),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  color: Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildOrderItemImage(itemMap),
              ),
              SizedBox(width: 12),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name'] ?? 'Product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Qty: ${item['quantity']} × \$${_itemUnitPrice(item).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    
                    // FOS Lens indicator
                    if (isFosLensProduct) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'FOS Lens Purchase',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                    ],

                    if (isWatchFaceProduct) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.watch, size: 14, color: AppColors.secondary),
                            SizedBox(width: 4),
                            Text(
                              'Watch Face Purchase',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    
                    SizedBox(height: 4),
                    
                    // WhatsApp button for stickers
                    if (showWhatsApp) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isWhatsAppLoading,
                          builder: (context, isLoading, child) {
                            return ElevatedButton.icon(
                              onPressed: isLoading ? null : () => _triggerStickerExportFromOrder(
                                controller,
                                item['product_name']?.toString() ?? 'Sticker Pack',
                                item['id'] as int
                              ),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/whatsapp.png',
                                      width: 20,
                                      height: 20,
                                    ),
                              label: Text(
                                isLoading ? 'Processing...' : 'Add to WhatsApp',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else if (isWatchFaceProduct) ...[
                      SizedBox(height: 8),
                      if (isOrderPaid) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _installWatchFaceFromOrder(order, item),
                            icon: const Icon(Icons.watch, size: 16, color: Colors.white),
                            label: const Text(
                              'Install Watch Face',
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Watch face available after payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ] else if (isDigital && !isStickerProduct && (isAudio || isVideo)) ...[
                      SizedBox(height: 8),
                      if (isOrderPaid) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Obx(() {
                                final isDownloading = _downloadingItems.value.contains(item['id']);
                                
                                return ElevatedButton.icon(
                                  onPressed: isDownloading ? null : () {
                                    if (isAudio) {
                                      _playAudioProduct(controller, item['id'] as int, item['product_name']?.toString() ?? 'Audio', item['image']?.toString());
                                    } else if (isVideo) {
                                      _playVideoProduct(controller, item['id'] as int, item['product_name']?.toString() ?? 'Video', item['image']?.toString());
                                    }
                                  },
                                icon: Icon(Icons.play_arrow, size: 16, color: Colors.white),
                                label: Text(
                                  'Play',
                                  style: TextStyle(fontSize: 12, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ));
                              },
                            ),
                            // const SizedBox(width: 8),
                            // // Download button
                            // Expanded(
                            //   child: Obx(() {
                            //     final isDownloading = _downloadingItems.contains(item['id']);
                            //     final progress = controller.downloadProgress[item['id']] ?? 0.0;
                            //
                            //     return ElevatedButton.icon(
                            //       onPressed: isDownloading ? null : () async {
                            //         // Prevent multiple simultaneous downloads
                            //         if (_downloadingItems.contains(item['id'])) {
                            //           return;
                            //         }
                            //
                            //         await _downloadDigitalProduct(
                            //           controller,
                            //           item['id'] as int,
                            //           item['product_name']?.toString() ?? 'Digital Product',
                            //           productType,
                            //           productImageUrl: item['image']?.toString(),
                            //         );
                            //       },
                            //       icon: isDownloading
                            //           ? SizedBox(
                            //               width: 18,
                            //               height: 16,
                            //               child: CircularProgressIndicator(
                            //                 strokeWidth: 2,
                            //                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            //               ),
                            //             )
                            //           : Icon(Icons.download, size: 16, color: Colors.white),
                            //       label: Container(
                            //         padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            //         child: Text(
                            //           isDownloading
                            //               ? '${progress.toStringAsFixed(0)}%'
                            //               : 'Download',
                            //           style: TextStyle(
                            //             fontSize: 11,
                            //             color: Colors.white,
                            //             fontWeight: FontWeight.w500,
                            //           ),
                            //           textAlign: TextAlign.center,
                            //         ),
                            //       ),
                            //       style: ElevatedButton.styleFrom(
                            //         backgroundColor: isDownloading
                            //             ? Colors.grey.shade600
                            //             : AppColors.primary,
                            //         foregroundColor: Colors.white,
                            //         minimumSize: Size(0, 36),
                            //         shape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(8),
                            //         ),
                            //       ),
                            //     );
                            //   },
                            // ),
                            // )
                            )
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Digital product available after payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              
              // Total
              Text(
                '\$${_itemLineTotal(item).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: widgets),
    );
  }

  static String _downloadLocationMessage(String savePath) {
    // Return the full exact file path so the user can easily locate it manually.
    return savePath.replaceAll(r'\', '/');
  }

  Future<void> _installWatchFaceFromOrder(
    Map<String, dynamic> order,
    Map<String, dynamic> item,
  ) async {
    await WatchFaceOrderHelper.installFromOrder(order, item);
  }

  /// Show download completion dialog instead of automatic navigation
  void _showDownloadCompleteDialog(BuildContext context, String productName, String location) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Download Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$productName has been downloaded successfully!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'File saved at:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                location,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to orders list
                    Get.offAllNamed(AppRoutes.orders);
                  },
                  icon: Icon(Icons.list_alt, size: 16),
                  label: Text('View Orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Determine product type from product name for correct download handling
  String? _getProductTypeFromName(String? productName) {
    if (productName == null || productName.isEmpty) return null;
    final lower = productName.toLowerCase();

    if (lower.contains('sticker') || lower.contains('stickers') ||
        lower.contains('sticker pack') || lower.contains('stickerpack') ||
        lower.contains('digital_stickers') || lower.contains('digital sticker')) {
      return 'sticker';
    }

    if (lower.contains('video') || lower.contains('mp4') || lower.contains('movie') || lower.contains('clip')) {
      return 'video';
    }

    if (lower.contains('audio') || lower.contains('mp3') || lower.contains('song') || lower.contains('jingle') || lower.contains('music')) {
      return 'audio';
    }

    if (lower.contains('.zip') || lower.contains('digital')) {
      return 'sticker';
    }

    final fruitNames = [
      'apple', 'banana', 'orange', 'grape', 'strawberry', 'peach', 'pear',
      'mango', 'pineapple', 'watermelon', 'cherry', 'kiwi', 'lemon', 'lime',
      'coconut', 'avocado', 'papaya', 'pomegranate', 'fig', 'plum', 'apricot'
    ];

    if (fruitNames.any((fruit) => lower.contains(fruit))) {
      return 'sticker';
    }

    return null;
  }

  Future<void> _downloadDigitalProduct(ProfileController controller, int orderItemId, String productName, String? productType, {String? productImageUrl}) async {
    // Set loading state
    _downloadingItems.value.add(orderItemId);
    
    try {
      debugPrint('[OrderDetails] Download started for orderItemId=$orderItemId, type=$productType (lifetime save to device)');
      final savePath = await controller.downloadDigitalProductToDevice(
        orderItemId, 
        productName,
        productType: productType,
      );
      if (savePath != null && savePath.isNotEmpty) {
        // For audio files, open the professional audio player
        if (productType == 'audio') {
          final url = await controller.getDigitalDownloadUrl(orderItemId);
          if (url != null && url.isNotEmpty) {
            Get.to(() => FullAudioPlayerScreen(
              audioUrl: url,
              filePath: savePath,
              productName: productName,
              productImageUrl: productImageUrl,
            ));
            return;
          }
        }
        
        // For video files, open the professional video player
        if (productType == 'video') {
          final url = await controller.getDigitalDownloadUrl(orderItemId);
          if (url != null && url.isNotEmpty) {
            Get.to(() => FullVideoPlayerScreen(
              videoUrl: url,
              filePath: savePath,
              productName: productName,
              productImageUrl: productImageUrl,
            ));
            return;
          }
        }
        
        // For other file types, show download completion dialog
        final location = _downloadLocationMessage(savePath);
        _showDownloadCompleteDialog(context, productName, location);
      }
    } catch (e) {
      debugPrint('[OrderDetails] Download to device failed: $e');
      // Fallback: open URL in browser so user can still download
      final url = await controller.getDigitalDownloadUrl(orderItemId);
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
      _downloadingItems.value.remove(orderItemId);
    }
  }

  /// Play audio — open player instantly, resolve URL inside player.
  void _playAudioProduct(
    ProfileController controller,
    int orderItemId,
    String productName,
    String? productImageUrl,
  ) {
    Get.to(() => FullAudioPlayerScreen(
      audioUrl: '',
      orderItemId: orderItemId,
      filePath: '',
      productName: productName,
      productImageUrl: productImageUrl,
    ));
  }

  /// Play video — open player instantly, stream while URL resolves inside player.
  void _playVideoProduct(
    ProfileController controller,
    int orderItemId,
    String productName,
    String? productImageUrl,
  ) {
    Get.to(() => FullVideoPlayerScreen(
      videoUrl: '',
      orderItemId: orderItemId,
      filePath: '',
      productName: productName,
      productImageUrl: productImageUrl,
    ));
  }

  /// View and play downloaded audio/video file
  Future<void> _viewDownloadedFile(ProfileController controller, int orderItemId, String productName, String? productType) async {
    try {
      debugPrint('[OrderDetails] Viewing downloaded file: orderItemId=$orderItemId, type=$productType');
      
      // Get file URL for streaming
      final url = await controller.getDigitalDownloadUrl(orderItemId);
      if (url != null && url.isNotEmpty) {
        if (productType == 'audio') {
          // Navigate to full audio player screen for streaming
          Get.to(() => FullAudioPlayerScreen(
            audioUrl: url,
            filePath: '', // Empty file path since we're streaming
            productName: productName,
            productImageUrl: null,
          ));
        } else if (productType == 'video') {
          // Navigate to full video player screen for streaming
          Get.to(() => FullVideoPlayerScreen(
            videoUrl: url,
            filePath: '', // Empty file path since we're streaming
            productName: productName,
            productImageUrl: null,
          ));
        }
      } else {
        Get.snackbar(
          'Error',
          'Could not load media file',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
        );
      }
    } catch (e) {
      debugPrint('[OrderDetails] Error viewing downloaded file: $e');
      Get.snackbar(
        'Error',
        'Failed to view file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    }
  }

  /// Show professional sticker download dialog
  Future<void> _showStickerDownloadDialog(String productName, int orderItemId) async {
    try {
      // Get download URL for the sticker pack
      final controller = Get.put(ProfileController());
      final downloadInfo = await controller.getDigitalDownloadInfo(
        orderItemId, 
        orderId: widget.orderId,
        productId: null,
        isSticker: true,
      );
      
      if (downloadInfo != null && downloadInfo['download_url'] != null) {
        final downloadUrl = downloadInfo['download_url'].toString();
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StickerDownloadDialog(
            productName: productName,
            downloadUrl: downloadUrl,
            itemId: orderItemId,
            orderId: widget.orderId,
            productId: null, // Will be fetched from item data
            onDownloadComplete: () {
              // Update UI state after download
              _downloadingItems.value.remove(orderItemId);
            },
            onWhatsAppComplete: () {
              _whatsAppExportingItems.remove(orderItemId);
            },
          ),
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not get download URL for stickers',
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open sticker download: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    }
  }

  /// Download ZIP then unzip + preview (old working flow).
  Future<void> _downloadAndExport(
    ProfileController controller,
    int orderItemId,
    String savePath,
    String productName,
  ) async {
    try {
      final url = await controller.getDigitalDownloadUrl(orderItemId);
      if (url != null && url.isNotEmpty) {
        final dio = Dio();
        await dio.download(url, savePath);
        debugPrint('[OrderDetails] ZIP downloaded to $savePath');
        await controller.unzipAndSaveStickersToGallery(savePath, productName);
      }
    } catch (e) {
      debugPrint('[OrderDetails] Download error: $e');
    }
  }

  /// Re-trigger sticker extraction and WhatsApp export from an order item
  Future<void> _triggerStickerExportFromOrder(ProfileController controller, String productName, int orderItemId) async {
    _isWhatsAppLoading.value = true;
    _whatsAppExportingItems.add(orderItemId);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/DigitalDownloads');

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final safeName = productName.replaceAll(RegExp(r'[^\w\s\-.]'), '_').replaceAll(RegExp(r'\s+'), '_');
      final fileName = '${safeName}_Stickers.zip';
      final savePath = '${downloadDir.path}/$fileName';

      if (File(savePath).existsSync()) {
        debugPrint('[OrderDetails] Existing ZIP found at $savePath. Exporting to WhatsApp...');
        await controller.unzipAndSaveStickersToGallery(savePath, productName);
      } else {
        debugPrint('[OrderDetails] ZIP not found at $savePath. Downloading in background...');
        await _downloadAndExport(controller, orderItemId, savePath, productName);
      }
    } catch (e) {
      debugPrint('[OrderDetails] Error in sticker export: $e');

      if (e.toString().contains('handleStickerPackPreviewResult') ||
          e.toString().contains('Unable to add to WhatsApp')) {
        print('[OrderDetails] WhatsApp error detected, delegating to main handler');
      } else {
        Get.snackbar('Error', 'Failed to export stickers to WhatsApp: $e', snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      _isWhatsAppLoading.value = false;
      _whatsAppExportingItems.remove(orderItemId);
    }
  }

  Map<String, dynamic> _orderItemAsProduct(Map<String, dynamic> item) => {
        'id': item['product_id'] ?? item['id'],
        'image': item['image'],
        'banner': item['banner'],
        'is_digital': item['is_digital'],
        'category_id': item['category_id'],
        'media_type': item['media_type'],
        'is_sticker_pack': item['is_sticker_pack'],
      };

  Widget _buildOrderItemImage(Map<String, dynamic> item) {
    if (item['watch_face_preview'] != null) {
      return WatchFaceOrderHelper.buildPreviewImage(
        item,
        size: 64,
        cacheKeyPrefix: 'order_item',
      );
    }
    return ProductCardImage(
      product: _orderItemAsProduct(item),
      cacheKeyPrefix: 'order_item',
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, String type) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                type == 'Shipping' ? Icons.local_shipping : Icons.payment,
                size: ScreenSize.iconSmall,
                color: AppColors.primary,
              ),
              SizedBox(width: ScreenSize.spacingSmall),
              Text(
                '$type Address',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            address['name'] ?? '',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (address['phone'] != null) ...[
            SizedBox(height: ScreenSize.spacingExtraSmall),
            Text(
              address['phone'],
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: ScreenSize.spacingExtraSmall),
          Text(
            '${address['address_line1'] ?? ''}${address['address_line2'] != null && address['address_line2'].toString().isNotEmpty ? ', ${address['address_line2']}' : ''}',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['pincode'] ?? ''}',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentCard(
    Map<String, dynamic> order, {
    bool isDigitalOnly = false,
  }) {
    final paymentMethod = order['payment_method'] ?? 'cash_on_delivery';
    var paymentStatus =
        (order['payment_status'] ?? 'pending').toString().toLowerCase();
    if (isDigitalOnly) {
      paymentStatus = 'paid';
    }
    final paymentDetails = order['payment_method_details'] as Map<String, dynamic>?;
    
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.spacingSmall,
                  vertical: ScreenSize.spacingExtraSmall,
                ),
                decoration: BoxDecoration(
                  color: paymentStatus == 'paid' 
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                  border: Border.all(
                    color: paymentStatus == 'paid' ? AppColors.success : AppColors.warning,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: paymentStatus == 'paid' ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: ScreenSize.spacingExtraSmall),
                    Text(
                      _formatStatus(paymentStatus),
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: paymentStatus == 'paid' ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            isDigitalOnly
                ? _formatDigitalPaymentMethod(paymentMethod)
                : _formatPaymentMethod(paymentMethod),
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
          if (paymentDetails != null) ...[
            SizedBox(height: ScreenSize.spacingSmall),
            if (paymentDetails['card_last_4'] != null)
              Text(
                'Card ending in ${paymentDetails['card_last_4']}',
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  color: AppColors.textTertiary,
                ),
              ),
            if (paymentDetails['upi_id'] != null)
              Text(
                'UPI: ${paymentDetails['upi_id']}',
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ],
      ),
    );
  }
  
  double _itemUnitPrice(Map<String, dynamic> item) => _parseDouble(
        item['price'] ??
            item['unit_price'] ??
            item['product_price'] ??
            item['item_price'] ??
            item['amount'] ??
            item['paid_price'] ??
            item['final_price'] ??
            0.0,
      );

  double _itemLineTotal(Map<String, dynamic> item) {
    final direct = _parseDouble(
      item['total'] ??
          item['line_total'] ??
          item['item_total'] ??
          item['paid_amount'] ??
          item['final_amount'] ??
          item['amount'] ??
          0.0,
    );
    if (direct > 0) return direct;
    final qty = item['quantity'] is int
        ? item['quantity'] as int
        : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    return _itemUnitPrice(item) * qty;
  }

  Widget _buildOrderSummary(
    Map<String, dynamic> order, {
    bool hasPhysicalItems = true,
  }) {
    final subtotal = _parseDouble(
      order['subtotal'] ?? order['sub_total'] ?? 0.0,
    );
    final shipping = _parseDouble(
      order['shipping_amount'] ?? order['shipping_cost'] ?? order['shipping'] ?? 0.0,
    );
    final tax = _parseDouble(
      order['tax_amount'] ?? order['tax'] ?? 0.0,
    );
    final discount = _parseDouble(
      order['discount_amount'] ?? order['discount'] ?? 0.0,
    );
    var total = _parseDouble(
      order['total_amount'] ?? order['total'] ?? order['grand_total'] ?? 0.0,
    );
    if (total <= 0) {
      total = subtotal + shipping + tax - discount;
    }
    
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal),
          if (hasPhysicalItems && shipping > 0)
            _buildSummaryRow('Shipping', shipping),
          if (tax > 0) _buildSummaryRow('Tax', tax),
          if (discount > 0) _buildSummaryRow('Discount', -discount, isDiscount: true),
          Divider(height: ScreenSize.spacingLarge),
          _buildSummaryRow('Total', total, isTotal: true),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? ScreenSize.textLarge : ScreenSize.textMedium,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? ScreenSize.textLarge : ScreenSize.textMedium,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
  
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  String _formatStatus(String status) {
    if (status.toLowerCase() == 'paid') return 'Paid';
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDigitalPaymentMethod(dynamic method) {
    final m = method?.toString().toLowerCase() ?? '';
    if (m == 'stripe' || m == 'card' || m.contains('online')) {
      return 'Online Payment';
    }
    if (m == 'cash_on_delivery' || m == 'cod') {
      return 'Digital Purchase';
    }
    return _formatPaymentMethod(method);
  }
  
  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'upi':
        return 'UPI';
      case 'wallet':
        return 'Digital Wallet';
      case 'net_banking':
        return 'Net Banking';
      default:
        return method.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

