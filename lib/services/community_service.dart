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
}