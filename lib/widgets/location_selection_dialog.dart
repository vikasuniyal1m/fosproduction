import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';
import '../controllers/home_controller.dart';
import '../services/location_service.dart';
import '../routes/app_routes.dart';
import '../utils/cache_manager.dart';

/// Location Selection Dialog
/// Shows current location option and saved addresses
class LocationSelectionDialog extends StatelessWidget {
  final HomeController controller;
  
  const LocationSelectionDialog({
    super.key,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Dialog(
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadiusLarge),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingLarge : ScreenSize.spacingLarge)),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ScreenSize.tileBorderRadiusLarge),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: ScreenSize.screenWidth >= 1200 ? ScreenSize.iconLarge :
                             (ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : 
                              (ScreenSize.screenWidth >= 768 ? ScreenSize.iconMedium : ScreenSize.iconSmall)),
                    ),
                  ),
                  SizedBox(width: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
                  Expanded(
                    child: Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: ScreenSize.screenWidth >= 1200 ? ScreenSize.headingExtraLarge :
                               (ScreenSize.screenWidth >= 1000 ? ScreenSize.headingHuge : 
                                (ScreenSize.screenWidth >= 768 ? ScreenSize.headingMedium : ScreenSize.headingSmall)),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Current Location Option
                    _buildCurrentLocationOption(),
                    
                    // Divider
                    Divider(height: 1, thickness: 1),
                    
                    // Saved Addresses
                    _buildSavedAddressesSection(),
                  ],
                ),
              ),
            ),
            
            // Footer - Add New Address
            Container(
              padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (CacheManager.isLoggedIn()) {
                      Get.back();
                      AppRoutes.toAddAddress();
                    } else {
                      Get.snackbar(
                        'Login Required',
                        'Please login to add a new address.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  icon: Icon(
                    Icons.add_location_alt, 
                    color: AppColors.primary,
                    size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                  ),
                  label: Text(
                    'Add New Address',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium),
                      horizontal: ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingLarge : ScreenSize.spacingLarge),
                    ),
                    side: BorderSide(
                      color: AppColors.primary,
                      width: ScreenSize.screenWidth >= 1000 ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 12 : (ScreenSize.screenWidth >= 768 ? 10 : 8)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentLocationOption() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Request permission and detect location
          final locationService = LocationService();
          final permission = await locationService.requestLocationPermission();
          final isGranted = permission == LocationPermission.whileInUse || permission == LocationPermission.always;

          if (isGranted) {
            // Get current location
            Get.back(); // Close dialog first
            await controller.detectAndSetCurrentLocation();
          } else if (permission == LocationPermission.deniedForever) {
            // Show message to open settings
            Get.snackbar(
              'Permission Required',
              'Please enable location permission from app settings',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingLarge : ScreenSize.spacingLarge)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.my_location,
                  color: AppColors.primary,
                  size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                ),
              ),
              SizedBox(width: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use Current Location',
                      style: TextStyle(
                        fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingXSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingExtraSmall : ScreenSize.spacingExtraSmall)),
                    Text(
                      'Detect your location automatically',
                      style: TextStyle(
                        fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.iconSmall : ScreenSize.iconSmall),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSavedAddressesSection() {
    return Obx(() {
      if (controller.addresses.isEmpty) {
        return Container(
          padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingLarge : ScreenSize.spacingLarge)),
          child: Column(
            children: [
              Icon(
                Icons.location_off_outlined,
                size: ScreenSize.screenWidth >= 1000 ? 64 : (ScreenSize.screenWidth >= 768 ? 56 : 48),
                color: AppColors.textTertiary,
              ),
              SizedBox(height: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
              Text(
                'No saved addresses',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
              Text(
                'Add an address to get started',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
            child: Text(
              'Saved Addresses',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...controller.addresses.map((address) => _buildAddressItem(address)),
        ],
      );
    });
  }
  
  Widget _buildAddressItem(Map<String, dynamic> address) {
    final isSelected = controller.selectedLocation.value?['id'] == address['id'];
    final label = address['label'] ?? address['type'] ?? 'home';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final addressLine1 = address['address_line1'] ?? '';
    final isDefault = address['is_default'] == true;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectSavedAddress(address),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium),
            vertical: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall / 2 : ScreenSize.spacingSmall / 2),
          ),
          padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 16 : (ScreenSize.screenWidth >= 768 ? 14 : 12)),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primary
                  : AppColors.border.withOpacity(0.3),
              width: isSelected ? (ScreenSize.screenWidth >= 1000 ? 2.5 : 2) : (ScreenSize.screenWidth >= 1000 ? 1.5 : 1),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getAddressIcon(label.toString().toLowerCase()),
                  color: isSelected 
                      ? AppColors.textWhite
                      : AppColors.primary,
                  size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.iconSmall : ScreenSize.iconSmall),
                ),
              ),
              SizedBox(width: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium)),
              
              // Address Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label.toString().split(' ').map((word) => 
                            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
                          ).join(' '),
                          style: TextStyle(
                            fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isDefault) ...[
                          SizedBox(width: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall : ScreenSize.spacingSmall)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ScreenSize.screenWidth >= 1000 ? 8 : (ScreenSize.screenWidth >= 768 ? 6 : 6),
                              vertical: ScreenSize.screenWidth >= 1000 ? 4 : (ScreenSize.screenWidth >= 768 ? 2 : 2),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 6 : (ScreenSize.screenWidth >= 768 ? 4 : 4)),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall),
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingXSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingExtraSmall : ScreenSize.spacingExtraSmall)),
                    if (addressLine1.isNotEmpty)
                      Text(
                        addressLine1,
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (city.isNotEmpty || state.isNotEmpty)
                      Text(
                        [city, state].where((s) => s.isNotEmpty).join(', '),
                        style: TextStyle(
                          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Selected Indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.iconMedium : ScreenSize.iconMedium),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'office':
        return Icons.business;
      default:
        return Icons.location_on;
    }
  }
}
