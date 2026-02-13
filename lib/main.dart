import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'utils/screen_size.dart';
import 'utils/cache_manager.dart';
import 'utils/app_colors.dart';
import 'utils/app_lifecycle.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize in parallel for faster startup
  await Future.wait([
    Hive.initFlutter(),
    CacheManager.init(),
  ]);
  
  // Open app state box (for process death recovery)
  await Hive.openBox('appState');

  // Initialize app lifecycle (this will restore state if needed)
  Get.put(AppLifecycleManager.instance);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Initialize ScreenSize early
        ScreenSize.init(context);
        
        return GetMaterialApp(
          title: 'FOS Productions',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.primary,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textWhite),
              titleTextStyle: TextStyle(
                color: AppColors.textWhite,
                fontSize: ScreenSize.headingMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                borderSide: const BorderSide(color: AppColors.inputBorderFocused, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                borderSide: const BorderSide(color: AppColors.inputError),
              ),
            ),
            useMaterial3: true,
          ),
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.routes,
        );
      },
    );
  }
}
