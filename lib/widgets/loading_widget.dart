import 'package:flutter/material.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';

/// Loading Widget
/// Reusable loading indicator for the entire app
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  final bool isFullScreen;
  
  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size,
    this.isFullScreen = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final loadingWidget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? ScreenSize.iconExtraLarge,
            height: size ?? ScreenSize.iconExtraLarge,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: ScreenSize.spacingMedium),
            Text(
              message!,
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
    
    if (isFullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background.withOpacity(0.9),
        body: loadingWidget,
      );
    }
    
    return loadingWidget;
  }
}

/// Overlay Loading Widget
/// Shows loading overlay on top of current screen
class OverlayLoading extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  
  const OverlayLoading({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.overlayLight,
            child: LoadingWidget(
              message: message,
              isFullScreen: true,
            ),
          ),
      ],
    );
  }
}

/// Button Loading Widget
/// Shows loading indicator inside a button
class ButtonLoading extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? color;
  
  const ButtonLoading({
    super.key,
    required this.isLoading,
    required this.child,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: ScreenSize.iconSmall,
          height: ScreenSize.iconSmall,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.textWhite,
            ),
          ),
        ),
      );
    }
    return child;
  }
}

