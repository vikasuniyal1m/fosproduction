import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../controllers/onboarding_controller.dart';

/// Onboarding Screen
/// Shows app introduction slides - Matching Figma Design Exactly
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    // Ensure controller is initialized
    final controller = Get.isRegistered<OnboardingController>()
        ? Get.find<OnboardingController>()
        : Get.put(OnboardingController());
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top right
            Padding(
              padding: EdgeInsets.only(
                top: ScreenSize.paddingLarge,
                right: ScreenSize.paddingLarge,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: controller.skipOnboarding,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.spacingSmall,
                      vertical: ScreenSize.spacingSmall,
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: ScreenSize.textLarge,
                      fontWeight: ScreenSize.isTabletDevice ? FontWeight.bold : FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            
            // Page View with illustrations
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.setPage,
                itemCount: controller.pages.length,
                itemBuilder: (context, index) {
                  final page = controller.pages[index];
                  return _buildOnboardingPage(page);
                },
              ),
            ),
            
            // Bottom section: Page indicator and buttons
            Obx(() => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ScreenSize.paddingLarge,
                vertical: ScreenSize.paddingLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      controller.pages.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: ScreenSize.spacingSmall,
                        ),
                        width: controller.currentPage.value == index
                            ? ScreenSize.widthPercent(ScreenSize.isTabletDevice ? 4.0 : 3.0)
                            : ScreenSize.widthPercent(ScreenSize.isTabletDevice ? 2.0 : 1.5),
                        height: ScreenSize.widthPercent(ScreenSize.isTabletDevice ? 2.0 : 1.5),
                        decoration: BoxDecoration(
                          color: controller.currentPage.value == index
                              ? const Color(0xFF0B5306) // Green for active
                              : const Color(0xFF0B5306).withOpacity(0.3), // Light green for inactive
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: ScreenSize.spacingLarge),
                  
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous button (only show if not on first page)
                      if (!controller.isFirstPage)
                        TextButton(
                          onPressed: controller.previousPage,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: ScreenSize.paddingLarge,
                              vertical: ScreenSize.paddingMedium,
                            ),
                          ),
                          child: Text(
                            'Prev',
                            style: TextStyle(
                              fontSize: ScreenSize.textLarge,
                              fontWeight: ScreenSize.isTabletDevice ? FontWeight.bold : FontWeight.w400,
                              color: const Color(0xFF0B5306), // Green color
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80), // Spacer to balance layout
                      
                      // Next/Get Started button
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ScreenSize.spacingSmall,
                          ),
                          child: SizedBox(
                            height: ScreenSize.buttonHeightLarge,
                            child: ElevatedButton(
                              onPressed: controller.nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B5306), // Green color
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ScreenSize.isTabletDevice ? ScreenSize.buttonBorderRadiusLarge : ScreenSize.buttonBorderRadius,
                                  ),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: ScreenSize.buttonPaddingHorizontal,
                                  vertical: ScreenSize.buttonPaddingVertical,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  controller.isLastPage ? 'Get Started' : 'Next',
                                  style: TextStyle(
                                    fontSize: ScreenSize.headingMedium,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  /// Build individual onboarding page
  Widget _buildOnboardingPage(OnboardingPage page) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Illustration Image - Takes upper 60-65% of screen
        // Removed horizontal padding to allow image to be larger
        Expanded(
          flex: ScreenSize.isTabletDevice ? 4 : 6, // Reduce image flex on tablets to give more room for text
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ScreenSize.paddingLarge,
              horizontal: ScreenSize.paddingLarge, // More padding on tablets
            ),
            child: Center(
              child: Image.asset(
                page.imagePath,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: ScreenSize.widthPercent(80),
                    height: ScreenSize.heightPercent(40),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(
                        ScreenSize.tileBorderRadiusLarge,
                      ),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      size: ScreenSize.iconExtraLarge * 2,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        SizedBox(height: ScreenSize.spacingSmall),
        
        // Title
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenSize.paddingLarge,
          ),
          child: Text(
            page.title,
            style: TextStyle(
              fontSize: ScreenSize.headingLarge,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        SizedBox(height: ScreenSize.spacingMedium),
        
        // Description
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenSize.paddingExtraLarge,
          ),
          child: Text(
            page.description,
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Bottom spacer
        SizedBox(height: ScreenSize.spacingSmall),
      ],
    );
  }
}
