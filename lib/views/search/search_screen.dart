import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/search_controller.dart' as search_ctrl;
import '../../widgets/loading_widget.dart';

/// Search Screen
/// Modern product search functionality with beautiful UI
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  late search_ctrl.SearchController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = Get.put(search_ctrl.SearchController());
    _searchController = TextEditingController(text: _controller.searchQuery.value);
    _searchController.addListener(_onSearchChanged);
  }
  
  void _onSearchChanged() {
    _controller.setSearchQuery(_searchController.text);
    if (_searchController.text.trim().isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_controller.searchQuery.value == _searchController.text) {
          _controller.searchProducts();
        }
      });
    } else {
      _controller.searchResults.clear();
    }
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (_controller.searchQuery.value.isEmpty && _controller.searchResults.isEmpty) {
          return _buildInitialState();
        }
        
        if (_controller.isLoading.value && _controller.searchResults.isEmpty) {
          return const LoadingWidget();
        }
        
        if (_controller.searchResults.isEmpty) {
          return _buildEmptyState();
        }
        
        return _buildSearchResults();
      }),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: _buildSearchBar(),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.border.withOpacity(0.3),
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _controller.searchProducts();
          }
        },
        decoration: InputDecoration(
          hintText: 'Search for products, brands...',
          hintStyle: TextStyle(
            color: AppColors.textTertiary,
            fontSize: ScreenSize.textMedium,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          suffixIcon: Obx(() => _controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _controller.clearSearch();
                  },
                )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: TextStyle(
          fontSize: ScreenSize.textMedium,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
  
  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ScreenSize.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ScreenSize.spacingLarge),
          
          // Welcome Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you looking for?',
                style: TextStyle(
                  fontSize: ScreenSize.headingLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: ScreenSize.spacingSmall),
              Text(
                'Discover amazing products',
                style: TextStyle(
                  fontSize: ScreenSize.textMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: ScreenSize.sectionSpacing),
          
          // Recent Searches
          if (_controller.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: ScreenSize.spacingSmall),
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: ScreenSize.headingSmall,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _controller.clearRecentSearches,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: ScreenSize.textSmall,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            Wrap(
              spacing: ScreenSize.spacingSmall,
              runSpacing: ScreenSize.spacingSmall,
              children: _controller.recentSearches.map((search) {
                return _buildSearchChip(
                  search,
                  Icons.history_rounded,
                  AppColors.backgroundGrey,
                  () {
                    _searchController.text = search;
                    _controller.searchProducts();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: ScreenSize.sectionSpacing),
          ],
          
          // Popular Searches
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: ScreenSize.spacingSmall),
              Text(
                'Trending Searches',
                style: TextStyle(
                  fontSize: ScreenSize.headingSmall,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          Wrap(
            spacing: ScreenSize.spacingSmall,
            runSpacing: ScreenSize.spacingSmall,
            children: _controller.popularSearches.map((search) {
              return _buildSearchChip(
                search,
                Icons.local_fire_department_rounded,
                AppColors.primary.withOpacity(0.1),
                () {
                  _searchController.text = search;
                  _controller.searchProducts();
                },
                isPopular: true,
              );
            }).toList(),
          ),
          
          SizedBox(height: ScreenSize.sectionSpacing),
          
          // Quick Categories
          Text(
            'Browse Categories',
            style: TextStyle(
              fontSize: ScreenSize.headingSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingMedium),
          _buildCategoryGrid(),
        ],
      ),
    );
  }
  
  Widget _buildSearchChip(
    String text,
    IconData icon,
    Color backgroundColor,
    VoidCallback onTap, {
    bool isPopular = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenSize.spacingMedium,
            vertical: ScreenSize.spacingSmall + 2,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            border: isPopular
                ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPopular ? AppColors.primary : AppColors.textSecondary,
              ),
              SizedBox(width: ScreenSize.spacingExtraSmall),
              Text(
                text,
                style: TextStyle(
                  fontSize: ScreenSize.textSmall,
                  color: isPopular ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isPopular ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryGrid() {
    return Obx(() {
      if (_controller.categories.isEmpty) {
        return Container(
          padding: EdgeInsets.all(ScreenSize.spacingLarge),
          child: Center(
            child: Text(
              'No categories available',
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }
      
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _controller.categories.length,
        itemBuilder: (context, index) {
          final category = _controller.categories[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to category products screen
                final categoryId = category['id'] as int;
                final categoryName = category['name'] as String;
                Get.toNamed(
                  '/category-products',
                  arguments: {
                    'categoryId': categoryId,
                    'categoryName': categoryName,
                  },
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (category['color'] as Color).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 32,
                      color: category['color'] as Color,
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ScreenSize.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: ScreenSize.headingLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              'We couldn\'t find any products matching your search',
              style: TextStyle(
                fontSize: ScreenSize.textMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _controller.clearSearch();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.spacingLarge,
                  vertical: ScreenSize.spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResults() {
    return RefreshIndicator(
      onRefresh: () => _controller.searchProducts(),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // Results Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ScreenSize.paddingMedium,
                vertical: ScreenSize.spacingMedium,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_controller.searchResults.length} results',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Get.snackbar('Info', 'Filters coming soon');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ScreenSize.spacingMedium,
                          vertical: ScreenSize.spacingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: ScreenSize.spacingExtraSmall),
                            Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Products Grid
          SliverPadding(
            padding: EdgeInsets.all(ScreenSize.paddingMedium),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ScreenSize.gridCrossAxisCount,
                crossAxisSpacing: ScreenSize.gridSpacing,
                mainAxisSpacing: ScreenSize.gridSpacing,
                childAspectRatio: ScreenSize.productCardAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _controller.searchResults.length) {
                    if (_controller.hasMore.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  
                  final product = _controller.searchResults[index];
                  return _buildProductCard(product);
                },
                childCount: _controller.searchResults.length + (_controller.hasMore.value ? 1 : 0),
              ),
            ),
          ),
          
          // Load more trigger
          if (_controller.hasMore.value)
            SliverToBoxAdapter(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                    if (!_controller.isLoading.value) {
                      _controller.loadMore();
                    }
                  }
                  return false;
                },
                child: const SizedBox(height: 100),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildProductCard(Map<String, dynamic> product) {
    final regularPrice = product['price'] ?? 0.0;
    final salePrice = product['sale_price'];
    final displayPrice = salePrice ?? regularPrice;
    final hasDiscount = salePrice != null && regularPrice > salePrice;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _controller.navigateToProductDetails(product['id']),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildProductImage(product),
                    ),
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Obx(() {
                        // Find current product in search results to get updated favorite status
                        final currentProduct = _controller.searchResults.firstWhere(
                          (p) => p['id'] == product['id'],
                          orElse: () => product,
                        );
                        final isFavorite = currentProduct['isFavorite'] == true;
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _controller.toggleFavorite(product['id']),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.textWhite.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    // Discount badge
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${((regularPrice - salePrice) / regularPrice * 100).toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Product Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(ScreenSize.spacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category
                      if (product['category'] != null && product['category']['name'] != null)
                        Text(
                          product['category']['name'],
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // Product Name
                      Text(
                        product['name'] ?? '',
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${product['rating'] ?? 0.0}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '(${product['review_count'] ?? 0})',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      
                      // Price
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${displayPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: ScreenSize.textSmall,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (hasDiscount) ...[
                            SizedBox(width: 4),
                            Text(
                              '\$${regularPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textTertiary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrl = product['image'];
    final imageHeight = ScreenSize.productCardImageHeight;
    
    if (imageUrl != null && imageUrl is String && imageUrl.isNotEmpty) {
      final cleanUrl = imageUrl.replaceAll('\\/', '/').trim();
      
      return CachedNetworkImage(
        imageUrl: cleanUrl,
        width: double.infinity,
        height: imageHeight,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: imageHeight,
          color: AppColors.backgroundGrey,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: imageHeight,
          color: AppColors.backgroundGrey,
          child: Icon(
            Icons.image_not_supported_rounded,
            color: AppColors.textTertiary,
            size: 40,
          ),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: imageHeight,
      color: AppColors.backgroundGrey,
      child: Icon(
        Icons.image_rounded,
        color: AppColors.textTertiary,
        size: 40,
      ),
    );
  }
}
