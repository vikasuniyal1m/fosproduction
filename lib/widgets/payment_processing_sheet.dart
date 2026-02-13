import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';

/// Payment Processing Bottom Sheet
/// Shows payment processing UI for online payment methods
class PaymentProcessingSheet extends StatefulWidget {
  final String paymentMethodType;
  final String paymentMethodName;
  final double amount;
  final Function() onSuccess;
  final Function() onFailure;
  
  const PaymentProcessingSheet({
    super.key,
    required this.paymentMethodType,
    required this.paymentMethodName,
    required this.amount,
    required this.onSuccess,
    required this.onFailure,
  });
  
  @override
  State<PaymentProcessingSheet> createState() => _PaymentProcessingSheetState();
}

class _PaymentProcessingSheetState extends State<PaymentProcessingSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isWaitingForOTP = true;
  bool _isVerifyingOTP = false;
  bool _isSuccess = false;
  bool _isFailed = false;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Show payment portal initially
    Future.delayed(const Duration(milliseconds: 500), () {
      _otpFocusNode.requestFocus();
    });
  }
  
  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty) {
      Get.snackbar('Error', 'Please enter OTP');
      return;
    }
    
    if (otp.length < 4) {
      Get.snackbar('Error', 'Please enter valid OTP');
      return;
    }
    
    setState(() {
      _isWaitingForOTP = false;
      _isVerifyingOTP = true;
    });
    
    _animationController.repeat();
    
    // Simulate OTP verification delay (2-3 seconds)
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate payment success (in real app, this would be actual payment gateway response)
    // For demo, any 4+ digit OTP will succeed
    setState(() {
      _isVerifyingOTP = false;
      _isSuccess = true;
    });
    
    _animationController.stop();
    
    // Wait a bit to show success animation
    await Future.delayed(const Duration(seconds: 1));
    
    // Call success callback
    widget.onSuccess();
  }
  
  void _handleFailure() {
    setState(() {
      _isWaitingForOTP = true;
      _isVerifyingOTP = false;
      _isFailed = false;
      _otpController.clear();
    });
    _otpFocusNode.requestFocus();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ScreenSize.tileBorderRadiusLarge),
          topRight: Radius.circular(ScreenSize.tileBorderRadiusLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: ScreenSize.spacingMedium),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ScreenSize.spacingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: ScreenSize.spacingExtraLarge),
                // Payment Method Info
                Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: ScreenSize.spacingSmall),
                    Expanded(
                      child: Text(
                        widget.paymentMethodName,
                        style: TextStyle(
                          fontSize: ScreenSize.textMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ScreenSize.spacingMedium),
                Text(
                  '₹${widget.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: ScreenSize.headingLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: ScreenSize.spacingLarge),
                
                if (_isWaitingForOTP) ...[
                  // OTP Input State
                  Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: ScreenSize.headingMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  Text(
                    'We have sent an OTP to your registered mobile number',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: TextStyle(
                      fontSize: ScreenSize.headingMedium,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '0000',
                      hintStyle: TextStyle(
                        fontSize: ScreenSize.headingMedium,
                        letterSpacing: 8,
                        color: AppColors.textTertiary,
                      ),
                      counterText: '',
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
                      filled: true,
                      fillColor: AppColors.cardBackground,
                    ),
                    onSubmitted: (_) => _verifyOTP(),
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
                        ),
                      ),
                      child: Text(
                        'Verify & Pay',
                        style: TextStyle(
                          fontSize: ScreenSize.textLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  TextButton(
                    onPressed: () {
                      Get.snackbar('Info', 'OTP will be sent to your registered mobile');
                    },
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ] else if (_isVerifyingOTP) ...[
                  // Verifying OTP state
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 2 * 3.14159,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.payment,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  Text(
                    'Verifying Payment',
                    style: TextStyle(
                      fontSize: ScreenSize.headingMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  Text(
                    'Please wait while we verify your payment',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_isSuccess) ...[
                  // Success state
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 50,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontSize: ScreenSize.headingMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  Text(
                    'Your payment has been processed successfully',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_isFailed) ...[
                  // Failed state
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 50,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  Text(
                    'Payment Failed',
                    style: TextStyle(
                      fontSize: ScreenSize.headingMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: ScreenSize.spacingSmall),
                  Text(
                    'Please try again or use a different payment method',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ScreenSize.spacingLarge),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleFailure,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(vertical: ScreenSize.spacingMedium),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

