import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> toggleFavorite(String productId, bool isFavorite) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Please sign in to save favorites');

    try {
      if (isFavorite) {
        // Check if already exists before inserting
        final existing = await _supabase
            .from('user_favorites')
            .select('id')
            .eq('user_id', userId)
            .eq('product_id', productId)
            .maybeSingle();

        if (existing == null) {
          // Only insert if it doesn't exist
          await _supabase.from('user_favorites').insert({
            'user_id': userId,
            'product_id': productId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } else {
        await _supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Item already in favorites - this is actually fine for adding
        if (!isFavorite) {
          throw Exception('Failed to remove from favorites');
        }
        // If we're adding and it already exists, that's okay
        return;
      }
      throw Exception('Failed to update favorite: ${e.message}');
    }
  }

  // Alternative method that's simpler and more reliable
  Future<void> addToFavorites(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Please sign in to save favorites');

    try {
      await _supabase.from('user_favorites').upsert({
        'user_id': userId,
        'product_id': productId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to add to favorites: ${e.message}');
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Please sign in to manage favorites');

    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to remove from favorites: ${e.message}');
    }
  }

  Future<bool> isFavorite(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final result = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('user_favorites')
        .select('''
          product:products (
            id,
            product_title,
            price,
            product_image,
            image_urls
          )
        ''')
        .eq('user_id', userId);

    return (response as List).map((fav) => fav['product'] as Map<String, dynamic>).toList();
  }
}