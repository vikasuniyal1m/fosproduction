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
    // 1. Check if location services are enabled on the device.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Disabled',
        'Please enable location services (GPS) on your device to proceed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
      return LocationPermission.denied;
    }

    // 2. Check the current permission status.
    LocationPermission permission = await checkLocationPermission();

    // 3. Handle based on status.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
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
      // User has permanently denied, show a dialog to open settings.
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
      return await checkLocationPermission();
    }

    return permission;
  }

  /// Get current location. Assumes permission has already been granted.
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Get current position with a timeout.
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Reverse geocode to get address details.
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        String addressLine1 = '';
        if (place.street != null && place.street!.isNotEmpty) {
          addressLine1 = place.street!;
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            addressLine1 = '${place.subThoroughfare}, $addressLine1';
          }
        } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressLine1 = place.subThoroughfare!;
        }

        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address_line1': addressLine1.isNotEmpty ? addressLine1 : (place.name ?? 'Unknown Location'),
          'address_line2': place.subLocality ?? '',
          'city': place.locality ?? place.subAdministrativeArea ?? '',
          'state': place.administrativeArea ?? '',
          'pincode': place.postalCode ?? '',
          'country': place.country ?? '',
        };
      }

      // Fallback if geocoding fails.
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address_line1': 'Lat: ${position.latitude}, Lon: ${position.longitude}',
        'address_line2': '', 'city': '', 'state': '', 'pincode': '', 'country': '',
      };

    } on TimeoutException {
      Get.snackbar(
        'Location Timeout',
        'Could not get location in time. Please check your GPS signal and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get location. Please ensure GPS is enabled and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      print('Error in getCurrentLocation: $e');
      return null;
    }
  }
}
