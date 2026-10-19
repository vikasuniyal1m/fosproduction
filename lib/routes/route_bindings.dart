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
import '../utils/getx_registry.dart';
import '../watch_faces/controllers/watch_faces_controller.dart';
import '../watch_faces/watch_faces_config.dart';

/// Route-level GetX bindings. Always use [AppRoutes.open] / Get.toNamed — not raw Get.to.
class RouteBindings {
  RouteBindings._();

  static void splash() => GetXRegistry.splash();
  static void onboarding() => GetXRegistry.onboarding();
  static void auth() => GetXRegistry.auth();

  static void home() {
    if (!Get.isRegistered<AuthController>()) {
      GetXRegistry.auth();
    }
    GetXRegistry.home();
  }

  static void productDetails() {
    GetXRegistry.product();
    if (!Get.isRegistered<ProfileController>()) {
      GetXRegistry.profile();
    }
  }

  static void digitalProducts() {
    if (!Get.isRegistered<HomeController>()) {
      GetXRegistry.home();
    }
  }

  static void cart() {
    final cart = GetXRegistry.cart();
    cart.loadCart();
  }

  static void profile() => GetXRegistry.profile();

  static void profileChild() {
    if (!Get.isRegistered<ProfileController>()) {
      GetXRegistry.profile();
    }
  }

  static void loyalty() => GetXRegistry.loyalty();
  static void referral() => GetXRegistry.referral();
  static void chat() {
    if (!Get.isRegistered<ChatController>()) {
      GetXRegistry.chat();
    }
  }

  static void wishlist() => GetXRegistry.wishlist();
  static void checkout() => GetXRegistry.checkout();

  static void digitalPayRedirect() {
    if (Get.isRegistered<CheckoutController>()) {
      Get.delete<CheckoutController>(force: true);
    }
    if (Get.isRegistered<StripePaymentController>()) {
      Get.delete<StripePaymentController>(force: true);
    }
    GetXRegistry.checkout();
  }

  static void coupons() => GetXRegistry.coupon();
  static void search() => GetXRegistry.search();
  static void orderDetails() => profileChild();
  static void paymentGateway() {
    if (!Get.isRegistered<CheckoutController>()) {
      GetXRegistry.checkout();
    }
  }

  static void stripePayment() => GetXRegistry.stripePayment();

  static void notifications() => GetXRegistry.notification();

  static void notificationSettings() {
    if (!Get.isRegistered<NotificationController>()) {
      GetXRegistry.notification();
    }
  }

  static void watchFaces() {
    if (WatchFacesConfig.isFeatureEnabled) {
      Get.lazyPut(() => WatchFacesController());
    }
  }
}
