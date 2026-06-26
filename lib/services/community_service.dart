import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plannus/models/community.dart';

class CommunityService {
  final _supabase = Supabase.instance.client;

  // READ function: Fetches all communities and checks if the current user has joined them, along with their role.
  Future<List<Community>> getCommunities() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('communities')
        .select('*, member_count:community_members(count)');

    // Fetch the communities the current user has joined and their role
    final myMemberships = await _supabase
        .from('community_members')
        .select('community_id, role')
        .eq('user_id', userId);

    // Create a map of community_id to CommunityRole for fast lookup
    final membershipMap = {
      for (var m in myMemberships)
        m['community_id'] as String: _parseRole(m['role'] as String)
    };

    return (response as List).map((json) {
      final role = membershipMap[json['id']]; // Will be null if not joined
      return Community.fromJson(json, role: role);
    }).toList();
  }

  // CREATE function: also assigns the 'owner' role to the creator
  Future<void> createCommunity(String name, String description, CommunityLevel level) async {
    final userId = _supabase.auth.currentUser!.id;
    
    final newCommunity = await _supabase.from('communities').insert({
      'name': name,
      'description': description,
      'level': level.name, 
      'created_by': userId,
    }).select().single();

    // Insert the junction row with the explicit owner role
    await _supabase.from('community_members').insert({
      'community_id': newCommunity['id'],
      'user_id': userId,
      'role': 'owner', 
    });
  }

  // Helper method to parse the string from db to enum.
  CommunityRole _parseRole(String roleStr) {
    switch (roleStr) {
      case 'owner': return CommunityRole.owner;
      case 'admin': return CommunityRole.admin;
      case 'pending': return CommunityRole.pending;
      default: return CommunityRole.member;
    }
  }

  // UPDATE function: Update an existing community's information
  Future<void> updateCommunity(String communityId, String newName, String newDescription) async {
    await _supabase.from('communities').update({
      'name': newName,
      'description': newDescription,
    }).eq('id', communityId);
  }

  // DELETE
  Future<void> deleteCommunity(String communityId) async {
    // Because of 'ON DELETE CASCADE' in SQL, deleting the community 
    // will automatically delete all associated member rows.
    await _supabase.from('communities').delete().eq('id', communityId);
  }

  // Function to join a community.
  Future<CommunityRole> joinCommunity(String communityId, CommunityLevel level) async {
    final userId = _supabase.auth.currentUser!.id;
    
    // Determine their role based on the community privacy level
    final role = (level == CommunityLevel.open) ? 'member' : 'pending';

    await _supabase.from('community_members').upsert({
      'community_id': communityId,
      'user_id': userId,
      'role': role,
    }, onConflict: 'community_id,user_id');

    return _parseRole(role);
  }

  // TODO: Function to leave a community.

  // Fetches a list of users whose role is currently 'pending'.
  Future<List<Map<String, dynamic>>> fetchPendingMembers(String communityId) async {
    final response = await _supabase
        .from('community_members')
        .select('''
          user_id,
          profiles (
            first_name,
            last_name,
            user_name,
            email
          )
        ''')
        .eq('community_id', communityId)
        .eq('role', 'pending');

    return (response as List).map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      if (profile == null) return {'user_id': row['user_id'], 'name': 'Unknown User'};

      final userName = profile['user_name'] as String?;
      final firstName = profile['first_name'] as String? ?? '';
      final lastName = profile['last_name'] as String? ?? '';
      
      final displayName = (userName != null && userName.isNotEmpty)
          ? userName
          : '$firstName $lastName'.trim();

      return {
        'user_id': row['user_id'],
        'name': displayName.isNotEmpty ? displayName : 'Unknown User',
        'email': profile['email'] ?? 'No email provided',
      };
    }).toList();
  }

  // Approves a user by updating their role from 'pending' to 'member'
  Future<void> approveMember(String communityId, String userId) async {
    await _supabase.from('community_members').update({
      'role': 'member',
    }).eq('community_id', communityId).eq('user_id', userId);
  }

  // Rejects a user by deleting their request from the database
  Future<void> rejectMember(String communityId, String userId) async {
    await _supabase.from('community_members').delete()
        .eq('community_id', communityId)
        .eq('user_id', userId);
  }

  // Fetches all members of a community along with their roles.
  Future<List<Map<String, dynamic>>> fetchCommunityMembers(String communityId) async {
    final response = await _supabase
        .from('community_members')
        .select('''
          user_id,
          role,
          profiles (
            first_name,
            last_name,
            user_name
          )
        ''')
        .eq('community_id', communityId)
        .order('role', ascending: true); // We put admins/owners near the top.

    return (response as List).map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      final role = row['role'] as String? ?? 'member';

      if (profile == null) return {'user_id': row['user_id'], 'name': 'Unknown User', 'role': role};

      final userName = profile['user_name'] as String?;
      final firstName = profile['first_name'] as String? ?? '';
      final lastName = profile['last_name'] as String? ?? '';

      final displayName = (userName != null && userName.isNotEmpty)
          ? userName
          : '$firstName $lastName'.trim();

      return {
        'user_id': row['user_id'],
        'name': displayName.isNotEmpty ? displayName : 'Unknown User',
        'role': role,
      };
    }).toList();
  }

  // Allows an admin or owner to remove a member from the community.
  Future<void> removeMember(String communityId, String userId) async {
    await _supabase.from('community_members').delete()
        .eq('community_id', communityId)
        .eq('user_id', userId);
  }

  // Promotes a regular member to an admin.
  Future<void> promoteToAdmin(String communityId, String userId) async {
    await _supabase.from('community_members').update({
      'role': 'admin',
    }).eq('community_id', communityId).eq('user_id', userId);
  }

  // Demotes an admin back to a regular member. ONLY DONE BY OWNER.
  Future<void> demoteToMember(String communityId, String userId) async {
    await _supabase.from('community_members').update({
      'role': 'member',
    }).eq('community_id', communityId).eq('user_id', userId);
  }
}