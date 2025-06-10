import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamController<List<Map<String, dynamic>>>? _productsController;
  RealtimeChannel? _channel;

  // Get all products with optional filtering - SHARED ACROSS ALL USERS
  Future<List<Map<String, dynamic>>> getAllProducts({
    String? category,
    String? searchQuery,
  }) async {
    try {
      // Get ALL products from ALL users - no user filtering
      var query = _supabase.from('products').select('*');
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);  
      }

      final response = await query.order('id', ascending: false);
      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        products = products.where((product) {
          final title = product['product_title']?.toString().toLowerCase() ?? '';
          final description = product['description']?.toString().toLowerCase() ?? '';
          final productCategory = product['category']?.toString().toLowerCase() ?? '';
          
          return title.contains(searchQuery.toLowerCase()) || 
                 description.contains(searchQuery.toLowerCase()) || 
                 productCategory.contains(searchQuery.toLowerCase());
        }).toList();
      }

      return products;
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get real-time stream of products - SHARED ACROSS ALL USERS
  Stream<List<Map<String, dynamic>>> getProductsStream({
    String? category,
    String? searchQuery,
  }) {
    // Close existing controller and channel
    _productsController?.close();
    _channel?.unsubscribe();

    _productsController = StreamController<List<Map<String, dynamic>>>.broadcast();

    // Initial data fetch
    _loadInitialData(category: category, searchQuery: searchQuery);

    // Set up real-time subscription with better error handling
    _setupRealtimeSubscription(category: category, searchQuery: searchQuery);

    return _productsController!.stream;
  }

  Future<void> _loadInitialData({String? category, String? searchQuery}) async {
    try {
      final products = await getAllProducts(
        category: category,
        searchQuery: searchQuery,
      );
      if (_productsController != null && !_productsController!.isClosed) {
        _productsController!.add(products);
      }
    } catch (e) {
      print('Error loading initial data: $e');
      if (_productsController != null && !_productsController!.isClosed) {
        _productsController!.addError(e);
      }
    }
  }

  void _setupRealtimeSubscription({String? category, String? searchQuery}) {
    try {
      _channel = _supabase
          .channel('products_${DateTime.now().millisecondsSinceEpoch}')
          .on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: '*',
              schema: 'public',
              table: 'products',
            ),
            (payload, [ref]) {
              print('Real-time update received: ${payload.eventType}');
              _handleRealtimeUpdate(
                payload,
                category: category,
                searchQuery: searchQuery,
              );
            },
          );
      
      // Subscribe to the channel separately
      _channel?.subscribe();
    } catch (e) {
      print('Error setting up real-time subscription: $e');
    }
  }

  Future<void> _handleRealtimeUpdate(
    dynamic payload, {
    String? category,
    String? searchQuery,
  }) async {
    try {
      print('Handling real-time update: ${payload.eventType}');
      
      // Add a small delay to ensure database consistency
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Refetch all products to ensure consistency
      final products = await getAllProducts(
        category: category,
        searchQuery: searchQuery,
      );
      
      if (_productsController != null && !_productsController!.isClosed) {
        _productsController!.add(products);
      }
    } catch (e) {
      print('Error handling real-time update: $e');
      if (_productsController != null && !_productsController!.isClosed) {
        _productsController!.addError(e);
      }
    }
  }

  // Add new product - will be visible to ALL users
  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    try {
      // Ensure the product data includes the current user's ID if needed
      // but product will still be visible to all users
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && !productData.containsKey('user_id')) {
        productData['user_id'] = currentUser.id;
      }

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select()
          .single();

      print('Product added successfully: ${response['id']}');
      
      // The real-time subscription will automatically update all connected clients
      return response;
    } catch (e) {
      print('Error adding product: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  // Get single product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('id', productId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Update product
  Future<Map<String, dynamic>> updateProduct(
    String productId, 
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('products')
          .update(updates)
          .eq('id', productId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get products by user (for user profile/management)
  Future<List<Map<String, dynamic>>> getProductsByUser(String userId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('user_id', userId)
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user products: $e');
    }
  }

  // Get categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('name')
          .order('name');

      return (response as List)
          .map((category) => category['name'] as String)
          .toList();
    } catch (e) {
      // If categories table doesn't exist, return default categories
      print('Categories table error: $e');
      return ['Electronics', 'Fashion', 'Home', 'Books', 'Sports', 'Other'];
    }
  }

  // Search products - ALL USERS
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .or('product_title.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get featured products (best offers) - ALL USERS
  Future<List<Map<String, dynamic>>> getFeaturedProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('best_offer', true)
          .order('id', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching featured products: $e');
      // Return regular products if best_offer column doesn't exist
      try {
        final fallbackResponse = await _supabase
            .from('products')
            .select('*')
            .order('id', ascending: false)
            .limit(10);
        return List<Map<String, dynamic>>.from(fallbackResponse);
      } catch (e2) {
        return [];
      }
    }
  }

  // Get products by category - ALL USERS
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('category', category)
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String productId, bool isFavorite) async {
    try {
      await _supabase
          .from('products')
          .update({'is_favorite': isFavorite})
          .eq('id', productId);
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Force refresh products (useful for manual refresh)
  void forceRefresh({String? category, String? searchQuery}) {
    _loadInitialData(category: category, searchQuery: searchQuery);
  }

  // Get latest products - ALL USERS
  Future<List<Map<String, dynamic>>> getLatestProducts({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .order('id', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch latest products: $e');
    }
  }

  // Get products count - ALL USERS
  Future<int> getProductsCount() async {
    try {
      final response = await _supabase
          .from('products')
          .select('id', const FetchOptions(
            head: true,
            count: CountOption.exact,
          ));
      
      return response.count ?? 0;
    } catch (e) {
      print('Error getting products count: $e');
      return 0;
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _productsController?.close();
    _channel?.unsubscribe();
  }
}