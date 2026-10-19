/// App Configuration
/// Centralized configuration for the app
class AppConfig {
  // API Configuration
  // static const String baseUrl = 'https://ecommercepanel.templateforwebsites.com/api/';
  static const String baseUrl = 'https://admin.fosproductions.org/api/';
  // static const String imageBaseUrl = 'https://ecommercepanel.templateforwebsites.com/uploads/';
  static const String imageBaseUrl = 'https://admin.fosproductions.org/uploads/';

  // Stripe Configuration
  // Note: Publishable key is fetched dynamically from backend
  // This is only used if you want to initialize Stripe statically
  static const String stripePublishableKey = ''; // Leave empty, fetched from backend
  static const String consumerKey = "ck_d9287a8ca09cbe63fffddfeeaeb83f04c1f31bd0";
  static const String consumerSecret = "cs_4d3a83ee6f085b179bc50f99e26d5517b4432604";
  // App Info
  static const String appName = 'FOS Productions';
  static const String appVersion = '1.0.0';
  
  // Feature Flags
  static const bool enableStripe = true;
  static const bool enableRazorpay = false;
  static const bool enablePayPal = false;
  
  // Payment Settings
  static const String defaultCurrency = 'usd';
  static const int paymentTimeoutSeconds = 30;
  
  // Debug Mode
  static const bool debugMode = true; // Set to false in production
}

