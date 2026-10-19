import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScreenSize {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late Orientation orientation;
  static late double _bottomBarHeight;

  // Device Categories (Refined based on your guide)
  static bool isTablet = false;
  static bool isLargeTablet = false;
  static bool isSmallTablet = false;
  static bool isSmallPhone = false;
  static bool isMediumPhone = false;
  static bool isLargePhone = false;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
    _bottomBarHeight = _mediaQueryData.padding.bottom;

    final shortestSide = _mediaQueryData.size.shortestSide;
    final width = _mediaQueryData.size.width;

    // logic according to your reference guide
    isTablet = shortestSide >= 600;
    isSmallTablet = shortestSide >= 600 && shortestSide < 800;
    isLargeTablet = shortestSide >= 800;
    isSmallPhone = shortestSide < 360;
    isMediumPhone = shortestSide >= 360 && shortestSide < 414;
    isLargePhone = shortestSide >= 414 && shortestSide < 600;

    ScreenUtil.init(
      context,
      // More realistic tablet design size for better aspect ratio compatibility
      designSize: isTablet ? const Size(834, 1112) : const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
    );
  }

  // --- Scaling Factors (Increased for Professional Tablet Experience) ---
  static double get _fontScale {
    if (screenWidth >= 1000) return 1.45;
    if (screenWidth >= 768) return 1.3;
    if (isTablet) return 1.15;
    if (isLargePhone) return 1.1;
    return 1.0;
  }

  static double get _spacingScale {
    if (screenWidth >= 1000) return 1.5;
    if (screenWidth >= 768) return 1.35;
    if (isTablet) return 1.2;
    if (isLargePhone) return 1.1;
    return 1.0;
  }

  static double get _iconScale {
    if (screenWidth >= 1000) return 1.5;
    if (screenWidth >= 768) return 1.35;
    if (isTablet) return 1.2;
    return 1.0;
  }

  // --- Dynamic Sizes (Using new logic + ScreenUtil) ---

  // Logo & Headers
  static double get logoSize => (45 * _iconScale).w;
  static double get textExtraSmall => (10 * _fontScale).sp;
  static double get textSmall => (12 * _fontScale).sp;
  static double get textMedium => (14 * _fontScale).sp;
  static double get textLarge => (16 * _fontScale).sp;
  static double get textExtraLarge => (18 * _fontScale).sp;

  static double get headingSmall => (20 * _fontScale).sp;
  static double get headingMedium => (24 * _fontScale).sp;
  static double get headingLarge => (28 * _fontScale).sp;
  static double get headingExtraLarge => (32 * _fontScale).sp;
  static double get headingHuge => (36 * _fontScale).sp;

  // Icons
  static double get iconExtraSmall => (12 * _iconScale).w;
  static double get iconSmall => (18 * _iconScale).w;
  static double get iconMedium => (24 * _iconScale).w;
  static double get iconLarge => (32 * _iconScale).w;
  static double get iconExtraLarge => (40 * _iconScale).w;

  // Spacing & Padding
  static double get spacingTiny => (2 * _spacingScale).h;
  static double get spacingSmall => (8 * _spacingScale).h;
  static double get spacingMedium => (16 * _spacingScale).h;
  static double get spacingLarge => (24 * _spacingScale).h;
  static double get paddingMedium => (16 * _spacingScale).w;
  static double get sectionSpacing => (24 * _spacingScale).h;

  // --- Backward Compatibility (KEEPING ALL ORIGINAL NAMES) ---
  static double get spacingExtraSmall => (4 * _spacingScale).h;
  static double get spacingXSmall => spacingExtraSmall;
  static double get spacingExtraLarge => (32 * _spacingScale).h;
  static double get spacingXLarge => spacingExtraLarge;
  static double get spacingHuge => (48 * _spacingScale).h;

  static double get paddingSmall => (8 * _spacingScale).w;
  static double get paddingLarge => (24 * _spacingScale).w;
  static double get paddingExtraLarge => (32 * _spacingScale).w;

  static double get sectionSpacingLarge => (32 * _spacingScale).h;
  static int get gridCrossAxisCount => isTablet ? 3 : 2;
  static double get gridSpacing => (16 * _spacingScale).w;

  static double get productCardImageHeight => (isTablet ? 145 : 110) * _spacingScale.h;
  static double get productCardHorizontalImageHeight => (isTablet ? 105 : 75) * _spacingScale.h;
  static double get productCardAspectRatio => screenWidth >= 768 ? 0.7 : (isTablet ? 0.9 : 0.8); 
  static double get productCardHorizontalWidth => (isTablet ? 155 : 120) * _spacingScale.w;
  static double get productCardHeight => (isTablet ? 250 : 210) * _spacingScale.h;
  static double get productCardHorizontalHeight => (isTablet ? 200 : 175) * _spacingScale.h;
  static double get productCardWidth => (isTablet ? 155 : 120) * _spacingScale.w;
  static double get productCardBorderRadius => (12 * _spacingScale).r;

  static double get bannerHeight => (180 * _spacingScale).h;
  static double get categoryIconSize => (70 * _iconScale).w;
  static double get categoryItemWidth => (80 * _iconScale).w;
  static double get categorySectionHeight => (100 * _spacingScale).h;

  // Original Button & Input properties (Now scaling with _spacingScale)
  static double get buttonHeightSmall => (40 * _spacingScale).h;
  static double get buttonHeightMedium => (48 * _spacingScale).h;
  static double get buttonHeightLarge => (56 * _spacingScale).h;
  static double get buttonHeightExtraLarge => (64 * _spacingScale).h;
  static double get buttonPaddingHorizontal => (24 * _spacingScale).w;
  static double get buttonPaddingVertical => (12 * _spacingScale).h;
  static double get buttonBorderRadius => (8 * _spacingScale).r;
  static double get buttonBorderRadiusLarge => (12 * _spacingScale).r;

  static double get inputPadding => (16 * _spacingScale).w;
  static double get inputBorderRadius => (8 * _spacingScale).r;
  static double get borderRadiusSmall => (6 * _spacingScale).r;
  static double get borderRadiusMedium => (12 * _spacingScale).r;
  static double get borderRadiusLarge => (16 * _spacingScale).r;
  static double get tileBorderRadius => (12 * _spacingScale).r;
  static double get tileBorderRadiusLarge => (16 * _spacingScale).r;

  static double get bottomNavHeight => (60 * _spacingScale).h;
  static double get bottomNavIconSize => 24.w;
  static double get bottomBarHeight => _bottomBarHeight;

  // Utility Methods
  static double widthPercent(double percent) => screenWidth * (percent / 100);
  static double heightPercent(double percent) => screenHeight * (percent / 100);
  static bool get isTabletDevice => isTablet;
}
