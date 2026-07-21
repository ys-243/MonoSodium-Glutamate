import 'package:supabase_flutter/supabase_flutter.dart';

class FriendService {
  final _supabase = Supabase.instance.client;

  // --- UNIFIED SEARCH METHOD ---
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final currentUserId = _supabase.auth.currentUser!.id;
    final cleanQuery = query.trim();

    // If the query contains an '@', we treat it as an email search. Otherwise, do username search
    if (cleanQuery.contains('@')) {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('email', cleanQuery)
          .neq('id', currentUserId); // Don't show the current user
          
      return List<Map<String, dynamic>>.from(response);
    } else {
      final response = await _supabase
          .from('profiles')
          .select()
          .ilike('user_name', '%$cleanQuery%') // Case-insensitive search for usernames by supabase
          .neq('id', currentUserId)
          .limit(10); // Limit results so the UI doesn't lag
          
      return List<Map<String, dynamic>>.from(response);
    }
  }

  // Using ID, since the search results will return the user's ID.
  Future<void> sendFriendRequestById(String targetId) async {
    final currentUserId = _supabase.auth.currentUser!.id;

    try {
      await _supabase.from('friendships').insert({
        'requester_id': currentUserId,
        'addressee_id': targetId,
        'status': 'pending',
      });
    } catch (e) {
      if (e.toString().contains('duplicate key') || e.toString().contains('unique constraint')) {
        throw Exception('A friend request has already been sent!');
      }
      rethrow;
    }
  }

  // Fetch a list of accepted friends
  Future<List<Map<String, dynamic>>> fetchFriends() async {
    final currentUserId = _supabase.auth.currentUser!.id;

    // Fetch friendships where the user is either the requester or addressee, and status is accepted
    final response = await _supabase
        .from('friendships')
        .select('''
          status,
          requester:profiles!requester_id (id, first_name, last_name, user_name, major, year_of_study, avatar_url),
          addressee:profiles!addressee_id (id, first_name, last_name, user_name, major, year_of_study, avatar_url)
        ''')
        .or('requester_id.eq.$currentUserId,addressee_id.eq.$currentUserId')
        .eq('status', 'accepted');

    // Parse the response to extract the *other* person's profile
    return (response as List).map((row) {
      final requester = row['requester'] as Map<String, dynamic>;
      final addressee = row['addressee'] as Map<String, dynamic>;

      // Determine which profile belongs to the friend
      return requester['id'] == currentUserId ? addressee : requester;
    }).toList();
  }

  // Fetch pending requests sent TO the current user
  Future<List<Map<String, dynamic>>> fetchPendingRequests() async {
    final currentUserId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('friendships')
        .select('''
          requester:profiles!requester_id (id, first_name, last_name, user_name, major, year_of_study, avatar_url)
        ''')
        .eq('addressee_id', currentUserId)
        .eq('status', 'pending');

    // Extract the profile data of the person who sent the request
    return (response as List).map((row) => row['requester'] as Map<String, dynamic>).toList();
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String requesterId) async {
    final currentUserId = _supabase.auth.currentUser!.id;

    await _supabase.from('friendships').update({
      'status': 'accepted',
    }).eq('addressee_id', currentUserId).eq('requester_id', requesterId);
  }

  // Reject a friend request
  Future<void> rejectFriendRequest(String requesterId) async {
    final currentUserId = _supabase.auth.currentUser!.id;

    await _supabase.from('friendships').delete()
        .eq('addressee_id', currentUserId)
        .eq('requester_id', requesterId);
  }
}