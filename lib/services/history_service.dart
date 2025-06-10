import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryService {
  final SupabaseClient _supabase;

  HistoryService() : _supabase = Supabase.instance.client;

  // Fetch all activities for the current user
  Future<List<Map<String, dynamic>>> fetchAllActivities() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_activities')
        .select('''
          id, 
          activity_type, 
          status, 
          created_at,
          products:product_id (id, name, price, image_url)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response;
  }

  // Fetch only purchase activities
  Future<List<Map<String, dynamic>>> fetchPurchases() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_activities')
        .select('''
          id, 
          activity_type, 
          status, 
          created_at,
          products:product_id (id, name, price, image_url)
        ''')
        .eq('user_id', userId)
        .eq('activity_type', 'purchase')
        .order('created_at', ascending: false);

    return response;
  }

  // Fetch only saved items
  Future<List<Map<String, dynamic>>> fetchSavedItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_activities')
        .select('''
          id, 
          activity_type, 
          status, 
          created_at,
          products:product_id (id, name, price, image_url)
        ''')
        .eq('user_id', userId)
        .eq('activity_type', 'saved')
        .order('created_at', ascending: false);

    return response;
  }

  // Record a new activity
  Future<void> recordActivity({
    required String productId,
    required String activityType,
    String? status,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('user_activities').insert({
      'user_id': userId,
      'product_id': productId,
      'activity_type': activityType,
      'status': status,
    });
  }

  // Helper methods for specific activity types
  Future<void> recordPurchase(String productId) async {
    await recordActivity(
      productId: productId,
      activityType: 'purchase',
      status: 'completed',
    );
  }

  Future<void> recordSavedItem(String productId) async {
    await recordActivity(
      productId: productId,
      activityType: 'saved',
    );
  }

  Future<void> recordViewedItem(String productId) async {
    await recordActivity(
      productId: productId,
      activityType: 'viewed',
    );
  }
}