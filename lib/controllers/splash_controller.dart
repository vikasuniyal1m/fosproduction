import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../utils/cache_manager.dart';

/// Splash Controller
/// Handles splash screen logic and navigation
class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }
  
  /// Initialize app and navigate to appropriate screen
  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if widget is still mounted
      if (!Get.isRegistered<SplashController>()) {
        print('Splash: Controller disposed, skipping navigation');
        return;
      }
      
      // Check onboarding status first
      final isOnboardingCompleted = CacheManager.isOnboardingCompleted();
      print('Splash: isOnboardingCompleted = $isOnboardingCompleted');
      
      // If onboarding not completed, show onboarding first
      if (!isOnboardingCompleted) {
        print('Splash: Navigating to Onboarding');
        AppRoutes.toOnboarding();
        return;
      }
      
      // Check authentication status
      final isLoggedIn = CacheManager.isLoggedIn();
      final isGuestMode = CacheManager.isGuestMode();
      final userToken = CacheManager.getUserToken();
      print('Splash: isLoggedIn = $isLoggedIn, isGuestMode = $isGuestMode');
      print('Splash: userToken exists = ${userToken != null && userToken.isNotEmpty}');
      
      if ((isLoggedIn && userToken != null && userToken.isNotEmpty) || isGuestMode) {
        // User is authenticated or browsing as guest, navigate to home
        print('Splash: Navigating to Home (isLoggedIn=$isLoggedIn, isGuestMode=$isGuestMode)');
        AppRoutes.toHome();
      } else {
        // User is not authenticated, navigate to login
        print('Splash: User is not authenticated, navigating to Login');
        AppRoutes.toLogin();
      }
    } catch (e, stackTrace) {
      print('Splash: Error during initialization: $e');
      print('Splash: StackTrace: $stackTrace');
      // Fallback navigation - check authentication first
      Future.delayed(const Duration(milliseconds: 500), () {
        final isLoggedIn = CacheManager.isLoggedIn();
        final isGuestMode = CacheManager.isGuestMode();
        final userToken = CacheManager.getUserToken();
        
        if ((isLoggedIn && userToken != null && userToken.isNotEmpty) || isGuestMode) {
          AppRoutes.toHome();
        } else {
          AppRoutes.toLogin();
        }
      });
    }
  }
  
  /// Reset onboarding (for testing/debugging)
  Future<void> resetOnboarding() async {
    await CacheManager.resetOnboarding();
    AppRoutes.toOnboarding();
  }
}

