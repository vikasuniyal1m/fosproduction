import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/api_endpoints.dart';

/// Order Confirmation Screen
/// Shows order success message, order details, and for digital orders: download option (DB already updated with payment_status = paid).
class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  Map<String, dynamic>? _orderDetails; // full order with items (for digital download)
  bool _loadingDetails = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _maybeFetchOrderDetails();
  }

  void _maybeFetchOrderDetails() {
    final args = Get.arguments;
    if (args is! Map<String, dynamic>) return;
    final isDigital = args['is_digital_order'] == true;
    final order = args['order'] as Map<String, dynamic>? ?? args;
    if (!isDigital || order == null) return;
    final orderId = order['id'];
    if (orderId == null) return;
    setState(() => _loadingDetails = true);
    _apiService.get(ApiEndpoints.orderDetails, queryParameters: {'id': orderId.toString()}).then((response) {
      try {
        final data = ApiService.handleResponse(response);
        if (mounted) setState(() {
          _orderDetails = data;
          _loadingDetails = false;
        });
      } catch (_) {
        if (mounted) setState(() => _loadingDetails = false);
      }
    }).catchError((_) {
      if (mounted) setState(() => _loadingDetails = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    Map<String, dynamic>? order;
    bool isDigitalOrder = false;

    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      order = args['order'] as Map<String, dynamic>? ?? args;
      isDigitalOrder = args['is_digital_order'] == true;
    } else if (args is int) {
      // If only order ID is passed, create minimal order map
      order = {
        'id': args,
        'order_number': 'ORD-$args',
        'status': 'confirmed',
        'payment_status': 'pending',
        'total': 0.0,
      };
    } else {
      order = null;
    }
    
    return PopScope(
      // Prevent back navigation from order confirmation
      // User should use the action buttons to navigate
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Show message that they should use action buttons
          Get.snackbar(
            'Info',
            'Please use the buttons below to continue',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ScreenSize.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: ScreenSize.spacingExtraLarge),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 60, color: AppColors.success),
                ),
                SizedBox(height: ScreenSize.spacingLarge),
                Text(
                  'Order Placed Successfully!',
                  style: TextStyle(
                    fontSize: ScreenSize.headingLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                Text(
                  'Thank you for your order. We have received your order and will begin processing it right away.',
                  style: TextStyle(
                    fontSize: ScreenSize.textMedium,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ScreenSize.spacingMedium),
                Container(
                  padding: EdgeInsets.all(ScreenSize.spacingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: AppColors.primary, size: 24),
                      SizedBox(width: ScreenSize.spacingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice Sent',
                              style: TextStyle(
                                fontSize: ScreenSize.textMedium,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your invoice has been sent to your email address',
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ScreenSize.spacingExtraLarge),
                if (order != null) _buildOrderDetailsCard(order),
                SizedBox(height: ScreenSize.spacingExtraLarge),
                if (isDigitalOrder && order != null)
                  _buildDownloadSection(order),
                _buildActionButtons(isDigitalOrder),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(Map<String, dynamic> order) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: TextStyle(
              fontSize: ScreenSize.headingSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          _buildDetailRow('Order Number', order['order_number'] ?? ''),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildDetailRow('Order Status', order['status'] ?? 'pending'),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildDetailRow('Payment Status', order['payment_status'] ?? 'pending'),
          SizedBox(height: ScreenSize.spacingSmall),
          _buildDetailRow(
            'Total Amount',
            '\$${(order['total'] ?? order['total_amount'] ?? 0.0).toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ScreenSize.textMedium,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? ScreenSize.textLarge : ScreenSize.textMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadSection(Map<String, dynamic> order) {
    if (_loadingDetails) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: ScreenSize.spacingLarge),
        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: ScreenSize.spacingSmall),
            Text(
              'Preparing download...',
              style: TextStyle(fontSize: ScreenSize.textMedium, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final items = _orderDetails?['items'] as List<dynamic>? ?? [];
    final digitalItems = items.where((e) => e is Map && (e['is_digital'] == true || e['is_digital'] == 1)).cast<Map<String, dynamic>>().toList();
    if (digitalItems.isEmpty) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: ScreenSize.spacingLarge),
        child: ElevatedButton.icon(
          onPressed: () => Get.offNamed(AppRoutes.orders),
          icon: Icon(Icons.download, color: Colors.white),
          label: Text(
            'View Orders to Download',
            style: TextStyle(fontSize: ScreenSize.textLarge, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: ScreenSize.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Download your purchase (lifetime access)',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          ...digitalItems.map((item) {
            final orderItemId = item['id'] as int?;
            final name = item['product_name'] as String? ?? 'Digital file';
            if (orderItemId == null) return SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
              child: ElevatedButton.icon(
                onPressed: () => _startDownload(orderItemId),
                icon: Icon(Icons.download, color: Colors.white, size: 20),
                label: Text(
                  'Download: $name',
                  style: TextStyle(fontSize: ScreenSize.textMedium, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _startDownload(int orderItemId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderDownload,
        queryParameters: {'order_item_id': orderItemId.toString()},
      );
      final data = ApiService.handleResponse(response);
      final downloadUrl = data['download_url'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        Get.snackbar('Error', 'Download link not available', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Get.snackbar('Success', 'Download started', snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.success, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Could not open download link', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }

  Widget _buildActionButtons([bool isDigitalOrder = false]) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.offNamed(AppRoutes.orders),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius)),
            ),
            child: Text(
              'View Orders',
              style: TextStyle(fontSize: ScreenSize.textLarge, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(height: ScreenSize.spacingMedium),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Get.offAllNamed(AppRoutes.home),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius)),
            ),
            child: Text(
              'Continue Shopping',
              style: TextStyle(fontSize: ScreenSize.textLarge, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
