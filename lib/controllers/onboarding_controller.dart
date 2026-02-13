import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../utils/cache_manager.dart';

/// Onboarding Controller
/// Handles onboarding screen logic
class OnboardingController extends GetxController {
  final RxInt currentPage = 0.obs;
  late PageController pageController;
  Timer? _autoTimer;
  static const Duration pageAutoAdvanceDuration = Duration(seconds: 10);
  
  // Onboarding pages data - Matching Figma Design
  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Choose Products',
      description: 'Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint. Velit officia consequat duis enim velit mollit.',
      imagePath: 'assets/images/onboarding1.png',
    ),
    OnboardingPage(
      title: 'Make Payment',
      description: 'Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint. Velit officia consequat duis enim velit mollit.',
      imagePath: 'assets/images/onboarding2.png',
    ),
    OnboardingPage(
      title: 'Get Your Order',
      description: 'Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint. Velit officia consequat duis enim velit mollit.',
      imagePath: 'assets/images/onboarding3.png',
    ),
  ];
  
  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    _startAutoAdvance();
  }
  
  @override
  void onClose() {
    _autoTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }
  
  /// Handle page change from UI
  void setPage(int index) {
    currentPage.value = index;
    _startAutoAdvance();
  }
  
  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer(pageAutoAdvanceDuration, () {
      if (isLastPage) {
        completeOnboarding();
      } else {
        nextPage();
        _startAutoAdvance();
      }
    });
  }
  
  /// Go to next page
  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Will be restarted by setPage after onPageChanged
    } else {
      // Last page - complete onboarding
      completeOnboarding();
    }
  }
  
  /// Go to previous page
  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Will be restarted by setPage after onPageChanged
    }
  }
  
  /// Skip onboarding
  void skipOnboarding() {
    _autoTimer?.cancel();
    completeOnboarding();
  }
  
  /// Complete onboarding and navigate to home (allow browsing without login)
  Future<void> completeOnboarding() async {
    _autoTimer?.cancel();
    await CacheManager.setOnboardingCompleted(true);
    AppRoutes.toHome();
  }
  
  /// Check if on first page
  bool get isFirstPage => currentPage.value == 0;
  
  /// Check if on last page
  bool get isLastPage => currentPage.value == pages.length - 1;
}

/// Onboarding Page Model
class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  
  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
