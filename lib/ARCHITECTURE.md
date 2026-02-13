# Flutter E-Commerce App Architecture

## Project Structure

This Flutter application follows **MVC (Model-View-Controller) architecture** using **GetX** for state management.

## 📁 Directory Structure

```
lib/
├── controllers/          # Business logic & state management
│   ├── auth_controller.dart
│   ├── onboarding_controller.dart
│   └── splash_controller.dart
├── views/               # UI Screens
│   ├── auth/
│   │   └── login_screen.dart
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   ├── splash/
│   │   └── splash_screen.dart
│   └── home/
│       └── home_screen.dart
├── widgets/             # Reusable widgets
│   ├── custom_bottom_nav_bar.dart
│   └── loading_widget.dart
├── utils/               # Utility files
│   ├── app_colors.dart      # Centralized color management
│   ├── app_lifecycle.dart   # App lifecycle handling
│   ├── cache_manager.dart   # Local storage & caching
│   └── screen_size.dart     # Responsive sizing
├── routes/              # Navigation routes
│   └── app_routes.dart
└── main.dart            # App entry point
```

## 🎨 Core Utilities

### 1. Screen Size (`lib/utils/screen_size.dart`)
- **Purpose**: Responsive design utility
- **Features**:
  - Calculates screen dimensions
  - Provides responsive text sizes (textSmall, textMedium, textLarge, etc.)
  - Provides responsive heading sizes (headingSmall, headingMedium, etc.)
  - Provides button sizes (buttonHeightSmall, buttonHeightMedium, etc.)
  - Provides spacing values (spacingSmall, spacingMedium, etc.)
  - Provides icon sizes, tile sizes, input field sizes
  - Detects device type (phone/tablet) and orientation

**Usage Example:**
```dart
Text(
  'Hello',
  style: TextStyle(fontSize: ScreenSize.textLarge),
)
```

### 2. App Colors (`lib/utils/app_colors.dart`)
- **Purpose**: Centralized color management
- **Features**:
  - Primary, secondary, accent colors
  - Background colors
  - Text colors
  - Status colors (success, error, warning, info)
  - Button colors
  - Border colors
  - Gradient colors
  - Shadow colors

**Usage Example:**
```dart
Container(
  color: AppColors.primary,
  child: Text('Text', style: TextStyle(color: AppColors.textWhite)),
)
```

### 3. Cache Manager (`lib/utils/cache_manager.dart`)
- **Purpose**: Lightweight local storage
- **Features**:
  - User data storage (token, email, name, etc.)
  - App settings (theme, language, notifications)
  - Cart & wishlist storage
  - Generic key-value storage
  - Clear all / clear user data methods

**Usage Example:**
```dart
await CacheManager.saveUserToken('token123');
String? token = CacheManager.getUserToken();
```

### 4. App Lifecycle (`lib/utils/app_lifecycle.dart`)
- **Purpose**: Handle app lifecycle events
- **Features**:
  - Detects app foreground/background states
  - Handles app pause/resume
  - Tracks time spent in background
  - Auto-refresh data when returning to foreground

**Usage Example:**
```dart
final lifecycle = AppLifecycleManager.instance;
if (lifecycle.isForeground) {
  // App is in foreground
}
```

## 🧩 Reusable Widgets

### 1. Loading Widget (`lib/widgets/loading_widget.dart`)
- **LoadingWidget**: Full-screen or inline loading indicator
- **OverlayLoading**: Loading overlay on top of content
- **ButtonLoading**: Loading indicator inside buttons

### 2. Custom Bottom Nav Bar (`lib/widgets/custom_bottom_nav_bar.dart`)
- Reusable bottom navigation bar
- Customizable icons and labels
- Active/inactive states

## 📱 Screens Implemented

### 1. Splash Screen
- Shows app logo and name
- Initializes app
- Navigates to onboarding (first time) or login/home (returning user)

### 2. Onboarding Screen
- 3-page introduction slides
- Page indicators
- Skip functionality
- Navigates to login after completion

### 3. Login Screen
- Email and password fields
- Password visibility toggle
- Form validation
- Forgot password link
- Sign up link
- Navigates to home after successful login

## 🚀 Getting Started

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the App:**
   ```bash
   flutter run
   ```

## 📦 Dependencies

- `get`: State management and navigation
- `get_storage`: Lightweight local storage
- `shared_preferences`: Additional storage option
- `flutter_screenutil`: Responsive sizing
- `dio`: HTTP client (for future API calls)
- `cached_network_image`: Image caching (for future use)

## 🎯 Next Steps

1. Implement Sign Up screen
2. Implement Forgot Password screen
3. Implement Home screen with products
4. Add API integration
5. Implement remaining modules from README

## 💡 Best Practices

1. **Always use ScreenSize** for responsive design
2. **Always use AppColors** for consistent theming
3. **Use CacheManager** for local data storage
4. **Follow MVC pattern**: Controllers for logic, Views for UI
5. **Keep widgets reusable** and in the widgets folder
6. **Use GetX** for state management and navigation

## 🔧 Customization

### Change App Colors
Edit `lib/utils/app_colors.dart` - all colors are centralized here.

### Change Screen Sizes
Edit `lib/utils/screen_size.dart` - adjust design size and responsive values.

### Add New Routes
Add routes in `lib/routes/app_routes.dart` and create corresponding screens/controllers.

