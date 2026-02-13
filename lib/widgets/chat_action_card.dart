import 'package:flutter/material.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';

/// Chat Action Card Widget
/// Zomato-style action cards for quick actions
class ChatActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  
  const ChatActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          right: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall), 
          bottom: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ScreenSize.isLargeTablet ? ScreenSize.paddingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingMedium : ScreenSize.spacingMedium),
          vertical: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingMedium : ScreenSize.spacingMedium),
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(ScreenSize.isLargeTablet ? ScreenSize.spacingSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 10 : (ScreenSize.isSmallTablet ? 9 : 8)),
              ),
              child: Icon(
                icon,
                size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall * 1.2 : (ScreenSize.isSmallTablet ? 22 : 20),
                color: iconColor ?? AppColors.primary,
              ),
            ),
            SizedBox(width: ScreenSize.isLargeTablet ? ScreenSize.spacingSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
            Text(
              title,
              style: TextStyle(
                fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textMedium),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: ScreenSize.isLargeTablet ? ScreenSize.spacingXSmall : (ScreenSize.isSmallTablet ? 5 : 4)),
            Icon(
              Icons.arrow_forward_ios,
              size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall * 0.7 : (ScreenSize.isSmallTablet ? 15 : 14),
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

