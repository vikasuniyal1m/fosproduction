import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/loading_widget.dart';

/// Addresses Screen
/// Manages user shipping addresses
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(ProfileController());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Addresses',
          style: TextStyle(fontSize: ScreenSize.headingSmall),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: ScreenSize.buttonHeightMedium,
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: ScreenSize.iconSmall),
            onPressed: controller.navigateToAddAddress,
            tooltip: 'Add New Address',
          ),
        ],
      ),
      body: Obx(() => controller.isLoadingAddresses.value
          ? const LoadingWidget()
          : controller.addresses.isEmpty
              ? _buildEmptyState(controller)
              : RefreshIndicator(
                  onRefresh: controller.loadAddresses,
                  child: ListView.builder(
                    padding: EdgeInsets.all(ScreenSize.spacingMedium),
                    itemCount: controller.addresses.length,
                    itemBuilder: (context, index) {
                      final address = controller.addresses[index];
                      return _buildAddressCard(address, controller);
                    },
                  ),
                )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.navigateToAddAddress,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        icon: Icon(Icons.add, size: ScreenSize.iconSmall),
        label: Text(
          'Add Address',
          style: TextStyle(fontSize: ScreenSize.textSmall),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(ProfileController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: ScreenSize.iconExtraLarge * 1.5,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          Text(
            'No Addresses Yet',
            style: TextStyle(
              fontSize: ScreenSize.headingSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first address to get started',
            style: TextStyle(
              fontSize: ScreenSize.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingLarge),
          ElevatedButton(
            onPressed: controller.navigateToAddAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textWhite,
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: EdgeInsets.symmetric(
                horizontal: ScreenSize.spacingMedium,
                vertical: ScreenSize.spacingSmall,
              ),
            ),
            child: Text('Add Address', style: TextStyle(fontSize: ScreenSize.textSmall)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddressCard(Map<String, dynamic> address, ProfileController controller) {
    final isDefault = address['is_default'] == true || address['is_default'] == 1;
    
    return Container(
      margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSize.spacingMedium,
              vertical: ScreenSize.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: isDefault ? AppColors.primaryLight.withValues(alpha: 0.1) : AppColors.backgroundGrey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ScreenSize.tileBorderRadius),
                topRight: Radius.circular(ScreenSize.tileBorderRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  address['type'] == 'home' 
                      ? Icons.home
                      : address['type'] == 'work'
                          ? Icons.work
                          : Icons.location_on,
                  color: isDefault ? AppColors.primary : AppColors.textSecondary,
                  size: ScreenSize.iconSmall,
                ),
                SizedBox(width: ScreenSize.spacingSmall),
                Expanded(
                  child: Text(
                    address['label'] ?? address['type'] ?? 'Address',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Address Details
          Padding(
            padding: EdgeInsets.all(ScreenSize.spacingSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['name'] ?? '',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  address['address_line1'] ?? '',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (address['address_line2'] != null && address['address_line2'].toString().isNotEmpty)
                  Text(
                    address['address_line2'],
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.textPrimary,
                    ),
                  ),
                Text(
                  '${address['city'] ?? ''}, ${address['state'] ?? ''} ${address['pincode'] ?? ''}',
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Phone: ${address['phone'] ?? ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.all(ScreenSize.spacingSmall),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.editAddress(address),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                      ),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.deleteAddress(address['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(fontSize: ScreenSize.textSmall),
                    ),
                  ),
                ),
                if (!isDefault)
                  SizedBox(width: 8),
                if (!isDefault)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.setDefaultAddress(address['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
                        ),
                      ),
                      child: Text(
                        'Set Default',
                        style: TextStyle(fontSize: ScreenSize.textSmall),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

