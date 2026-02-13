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

    // logic according to your reference guide
    isTablet = shortestSide >= 600;
    isSmallTablet = shortestSide >= 600 && shortestSide < 768;
    isLargeTablet = shortestSide >= 768;
    isSmallPhone = shortestSide < 360;
    isMediumPhone = shortestSide >= 360 && shortestSide < 414;
    isLargePhone = shortestSide >= 414 && shortestSide < 600;

    ScreenUtil.init(
      context,
      // Based on iPhone X (375x812) for phones and iPad (768x1024) for tablets
      designSize: isTablet ? const Size(768, 1024) : const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
    );
  }

  // --- Scaling Factors (Improved for readability) ---
  static double get _fontScale {
    if (isLargeTablet) return 1.2; // Reduced for better tablet readability
    if (isSmallTablet) return 1.1; // Reduced for better tablet readability
    if (isLargePhone) return 1.1; // Pro Max & Ultra phones
    if (isSmallPhone) return 0.90; // SE & small Androids
    return 1.0;
  }

  static double get _spacingScale {
    if (isLargeTablet) return 1.2; // Reduced for better tablet spacing
    if (isSmallTablet) return 1.1; // Reduced for better tablet spacing
    if (isLargePhone) return 1.1;
    if (isSmallPhone) return 0.90;
    return 1.0;
  }

  static double get _iconScale {
    if (isLargeTablet) return 1.2; // Reduced for better tablet icons
    if (isSmallTablet) return 1.1; // Reduced for better tablet icons
    if (isLargePhone) return 1.1;
    if (isSmallPhone) return 0.90;
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

  static double get productCardImageHeight => (150 * _spacingScale).h;
  static double get productCardHorizontalImageHeight => (120 * _spacingScale).h;
  static double get productCardAspectRatio => isTablet ? 0.75 : 0.6; // Increased card height for tablets with 3 columns
  static double get productCardHorizontalWidth => (200 * _spacingScale).w;
  static double get productCardHorizontalHeight => (180 * _spacingScale).h;

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
