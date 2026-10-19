import 'package:flutter/material.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';

/// Custom Bottom Navigation Bar
/// Reusable bottom navigation bar widget
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });
  
  @override
  Widget build(BuildContext context) {
    // Initialize ScreenSize if not already done
    ScreenSize.init(context);
    
    return Container(
      // Use responsive height based on screen size
      constraints: BoxConstraints(
        minHeight: ScreenSize.screenWidth >= 1200 ? ScreenSize.bottomNavHeight + ScreenSize.bottomBarHeight : 
                 (ScreenSize.screenWidth >= 1000 ? ScreenSize.bottomNavHeight + ScreenSize.bottomBarHeight : 
                 (ScreenSize.screenWidth >= 768 ? ScreenSize.bottomNavHeight + ScreenSize.bottomBarHeight - 4 : ScreenSize.bottomNavHeight + ScreenSize.bottomBarHeight)),
      ),
      decoration: BoxDecoration(
        color: AppColors.bottomNavBackground,
        boxShadow: AppColors.cardShadow,
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            items.length,
            (index) => _buildNavItem(
              items[index],
              index == currentIndex,
              () => onTap(index),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(BottomNavItem item, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: ScreenSize.screenWidth >= 1200 ? ScreenSize.spacingSmall : 
                   (ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : 
                   (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingTiny : ScreenSize.spacingSmall)),
          ),
          constraints: BoxConstraints(
            minHeight: 0,
            maxHeight: double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: ScreenSize.screenWidth >= 1200 ? ScreenSize.bottomNavIconSize : 
                     (ScreenSize.screenWidth >= 1000 ? ScreenSize.bottomNavIconSize : 
                     (ScreenSize.screenWidth >= 768 ? ScreenSize.bottomNavIconSize * 0.9 : ScreenSize.bottomNavIconSize)),
                color: isSelected
                    ? AppColors.bottomNavSelected
                    : AppColors.bottomNavUnselected,
              ),
              SizedBox(height: ScreenSize.screenWidth >= 1200 ? 2 : (ScreenSize.screenWidth >= 1000 ? 2 : (ScreenSize.screenWidth >= 768 ? 1 : 2))),
              Flexible(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.textSmall : 
                           (ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : 
                           (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textSmall)),
                    color: isSelected
                        ? AppColors.bottomNavSelected
                        : AppColors.bottomNavUnselected,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

/// Bottom Navigation Item Model
class BottomNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  
  BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

