import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';
import '../routes/app_routes.dart';

/// Floating Help Button Widget
/// Professional help button that appears on screens for quick access
class FloatingHelpButton extends StatefulWidget {
  final bool showChatOption;
  final bool showHelpScreenOption;
  
  const FloatingHelpButton({
    super.key,
    this.showChatOption = true,
    this.showHelpScreenOption = true,
  });
  
  @override
  State<FloatingHelpButton> createState() => _FloatingHelpButtonState();
}

class _FloatingHelpButtonState extends State<FloatingHelpButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _navigateToChat() {
    _toggleExpansion();
    Future.delayed(const Duration(milliseconds: 150), () {
      Get.toNamed(AppRoutes.chat);
    });
  }

  void _navigateToHelp() {
    _toggleExpansion();
    Future.delayed(const Duration(milliseconds: 150), () {
      Get.toNamed(AppRoutes.helpSupport);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Transparent overlay when expanded
        if (_isExpanded)
          Positioned.fill(
            child: FadeTransition(
              opacity: _overlayAnimation,
              child: GestureDetector(
                onTap: _toggleExpansion,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
        
        // Expanded options
        if (_isExpanded) ...[
          // Help Screen option (shown first, on top)
          if (widget.showHelpScreenOption)
            Positioned(
              right: ScreenSize.spacingMedium,
              bottom: widget.showChatOption ? 180 : 100,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildOptionButton(
                  icon: Icons.help_outline,
                  label: 'Help Center',
                  color: AppColors.info,
                  onTap: _navigateToHelp,
                ),
              ),
            ),
          
          // Chat option (shown second, below Help Center)
          if (widget.showChatOption)
            Positioned(
              right: ScreenSize.spacingMedium,
              bottom: 100,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildOptionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat Support',
                  color: AppColors.primary,
                  onTap: _navigateToChat,
                ),
              ),
            ),
        ],
        
        // Main help button
        Positioned(
          right: ScreenSize.spacingMedium,
          bottom: ScreenSize.spacingMedium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Tooltip/helper text
              if (_isExpanded)
                Container(
                  margin: EdgeInsets.only(
                    bottom: ScreenSize.spacingSmall,
                    right: ScreenSize.spacingSmall,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.spacingMedium,
                    vertical: ScreenSize.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Need help?',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: ScreenSize.textSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              // Main FAB
              GestureDetector(
                onTap: _toggleExpansion,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(_isExpanded ? 0.6 : 0.4),
                        blurRadius: _isExpanded ? 16 : 12,
                        offset: const Offset(0, 4),
                        spreadRadius: _isExpanded ? 2 : 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(_isExpanded ? 0.3 : 0.1),
                        blurRadius: _isExpanded ? 12 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      _isExpanded ? Icons.close : Icons.help_outline,
                      color: AppColors.textWhite,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ScreenSize.spacingLarge,
          vertical: ScreenSize.spacingMedium,
        ),
        margin: EdgeInsets.only(bottom: ScreenSize.spacingSmall),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            SizedBox(width: ScreenSize.spacingMedium),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ScreenSize.textMedium,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: ScreenSize.spacingSmall),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

