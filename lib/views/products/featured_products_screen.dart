// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../utils/screen_size.dart';
// import '../../utils/app_colors.dart';
// import '../../controllers/home_controller.dart';
// import '../../widgets/loading_widget.dart';
//
// /// Featured Products Screen
// /// Shows all featured products in a grid layout
// class FeaturedProductsScreen extends StatelessWidget {
//   const FeaturedProductsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     ScreenSize.init(context);
//
//     // Get arguments from navigation
//     final args = Get.arguments as Map<String, dynamic>? ?? {};
//     final title = args['title'] as String? ?? 'Featured Products';
//     final products = args['products'] as List<Map<String, dynamic>>? ?? [];
//
//     // Initialize controller
//     final homeController = Get.put(HomeController());
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: Text(
//           title,
//           style: TextStyle(
//             fontSize: ScreenSize.headingMedium,
//             fontWeight: FontWeight.bold,
//             color: AppColors.textWhite,
//           ),
//         ),
//         backgroundColor: AppColors.primary,
//         foregroundColor: AppColors.textWhite,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(
//             Icons.arrow_back,
//             size: ScreenSize.iconMedium,
//             color: AppColors.textWhite,
//           ),
//           onPressed: () => Get.back(),
//         ),
//         actions: [
//           // Sort button
//           IconButton(
//             icon: Icon(
//               Icons.sort,
//               size: ScreenSize.iconMedium,
//               color: AppColors.textWhite,
//             ),
//             onPressed: () => homeController.showSortDialog(),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         if (homeController.isLoading.value && products.isEmpty) {
//           return const LoadingWidget();
//         }
//
//         // Use passed products or controller's featured products
//         final featuredProducts = products.isNotEmpty
//             ? products.obs
//             : homeController.featuredProducts;
//
//         if (featuredProducts.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.star_outline,
//                   size: ScreenSize.iconExtraLarge * 2,
//                   color: AppColors.textTertiary,
//                 ),
//                 SizedBox(height: ScreenSize.spacingLarge),
//                 Text(
//                   'No featured products available',
//                   style: TextStyle(
//                     fontSize: ScreenSize.headingMedium,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 SizedBox(height: ScreenSize.spacingSmall),
//                 Text(
//                   'Check back later for amazing deals',
//                   style: TextStyle(
//                     fontSize: ScreenSize.textMedium,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         return Column(
//           children: [
//             // Products count and filter info
//             Container(
//               padding: EdgeInsets.all(ScreenSize.paddingMedium),
//               child: Row(
//                 children: [
//                   Text(
//                     '${featuredProducts.length} Products',
//                     style: TextStyle(
//                       fontSize: ScreenSize.textMedium,
//                       color: AppColors.textSecondary,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const Spacer(),
//                   // Filter indicator
//                   if (homeController.featuredSortBy.value != 'default')
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: ScreenSize.spacingSmall,
//                         vertical: ScreenSize.spacingTiny,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.primary.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
//                       ),
//                       child: Text(
//                         homeController.featuredSortBy.value.toUpperCase(),
//                         style: TextStyle(
//                           fontSize: ScreenSize.textSmall,
//                           color: AppColors.primary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//             // Products grid
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: ScreenSize.paddingMedium),
//                 child: GridView.builder(
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: ScreenSize.gridCrossAxisCount,
//                     crossAxisSpacing: ScreenSize.gridSpacing,
//                     mainAxisSpacing: ScreenSize.gridSpacing,
//                     childAspectRatio: ScreenSize.productCardAspectRatio,
//                   ),
//                   itemCount: featuredProducts.length,
//                   itemBuilder: (context, index) {
//                     final product = featuredProducts[index];
//                     return _buildFeaturedProductCard(homeController, product);
//                   },
//                 ),
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }
//
//   /// Build featured product card with special styling
//   Widget _buildFeaturedProductCard(HomeController controller, Map<String, dynamic> product) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.cardBackground,
//         borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
//         border: Border.all(
//           color: AppColors.primary.withOpacity(0.2),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           // Featured badge
//           Positioned(
//             top: ScreenSize.spacingSmall,
//             left: ScreenSize.spacingSmall,
//             child: Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: ScreenSize.spacingSmall,
//                 vertical: ScreenSize.spacingTiny,
//               ),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppColors.primary,
//                     AppColors.accent,
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(ScreenSize.buttonBorderRadius),
//               ),
//               child: Text(
//                 '⭐ FEATURED',
//                 style: TextStyle(
//                   fontSize: ScreenSize.textExtraSmall,
//                   color: AppColors.textWhite,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ),
//           ),
//
//           // Product content
//           Padding(
//             padding: EdgeInsets.all(ScreenSize.paddingSmall),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Product image
//                 Container(
//                   height: ScreenSize.productCardHorizontalImageHeight,
//                   width: double.infinity,
//                   margin: EdgeInsets.only(top: ScreenSize.spacingMedium),
//                   decoration: BoxDecoration(
//                     color: AppColors.backgroundGrey,
//                     borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(ScreenSize.tileBorderRadius),
//                     child: Image.network(
//                       product['image']?.toString() ?? '',
//                       fit: BoxFit.cover,
//                       height: ScreenSize.productCardHorizontalImageHeight,
//                       errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             color: AppColors.backgroundGrey,
//                             child: Icon(
//                               Icons.image_not_supported,
//                               size: ScreenSize.iconLarge,
//                               color: AppColors.textTertiary,
//                             ),
//                           );
//                         },
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: ScreenSize.spacingSmall),
//
//                 // Product info
//                 Expanded(
//                   flex: 2,
//                   child: Flexible(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                       // Product name
//                       Text(
//                         product['name']?.toString() ?? '',
//                         style: TextStyle(
//                           fontSize: ScreenSize.textSmall,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.textPrimary,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//
//                       SizedBox(height: ScreenSize.spacingTiny),
//
//                       // Price
//                       if (product['sale_price'] != null && product['sale_price'] > 0)
//                         Row(
//                           children: [
//                             Text(
//                               '\$${product['sale_price']?.toStringAsFixed(2) ?? '0.00'}',
//                               style: TextStyle(
//                                 fontSize: ScreenSize.textMedium,
//                                 fontWeight: FontWeight.bold,
//                                 color: AppColors.primary,
//                               ),
//                             ),
//                             SizedBox(width: ScreenSize.spacingExtraSmall),
//                             Text(
//                               '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
//                               style: TextStyle(
//                                 fontSize: ScreenSize.textSmall,
//                                 color: AppColors.textTertiary,
//                                 decoration: TextDecoration.lineThrough,
//                               ),
//                             ),
//                           ],
//                         )
//                       else
//                         Text(
//                           '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
//                           style: TextStyle(
//                             fontSize: ScreenSize.textMedium,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.primary,
//                           ),
//                         ),
//
//                       SizedBox(height: ScreenSize.spacingTiny),
//
//                       // Rating
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.star,
//                             size: ScreenSize.iconSmall,
//                             color: AppColors.accent,
//                           ),
//                           SizedBox(width: ScreenSize.spacingExtraSmall),
//                           Text(
//                             '${(product['rating'] ?? 0.0).toStringAsFixed(1)}',
//                             style: TextStyle(
//                               fontSize: ScreenSize.textSmall,
//                               color: AppColors.textSecondary,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Wishlist button
//           Positioned(
//             top: ScreenSize.spacingSmall,
//             right: ScreenSize.spacingSmall,
//             child: GestureDetector(
//               onTap: () => controller.toggleFavorite(product['id']),
//               child: Container(
//                 padding: EdgeInsets.all(4),
//                 decoration: BoxDecoration(
//                   color: AppColors.textWhite.withOpacity(0.7),
//                   border: Border.all(color: Colors.green, width: 1.0),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   product['isFavorite'] == true ? Icons.favorite : Icons.favorite_border,
//                   color: product['isFavorite'] == true ? Colors.green : Colors.black.withOpacity(0.5),
//                   size: ScreenSize.iconSmall,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
