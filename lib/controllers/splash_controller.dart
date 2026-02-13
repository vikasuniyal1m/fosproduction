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
    await Future.delayed(const Duration(seconds: 3));
    
    // Check onboarding status first
    final isOnboardingCompleted = CacheManager.isOnboardingCompleted();
    
    // Debug logs
    print('Splash: isOnboardingCompleted = $isOnboardingCompleted');
    
    // If onboarding not completed, show onboarding first
    if (!isOnboardingCompleted) {
      print('Splash: Navigating to Onboarding (first time user)');
      AppRoutes.toOnboarding();
      return;
    }
    
    // Navigate based on app state
    // Allow browsing without login - always go to home
    // Users can browse products without registration
    // Login will only be required for account-based features (cart, checkout, etc.)
    print('Splash: Navigating to Home (browsing allowed without login)');
    AppRoutes.toHome();
  }
  
  /// Reset onboarding (for testing/debugging)
  Future<void> resetOnboarding() async {
    await CacheManager.resetOnboarding();
    AppRoutes.toOnboarding();
  }
}

