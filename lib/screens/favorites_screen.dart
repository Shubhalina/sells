import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sells/services/product_service.dart';
import 'package:sells/screens/product_details.dart';
import 'dart:async';
import 'package:sells/services/favorites_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesService _favoritesService = FavoritesService();

  bool isLoading = false;
  bool hasError = false;
  String? errorMessage;
  List<Map<String, dynamic>> favoriteProducts = [];
  // ... keep other existing variables ...

  Future<void> _loadFavoriteProducts() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = null;
      });

      final response = await _favoritesService.getFavoriteProducts();
      
      if (mounted) {
        setState(() {
          favoriteProducts = response;
          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = error.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

 Future<void> _toggleFavorite(String productId) async {
  try {
    final isCurrentlyFavorite = favoriteProducts
        .any((product) => product['id'] == productId);

    await _favoritesService.toggleFavorite(productId, !isCurrentlyFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !isCurrentlyFavorite 
            ? 'Added to favorites!' 
            : 'Removed from favorites',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );

    await _loadFavoriteProducts();
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceAll('Exception: ', ''),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          productId: product['id'].toString(),
          title: product['product_title'] ?? '',
          price: (product['price'] ?? 0).toDouble(),
          image: product['product_image'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteProducts,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              if (errorMessage?.contains('sign in') ?? false)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('Sign In'),
                ),
              TextButton(
                onPressed: _loadFavoriteProducts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (favoriteProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              "No favorite products yet",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadFavoriteProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorites updated'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = favoriteProducts[index];
          final images = _getProductImages(product);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _navigateToProductDetails(product),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: images.isNotEmpty
                          ? Image.network(
                              images[0],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product_title'] ?? 'No title',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${product['price']?.toString() ?? '0'}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        favoriteProducts.any((p) => p['id'] == product['id'])
                          ? Icons.favorite
                          : Icons.favorite_border,
                        color: Colors.red,
                        key: ValueKey(favoriteProducts.any((p) => p['id'] == product['id'])),
                      ),
                    ),
                    onPressed: () => _toggleFavorite(product['id'].toString()),
                  )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getProductImages(Map<String, dynamic> product) {
    List<String> images = [];
    
    if (product['image_urls'] != null && product['image_urls'] is List) {
      images = List<String>.from(product['image_urls']);
    }
    
    if (images.isEmpty && product['product_image'] != null) {
      images = [product['product_image'].toString()];
    }
    
    return images;
  }
}