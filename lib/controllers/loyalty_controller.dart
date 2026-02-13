import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';

/// Loyalty Points Controller
/// Handles loyalty points logic and API calls
class LoyaltyController extends GetxController {
  final ApiService _apiService = ApiService();
  
  // Points Data
  final RxBool isLoading = false.obs;
  final RxInt currentPoints = 0.obs;
  final RxInt totalEarned = 0.obs;
  final RxInt totalOrders = 0.obs;
  final RxInt pointsPerOrder = 0.obs;
  
  // History
  final RxBool isLoadingHistory = false.obs;
  final RxList<Map<String, dynamic>> history = <Map<String, dynamic>>[].obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasMore = false.obs;
  
  // Redeem
  final RxBool isRedeeming = false.obs;
  final TextEditingController pointsToRedeemController = TextEditingController();
  final RxDouble discountAmount = 0.0.obs;
  final RxInt pointsToRedeem = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadPoints();
    loadHistory();
  }
  
  @override
  void onClose() {
    pointsToRedeemController.dispose();
    super.onClose();
  }
  
  /// Load user's loyalty points
  Future<void> loadPoints() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get(ApiEndpoints.loyaltyPoints);
      final data = ApiService.handleResponse(response);
      
      currentPoints.value = data['current_points'] ?? 0;
      totalEarned.value = data['total_earned'] ?? 0;
      totalOrders.value = data['total_orders'] ?? 0;
      pointsPerOrder.value = data['points_per_order'] ?? 0;
    } catch (e) {
      print('[Loyalty] Error loading points: $e');
      Get.snackbar('Error', 'Failed to load loyalty points', 
        snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Load points history
  Future<void> loadHistory({int page = 1}) async {
    isLoadingHistory.value = true;
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.loyaltyHistory}?page=$page&limit=20'
      );
      final data = ApiService.handleResponse(response);
      
      if (page == 1) {
        history.value = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      } else {
        history.addAll(List<Map<String, dynamic>>.from(data['transactions'] ?? []));
      }
      
      final pagination = data['pagination'] ?? {};
      currentPage.value = pagination['current_page'] ?? 1;
      totalPages.value = pagination['total_pages'] ?? 1;
      hasMore.value = pagination['has_next'] ?? false;
    } catch (e) {
      print('[Loyalty] Error loading history: $e');
      Get.snackbar('Error', 'Failed to load points history', 
        snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingHistory.value = false;
    }
  }
  
  /// Calculate redemption
  Future<void> calculateRedemption(int points, double orderAmount) async {
    if (points <= 0) {
      discountAmount.value = 0.0;
      pointsToRedeem.value = 0;
      return;
    }
    
    if (points > currentPoints.value) {
      Get.snackbar('Error', 'Insufficient points', 
        snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    isRedeeming.value = true;
    try {
      final response = await _apiService.post(
        ApiEndpoints.loyaltyRedeem,
        data: {
          'points': points,
          'order_amount': orderAmount,
        }
      );
      final data = ApiService.handleResponse(response);
      
      discountAmount.value = data['discount_amount'] ?? 0.0;
      pointsToRedeem.value = data['points_redeemed'] ?? 0;
    } catch (e) {
      print('[Loyalty] Error calculating redemption: $e');
      Get.snackbar('Error', 'Failed to calculate redemption', 
        snackPosition: SnackPosition.BOTTOM);
    } finally {
      isRedeeming.value = false;
    }
  }
  
  /// Refresh data
  Future<void> refresh() async {
    await Future.wait([
      loadPoints(),
      loadHistory(page: 1),
    ]);
  }
}

