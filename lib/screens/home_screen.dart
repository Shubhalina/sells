import 'package:flutter/material.dart';
import 'package:sells/screens/favorites_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sells/screens/AddProductPage.dart';
import 'package:sells/screens/product_details.dart';
import 'package:sells/screens/UserProfilePage.dart';
import 'package:sells/services/product_service.dart';
import 'package:sells/services/favorites_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final categories = [
    'All',
    'Electronics',
    'Fashion',
    'Home',
    'Accessories',
    'Books',
  ];

  final categoryIcons = {
    'All': Icons.apps_rounded,
    'Electronics': Icons.electrical_services_rounded,
    'Fashion': Icons.checkroom_rounded,
    'Home': Icons.home_rounded,
    'Accessories': Icons.watch_rounded,
    'Books': Icons.menu_book_rounded,
  };

  final categoryColors = {
    'All': const Color(0xFF6C5CE7),
    'Electronics': const Color(0xFF00B894),
    'Fashion': const Color(0xFFE17055),
    'Home': const Color(0xFF0984E3),
    'Accessories': const Color(0xFFE84393),
    'Books': const Color(0xFFFD79A8),
  };

  final ProductService _productService = ProductService();
  final FavoritesService _favoritesService = FavoritesService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  Set<String> favoriteProductIds = {}; // Track favorite products
  String selectedCategory = 'All';
  bool isLoading = true;
  String _searchQuery = '';
  StreamSubscription? _favoritesSubscription;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();

  // Single stream subscription
  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;

  // Initializes the products stream and updates the product lists
  void _initializeProductsStream() {
    _productsSubscription?.cancel();
    _productsSubscription = _productService.getProductsStream().listen((products) {
      if (mounted) {
        setState(() {
          allProducts = products;
          filteredProducts = _filterProducts(products);
          isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  // Loads the favorite product IDs for the current user
  Future<void> _loadFavoriteProductIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        favoriteProductIds = {};
      });
      return;
    }
    final response = await _supabase.from('user_favorites').select();
if (response.error != null) {  // Some versions use error as a property
  print('Error: ${response.error!.message}');
  return;
}
// Process successful response
  favoriteProductIds = {
    for (var item in response.data) item['product_id'].toString()
  };
}

 @override
void initState() {
  super.initState();
  _initializeAnimations();
  _initializeProductsStream();
  _loadFavoriteProductIds();
  _searchController.addListener(_onSearchChanged);
  _setupFavoritesListener();
}

/// Initializes animation controllers and animations for fade and slide effects.
void _initializeAnimations() {
  _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeIn,
  );
  _slideAnimation = Tween<Offset>(
    begin: const Offset(0.5, 0),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ),
  );
  _fadeController.forward();
  _slideController.forward();
}

@override
void dispose() {
  _favoritesSubscription?.cancel();
  _fadeController.dispose();
  _slideController.dispose();
  _searchController.dispose();
  _productsSubscription?.cancel();
  _productService.dispose();
  super.dispose();
}

  void _setupFavoritesListener() {
  _supabase
      .channel('favorites_changes')
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',
          schema: 'public',
          table: 'user_favorites',
        ),
        (payload, [ref]) {
          if (mounted) {
            _loadFavoriteProductIds();
          }
        },
      )
      .subscribe();
}
// This is already in your code, just confirming it's correct
Future<void> _toggleFavorite(String productId) async {
  if (_supabase.auth.currentUser == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please sign in to add favorites'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  try {
    final isCurrentlyFavorite = favoriteProductIds.contains(productId);
    
    if (isCurrentlyFavorite) {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('product_id', productId);
      
      if (!mounted) return;
      setState(() {
        favoriteProductIds.remove(productId);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      await _supabase.from('user_favorites').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'product_id': productId,
      });
      
      if (!mounted) return;
      setState(() {
        favoriteProductIds.add(productId);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to favorites'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error updating favorite: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  List<Map<String, dynamic>> _filterProducts(List<Map<String, dynamic>> products) {
    List<Map<String, dynamic>> filtered = products;

    if (selectedCategory != 'All') {
      filtered = filtered.where((product) => 
        product['category']?.toString().toLowerCase() == selectedCategory.toLowerCase()
      ).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final title = product['product_title']?.toString().toLowerCase() ?? '';
        final description = product['description']?.toString().toLowerCase() ?? '';
        final category = product['category']?.toString().toLowerCase() ?? '';
        
        return title.contains(_searchQuery) || 
               description.contains(_searchQuery) || 
               category.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.toLowerCase();
    if (_searchQuery != newQuery) {
      setState(() {
        _searchQuery = newQuery;
        filteredProducts = _filterProducts(allProducts);
      });
    }
  }

  void _onCategoryChanged(String category) {
    if (selectedCategory != category) {
      setState(() {
        selectedCategory = category;
        filteredProducts = _filterProducts(allProducts);
      });
    }
  }

  Future<void> _refreshProducts() async {
    _initializeProductsStream();
    _loadFavoriteProductIds();
  }

  void _showFavoritesPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FavoritesPage(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    ).then((_) {
      // Refresh favorites when returning from favorites page
      _loadFavoriteProductIds();
    });
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search amazing products...",
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, int index) {
    final isSelected = selectedCategory == category;
    final color = categoryColors[category] ?? Colors.blue;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.5 * (index + 1), 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _slideController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
          child: GestureDetector(
            onTap: () => _onCategoryChanged(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? color.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: isSelected ? 6 : 3,
                    offset: Offset(0, isSelected ? 3 : 1),
                  ),
                ],
                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcons[category],
                    color: isSelected ? Colors.white : color,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to get image URLs from product
  List<String> _getProductImages(Map<String, dynamic> product) {
    List<String> images = [];
    
    // First try to get from image_urls array
    if (product['image_urls'] != null) {
      if (product['image_urls'] is List) {
        images = List<String>.from(product['image_urls']);
      }
    }
    
    // If no images in array, fall back to single product_image
    if (images.isEmpty && product['product_image'] != null && product['product_image'].toString().isNotEmpty) {
      images = [product['product_image'].toString()];
    }
    
    return images;
  }

  // Widget to build the image carousel/slider
  Widget _buildImageCarousel(List<String> images, int productIndex) {
    if (images.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade100,
            ],
          ),
        ),
        child: Icon(
          Icons.image_rounded,
          size: 60,
          color: Colors.grey.shade400,
        ),
      );
    }

    if (images.length == 1) {
      return Image.network(
        images[0],
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
              ],
            ),
          ),
          child: Icon(
            Icons.image_rounded,
            size: 60,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, imageIndex) {
        return Stack(
          children: [
            Image.network(
              images[imageIndex],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade100,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.image_rounded,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            // Image count indicator
            if (images.length > 1)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${imageIndex + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final price = product['price'] != null
        ? (product['price'] is num
            ? product['price']
            : double.tryParse(product['price'].toString()) ?? 0)
        : 0;

    final images = _getProductImages(product);
    final productId = product['id'].toString();
    final isFavorite = favoriteProductIds.contains(productId);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _fadeController,
              curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ProductDetailsPage(
                          productId: product['id'],
                          title: product['product_title'] ?? '',
                          price: price.toDouble(),
                          image: images.isNotEmpty ? images[0] : '',
                        ),
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: _buildImageCarousel(images, index),
                            ),
                          ),
                          // Multiple images indicator
                          if (images.length > 1)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${images.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Favorite button - NOW FUNCTIONAL
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _toggleFavorite(productId),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: isFavorite ? Colors.red : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['product_title'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B894).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "₹${price.toString()}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00B894),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (product['best_offer'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "Best Offer",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    UserProfileScreen(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/usericon.png'),
              backgroundColor: Colors.white,
            ),
          ),
        ),
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: _showFavoritesPage,
              child: const Icon(
                Icons.favorite_border_rounded,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
          // Notifications Button
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: Stack(
          children: [
            _buildGradientBackground(),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) =>
                          _buildCategoryChip(categories[index], index),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          "Featured Deals",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "See All",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                isLoading
                    ? const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      )
                    : filteredProducts.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No products found",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildProductCard(
                                    filteredProducts[index], index),
                                childCount: filteredProducts.length,
                              ),
                            ),
                          ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const AddProductPage(),
                transitionDuration: const Duration(milliseconds: 400),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}
