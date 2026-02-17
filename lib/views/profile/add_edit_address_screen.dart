import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';

/// Add/Edit Address Screen
/// Allows user to add or edit shipping address.
/// Uses local TextEditingControllers so the form is not affected if ProfileController
/// is disposed when the route is popped (avoids "used after being disposed" crash).
class AddEditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _fromCheckout = false;
  late final TextEditingController _addressTypeController;
  late final TextEditingController _addressNameController;
  late final TextEditingController _addressPhoneController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _addressCityController;
  late final TextEditingController _addressStateController;
  late final TextEditingController _addressPincodeController;
  bool _isDefaultAddress = false;

  @override
  void initState() {
    super.initState();
    _addressTypeController = TextEditingController(text: 'home');
    _addressNameController = TextEditingController();
    _addressPhoneController = TextEditingController();
    _addressLine1Controller = TextEditingController();
    _addressLine2Controller = TextEditingController();
    _addressCityController = TextEditingController();
    _addressStateController = TextEditingController();
    _addressPincodeController = TextEditingController();

    if (widget.address != null) {
      _initializeFromAddress(widget.address!);
    }

    final args = Get.arguments as Map<String, dynamic>?;
    _fromCheckout = args?['from_checkout'] == true;
    final useCurrentLocation = args?['use_current_location'] == true;
    if (useCurrentLocation && widget.address == null && Get.isRegistered<ProfileController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<ProfileController>().detectCurrentLocation(
          onLocationDetected: (data) {
            if (data != null && mounted) {
              setState(() {
                _addressLine1Controller.text = data['address_line1'] ?? '';
                _addressLine2Controller.text = data['address_line2'] ?? '';
                _addressCityController.text = data['city'] ?? '';
                _addressStateController.text = data['state'] ?? '';
                _addressPincodeController.text = data['pincode'] ?? '';
              });
            }
          },
        );
      });
    }
  }

  void _initializeFromAddress(Map<String, dynamic> address) {
    _addressTypeController.text = address['type'] ?? 'home';
    _addressNameController.text = address['name'] ?? '';
    _addressPhoneController.text = address['phone'] ?? '';
    _addressLine1Controller.text = address['address_line1'] ?? '';
    _addressLine2Controller.text = address['address_line2'] ?? '';
    _addressCityController.text = address['city'] ?? '';
    _addressStateController.text = address['state'] ?? '';
    _addressPincodeController.text = address['pincode'] ?? '';
    _isDefaultAddress = address['is_default'] == true || address['is_default'] == 1;
  }

  @override
  void dispose() {
    _addressTypeController.dispose();
    _addressNameController.dispose();
    _addressPhoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _addressCityController.dispose();
    _addressStateController.dispose();
    _addressPincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);

    if (!Get.isRegistered<ProfileController>()) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.address == null ? 'Add Address' : 'Edit Address',
            style: TextStyle(fontSize: ScreenSize.headingSmall),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          toolbarHeight: ScreenSize.buttonHeightMedium,
        ),
        body: const Center(child: Text('Saving...')),
      );
    }

    final controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.address == null ? 'Add Address' : 'Edit Address',
          style: TextStyle(fontSize: ScreenSize.headingSmall),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        toolbarHeight: ScreenSize.buttonHeightMedium,
      ),
      body: Obx(() => (controller.isSavingAddress.value || controller.isDetectingLocation.value)
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: EdgeInsets.all(ScreenSize.spacingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _addressTypeController.text.isEmpty ? 'home' : _addressTypeController.text,
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
                        setState(() => _addressTypeController.text = value ?? 'home');
                      },
                      style: TextStyle(fontSize: ScreenSize.textSmall, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    if (widget.address == null)
                      OutlinedButton.icon(
                        onPressed: () => controller.detectCurrentLocation(
                          onLocationDetected: (data) {
                            if (data != null && mounted) {
                              setState(() {
                                _addressLine1Controller.text = data['address_line1'] ?? '';
                                _addressLine2Controller.text = data['address_line2'] ?? '';
                                _addressCityController.text = data['city'] ?? '';
                                _addressStateController.text = data['state'] ?? '';
                                _addressPincodeController.text = data['pincode'] ?? '';
                              });
                            }
                          },
                        ),
                        icon: Icon(Icons.my_location, color: AppColors.primary, size: ScreenSize.iconSmall),
                        label: Text(
                          'Use Current Location',
                          style: TextStyle(color: AppColors.primary, fontSize: ScreenSize.textSmall),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                          ),
                        ),
                      ),
                    if (widget.address == null) SizedBox(height: ScreenSize.spacingSmall),
                    TextFormField(
                      controller: _addressNameController,
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
                        if (value == null || value.trim().isEmpty) return 'Name is required';
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    TextFormField(
                      controller: _addressPhoneController,
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
                        if (value == null || value.trim().isEmpty) return 'Phone number is required';
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    TextFormField(
                      controller: _addressLine1Controller,
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
                        if (value == null || value.trim().isEmpty) return 'Address is required';
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    TextFormField(
                      controller: _addressLine2Controller,
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
                    TextFormField(
                      controller: _addressCityController,
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
                        if (value == null || value.trim().isEmpty) return 'City is required';
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    TextFormField(
                      controller: _addressStateController,
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
                        if (value == null || value.trim().isEmpty) return 'State is required';
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    TextFormField(
                      controller: _addressPincodeController,
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
                        if (value == null || value.trim().isEmpty) return 'Pincode is required';
                        return null;
                      },
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    CheckboxListTile(
                      title: Text('Set as default address', style: TextStyle(fontSize: ScreenSize.textSmall)),
                      value: _isDefaultAddress,
                      onChanged: (value) => setState(() => _isDefaultAddress = value ?? false),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    SizedBox(height: ScreenSize.spacingMedium),
                    SizedBox(
                      height: ScreenSize.buttonHeightMedium,
                      child: ElevatedButton(
                        onPressed: () => _saveAddress(controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                          ),
                        ),
                        child: Text(
                          widget.address == null ? 'Save Address' : 'Update Address',
                          style: TextStyle(fontSize: ScreenSize.textMedium, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
    );
  }

  void _saveAddress(ProfileController controller) {
    if (!_formKey.currentState!.validate()) return;
    final addressData = {
      'name': _addressNameController.text.trim(),
      'phone': _addressPhoneController.text.trim(),
      'address_line1': _addressLine1Controller.text.trim(),
      'address_line2': _addressLine2Controller.text.trim(),
      'city': _addressCityController.text.trim(),
      'state': _addressStateController.text.trim(),
      'pincode': _addressPincodeController.text.trim(),
      'type': _addressTypeController.text,
      'is_default': _isDefaultAddress,
    };
    controller.saveAddressWithData(
      widget.address != null ? widget.address!['id'] as int? : null,
      addressData,
      fromCheckout: _fromCheckout,
    );
  }
}
