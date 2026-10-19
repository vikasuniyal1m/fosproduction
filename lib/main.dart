import 'package:ecommerceapp/utils/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firebase_core/firebase_core.dart'; // Firebase disabled

import 'utils/release_config.dart';
import 'utils/screen_size.dart';
import 'utils/cache_manager.dart';
import 'utils/app_lifecycle.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';
import 'services/cart_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force light theme system UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Restrict to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase (auto-detects from google-services.json / GoogleService-Info.plist) - DISABLED
  // await Firebase.initializeApp();

  // Initialize in parallel for faster startup
  await Future.wait([
    Hive.initFlutter(),
    CacheManager.init(),
  ]);
  
  // Open app state box (for process death recovery)
  await Hive.openBox('appState');

  // Initialize Notification Service (non-blocking - app starts immediately)
  Get.putAsync(() => NotificationService().init());

  // Initialize Cart Sync Service for real-time cart updates
  Get.put(CartSyncService());

  // Initialize app lifecycle (this will restore state if needed)
  Get.put(AppLifecycleManager.instance);

  // Clear any cached theme mode to force light theme
  await CacheManager.saveThemeMode('light');

  runWithReleaseConfig(() => runApp(const MyApp()));
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
          themeMode: ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              background: AppColors.background,
              surface: AppColors.background,
              onBackground: AppColors.textPrimary,
              onSurface: AppColors.textPrimary,
            ),
            scaffoldBackgroundColor: AppColors.background,
            cardColor: AppColors.cardBackground,
            dividerColor: AppColors.border,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
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
            // useMaterial3: true,
          ),
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.routes,
        );
      },
    );
  }
}
