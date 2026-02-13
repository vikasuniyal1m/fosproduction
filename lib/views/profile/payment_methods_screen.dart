import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';

/// Payment Methods Screen
/// Manages user saved payment methods
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Payment Methods',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: ScreenSize.iconMedium),
            onPressed: controller.navigateToAddPaymentMethod,
            tooltip: 'Add Payment Method',
          ),
        ],
      ),
      body: Obx(() => controller.isLoadingPaymentMethods.value
          ? const LoadingWidget()
          : controller.paymentMethods.isEmpty
              ? _buildEmptyState(controller)
              : RefreshIndicator(
                  onRefresh: controller.loadPaymentMethods,
                  child: ListView.builder(
                    padding: EdgeInsets.all(ScreenSize.spacingMedium),
                    itemCount: controller.paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = controller.paymentMethods[index];
                      return _buildPaymentMethodCard(method, controller);
                    },
                  ),
                )),
      // Removed floating action button to avoid redundancy with app bar action button
    );
  }
  
  Widget _buildEmptyState(ProfileController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: ScreenSize.iconExtraLarge * 2,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          Text(
            'No Payment Methods',
            style: TextStyle(
              fontSize: ScreenSize.headingMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Text(
            'Add a payment method for faster checkout',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingExtraLarge),
          ElevatedButton(
            onPressed: controller.navigateToAddPaymentMethod,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: EdgeInsets.symmetric(
                horizontal: ScreenSize.spacingLarge,
                vertical: ScreenSize.spacingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
              ),
            ),
            child: Text('Add Payment Method', style: TextStyle(fontSize: ScreenSize.textMedium)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodCard(Map<String, dynamic> method, ProfileController controller) {
    final type = method['type'] ?? 'card';
    final isDefault = method['is_default'] ?? false;
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'card':
        icon = Icons.credit_card;
        iconColor = AppColors.primary;
        break;
      case 'upi':
        icon = Icons.account_balance_wallet;
        iconColor = AppColors.secondary;
        break;
      case 'wallet':
        icon = Icons.wallet;
        iconColor = AppColors.accent;
        break;
      case 'netbanking':
        icon = Icons.account_balance;
        iconColor = AppColors.info;
        break;
      default:
        icon = Icons.payment;
        iconColor = AppColors.textSecondary;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(ScreenSize.spacingSmall),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              ),
              child: Icon(icon, color: iconColor, size: ScreenSize.iconMedium),
            ),
            title: Text(
              method['label'] ?? method['display'] ?? 'Payment Method',
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _getPaymentMethodSubtitle(method),
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: isDefault
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.spacingSmall,
                      vertical: ScreenSize.spacingExtraSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(ScreenSize.borderRadiusSmall),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  )
                : null,
          ),
          Divider(height: 1, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!isDefault)
                TextButton.icon(
                  onPressed: () => controller.setDefaultPaymentMethod(method['id']),
                  icon: Icon(Icons.star_outline, size: ScreenSize.iconSmall),
                  label: Text('Set Default', style: TextStyle(fontSize: ScreenSize.textMedium)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              TextButton.icon(
                onPressed: () => controller.editPaymentMethod(method),
                icon: Icon(Icons.edit_outlined, size: ScreenSize.iconSmall),
                label: Text('Edit', style: TextStyle(fontSize: ScreenSize.textMedium)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.info,
                ),
              ),
              TextButton.icon(
                onPressed: () => controller.deletePaymentMethod(method['id']),
                icon: Icon(Icons.delete_outline, size: ScreenSize.iconSmall),
                label: Text('Delete', style: TextStyle(fontSize: ScreenSize.textMedium)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getPaymentMethodSubtitle(Map<String, dynamic> method) {
    final type = method['type'] ?? 'card';
    
    if (type == 'card') {
      final expiryMonth = method['card_expiry_month'];
      final expiryYear = method['card_expiry_year'];
      if (expiryMonth != null && expiryYear != null) {
        return 'Expires ${expiryMonth.toString().padLeft(2, '0')}/${expiryYear}';
      }
      return 'Credit/Debit Card';
    } else if (type == 'upi') {
      return 'UPI Payment';
    } else if (type == 'wallet') {
      return '${method['wallet_type'] ?? 'Wallet'} Wallet';
    } else if (type == 'netbanking') {
      return 'Net Banking';
    }
    
    return 'Payment Method';
  }
}

