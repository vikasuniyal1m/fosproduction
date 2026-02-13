# E-Commerce Mobile Application

A comprehensive Flutter-based e-commerce mobile application for Android and iOS with a complete admin panel backend.

## 📱 Overview

This is a full-featured e-commerce application built with Flutter, providing a seamless shopping experience across multiple device sizes. The app includes user authentication, product browsing, shopping cart, checkout, order management, reviews, and much more.

## ✨ Features

### 🔐 1. User Account & Authentication
- Sign up / Login via email, phone, Google, Apple, or Facebook
- Profile management (name, shipping address, payment methods)
- Forgot / reset password
- Secure token-based authentication

### 🛍️ 2. Product Browsing & Categories
- Organized categories: Apparel (T-shirts), Home (candles, cups), Collectibles (bobbleheads), Stationery (journals), Health (vitamins), Cartoon Line (future)
- Advanced search with filters (price, popularity, category, rating)
- Sorting options (low–high, new arrivals, bestsellers)
- Product details (images, price, stock, description, variants like size/color)
- Product images gallery with zoom
- Related products suggestions

### 🛒 3. Shopping Cart & Checkout
- Add/remove products to cart
- Save items to wishlist
- Apply promo codes / discounts
- Multiple delivery addresses
- Secure checkout flow
- Quantity management
- Cart persistence across sessions

### 💳 4. Payment & Orders
- Payment gateways: credit/debit cards, PayPal, Apple Pay, Google Pay, COD (if supported)
- Order confirmation with summary
- Live order tracking (processing → shipped → delivered)
- Order history & re-order option
- Downloadable invoice/receipt
- Order cancellation and return requests

### ⭐ 5. Reviews & Engagement
- Rate & review products (e.g., T-shirts, candles, vitamins)
- Like / report reviews
- Share products on social media
- Review moderation (pending/approved/rejected)
- Review images support

### 🔔 6. Notifications & Communication
- Push notifications (new cartoon products, discounts, back-in-stock alerts)
- Email/SMS updates for order status
- In-app customer support (chat, FAQs, contact form)
- Help & Support section

### 🎁 7. Marketing & Loyalty
- Discount coupons & seasonal offers
- Flash sales (e.g., holiday discounts on candles or T-shirts)
- Loyalty/reward points for repeat buyers
- "Refer & Earn" program
- Promotional banners

### 📍 8. Location Services
- Location-based delivery address selection
- GPS integration for accurate addresses
- Multiple saved addresses

## 🏗️ Architecture

### Project Structure
```
lib/
├── controllers/      # State management (GetX controllers)
├── views/           # UI screens
├── widgets/         # Reusable UI components
├── services/        # API services and business logic
├── utils/           # Utilities (colors, screen size, cache)
├── routes/          # Navigation routes
└── models/          # Data models
```

### State Management
- **GetX** for state management, dependency injection, and routing
- Reactive programming with `Obx` and `GetBuilder`
- Controller-based architecture

### Responsive Design
- **ScreenSize** utility for device-adaptive UI
- **flutter_screenutil** for responsive sizing
- Breakpoint-based layouts for phones and tablets
- Orientation support (portrait/landscape)

## 🛠️ Technology Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.9.0+
- **State Management**: GetX 4.6.6
- **Local Storage**: Hive, SharedPreferences, GetStorage
- **Network**: Dio 5.4.0
- **UI**: Material Design 3
- **Responsive**: flutter_screenutil 5.9.0
- **Image Caching**: cached_network_image 3.3.1
- **Location**: geolocator, geocoding
- **Device Preview**: device_preview (dev only)

### Backend
- **Language**: PHP
- **Database**: MySQL
- **API**: RESTful API
- **Authentication**: JWT/Bearer tokens

## 📦 Installation

### Prerequisites
- Flutter SDK 3.9.0 or higher
- Dart SDK 3.9.0 or higher
- Android Studio / Xcode (for mobile development)
- PHP 7.4+ and MySQL (for backend)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ecomm_whole_app/ecommerceapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   - Update `lib/services/api_service.dart` with your backend URL
   - Update `lib/services/api_endpoints.dart` if needed

4. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🍎 iOS Setup & Code Signing

### Prerequisites for iOS Development
- macOS with Xcode installed
- Apple Developer Account (free or paid)
- iOS device (for physical device testing) or iOS Simulator

### Common Error: "No valid code signing certificates were found"

If you encounter this error when trying to build or run the app on an iOS device, follow these steps:

#### Step-by-Step Solution

1. **Open the Flutter project's Xcode workspace**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```
   Or from the project root:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select the Runner project**
   - In Xcode, click on the **'Runner'** project in the left navigator
   - Select the **'Runner'** target in the project settings (under TARGETS)

3. **Configure Signing & Capabilities**
   - Go to the **"Signing & Capabilities"** tab
   - Under **"Team"**, select your Apple Developer account
   - If you don't see your team:
     - Click **"Add Account..."** and sign in with your Apple ID
     - Ensure you have a valid unique Bundle ID (e.g., `com.yourcompany.ecommerceapp`)
     - Register your device with your Apple Developer Account if needed
   - Check **"Automatically manage signing"** - Xcode will create certificates and provisioning profiles automatically

4. **Verify Bundle Identifier**
   - Make sure the Bundle Identifier is unique (e.g., `com.yourcompany.ecommerceapp`)
   - You can change it in the **"General"** tab under **"Identity"**

5. **Build or run your project again**
   ```bash
   flutter run
   ```
   Or build for release:
   ```bash
   flutter build ios --release
   ```

6. **Trust the Development Certificate on your iOS device**
   - On your iOS device, go to: **Settings > General > Device Management**
   - Find your newly created Development Certificate
   - Tap on it and select **"Trust [Your Name]"**
   - Confirm by tapping **"Trust"**

### Alternative: Run on iOS Simulator (No Code Signing Required)

If you don't have an Apple Developer account or want to test quickly, you can run on the iOS Simulator without code signing:

1. **List available simulators**
   ```bash
   flutter devices
   ```

2. **Run on a specific simulator**
   ```bash
   flutter run -d "iPhone 15 Pro"
   ```
   Or use the device ID:
   ```bash
   flutter run -d <device-id>
   ```

3. **Open iOS Simulator manually**
   ```bash
   open -a Simulator
   ```

### Troubleshooting

#### Issue: "No development certificates available"
- **Solution**: Make sure you're signed in to Xcode with your Apple ID
- Go to **Xcode > Settings > Accounts**
- Add your Apple ID if not already added
- Download manual profiles if needed

#### Issue: "Provisioning profile doesn't match"
- **Solution**: Let Xcode automatically manage signing
- Uncheck and re-check **"Automatically manage signing"**
- Clean and rebuild: `flutter clean && flutter pub get && flutter run`

#### Issue: "Bundle ID already exists"
- **Solution**: Change the Bundle Identifier to something unique
- In Xcode: **Runner > General > Identity > Bundle Identifier**
- Use reverse domain notation: `com.yourcompany.appname`

#### Issue: Device not registered
- **Solution**: Connect your iOS device to your Mac
- In Xcode: **Window > Devices and Simulators**
- Select your device and click **"Use for Development"**

### Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/library/content/documentation/IDEs/Conceptual/AppDistributionGuide/MaintainingCertificates/MaintainingCertificates.html)
- [Flutter iOS Setup Guide](https://docs.flutter.dev/deployment/ios)
- [Xcode Signing & Capabilities](https://developer.apple.com/documentation/xcode/managing-signing-assets)

### Quick Reference Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run on iOS device
flutter run

# Run on specific iOS simulator
flutter run -d "iPhone 15 Pro"

# Build iOS release
flutter build ios --release

# Open Xcode workspace
open ios/Runner.xcworkspace

# List available devices
flutter devices
```

## 🎨 Responsive Design

The app is built with responsive design principles to work seamlessly across:
- **Small Phones** (< 360px width): iPhone SE, small Android phones
- **Medium Phones** (360-414px): iPhone 12, standard Android phones
- **Large Phones** (414-600px): iPhone Pro Max, large Android phones
- **Small Tablets** (600-768px): iPad Mini, small Android tablets
- **Large Tablets** (> 768px): iPad Pro, large Android tablets

### Key Responsive Features
- Adaptive text sizes based on device type
- Flexible grid layouts (2 columns on phone, 3 on tablet)
- Responsive spacing and padding
- Orientation-aware layouts
- Safe area handling for notches and system bars

See [RESPONSIVE_ROADMAP.md](./RESPONSIVE_ROADMAP.md) for detailed responsive design roadmap.

📱 **Complete Screen Sizes Reference**: See [SCREEN_SIZES_REFERENCE.md](./SCREEN_SIZES_REFERENCE.md) for comprehensive lists of all iPhone and Android device screen sizes with brand names, breakpoints, and responsive UI implementation guidelines.

## 🧪 Testing

### Device Preview (Development)
The app includes Device Preview for testing on different device sizes in debug mode:
- Automatically enabled in debug builds
- Test on various device sizes without physical devices
- Screenshot capabilities

### Manual Testing Checklist
- [ ] Test on small phones (< 360px)
- [ ] Test on medium phones (360-414px)
- [ ] Test on large phones (414-600px)
- [ ] Test on tablets (600px+)
- [ ] Test portrait and landscape orientations
- [ ] Verify no overflow issues
- [ ] Test with different text scale factors
- [ ] Test on Android and iOS

## 🐛 Known Issues & Solutions

### Overflow Issues
- All text widgets use `maxLines` and `overflow: TextOverflow.ellipsis`
- Flexible/Expanded widgets used in Row/Column layouts
- SafeArea widgets for notch handling

### Build Issues
- Android: Ensure `build.gradle.kts` uses Kotlin DSL syntax correctly
- iOS: Check Info.plist for required permissions

## 📝 Code Style

- Follow Flutter/Dart style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Keep widgets small and reusable
- Use const constructors where possible

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly on multiple devices
4. Ensure no overflow issues
5. Submit a pull request

## 📄 License

This project is proprietary and confidential.

## 👥 Team

- **Development**: E-Commerce Team
- **Backend**: PHP/MySQL Team
- **Design**: UI/UX Team

## 📞 Support

For issues, questions, or contributions, please contact the development team.

---

**Last Updated**: 2025-01-27
**Version**: 1.0.0+1
