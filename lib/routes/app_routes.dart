import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../controllers/splash_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../views/splash/splash_screen.dart';
import '../views/onboarding/onboarding_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/auth/reset_password_screen.dart';
import '../views/auth/new_password_screen.dart';
import '../views/home/home_screen.dart';
import '../views/products/product_details_screen.dart';
import '../views/products/category_products_screen.dart';
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
import '../views/profile/notification_settings_screen.dart';
import '../controllers/notification_controller.dart';
import '../utils/cache_manager.dart';

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
  static const String loyaltyPoints = '/loyalty-points';
  static const String referralProgram = '/referral-program';
  static const String invoiceView = '/invoice-view';
  static const String termsConditions = '/terms-conditions';
  static const String privacyPolicy = '/privacy-policy';
  static const String returnPolicy = '/return-policy';
  static const String notifications = '/notifications';
  
  // Route list
  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder(() {
        Get.put(OnboardingController());
      }),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
    ),
    GetPage(
      name: signup,
      page: () => const SignUpScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController());
        }
      }),
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ResetPasswordScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController());
        }
      }),
    ),
    GetPage(
      name: newPassword,
      page: () {
        final token = Get.parameters['token'];
        return NewPasswordScreen(token: token);
      },
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController());
        }
      }),
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: BindingsBuilder(() {
        // Ensure AuthController exists for home screen
        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController());
        }
        Get.put(HomeController());
      }),
    ),
    GetPage(
      name: productDetails,
      page: () => const ProductDetailsScreen(),
      binding: BindingsBuilder(() {
        Get.put(ProductController());
      }),
    ),
    GetPage(
      name: categoryProducts,
      page: () => const CategoryProductsScreen(),
    ),
    GetPage(
      name: cart,
      page: () => const CartScreen(),
      binding: BindingsBuilder(() {
        // Ensure cart is loaded when navigating to cart screen
        if (Get.isRegistered<CartController>()) {
          final cartController = Get.find<CartController>();
          cartController.loadCart();
        } else {
          final cartController = Get.put(CartController());
          cartController.loadCart();
        }
      }),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),
    GetPage(
      name: editProfile,
      page: () => const EditProfileScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
    ),
    GetPage(
      name: changePassword,
      page: () => const ChangePasswordScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
    ),
    GetPage(
      name: orders,
      page: () => const OrdersScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
    ),
    GetPage(
      name: addresses,
      page: () => const AddressesScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
    ),
    GetPage(
      name: addAddress,
      page: () => const AddEditAddressScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
    ),
    GetPage(
      name: editAddress,
      page: () {
        final address = Get.arguments as Map<String, dynamic>?;
        return AddEditAddressScreen(address: address);
      },
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
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
      binding: BindingsBuilder(() {
        Get.put(LoyaltyController());
      }),
    ),
    GetPage(
      name: referralProgram,
      page: () => const ReferralProgramScreen(),
      binding: BindingsBuilder(() {
        Get.put(ReferralController());
      }),
    ),
    GetPage(
      name: paymentMethods,
      page: () => const PaymentMethodsScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
    ),
    GetPage(
      name: addPaymentMethod,
      page: () => const AddEditPaymentMethodScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
    ),
    GetPage(
      name: editPaymentMethod,
      page: () {
        final paymentMethod = Get.arguments as Map<String, dynamic>?;
        return AddEditPaymentMethodScreen(paymentMethod: paymentMethod);
      },
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
    ),
    GetPage(
      name: chat,
      page: () {
        return const ChatScreen();
      },
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ChatController>()) {
          Get.put(ChatController());
        }
      }),
    ),
    GetPage(
      name: wishlist,
      page: () => const WishlistScreen(),
      binding: BindingsBuilder(() {
        Get.put(WishlistController());
      }),
    ),
    GetPage(
      name: checkout,
      page: () => const CheckoutScreen(),
      binding: BindingsBuilder(() {
        Get.put(CheckoutController());
      }),
    ),
    GetPage(
      name: orderConfirmation,
      page: () => const OrderConfirmationScreen(),
    ),
    GetPage(
      name: coupons,
      page: () => CouponsScreen(),
      binding: BindingsBuilder(() {
        Get.put(CouponController());
      }),
    ),
    GetPage(
      name: search,
      page: () => const SearchScreen(),
      binding: BindingsBuilder(() {
        Get.put(search_controller.SearchController());
      }),
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
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
      }),
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
    ),
    GetPage(
      name: stripePayment,
      page: () => const StripePaymentScreen(),
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
      page: () => const NotificationSettingsScreen(),
      binding: BindingsBuilder(() {
        Get.put(NotificationController());
      }),
    ),
  ];
  
  // Navigation methods
  static void toSplash() => Get.offAllNamed(splash);
  static void toOnboarding() => Get.offAllNamed(onboarding);
  static void toLogin() => Get.toNamed(login);
  static void toSignup() => Get.toNamed(signup);
  static void toForgotPassword() => Get.toNamed(forgotPassword);
  static void toNewPassword(String token) => Get.toNamed('$newPassword?token=$token');
  static void toHome() => Get.offAllNamed(home);
  static void toCategoryProducts(int categoryId, String categoryName) => Get.toNamed(
    categoryProducts,
    arguments: {
      'categoryId': categoryId,
      'categoryName': categoryName,
    },
  );
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
  static void toAddAddress() => Get.toNamed(addAddress);
  static void toAddPaymentMethod() => Get.toNamed(addPaymentMethod);
  static void toSearch() => Get.toNamed(search);
}

