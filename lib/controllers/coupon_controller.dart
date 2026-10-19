import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../utils/data_cache.dart';
import '../utils/getx_registry.dart';

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
    _loadCachedCoupons();
    loadCoupons();
    GetXRegistry.cart().loadCart();
  }

  void _loadCachedCoupons() {
    final cached = DataCache.loadList(DataCache.coupons);
    if (cached != null && cached.isNotEmpty) {
      coupons.value = cached;
      usedCoupons.value = coupons.where((c) => c['is_used'] == true).toList();
    }
  }
  
  /// Load all available coupons
  Future<void> loadCoupons() async {
    if (coupons.isEmpty) {
      isLoading.value = true;
    }
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
      await DataCache.saveList(DataCache.coupons, coupons.toList());
    } catch (e) {
      if (coupons.isEmpty) {
        ApiService.showErrorSnackbar(e);
      }
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

  static double couponMinAmount(Map<String, dynamic> coupon) {
    final candidates = [
      coupon['minimum_amount'],
      coupon['minimum_purchase'],
      coupon['min_amount'],
      coupon['min_purchase'],
      coupon['minimum_order_value'],
      coupon['min_order_amount'],
      coupon['minimum_order_amount'],
    ];
    if (coupon['data'] is num) {
      candidates.add(coupon['data']);
    }
    for (final v in candidates) {
      if (v == null) continue;
      final parsed = v is num
          ? v.toDouble()
          : double.tryParse(v.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }

  /// Cart must have items and meet minimum order for this coupon.
  bool isCouponEligible(
    Map<String, dynamic> coupon,
    double cartSubtotal, {
    required bool cartHasItems,
  }) {
    if (isCouponUsed(coupon['code']?.toString() ?? '')) return false;
    if (!cartHasItems || cartSubtotal <= 0) return false;
    final min = couponMinAmount(coupon);
    if (min > 0 && cartSubtotal < min) return false;
    return true;
  }

  String couponDisabledReason(
    Map<String, dynamic> coupon,
    double cartSubtotal, {
    required bool cartHasItems,
  }) {
    if (isCouponUsed(coupon['code']?.toString() ?? '')) {
      return 'Already used';
    }
    if (!cartHasItems || cartSubtotal <= 0) {
      return 'Add products to cart';
    }
    final min = couponMinAmount(coupon);
    if (min > 0 && cartSubtotal < min) {
      return 'Min order \$${min.toStringAsFixed(0)}';
    }
    return '';
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

