import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';

/// Coupon Controller
/// Manages coupon listing and selection
class CouponController extends GetxController {
  final ApiService _apiService = ApiService();
  
  // Loading states
  final RxBool isLoading = false.obs;
  
  // Coupons list
  final RxList<Map<String, dynamic>> coupons = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> usedCoupons = <Map<String, dynamic>>[].obs;
  
  // Selected coupon (for applying to checkout)
  final RxMap<String, dynamic> selectedCoupon = <String, dynamic>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadCoupons();
  }
  
  /// Load all available coupons
  Future<void> loadCoupons() async {
    isLoading.value = true;
    try {
      // Get all coupons
      final response = await _apiService.get(
        ApiEndpoints.availableCoupons,
      );
      final data = ApiService.handleResponse(response);
      coupons.value = List<Map<String, dynamic>>.from(data['coupons'] ?? []);
      
      // Mark used coupons based on is_used flag from API
      final usedCouponsList = coupons.where((coupon) {
        return coupon['is_used'] == true;
      }).toList();
      usedCoupons.value = usedCouponsList;
      
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      coupons.value = [];
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Check if coupon is used
  bool isCouponUsed(String couponCode) {
    return coupons.any((coupon) => 
      coupon['code'] == couponCode && coupon['is_used'] == true
    );
  }
  
  /// Select coupon to apply in checkout
  void selectCoupon(Map<String, dynamic> coupon) {
    if (isCouponUsed(coupon['code'])) {
      Get.snackbar('Error', 'This coupon has already been used');
      return;
    }
    
    selectedCoupon.value = coupon;
    // Don't show snackbar here, let checkout screen handle it
  }
  
  /// Clear selected coupon
  void clearSelectedCoupon() {
    selectedCoupon.clear();
  }
  
  /// Refresh coupons list
  Future<void> refreshCoupons() async {
    await loadCoupons();
  }
}

