import 'package:flutter/material.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';

/// Responsive Button Widget
/// Ensures button text never overflows and adapts to all screen sizes
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  
  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.fontWeight,
    this.width,
    this.height,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    // Initialize ScreenSize if not already initialized
    ScreenSize.init(context);
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? ScreenSize.buttonHeightMedium,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style ?? ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
          ),
          elevation: 0,
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: ScreenSize.buttonPaddingHorizontal,
            vertical: ScreenSize.buttonPaddingVertical,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? Colors.white,
                  ),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      SizedBox(width: ScreenSize.spacingExtraSmall),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: fontSize ?? ScreenSize.textLarge,
                          fontWeight: fontWeight ?? FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Responsive Outlined Button Widget
class ResponsiveOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  
  const ResponsiveOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.foregroundColor,
    this.borderColor,
    this.fontSize,
    this.fontWeight,
    this.width,
    this.height,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    // Initialize ScreenSize if not already initialized
    ScreenSize.init(context);
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? ScreenSize.buttonHeightMedium,
      child: OutlinedButton(
        onPressed: onPressed,
        style: style ?? OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? AppColors.primary,
          side: BorderSide(
            color: borderColor ?? foregroundColor ?? AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
          ),
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: ScreenSize.buttonPaddingHorizontal,
            vertical: ScreenSize.buttonPaddingVertical,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: ScreenSize.spacingExtraSmall),
              ],
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize ?? ScreenSize.textLarge,
                    fontWeight: fontWeight ?? FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

