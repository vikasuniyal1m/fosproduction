import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';

/// Add/Edit Payment Method Screen
/// Allows user to add or edit payment methods (Card, UPI, Wallet, Net Banking)
class AddEditPaymentMethodScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentMethod;
  
  const AddEditPaymentMethodScreen({super.key, this.paymentMethod});
  
  @override
  State<AddEditPaymentMethodScreen> createState() => _AddEditPaymentMethodScreenState();
}

class _AddEditPaymentMethodScreenState extends State<AddEditPaymentMethodScreen> {
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize form only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        final controller = Get.find<ProfileController>();
        if (widget.paymentMethod != null) {
          controller.initializePaymentMethodForm(widget.paymentMethod!);
        } else {
          controller.clearPaymentMethodForm();
        }
        _isInitialized = true;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.paymentMethod != null ? 'Edit Payment Method' : 'Add Payment Method',
          style: TextStyle(fontSize: ScreenSize.headingMedium),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightLarge,
      ),
      body: Form(
        key: controller.paymentMethodFormKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ScreenSize.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment Method Type
              Text(
                'Payment Method Type',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: ScreenSize.spacingSmall),
              Obx(() => DropdownButtonFormField<String>(
                value: controller.paymentMethodType.value,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.inputPadding,
                    vertical: ScreenSize.spacingMedium,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'upi',
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: AppColors.secondary, size: ScreenSize.iconSmall),
                        SizedBox(width: ScreenSize.spacingSmall),
                        Text('UPI', style: TextStyle(fontSize: ScreenSize.textMedium)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'wallet',
                    child: Row(
                      children: [
                        Icon(Icons.wallet, color: AppColors.accent, size: ScreenSize.iconSmall),
                        SizedBox(width: ScreenSize.spacingSmall),
                        Text('Wallet', style: TextStyle(fontSize: ScreenSize.textMedium)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'netbanking',
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, color: AppColors.info, size: ScreenSize.iconSmall),
                        SizedBox(width: ScreenSize.spacingSmall),
                        Text('Net Banking', style: TextStyle(fontSize: ScreenSize.textMedium)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'cash_on_delivery',
                    child: Row(
                      children: [
                        Icon(Icons.money, color: AppColors.success, size: ScreenSize.iconSmall),
                        SizedBox(width: ScreenSize.spacingSmall),
                        Text('Cash on Delivery', style: TextStyle(fontSize: ScreenSize.textMedium)),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    // Only clear type-specific fields, keep is_default and other settings
                    controller.clearTypeSpecificFields();
                    controller.paymentMethodType.value = value;
                  }
                },
              )),
              SizedBox(height: ScreenSize.spacingExtraLarge),
              
              // Type-specific fields
              Obx(() => _buildTypeSpecificFields(controller)),
              
              SizedBox(height: ScreenSize.spacingExtraLarge),
              
              // Set as Default
              Obx(() => CheckboxListTile(
                title: Text('Set as default payment method', style: TextStyle(fontSize: ScreenSize.textMedium)),
                value: controller.isDefaultPaymentMethod.value,
                onChanged: (value) {
                  controller.isDefaultPaymentMethod.value = value ?? false;
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              )),
              
              SizedBox(height: ScreenSize.spacingExtraLarge),
              
              // Save Button
              SizedBox(
                height: ScreenSize.buttonHeightMedium,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isSavingPaymentMethod.value
                      ? null
                      : () => controller.savePaymentMethod(widget.paymentMethod != null ? widget.paymentMethod!['id'] as int? : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.buttonPaddingHorizontal,
                      vertical: ScreenSize.buttonPaddingVertical,
                    ),
                  ),
                  child: Obx(() => controller.isSavingPaymentMethod.value
                      ? SizedBox(
                          width: ScreenSize.iconSmall,
                          height: ScreenSize.iconSmall,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                          ),
                        )
                      : Text(
                          widget.paymentMethod != null ? 'Update Payment Method' : 'Add Payment Method',
                          style: TextStyle(fontSize: ScreenSize.textMedium),
                        )),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTypeSpecificFields(ProfileController controller) {
    switch (controller.paymentMethodType.value) {
      case 'cash_on_delivery':
        return _buildCashOnDeliveryFields();
      case 'upi':
        return _buildUPIFields(controller);
      case 'wallet':
        return _buildWalletFields(controller);
      case 'netbanking':
        return _buildNetBankingFields(controller);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUPIFields(ProfileController controller) {
    return TextFormField(
      controller: controller.upiIdController,
      decoration: InputDecoration(
        labelText: 'UPI ID',
        hintText: 'yourname@paytm',
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'UPI ID is required';
        }
        if (!RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$').hasMatch(value)) {
          return 'Invalid UPI ID format';
        }
        return null;
      },
    );
  }
  
  Widget _buildWalletFields(ProfileController controller) {
    return DropdownButtonFormField<String>(
      value: controller.walletTypeController.text.isEmpty ? null : controller.walletTypeController.text,
      decoration: InputDecoration(
        labelText: 'Wallet Type',
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: ['paytm', 'phonepe', 'googlepay', 'amazonpay'].map((wallet) {
        return DropdownMenuItem(
          value: wallet,
          child: Text(wallet.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.walletTypeController.text = value;
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Wallet type is required';
        }
        return null;
      },
    );
  }
  
  Widget _buildNetBankingFields(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.bankNameController,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            hintText: 'State Bank of India',
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bank name is required';
            }
            return null;
          },
        ),
        SizedBox(height: ScreenSize.spacingLarge),
        TextFormField(
          controller: controller.accountNumberController,
          decoration: InputDecoration(
            labelText: 'Account Number (Last 4 digits)',
            hintText: '1234',
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Account number is required';
            }
            if (value.length < 4) {
              return 'Enter last 4 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCashOnDeliveryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash on Delivery does not require additional payment details.',
          style: TextStyle(
            fontSize: ScreenSize.textMedium,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: ScreenSize.spacingMedium),
        Text(
          'You will pay with cash when your order is delivered.',
          style: TextStyle(
            fontSize: ScreenSize.textSmall,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
