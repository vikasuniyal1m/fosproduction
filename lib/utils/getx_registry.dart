import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/coupon_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/loyalty_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/referral_controller.dart';
import '../controllers/splash_controller.dart';
import '../controllers/stripe_payment_controller.dart';
import '../controllers/wishlist_controller.dart';
import '../controllers/search_controller.dart' as app_search;
import '../services/notification_service.dart';
import '../watch_faces/controllers/watch_faces_controller.dart';
import '../watch_faces/data/watch_faces_repository.dart';

/// Safe GetX controller access — prevents "Controller not found" crashes.
class GetXRegistry {
  GetXRegistry._();

  static T findOrPut<T>(T Function() create, {bool permanent = false}) {
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    }
    return Get.put(create(), permanent: permanent);
  }

  static T? findOrNull<T>() {
    if (!Get.isRegistered<T>()) return null;
    return Get.find<T>();
  }

  static Future<void> deleteIfRegistered<T>() async {
    if (Get.isRegistered<T>()) {
      await Get.delete<T>(force: true);
    }
  }

  /// Clears checkout/payment controllers before a fresh digital pay flow.
  static Future<void> resetPaymentFlow() async {
    await deleteIfRegistered<CheckoutController>();
    await deleteIfRegistered<StripePaymentController>();
  }

  static AuthController auth() => findOrPut(() => AuthController());
  static SplashController splash() => findOrPut(() => SplashController());
  static OnboardingController onboarding() => findOrPut(() => OnboardingController());
  static HomeController home() =>
      findOrPut(() => HomeController(), permanent: true);
  static CartController cart() =>
      findOrPut(() => CartController(), permanent: true);
  static CheckoutController checkout() => findOrPut(() => CheckoutController());
  static ProfileController profile() => findOrPut(() => ProfileController());
  static ProductController product() => findOrPut(() => ProductController());
  static WishlistController wishlist() =>
      findOrPut(() => WishlistController(), permanent: true);
  static CouponController coupon() => findOrPut(() => CouponController());
  static ChatController chat() => findOrPut(() => ChatController());
  static NotificationController notification() => findOrPut(() => NotificationController());
  static LoyaltyController loyalty() => findOrPut(() => LoyaltyController());
  static ReferralController referral() => findOrPut(() => ReferralController());
  static StripePaymentController stripePayment() => findOrPut(() => StripePaymentController());
  static app_search.SearchController search() => findOrPut(() => app_search.SearchController());
  static WatchFacesController watchFaces() =>
      findOrPut(() => WatchFacesController(repository: WatchFacesRepository()));

  static NotificationService? notificationServiceOrNull() => findOrNull<NotificationService>();

  static NotificationService notificationService() {
    final service = notificationServiceOrNull();
    if (service == null) {
      throw StateError(
        'NotificationService is not ready yet. It is initialized asynchronously in main().',
      );
    }
    return service;
  }
}
