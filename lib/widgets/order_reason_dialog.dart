import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';

/// Order Reason Dialog
/// Dialog for entering cancel/return reason
class OrderReasonDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final List<String>? predefinedReasons;
  final bool isReturn;
  
  const OrderReasonDialog({
    super.key,
    required this.title,
    required this.hintText,
    this.predefinedReasons,
    this.isReturn = false,
  });
  
  @override
  State<OrderReasonDialog> createState() => _OrderReasonDialogState();
}

class _OrderReasonDialogState extends State<OrderReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  final RxBool _isSubmitting = false.obs;
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
  
  void _submit() {
    final reason = _selectedReason ?? _reasonController.text.trim();
    
    if (reason.isEmpty) {
      Get.snackbar(
        'Error',
        'Please provide a reason',
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
      );
      return;
    }
    
    _isSubmitting.value = true;
    Get.back(result: reason);
  }
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
      ),
      child: Container(
        padding: EdgeInsets.all(ScreenSize.spacingLarge),
        constraints: BoxConstraints(
          maxWidth: ScreenSize.screenWidth * 0.9,
          maxHeight: ScreenSize.screenHeight * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontSize: ScreenSize.headingMedium,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            
            // Predefined reasons (if provided)
            if (widget.predefinedReasons != null && widget.predefinedReasons!.isNotEmpty) ...[
              Text(
                'Select a reason:',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: ScreenSize.spacingSmall),
              ...widget.predefinedReasons!.map((reason) {
                return RadioListTile<String>(
                  title: Text(
                    reason,
                    style: TextStyle(fontSize: ScreenSize.textMedium),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                      _reasonController.clear();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }),
              SizedBox(height: ScreenSize.spacingMedium),
              Text(
                'Or enter your own reason:',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: ScreenSize.spacingSmall),
            ],
            
            // Text field for custom reason
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _selectedReason = null;
                  });
                }
              },
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                SizedBox(width: ScreenSize.spacingSmall),
                Obx(() => ElevatedButton(
                  onPressed: _isSubmitting.value ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isReturn ? AppColors.warning : AppColors.error,
                    foregroundColor: AppColors.textWhite,
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.spacingLarge,
                      vertical: ScreenSize.spacingSmall,
                    ),
                  ),
                  child: _isSubmitting.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                          ),
                        )
                      : Text(widget.isReturn ? 'Submit Return' : 'Cancel Order'),
                )),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}

