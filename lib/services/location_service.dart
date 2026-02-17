import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../utils/app_colors.dart';

/// Location Service
/// Handles location permissions and GPS location detection
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Error checking location service: $e');
      return false; // Safe fallback
    }
  }

  /// Check the current status of location permission.
  Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      print('Error checking location permission: $e');
      return LocationPermission.denied; // Safe fallback
    }
  }

  /// Request location permission from the user.
  /// Handles different permission states like granted, denied, and permanently denied.
  Future<LocationPermission> requestLocationPermission() async {
    debugPrint('[LocationService] requestLocationPermission - checking if location service enabled');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[LocationService] isLocationServiceEnabled: $serviceEnabled');
    if (!serviceEnabled) {
      debugPrint('[LocationService] Location service DISABLED - showing snackbar');
      Get.snackbar(
        'Location Disabled',
        'Please enable location services (GPS) on your device to proceed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
      return LocationPermission.denied;
    }

    debugPrint('[LocationService] Checking current permission...');
    LocationPermission permission = await checkLocationPermission();
    debugPrint('[LocationService] Current permission: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('[LocationService] Permission denied - requesting...');
      permission = await Geolocator.requestPermission();
      debugPrint('[LocationService] After request: $permission');
      if (permission == LocationPermission.denied) {
        debugPrint('[LocationService] User denied permission');
        Get.snackbar(
          'Permission Denied',
          'Location permission is required to detect your address automatically.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.1),
          colorText: AppColors.error,
        );
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationService] Permission deniedForever - showing settings dialog');
      await Get.dialog(
        AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is permanently denied. You need to enable it from settings to detect your current location automatically.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      permission = await checkLocationPermission();
      debugPrint('[LocationService] After settings dialog permission: $permission');
      return permission;
    }

    debugPrint('[LocationService] requestLocationPermission - returning granted: $permission');
    return permission;
  }

  /// Get current location. Assumes permission has already been granted.
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    debugPrint('[LocationService] getCurrentLocation ENTRY');
    debugPrint('[LocationService] getCurrentLocation - calling Geolocator.getCurrentPosition (timeLimit 15s)...');
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      debugPrint('[LocationService] Position received: lat=${position.latitude}, lon=${position.longitude}');

      debugPrint('[LocationService] Reverse geocoding...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      debugPrint('[LocationService] placemarkFromCoordinates returned ${placemarks.length} placemarks');

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        debugPrint('[LocationService] First place: name=${place.name}, street=${place.street}, locality=${place.locality}, administrativeArea=${place.administrativeArea}, postalCode=${place.postalCode}');

        String addressLine1 = '';
        if (place.street != null && place.street!.isNotEmpty) {
          addressLine1 = place.street!;
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            addressLine1 = '${place.subThoroughfare}, $addressLine1';
          }
        } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressLine1 = place.subThoroughfare!;
        }

        final result = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address_line1': addressLine1.isNotEmpty ? addressLine1 : (place.name ?? 'Unknown Location'),
          'address_line2': place.subLocality ?? '',
          'city': place.locality ?? place.subAdministrativeArea ?? '',
          'state': place.administrativeArea ?? '',
          'pincode': place.postalCode ?? '',
          'country': place.country ?? '',
        };
        debugPrint('[LocationService] getCurrentLocation SUCCESS - returning address map');
        return result;
      }

      debugPrint('[LocationService] placemarks empty - returning fallback lat/lon only');
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address_line1': 'Lat: ${position.latitude}, Lon: ${position.longitude}',
        'address_line2': '', 'city': '', 'state': '', 'pincode': '', 'country': '',
      };

    } on TimeoutException {
      debugPrint('[LocationService] getCurrentLocation TIMEOUT - Geolocator.getCurrentPosition took > 15s');
      Get.snackbar(
        'Location Timeout',
        'Could not get location in time. Please check your GPS signal and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stack) {
      debugPrint('[LocationService] getCurrentLocation ERROR: $e');
      debugPrint('[LocationService] stackTrace: $stack');
      Get.snackbar(
        'Location Error',
        'Failed to get location. Please ensure GPS is enabled and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
}
