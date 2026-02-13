/// API Endpoints
/// Centralized API endpoint paths
class ApiEndpoints {
  // Auth
  static const String register = 'auth/register.php';
  static const String login = 'auth/login.php';
  static const String forgotPassword = 'auth/forgot-password.php';
  static const String resetPassword = 'auth/reset-password.php';
  
  // User
  static const String userProfile = 'user/profile.php';
  static const String changePassword = 'user/change-password.php';
  static const String deleteAccount = 'user/delete-account.php';

  // Orders
  static const String ordersList = 'orders/list.php';
  static const String orderDetails = 'orders/details.php';
  static const String ordersCreate = 'orders/create.php';
  static const String orderTracking = 'orders/tracking.php';
  static const String orderReorder = 'orders/reorder.php';
  static const String orderInvoice = 'orders/invoice.php';
  static const String orderCancel = 'orders/cancel.php';
  static const String orderReturn = 'orders/return.php';
  
  // Payments
  static const String paymentInitiate = 'payments/initiate.php';
  static const String paymentVerify = 'payments/verify.php';
  
  // Stripe Payments
  static const String stripeCreateIntent = 'payments/stripe/create_intent.php';
  static const String stripeCreatePaymentMethod = 'payments/stripe/create_payment_method.php';
  static const String stripeConfirmPayment = 'payments/stripe/confirm_payment.php';
  static const String stripeGetStatus = 'payments/stripe/get_status.php';
  
  // Checkout
  static const String checkoutSummary = 'checkout/summary.php';
  static const String checkoutApplyCoupon = 'checkout/apply-coupon.php';
  static const String checkoutAvailableCoupons = 'checkout/available-coupons.php';
  
  // Addresses
  static const String addressesList = 'addresses/list.php';
  static const String addressesAdd = 'addresses/add.php';
  static const String addressesUpdate = 'addresses/update.php?id={id}';
  static const String addressesDelete = 'addresses/delete.php?id={id}';
  static const String addressesSetDefault = 'addresses/set-default.php?id={id}';
  
  // Payment Methods
  static const String paymentMethodsList = 'payment-methods/list.php';
  static const String paymentMethodsAdd = 'payment-methods/add.php';
  static const String paymentMethodsUpdate = 'payment-methods/update.php?id={id}';
  static const String paymentMethodsDelete = 'payment-methods/delete.php?id={id}';
  static const String paymentMethodsSetDefault = 'payment-methods/set-default.php?id={id}';

  // Categories
  static const String categoriesList = 'categories/list.php';
  static const String categoryDetails = 'categories/details.php';
  
  // Products
  static const String productsList = 'products/list.php';
  static const String productDetails = 'products/details.php';
  static const String productSearch = 'products/search.php';
  static const String featuredProducts = 'products/featured.php';
  static const String bestsellerProducts = 'products/bestsellers.php';
  static const String newArrivals = 'products/new-arrivals.php';
  static const String discountedProducts = 'products/discounted.php';
  static const String topRatedProducts = 'products/top-rated.php';
  
  // Banners
  static const String bannersList = 'banners/list.php';
  
  // Coupons
  static const String validateCoupon = 'coupons/validate.php';
  static const String availableCoupons = 'coupons/available.php';
  
  // Flash Sales
  static const String flashSales = 'flash-sales/list.php';
  
  // Reviews
  static const String reviewsList = 'reviews/list.php';
  static const String createReview = 'reviews/create.php';
  static const String reviewLike = 'reviews/like.php';
  static const String reviewReport = 'reviews/report.php';
  
  // Notifications
  static const String notificationsList = 'notifications/list.php';
  static const String notificationRegisterToken = 'notifications/register-token.php';
  static const String notificationSend = 'notifications/send.php';
  static const String notificationMarkRead = 'notifications/mark-read.php';
  static const String notificationReadAll = 'notifications/read-all.php';
  static const String notificationUnreadCount = 'notifications/unread-count.php';
  
  // Cart
  static const String cartList = 'cart/list.php';
  static const String cartAdd = 'cart/add.php';
  static const String cartUpdate = 'cart/update.php';
  static const String cartRemove = 'cart/remove.php';
  static const String cartClear = 'cart/clear.php';
  
  // Wishlist
  static const String wishlistList = 'wishlist/list.php';
  static const String wishlistAdd = 'wishlist/add.php';
  static const String wishlistRemove = 'wishlist/remove.php';
  static const String wishlistClear = 'wishlist/clear.php';

  // Chat
  static const String chatConversationsCreate = 'chat/conversations/create.php';
  static const String chatConversationsList = 'chat/conversations/list.php';
  static const String chatConversationsGet = 'chat/conversations/get.php';
  static const String chatConversationsClose = 'chat/conversations/close.php';
  static const String chatMessagesSend = 'chat/messages/send.php';
  static const String chatMessagesList = 'chat/messages/list.php';
  
  // Loyalty Points
  static const String loyaltyPoints = 'loyalty/points.php';
  static const String loyaltyHistory = 'loyalty/history.php';
  static const String loyaltyRedeem = 'loyalty/redeem.php';
  
  // Referrals
  static const String referralCode = 'referrals/code.php';
  static const String referralStats = 'referrals/stats.php';
  static const String referralApply = 'referrals/apply.php';
}

