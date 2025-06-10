import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sells/screens/AddProductPage.dart';
import 'package:sells/screens/product_details.dart';
import 'package:sells/screens/UserProfilePage.dart';
import 'package:sells/services/product_service.dart';
import 'package:sells/screens/history_screen.dart';
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
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  String selectedCategory = 'All';
  bool isLoading = true;
  String _searchQuery = '';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();

  // Single stream subscription
  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeProductsStream();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _productsSubscription?.cancel();
    _productService.dispose();
    super.dispose();
  }

  void _initializeProductsStream() {
    setState(() {
      isLoading = true;
    });

    _productsSubscription?.cancel();

    _productsSubscription = _productService.getProductsStream(
      category: selectedCategory == 'All' ? null : selectedCategory,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    ).listen(
      (products) {
        if (mounted) {
          setState(() {
            allProducts = products;
            filteredProducts = _filterProducts(products);
            isLoading = false;
          });
          
          if (!_fadeController.isCompleted) {
            _fadeController.forward();
            _slideController.forward();
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading products: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
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
  }

  void _showHistoryPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HistoryPage(),
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

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final price = product['price'] != null
        ? (product['price'] is num
            ? product['price']
            : double.tryParse(product['price'].toString()) ?? 0)
        : 0;

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
                          image: product['product_image'] ?? '',
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
                              child: Image.network(
                                product['product_image'] ?? '',
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
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.favorite_border_rounded,
                                size: 20,
                                color: Colors.grey.shade700,
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
          // History Button
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
              onTap: _showHistoryPage,
              child: const Icon(
                Icons.history_rounded,
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
