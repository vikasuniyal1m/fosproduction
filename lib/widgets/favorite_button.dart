import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../utils/app_colors.dart';
import '../utils/getx_registry.dart';
import '../utils/screen_size.dart';

/// Instant wishlist heart — reads [WishlistController.wishlistItems] via Obx.
class FavoriteButton extends StatelessWidget {
  final dynamic productId;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.productId,
    this.onToggle,
  });

  int? get _id {
    if (productId is int) return productId as int;
    return int.tryParse(productId?.toString() ?? '');
  }

  static bool _containsId(List<Map<String, dynamic>> items, int id) {
    return items.any((item) {
      final itemId = item['id'];
      if (itemId is int) return itemId == id;
      return int.tryParse(itemId?.toString() ?? '') == id;
    });
  }

  void _handleTap(int id) {
    if (onToggle != null) {
      onToggle!();
      return;
    }
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().toggleFavorite(id);
    } else {
      GetXRegistry.wishlist().toggleWishlist(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _id;
    if (id == null) return const SizedBox.shrink();

    return Obx(() {
      final items = GetXRegistry.wishlist().wishlistItems;
      final isFav = _containsId(items, id);
      return _buildIcon(isFav: isFav, id: id);
    });
  }

  Widget _buildIcon({required bool isFav, required int id}) {
    return IconButton(
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? Colors.green : Colors.black.withOpacity(0.5),
        size: ScreenSize.iconSmall,
      ),
      onPressed: () => _handleTap(id),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.textWhite.withOpacity(0.7),
        side: const BorderSide(color: Colors.green, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(4),
        minimumSize: const Size(28, 28),
      ),
    );
  }
}
