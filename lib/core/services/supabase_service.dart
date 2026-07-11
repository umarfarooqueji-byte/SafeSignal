import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Sign in Anonymously if not logged in
  Future<void> signInAnonymouslyIfNeeded() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      try {
        await _client.auth.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous sign-in error: $e');
      }
    }
  }

  // Upsert user profile
  Future<void> upsertProfile({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'name': name,
          'email': email,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        });
      } catch (e) {
        debugPrint('Profile upsert error: $e');
      }
    }
  }

  // Save scan history
  Future<void> saveScanHistory({
    required String scanType, // 'URL', 'EMAIL', 'DEVICE'
    String? target,
    required String status, // 'SAFE', 'WARNING', 'DANGER'
    Map<String, dynamic>? details,
  }) async {
    // Ensure we have at least an anonymous user session
    await signInAnonymouslyIfNeeded();
    final user = _client.auth.currentUser;

    try {
      await _client.from('scan_history').insert({
        'user_id': user?.id,
        'scan_type': scanType,
        'target': target,
        'status': status,
        if (details != null) 'details': details,
      });
    } catch (e) {
      debugPrint('Save scan history error: $e');
    }
  }

  // Fetch scan history
  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _client
          .from('scan_history')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Fetch scan history error: $e');
      return [];
    }
  }
}
