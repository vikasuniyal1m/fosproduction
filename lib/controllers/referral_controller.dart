import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/app_colors.dart';

/// Referral Controller
/// Handles referral program logic and API calls
class ReferralController extends GetxController {
  final ApiService _apiService = ApiService();
  
  // Referral Data
  final RxBool isLoading = false.obs;
  final RxString referralCode = ''.obs;
  final RxString referralLink = ''.obs;
  
  // Statistics
  final RxBool isLoadingStats = false.obs;
  final RxInt totalReferrals = 0.obs;
  final RxInt successfulReferrals = 0.obs;
  final RxInt rewardPointsEarned = 0.obs;
  final RxList<Map<String, dynamic>> referredUsers = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadReferralCode();
    loadStats();
  }
  
  /// Load user's referral code
  Future<void> loadReferralCode() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get(ApiEndpoints.referralCode);
      final data = ApiService.handleResponse(response);
      
      referralCode.value = data['referral_code'] ?? '';
      referralLink.value = data['referral_link'] ?? 'Use code: ${referralCode.value} during signup';
    } catch (e) {
      print('[Referral] Error loading code: $e');
      Get.snackbar('Error', 'Failed to load referral code', 
        snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Load referral statistics
  Future<void> loadStats() async {
    isLoadingStats.value = true;
    try {
      final response = await _apiService.get(ApiEndpoints.referralStats);
      final data = ApiService.handleResponse(response);
      
      totalReferrals.value = data['total_referrals'] ?? 0;
      successfulReferrals.value = data['successful_referrals'] ?? 0;
      rewardPointsEarned.value = data['reward_points_earned'] ?? 0;
      referredUsers.value = List<Map<String, dynamic>>.from(data['referred_users'] ?? []);
    } catch (e) {
      print('[Referral] Error loading stats: $e');
      Get.snackbar('Error', 'Failed to load referral statistics', 
        snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingStats.value = false;
    }
  }
  
  /// Share referral code
  Future<void> shareReferralCode() async {
    if (referralCode.value.isEmpty) {
      await loadReferralCode();
    }
    
    final shareText = 'Join me on this amazing shopping app! Use my referral code: ${referralCode.value} and get amazing rewards!';
    
    try {
      await Share.share(shareText, subject: 'Referral Code');
    } catch (e) {
      print('[Referral] Error sharing: $e');
      Get.snackbar('Error', 'Failed to share referral code', 
        snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  /// Copy referral code to clipboard
  Future<void> copyReferralCode() async {
    if (referralCode.value.isEmpty) {
      await loadReferralCode();
    }
    
    // Copy to clipboard using Flutter's Clipboard
    await Clipboard.setData(ClipboardData(text: referralCode.value));
    Get.snackbar('Copied', 'Referral code copied to clipboard', 
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: AppColors.textWhite,
    );
  }
  
  /// Refresh data
  Future<void> refresh() async {
    await Future.wait([
      loadReferralCode(),
      loadStats(),
    ]);
  }
}

