import 'dart:io';
import 'package:flutter/services.dart';

/// Tracking Service
/// Handles App Tracking Transparency (ATT) for iOS
class TrackingService {
  static const MethodChannel _channel = MethodChannel('app_tracking_transparency');
  
  /// Request tracking authorization (iOS only)
  /// Returns: 0 = notDetermined, 1 = restricted, 2 = denied, 3 = authorized
  static Future<int> requestTrackingAuthorization() async {
    if (!Platform.isIOS) {
      // Android doesn't use ATT
      return 3; // Return authorized for Android
    }
    
    try {
      final int status = await _channel.invokeMethod('requestTrackingAuthorization');
      return status;
    } catch (e) {
      print('Error requesting tracking authorization: $e');
      return 2; // Return denied on error
    }
  }
  
  /// Get current tracking authorization status
  static Future<int> getTrackingAuthorizationStatus() async {
    if (!Platform.isIOS) {
      return 3; // Return authorized for Android
    }
    
    try {
      final int status = await _channel.invokeMethod('getTrackingAuthorizationStatus');
      return status;
    } catch (e) {
      print('Error getting tracking authorization status: $e');
      return 0; // Return notDetermined on error
    }
  }
}

