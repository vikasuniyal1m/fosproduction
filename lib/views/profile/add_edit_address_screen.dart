import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';

/// Add/Edit Address Screen
/// Allows user to add or edit shipping address
class AddEditAddressScreen extends GetView<ProfileController> {
  final Map<String, dynamic>? address;
  
  const AddEditAddressScreen({super.key, this.address});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    // Check if should use current location
    final args = Get.arguments as Map<String, dynamic>?;
    final useCurrentLocation = args?['use_current_location'] == true;
    
    // Initialize form if editing
    if (address != null) {
      controller.initializeAddressForm(address!);
    } else if (useCurrentLocation) {
      // Show current location option
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.detectCurrentLocation();
      });
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          address == null ? 'Add Address' : 'Edit Address',
          style: TextStyle(fontSize: ScreenSize.headingSmall),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        toolbarHeight: ScreenSize.buttonHeightMedium,
      ),
      body: Obx(() => controller.isSavingAddress.value
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: EdgeInsets.all(ScreenSize.spacingMedium),
              child: Form(
                key: controller.addressFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Address Type
                    DropdownButtonFormField<String>(
                      initialValue: controller.addressTypeController.text.isEmpty
                          ? 'home'
                          : controller.addressTypeController.text,
                      decoration: InputDecoration(
                        labelText: 'Address Type',
                        labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary, size: ScreenSize.iconSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(value: 'home', child: Text('Home', style: TextStyle(fontSize: ScreenSize.textSmall))),
                        DropdownMenuItem(value: 'work', child: Text('Work', style: TextStyle(fontSize: ScreenSize.textSmall))),
                        DropdownMenuItem(value: 'other', child: Text('Other', style: TextStyle(fontSize: ScreenSize.textSmall))),
                      ],
                      onChanged: (value) {
                        controller.addressTypeController.text = value ?? 'home';
                      },
                      style: TextStyle(fontSize: ScreenSize.textSmall, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Current Location Button (only when adding new address)
                    if (address == null)
                      OutlinedButton.icon(
                        onPressed: () => controller.detectCurrentLocation(),
                        icon: Icon(Icons.my_location, color: AppColors.primary, size: ScreenSize.iconSmall),
                        label: Text(
                          'Use Current Location',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: ScreenSize.textSmall,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                          ),
                        ),
                      ),
                    if (address == null) SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Full Name
                    TextFormField(
                      controller: controller.addressNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        hintText: 'Enter recipient name',
                        hintStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary, size: ScreenSize.iconSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Phone
                    TextFormField(
                      controller: controller.addressPhoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        hintText: 'Enter phone number',
                        hintStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary, size: ScreenSize.iconSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Address Line 1
                    TextFormField(
                      controller: controller.addressLine1Controller,
                      decoration: InputDecoration(
                        labelText: 'Address Line 1',
                        labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        hintText: 'Street address, P.O. box',
                        hintStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        prefixIcon: Icon(Icons.home_outlined, color: AppColors.primary, size: ScreenSize.iconSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Address Line 2
                    TextFormField(
                      controller: controller.addressLine2Controller,
                      decoration: InputDecoration(
                        labelText: 'Address Line 2 (Optional)',
                        labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        hintText: 'Apartment, suite, unit, building, floor, etc.',
                        hintStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        prefixIcon: Icon(Icons.business_outlined, color: AppColors.primary, size: ScreenSize.iconSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // City
                    TextFormField(
                      controller: controller.addressCityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        hintText: 'Enter city',
                        hintStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.primary, size: ScreenSize.iconSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),

                    // State
                    TextFormField(
                      controller: controller.addressStateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        hintText: 'Enter state',
                        hintStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        prefixIcon: Icon(Icons.map_outlined, color: AppColors.primary, size: ScreenSize.iconSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Pincode
                    TextFormField(
                      controller: controller.addressPincodeController,
                      decoration: InputDecoration(
                        labelText: 'Pincode',
                        labelStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        hintText: 'Enter pincode',
                        hintStyle: TextStyle(fontSize: ScreenSize.textSmall),
                        prefixIcon: Icon(Icons.pin_outlined, color: AppColors.primary, size: ScreenSize.iconSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pincode is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    
                    // Set as Default
                    Obx(() => CheckboxListTile(
                      title: Text(
                        'Set as default address',
                        style: TextStyle(fontSize: ScreenSize.textSmall),
                      ),
                      value: controller.isDefaultAddress.value,
                      onChanged: (value) {
                        controller.isDefaultAddress.value = value ?? false;
                      },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    )),
                    SizedBox(height: ScreenSize.spacingMedium),
                    
                    // Save Button
                    SizedBox(
                      height: ScreenSize.buttonHeightMedium,
                      child: ElevatedButton(
                        onPressed: () => controller.saveAddress(address != null ? address!['id'] as int? : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                          ),
                        ),
                        child: Text(
                          address == null ? 'Save Address' : 'Update Address',
                          style: TextStyle(
                            fontSize: ScreenSize.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
    );
  }
}

