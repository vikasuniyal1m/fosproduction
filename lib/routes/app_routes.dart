import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../controllers/splash_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../views/fos_lens/fos_lens_editor_screen.dart';
import '../watch_faces/controllers/watch_faces_controller.dart';
import '../watch_faces/screens/watch_faces_screen.dart';
import '../watch_faces/watch_faces_config.dart';
import '../views/splash/splash_screen.dart';
import '../views/onboarding/onboarding_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/auth/reset_password_screen.dart';
import '../views/auth/new_password_screen.dart';
import '../views/home/home_screen.dart';
import '../views/products/product_details_screen.dart';
import '../views/products/category_products_screen.dart';
import '../views/products/featured_products_screen.dart';
import '../views/products/digital_products_screen.dart';
import '../controllers/product_controller.dart';
import '../views/cart/cart_screen.dart';
import '../controllers/cart_controller.dart';
import '../views/profile/profile_screen.dart';
import '../views/profile/edit_profile_screen.dart';
import '../views/profile/change_password_screen.dart';
import '../views/profile/orders_screen.dart';
import '../views/profile/addresses_screen.dart';
import '../views/profile/add_edit_address_screen.dart';
import '../views/profile/help_support_screen.dart';
import '../views/profile/about_screen.dart';
import '../views/profile/terms_conditions_screen.dart';
import '../views/profile/privacy_policy_screen.dart';
import '../views/profile/return_policy_screen.dart';
import '../views/profile/payment_methods_screen.dart';
import '../views/profile/add_edit_payment_method_screen.dart';
import '../views/profile/loyalty_points_screen.dart';
import '../views/profile/referral_program_screen.dart';
import '../controllers/loyalty_controller.dart';
import '../controllers/referral_controller.dart';
import '../views/chat/chat_screen.dart';
import '../views/wishlist/wishlist_screen.dart';
import '../controllers/profile_controller.dart';
import '../controllers/wishlist_controller.dart';
import '../controllers/chat_controller.dart';
import '../views/checkout/checkout_screen.dart';
import '../views/checkout/order_confirmation_screen.dart';
import '../controllers/checkout_controller.dart';
import '../views/coupons/coupons_screen.dart';
import '../controllers/coupon_controller.dart';
import '../views/search/search_screen.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../views/orders/order_tracking_screen.dart';
import '../views/orders/order_details_screen.dart';
import '../views/orders/invoice_view_screen.dart';
import '../views/payment/payment_gateway_screen.dart';
import '../views/payment/stripe_payment_screen.dart';
import '../views/payment/digital_pay_redirect_screen.dart';
import '../views/profile/notification_settings_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/profile/gallery_screen.dart';
import '../controllers/notification_controller.dart';
import '../utils/cache_manager.dart';
import 'route_bindings.dart';

/// App Routes
/// Centralized route management using GetX
class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String newPassword = '/new-password';
  static const String home = '/home';
  static const String productDetails = '/product-details';
  static const String categoryProducts = '/category-products';
  static const String digitalProducts = '/digital-products';
  static const String featuredProducts = '/featured-products';
  static const String cart = '/cart';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String orders = '/orders';
  static const String addresses = '/addresses';
  static const String addAddress = '/add-address';
  static const String editAddress = '/edit-address';
  static const String helpSupport = '/help-support';
  static const String about = '/about';
  static const String paymentMethods = '/payment-methods';
  static const String addPaymentMethod = '/add-payment-method';
  static const String editPaymentMethod = '/edit-payment-method';
  static const String chat = '/chat';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String coupons = '/coupons';
  static const String search = '/search';
  static const String orderDetails = '/order-details';
  static const String orderTracking = '/order-tracking';
  static const String paymentGateway = '/payment-gateway';
  static const String stripePayment = '/stripe-payment';
  static const String digitalPayRedirect = '/digital-pay-redirect';
  static const String loyaltyPoints = '/loyalty-points';
  static const String referralProgram = '/referral-program';
  static const String invoiceView = '/invoice-view';
  static const String termsConditions = '/terms-conditions';
  static const String privacyPolicy = '/privacy-policy';
  static const String returnPolicy = '/return-policy';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notification-settings';
  static const String gallery = '/gallery';
  static const String fosLensEditor = '/fos-lens-editor';
  static const String watchFaces = '/watch-faces';

  // Route list
  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(RouteBindings.splash),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder(RouteBindings.onboarding),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(RouteBindings.auth),
    ),
    GetPage(
      name: signup,
      page: () => const SignUpScreen(),
      binding: BindingsBuilder(RouteBindings.auth),
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ResetPasswordScreen(),
      binding: BindingsBuilder(RouteBindings.auth),
    ),
    GetPage(
      name: newPassword,
      page: () {
        final token = Get.parameters['token'] != null ? Uri.decodeComponent(Get.parameters['token']!) : null;
        return NewPasswordScreen(token: token);
      },
      binding: BindingsBuilder(RouteBindings.auth),
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: BindingsBuilder(RouteBindings.home),
    ),
    GetPage(
      name: productDetails,
      page: () => const ProductDetailsScreen(),
      binding: BindingsBuilder(RouteBindings.productDetails),
    ),
    GetPage(
      name: categoryProducts,
      page: () => const CategoryProductsScreen(),
    ),
    // GetPage(
    //   name: featuredProducts,
    //   page: () => const FeaturedProductsScreen(),
    //   binding: BindingsBuilder(() {
    //     if (!Get.isRegistered<HomeController>()) {
    //       Get.put(HomeController());
    //     }
    //   }),
    // ),
    GetPage(
      name: digitalProducts,
      page: () => const DigitalProductsScreen(),
      binding: BindingsBuilder(RouteBindings.digitalProducts),
    ),
    GetPage(
      name: cart,
      page: () => const CartScreen(),
      binding: BindingsBuilder(RouteBindings.cart),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(RouteBindings.profile),
    ),
    GetPage(
      name: editProfile,
      page: () => const EditProfileScreen(),
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: changePassword,
      page: () => const ChangePasswordScreen(),
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: orders,
      page: () => const OrdersScreen(),
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: addresses,
      page: () => const AddressesScreen(),
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: addAddress,
      page: () => const AddEditAddressScreen(),
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: editAddress,
      page: () {
        final address = Get.arguments as Map<String, dynamic>?;
        return AddEditAddressScreen(address: address);
      },
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: helpSupport,
      page: () => const HelpSupportScreen(),
    ),
    GetPage(
      name: about,
      page: () => const AboutScreen(),
    ),
    GetPage(
      name: loyaltyPoints,
      page: () => const LoyaltyPointsScreen(),
      binding: BindingsBuilder(RouteBindings.loyalty),
    ),
    GetPage(
      name: referralProgram,
      page: () => const ReferralProgramScreen(),
      binding: BindingsBuilder(RouteBindings.referral),
    ),
    GetPage(
      name: paymentMethods,
      page: () => const PaymentMethodsScreen(),
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: addPaymentMethod,
      page: () => const AddEditPaymentMethodScreen(),
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: editPaymentMethod,
      page: () {
        final paymentMethod = Get.arguments as Map<String, dynamic>?;
        return AddEditPaymentMethodScreen(paymentMethod: paymentMethod);
      },
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: chat,
      page: () {
        return const ChatScreen();
      },
      binding: BindingsBuilder(RouteBindings.chat),
    ),
    GetPage(
      name: wishlist,
      page: () => const WishlistScreen(),
      binding: BindingsBuilder(RouteBindings.wishlist),
    ),
    GetPage(
      name: checkout,
      page: () => const CheckoutScreen(),
      binding: BindingsBuilder(RouteBindings.checkout),
    ),
    GetPage(
      name: orderConfirmation,
      page: () => const OrderConfirmationScreen(),
    ),
    GetPage(
      name: coupons,
      page: () => CouponsScreen(),
      binding: BindingsBuilder(RouteBindings.coupons),
    ),
    GetPage(
      name: search,
      page: () => const SearchScreen(),
      binding: BindingsBuilder(RouteBindings.search),
    ),
    GetPage(
      name: orderTracking,
      page: () {
        final orderId = Get.arguments as int?;
        if (orderId == null) {
          Get.back();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.red,
            ),
            body: const Center(
              child: Text('Order ID is required'),
            ),
          );
        }
        return OrderTrackingScreen(orderId: orderId);
      },
    ),
    GetPage(
      name: invoiceView,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final invoiceUrl = args?['invoice_url'] ?? '';
        if (invoiceUrl.isEmpty) {
          Get.back();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.red,
            ),
            body: const Center(
              child: Text('Invoice URL is required'),
            ),
          );
        }
        return InvoiceViewScreen(invoiceUrl: invoiceUrl);
      },
    ),
    GetPage(
      name: orderDetails,
      page: () {
        final arguments = Get.arguments;
        if (arguments == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.red,
            ),
            body: const Center(
              child: Text('Order ID is required'),
            ),
          );
        }
        
        int? orderId;
        if (arguments is int) {
          orderId = arguments;
        } else if (arguments is String) {
          orderId = int.tryParse(arguments);
        } else {
          orderId = int.tryParse(arguments.toString());
        }
        
        if (orderId == null || orderId <= 0) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.red,
            ),
            body: const Center(
              child: Text('Invalid Order ID'),
            ),
          );
        }
        
        return OrderDetailsScreen(orderId: orderId);
      },
      binding: BindingsBuilder(RouteBindings.profileChild),
    ),
    GetPage(
      name: paymentGateway,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        return PaymentGatewayScreen(
          orderId: args['order_id'] as int?,
          paymentMethod: args['payment_method'] as String?,
          amount: args['amount'] as double?,
        );
      },
      binding: BindingsBuilder(RouteBindings.paymentGateway),
    ),
    GetPage(
      name: stripePayment,
      page: () => const StripePaymentScreen(),
      binding: BindingsBuilder(RouteBindings.stripePayment),
    ),
    GetPage(
      name: digitalPayRedirect,
      page: () => const DigitalPayRedirectScreen(),
      binding: BindingsBuilder(RouteBindings.digitalPayRedirect),
    ),
    GetPage(
      name: termsConditions,
      page: () => const TermsConditionsScreen(),
    ),
    GetPage(
      name: privacyPolicy,
      page: () => const PrivacyPolicyScreen(),
    ),
    GetPage(
      name: returnPolicy,
      page: () => const ReturnPolicyScreen(),
    ),
    GetPage(
      name: notifications,
      page: () => const NotificationsScreen(),
      binding: BindingsBuilder(RouteBindings.notifications),
    ),
    GetPage(
      name: notificationSettings,
      page: () => const NotificationSettingsScreen(),
      binding: BindingsBuilder(RouteBindings.notificationSettings),
    ),
    GetPage(
      name: gallery,
      page: () => const GalleryScreen(),
    ),
    GetPage(
      name: fosLensEditor,
      page: () {
        if (!CacheManager.isLoggedIn()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.back();
            Get.snackbar('Login Required', 'Please login to use FOS Lens.');
            toLogin();
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        final args = Get.arguments;
        final path = args is Map ? args['path'] as String? : null;
        if (path == null || path.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.back();
            Get.snackbar('FOS Lens', 'No image was selected.');
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return FosLensEditorScreen(imagePath: path);
      },
    ),
    GetPage(
      name: watchFaces,
      page: () {
        if (!WatchFacesConfig.isFeatureEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.key.currentState?.canPop() ?? false) Get.back();
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return const WatchFacesScreen();
      },
      binding: BindingsBuilder(RouteBindings.watchFaces),
    ),
  ];
  
  /// Use this instead of raw Get.to() so route bindings always run.
  static Future<T?>? open<T>(
    String route, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    return Get.toNamed<T>(route, arguments: arguments, parameters: parameters);
  }

  // Navigation methods
  static void toSplash() => Get.offAllNamed(splash);
  static void toOnboarding() => Get.offAllNamed(onboarding);
  static void toLogin() => Get.toNamed(login);
  static void toSignup() => Get.toNamed(signup);
  static void toForgotPassword() => Get.toNamed(forgotPassword);
  static void toNewPassword(String token) => Get.toNamed('$newPassword?token=${Uri.encodeComponent(token)}');
  static void toHome() => Get.offAllNamed(home);
  static void toCategoryProducts(int categoryId, String categoryName) => Get.toNamed(
    categoryProducts,
    arguments: {
      'categoryId': categoryId,
      'categoryName': categoryName,
    },
  );
  static void toDigitalProducts() => Get.toNamed(digitalProducts);
  static void toOrders() => Get.toNamed(orders);
  static void toWishlist() {
    // Check if user is logged in
    if (!CacheManager.isLoggedIn()) {
      Get.snackbar(
        'Login Required',
        'Please login to view your wishlist',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Navigate to login
      Future.delayed(const Duration(milliseconds: 500), () {
        toLogin();
      });
      return;
    }
    Get.toNamed(wishlist);
  }
  static void toCheckout() => Get.toNamed(checkout);
  static void toOrderConfirmation(Map<String, dynamic> order) => Get.offAllNamed(orderConfirmation, arguments: order);
  static void toCoupons() => Get.toNamed(coupons);
  static void toReferralProgram() => Get.toNamed(referralProgram);
  static void toAddAddress() => Get.toNamed(addAddress);
  static void toAddPaymentMethod() => Get.toNamed(addPaymentMethod);
  static void toSearch() => Get.toNamed(search);
  static void toFosLensEditor(String imagePath) =>
      Get.toNamed(fosLensEditor, arguments: {'path': imagePath});
  static void toWatchFaces() {
    if (!WatchFacesConfig.isFeatureEnabled) return;
    Get.toNamed(watchFaces);
  }
}

