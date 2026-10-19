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
        icon: Icon(Icons.arrow_back, 
                  size: ScreenSize.screenWidth >= 1000 ? ScreenSize.iconMedium : ScreenSize.iconMedium,
                  color: AppColors.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: _buildSearchBar(),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.border.withOpacity(0.3),
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      height: ScreenSize.screenWidth >= 1000 ? 52 : (ScreenSize.screenWidth >= 768 ? 48 : 45),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 26 : (ScreenSize.screenWidth >= 768 ? 24 : 25)),
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
          hintText: 'Search for products',
          hintStyle: TextStyle(
            color: AppColors.textTertiary,
            fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : ScreenSize.textMedium,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? 14.0 : 12.0),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: ScreenSize.screenWidth >= 1000 ? 24 : 22,
            ),
          ),
          suffixIcon: Obx(() => _controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                    size: ScreenSize.screenWidth >= 1000 ? 22 : 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _controller.clearSearch();
                  },
                )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: ScreenSize.screenWidth >= 1000 ? 18 : 16, 
            vertical: ScreenSize.screenWidth >= 1000 ? 14 : 12
          ),
        ),
        style: TextStyle(
          fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : ScreenSize.textMedium,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
  
  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.paddingMedium : ScreenSize.paddingMedium)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingLarge)),
          
          // Welcome Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you looking for?',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.headingExtraLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.headingLarge : ScreenSize.headingLarge),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: ScreenSize.spacingSmall),
              Text(
                'Discover amazing products',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: ScreenSize.screenWidth >= 1000 ? ScreenSize.sectionSpacing : (ScreenSize.screenWidth >= 768 ? ScreenSize.sectionSpacing : ScreenSize.sectionSpacing)),
          
          // Recent Searches
          if (_controller.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: ScreenSize.screenWidth >= 1000 ? 22 : (ScreenSize.screenWidth >= 768 ? 20 : 20),
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: ScreenSize.spacingSmall),
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.headingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.headingSmall : ScreenSize.headingSmall),
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
                      fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
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
                size: ScreenSize.screenWidth >= 1000 ? 22 : (ScreenSize.screenWidth >= 768 ? 20 : 20),
                color: AppColors.primary,
              ),
              SizedBox(width: ScreenSize.spacingSmall),
              Text(
                'Trending Searches',
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.headingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.headingSmall : ScreenSize.headingSmall),
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
              fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.headingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.headingSmall : ScreenSize.headingSmall),
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
        borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 26 : (ScreenSize.screenWidth >= 768 ? 24 : 25)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium),
            vertical: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingSmall + 4 : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingSmall + 3 : ScreenSize.spacingSmall + 2),
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 26 : (ScreenSize.screenWidth >= 768 ? 24 : 25)),
            border: isPopular
                ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ScreenSize.screenWidth >= 1000 ? 18 : (ScreenSize.screenWidth >= 768 ? 17 : 16),
                color: isPopular ? AppColors.primary : AppColors.textSecondary,
              ),
              SizedBox(width: ScreenSize.spacingExtraSmall),
              Text(
                text,
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
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
          padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingLarge)),
          child: Center(
            child: Text(
              'No categories available',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }
      
      // Responsive grid columns
      int crossAxisCount;
      double childAspectRatio;
      double crossAxisSpacing;
      double mainAxisSpacing;
      
      if (ScreenSize.screenWidth >= 1000) {
        crossAxisCount = 6;
        childAspectRatio = 1.0;
        crossAxisSpacing = 16;
        mainAxisSpacing = 16;
      } else if (ScreenSize.screenWidth >= 768) {
        crossAxisCount = 4;
        childAspectRatio = 1.05;
        crossAxisSpacing = 14;
        mainAxisSpacing = 14;
      } else {
        crossAxisCount = 3;
        childAspectRatio = 1.1;
        crossAxisSpacing = 12;
        mainAxisSpacing = 12;
      }
      
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
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
              borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 18 : (ScreenSize.screenWidth >= 768 ? 17 : 16)),
              child: Container(
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 18 : (ScreenSize.screenWidth >= 768 ? 17 : 16)),
                  border: Border.all(
                    color: (category['color'] as Color).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: ScreenSize.screenWidth >= 1000 ? 36 : (ScreenSize.screenWidth >= 768 ? 34 : 32),
                      color: category['color'] as Color,
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textSmall : (ScreenSize.screenWidth >= 768 ? ScreenSize.textSmall : ScreenSize.textSmall),
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
        padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? ScreenSize.paddingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.paddingMedium : ScreenSize.paddingLarge)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ScreenSize.screenWidth >= 1000 ? 28 : (ScreenSize.screenWidth >= 768 ? 26 : 24)),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: ScreenSize.screenWidth >= 1000 ? 72 : (ScreenSize.screenWidth >= 768 ? 68 : 64),
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingLarge)),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.headingExtraLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.headingLarge : ScreenSize.headingLarge),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ScreenSize.spacingSmall),
            Text(
              'We couldn\'t find any products matching your search',
              style: TextStyle(
                fontSize: ScreenSize.screenWidth >= 1000 ? ScreenSize.textMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.textMedium : ScreenSize.textMedium),
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingLarge)),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _controller.clearSearch();
              },
              icon: Icon(Icons.refresh_rounded, size: ScreenSize.screenWidth >= 1000 ? 22 : 20),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingLarge : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingLarge),
                  vertical: ScreenSize.screenWidth >= 1000 ? ScreenSize.spacingMedium : (ScreenSize.screenWidth >= 768 ? ScreenSize.spacingMedium : ScreenSize.spacingMedium),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenSize.screenWidth >= 1000 ? 26 : (ScreenSize.screenWidth >= 768 ? 24 : 25)),
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
    final isDigital = product['is_digital'] == true || product['is_digital'] == 1;
    final mediaType = product['media_type']?.toString().toLowerCase();
    final isVideo = isDigital && mediaType == 'video';
    final isAudio = isDigital && mediaType == 'audio';
    
    // Debug print to check data
    print('SearchScreen Product Card - Product ID: ${product['id']}');
    print('SearchScreen Product Card - is_digital: ${product['is_digital']} (type: ${product['is_digital'].runtimeType})');
    print('SearchScreen Product Card - media_type: ${product['media_type']} (type: ${product['media_type'].runtimeType})');
    print('SearchScreen Product Card - isDigital: $isDigital, isVideo: $isVideo, isAudio: $isAudio');
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _controller.navigateToProductDetails(product['id'], preview: product),
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
                      child: isVideo
                          ? _buildVideoThumbnail(product)
                          : isAudio
                              ? _buildAudioThumbnail(product)
                              : _buildProductImage(product),
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
                  padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingSmall, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Category
                      if (product['category'] != null && product['category']['name'] != null)
                        Text(
                          product['category']['name'],
                          style: TextStyle(
                            fontSize: 8,
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
                          fontSize: ScreenSize.textExtraSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.1,
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
                            size: 10,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${product['rating'] ?? 0.0}',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '(${product['review_count'] ?? 0})',
                            style: TextStyle(
                              fontSize: 7,
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
                              fontSize: ScreenSize.textExtraSmall,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (hasDiscount) ...[
                            SizedBox(width: 4),
                            Text(
                              '\$${regularPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 7,
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

  /// Build video thumbnail for video products
  Widget _buildVideoThumbnail(Map<String, dynamic> product) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video placeholder with play icon
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Icon(
              Icons.play_circle_outline,
              size: 32,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          // Play button overlay
          Positioned(
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          // Video label
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 10, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build audio thumbnail for audio products
  Widget _buildAudioThumbnail(Map<String, dynamic> product) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.blue.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Audio icon
          Icon(
            Icons.audiotrack,
            size: 32,
            color: Colors.white.withOpacity(0.8),
          ),
          // Play button overlay
          Positioned(
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                size: 16,
                color: Colors.blue,
              ),
            ),
          ),
          // Audio label
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.audiotrack, size: 10, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Audio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
