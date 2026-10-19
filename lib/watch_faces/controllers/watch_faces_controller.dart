import 'package:flutter/foundation.dart';

import 'package:get/get.dart';



import '../../utils/getx_registry.dart';

import '../../routes/app_routes.dart';

import '../../services/api_endpoints.dart';

import '../../services/api_service.dart';

import '../../utils/cache_manager.dart';

import '../data/watch_faces_repository.dart';

import '../models/watch_face_model.dart';

import '../watch_faces_config.dart';



/// Purchase state + pay flow for fruit watch faces.

class WatchFacesController extends GetxController {

  static const String _purchasedIdsKey = 'watch_face_purchased_ids';



  final WatchFacesRepository repository;

  final ApiService _apiService = ApiService();



  WatchFacesController({WatchFacesRepository? repository})

      : repository = repository ?? WatchFacesRepository();



  final RxBool isLoadingPurchases = false.obs;

  final RxMap<String, bool> purchasedByFaceId = <String, bool>{}.obs;



  List<String> _localPurchasedIds() {

    final raw = CacheManager.getData<List>(_purchasedIdsKey);

    if (raw == null) return [];

    return raw.map((e) => e.toString()).toList();

  }



  Future<void> _persistFaceId(String faceId) async {

    final ids = _localPurchasedIds();

    if (!ids.contains(faceId)) {

      ids.add(faceId);

      await CacheManager.saveData(_purchasedIdsKey, ids);

    }

  }



  /// Marks only this face — each watch face is purchased separately.

  Future<void> markFacePurchased(String faceId) async {

    purchasedByFaceId[faceId] = true;

    await _persistFaceId(faceId);

  }



  void _applyLocalPurchases() {

    for (final id in _localPurchasedIds()) {

      purchasedByFaceId[id] = true;

    }

  }



  @override

  void onInit() {

    super.onInit();

    _applyLocalPurchases();

  }



  bool isPurchased(WatchFace face) {

    if (WatchFacesConfig.bypassPurchaseForTesting) return true;

    return purchasedByFaceId[face.id] == true;

  }



  bool canInstall(WatchFace face) {

    if (WatchFacesConfig.bypassPurchaseForTesting) return face.isInstallable;

    return isPurchased(face) && face.isInstallable;

  }



  bool showInstallAction(WatchFace face) {

    if (!face.isInstallable) return false;

    if (WatchFacesConfig.bypassPurchaseForTesting) return true;

    return isPurchased(face);

  }



  /// Local cache + per-face backend sync (watch_face_id in order notes).

  Future<void> refreshPurchaseState(List<WatchFace> faces) async {

    if (WatchFacesConfig.bypassPurchaseForTesting) return;

    _applyLocalPurchases();

    if (!CacheManager.isLoggedIn()) return;



    isLoadingPurchases.value = true;

    try {
      final results = await Future.wait(
        faces.map((face) async {
          final purchased = await _fetchHasPurchasedFace(face);
          return (face.id, purchased);
        }),
      );
      for (final (faceId, purchased) in results) {
        if (purchased) await markFacePurchased(faceId);
      }
    } finally {

      isLoadingPurchases.value = false;

    }

  }



  Future<bool> _fetchHasPurchasedFace(WatchFace face) async {

    try {

      final productId = face.productId;

      final query = <String, String>{

        'watch_face_id': face.id,

        if (productId != null && productId > 0)

          'product_id': productId.toString(),

      };

      final response = await _apiService.get(

        ApiEndpoints.orderHasPurchased,

        queryParameters: query,

      );

      final data = ApiService.handleResponse(response);

      return data['has_purchased'] == true;

    } catch (e) {

      debugPrint('[WatchFace] has_purchased faceId=${face.id} error: $e');

      return false;

    }

  }



  Future<bool> verifyPurchaseForFace(WatchFace face) async {

    if (WatchFacesConfig.bypassPurchaseForTesting) return true;

    if (!face.requiresPurchase) return true;

    if (isPurchased(face)) return true;



    if (!CacheManager.isLoggedIn()) return false;

    if (face.productId == null || face.productId! <= 0) return false;



    if (await _fetchHasPurchasedFace(face)) {

      await markFacePurchased(face.id);

      return true;

    }

    return false;

  }



  Future<void> payForFace(WatchFace face) async {

    if (WatchFacesConfig.bypassPurchaseForTesting) return;

    if (!face.requiresPurchase) return;



    if (!CacheManager.isLoggedIn()) {

      Get.snackbar('Login Required', 'Please login to purchase this watch face.');

      await Future.delayed(const Duration(milliseconds: 400));

      AppRoutes.toLogin();

      return;

    }



    final productId = face.productId;

    if (productId == null || productId <= 0) {

      Get.snackbar(

        'Not linked',

        'This watch face is not linked to a store product yet. Add productId in watch_faces.json.',

      );

      return;

    }



    final cartController = GetXRegistry.cart();



    await cartController.clearCart();

    final added = await cartController.addToCart(

      productId: productId,

      quantity: 1,

    );

    if (!added) return;



    final amount = face.price ?? 0;



    await GetXRegistry.resetPaymentFlow();



    final payResult = await AppRoutes.open(

      AppRoutes.digitalPayRedirect,

      arguments: {

        'digital_quick_pay': true,

        'quick_pay_amount': amount,

        'watch_face_id': face.id,
        'watch_face_title': face.title,
      },

    );



    if (payResult is Map && payResult['success'] == true) {

      await markFacePurchased(face.id);

      _reloadOrdersList();

    }

  }



  void _reloadOrdersList() {

    try {

      GetXRegistry.profile().loadOrders(silent: true);

    } catch (e) {

      debugPrint('[WatchFace] reload orders: $e');

    }

  }

}


