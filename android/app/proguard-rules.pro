# Flutter's default rules.
-dontwarn io.flutter.embedding.**

# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.** { *; }

# Keep rule for the Stripe SDK
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.stripe.android.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep GetX state management
-keep class io.getx.** { *; }

# Keep network models
-keep class com.dio.** { *; }

# Keep shared preferences
-keep class android.content.SharedPreferences.** { *; }

# Keep local storage
-keep class com.hive.** { *; }
-keep class com.get_storage.** { *; }

# Keep image loading
-keep class com.cached_network_image.** { *; }

# Keep payment models
-keep class com.stripe.android.model.** { *; }

# Keep custom models (add your package name)
-keep class com.fosproduction.ecommerceapp.** { *; }

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
}
