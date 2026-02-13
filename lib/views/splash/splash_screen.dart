import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/splash_controller.dart';

/// Splash Screen
/// First screen shown when app launches - Matching Figma Design Exactly
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Initialize screen size
    ScreenSize.init(context);
    
    return GetBuilder<SplashController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.background, // Same as login page
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.background, // Same as login page
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Simplified responsive logic using ScreenSize scaling
                final maxLogoWidth = ScreenSize.widthPercent(ScreenSize.isTabletDevice ? 55 : 70);
                final maxLogoHeight = ScreenSize.heightPercent(ScreenSize.isTabletDevice ? 40 : 35);
                
                // Use scaled values directly
                final loaderSize = ScreenSize.iconExtraLarge; 
                final loaderStroke = ScreenSize.isTabletDevice ? 4.0 : 3.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenSize.paddingLarge,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxLogoWidth,
                          maxHeight: maxLogoHeight,
                        ),
                        child: Image.asset(
                          'assets/images/FOSProduction.png',
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.shopping_bag,
                              size: ScreenSize.logoSize * 2.0,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: ScreenSize.sectionSpacing),
                    SizedBox(
                      width: loaderSize,
                      height: loaderSize,
                      child: CircularProgressIndicator(
                        strokeWidth: loaderStroke,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
