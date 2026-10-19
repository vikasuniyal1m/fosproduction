import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../utils/screen_size.dart';

import '../../controllers/onboarding_controller.dart';



/// Onboarding Screen

/// Shows app introduction slides - Responsive Figma Design

class OnboardingScreen extends StatelessWidget {

  const OnboardingScreen({super.key});

  

  @override

  Widget build(BuildContext context) {

    ScreenSize.init(context);

    // Ensure controller is initialized

    final controller = Get.isRegistered<OnboardingController>()

        ? Get.find<OnboardingController>()

        : Get.put(OnboardingController());

    

    // Responsive breakpoints

    final isCompact = ScreenSize.screenHeight < 700;

    final isTablet = ScreenSize.isTabletDevice;

    final isLargeScreen = ScreenSize.screenWidth >= 1200;

    

    return Scaffold(

      backgroundColor: Colors.white,

      body: SafeArea(

        child: Column(

          children: [

            // Skip button at top right - Responsive

            Padding(

              padding: EdgeInsets.only(

                top: isCompact ? ScreenSize.paddingMedium : ScreenSize.paddingLarge,

                right: isCompact ? ScreenSize.paddingMedium : ScreenSize.paddingLarge,

              ),

              child: Align(

                alignment: Alignment.topRight,

                child: TextButton(

                  onPressed: controller.skipOnboarding,

                  style: TextButton.styleFrom(

                    padding: EdgeInsets.symmetric(

                      horizontal: isCompact ? ScreenSize.spacingSmall : ScreenSize.spacingMedium,

                      vertical: isCompact ? ScreenSize.spacingTiny : ScreenSize.spacingSmall,

                    ),

                  ),

                  child: Text(

                    'Skip',

                    style: TextStyle(

                      fontSize: isCompact ? ScreenSize.textMedium : ScreenSize.textLarge,

                      fontWeight: FontWeight.w500,

                      color: Colors.black.withOpacity(0.7),

                    ),

                  ),

                ),

              ),

            ),

            

            // Page View with illustrations - Responsive

            Expanded(

              child: PageView.builder(

                controller: controller.pageController,

                onPageChanged: controller.setPage,

                itemCount: controller.pages.length,

                itemBuilder: (context, index) {

                  final page = controller.pages[index];

                  return _buildResponsiveOnboardingPage(page, isCompact, isTablet, isLargeScreen);

                },

              ),

            ),

            

            // Bottom section: Page indicator and buttons - Responsive

            Obx(() => Padding(

              padding: EdgeInsets.symmetric(

                horizontal: isCompact ? ScreenSize.paddingMedium : ScreenSize.paddingLarge,

                vertical: isCompact ? ScreenSize.paddingMedium : ScreenSize.paddingLarge,

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  // Page indicator dots - Responsive sizing

                  Row(

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: List.generate(

                      controller.pages.length,

                      (index) => AnimatedContainer(

                        duration: const Duration(milliseconds: 300),

                        margin: EdgeInsets.symmetric(

                          horizontal: ScreenSize.spacingExtraSmall,

                        ),

                        width: controller.currentPage.value == index

                            ? (isCompact ? 24 : 32)

                            : (isCompact ? 6 : 8),

                        height: isCompact ? 6 : 8,

                        decoration: BoxDecoration(

                          color: controller.currentPage.value == index

                              ? const Color(0xFF0B5306)

                              : const Color(0xFF0B5306).withOpacity(0.3),

                          borderRadius: BorderRadius.circular(isCompact ? 3 : 4),

                        ),

                      ),

                    ),

                  ),

                  

                  SizedBox(height: isCompact ? ScreenSize.spacingMedium : ScreenSize.spacingLarge),

                  

                  // Navigation buttons - Responsive layout

                  Row(

                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [

                      // Previous button (only show if not on first page)

                      if (!controller.isFirstPage)

                        Container(

                          height: isCompact ? 44 : 52,

                          child: TextButton(

                            onPressed: controller.previousPage,

                            style: TextButton.styleFrom(

                              padding: EdgeInsets.symmetric(

                                horizontal: isCompact ? ScreenSize.paddingMedium : ScreenSize.paddingLarge,

                                vertical: ScreenSize.spacingSmall,

                              ),

                              minimumSize: Size(60, isCompact ? 44 : 52),

                            ),

                            child: Text(

                              'Prev',

                              style: TextStyle(

                                fontSize: isCompact ? ScreenSize.textMedium : ScreenSize.textLarge,

                                fontWeight: FontWeight.w500,

                                color: const Color(0xFF0B5306),

                              ),

                            ),

                          ),

                        )

                      else

                        SizedBox(width: isCompact ? 60 : 80), // Spacer to balance layout

                      

                      // Next/Get Started button - Responsive

                      Expanded(

                        child: Container(

                          height: isCompact ? 48 : 56,

                          margin: EdgeInsets.symmetric(

                            horizontal: isCompact ? ScreenSize.spacingSmall : ScreenSize.spacingMedium,

                          ),

                          child: ElevatedButton(

                            onPressed: controller.nextPage,

                            style: ElevatedButton.styleFrom(

                              backgroundColor: const Color(0xFF0B5306),

                              foregroundColor: Colors.white,

                              shape: RoundedRectangleBorder(

                                borderRadius: BorderRadius.circular(

                                  isCompact ? 12 : 16,

                                ),

                              ),

                              elevation: 2,

                              padding: EdgeInsets.symmetric(

                                horizontal: isCompact ? ScreenSize.paddingLarge : ScreenSize.paddingExtraLarge,

                                vertical: ScreenSize.spacingMedium,

                              ),

                            ),

                            child: FittedBox(

                              fit: BoxFit.scaleDown,

                              child: Text(

                                controller.isLastPage ? 'Get Started' : 'Next',

                                style: TextStyle(

                                  fontSize: isCompact ? ScreenSize.textLarge : ScreenSize.headingMedium,

                                  fontWeight: FontWeight.w600,

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

                    ],

                  ),

                  

                  // Bottom padding for better spacing

                  SizedBox(height: isCompact ? ScreenSize.paddingSmall : ScreenSize.paddingMedium),

                ],

              ),

            )),

          ],

        ),

      ),

    );

  }

  

  /// Build responsive onboarding page

  Widget _buildResponsiveOnboardingPage(OnboardingPage page, bool isCompact, bool isTablet, bool isLargeScreen) {

    // Responsive flex ratios

    final imageFlex = isCompact ? 5 : (isTablet ? 4 : 3);

    final textFlex = isCompact ? 3 : (isTablet ? 3 : 2);

    

    return Column(

      mainAxisAlignment: MainAxisAlignment.center,

      children: [

        // Illustration Image - Responsive sizing

        Expanded(

          flex: imageFlex,

          child: Padding(

            padding: EdgeInsets.symmetric(

              horizontal: isCompact ? ScreenSize.paddingMedium : ScreenSize.paddingLarge,

              vertical: isCompact ? ScreenSize.paddingMedium : ScreenSize.paddingLarge,

            ),

            child: Center(

              child: Container(

                width: isLargeScreen 

                    ? ScreenSize.widthPercent(50)

                    : (isTablet ? ScreenSize.widthPercent(70) : ScreenSize.widthPercent(85)),

                child: Image.asset(

                  page.imagePath,

                  fit: BoxFit.contain,

                  errorBuilder: (context, error, stackTrace) {

                    return Container(

                      width: double.infinity,

                      decoration: BoxDecoration(

                        color: Colors.grey[100],

                        borderRadius: BorderRadius.circular(

                          isCompact ? 16 : 20,

                        ),

                        border: Border.all(

                          color: Colors.grey[300]!,

                          width: 1,

                        ),

                      ),

                      child: Column(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          Icon(

                            Icons.image_not_supported,

                            size: isCompact ? ScreenSize.iconExtraLarge : ScreenSize.iconExtraLarge * 1.5,

                            color: Colors.grey[400],

                          ),

                          SizedBox(height: ScreenSize.spacingSmall),

                          Text(

                            'Image Preview',

                            style: TextStyle(

                              fontSize: isCompact ? ScreenSize.textSmall : ScreenSize.textMedium,

                              color: Colors.grey[600],

                              fontWeight: FontWeight.w500,

                            ),

                          ),

                        ],

                      ),

                    );

                  },

                ),

              ),

            ),

          ),

        ),

        

        // Text content area - Responsive typography

        Expanded(

          flex: textFlex,

          child: Padding(

            padding: EdgeInsets.symmetric(

              horizontal: isCompact ? ScreenSize.paddingLarge : ScreenSize.paddingExtraLarge,

              vertical: ScreenSize.paddingMedium,

            ),

            child: SingleChildScrollView(

              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                // Title - Responsive font size

                Text(

                  page.title,

                  style: TextStyle(

                    fontSize: isCompact 

                        ? ScreenSize.headingMedium 

                        : (isTablet ? ScreenSize.headingLarge : ScreenSize.headingExtraLarge),

                    fontWeight: FontWeight.w700,

                    color: Colors.black,

                    height: 1.1,

                  ),

                  textAlign: TextAlign.center,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                ),

                

                SizedBox(height: isCompact ? ScreenSize.spacingMedium : ScreenSize.spacingLarge),

                

                // Description - Responsive font size

                Text(

                  page.description,

                  style: TextStyle(

                    fontSize: isCompact 

                        ? ScreenSize.textMedium 

                        : (isTablet ? ScreenSize.textLarge : ScreenSize.textExtraLarge),

                    fontWeight: FontWeight.w400,

                    color: Colors.grey[600],

                    height: 1.5,

                  ),

                  textAlign: TextAlign.center,

                  maxLines: isCompact ? 4 : 3,

                  overflow: TextOverflow.ellipsis,

                ),

              ],

            ),

          ),

          ),

        ),

      ],

    );

  }

}

