import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plannus/models/post.dart';
import 'package:plannus/models/post_reply.dart';

class PostService {
  final _supabase = Supabase.instance.client;

  // Fetch Posts + Count Replies
  Future<List<Post>> fetchCommunityPosts(String communityId) async {
    final response = await _supabase
        .from('posts')
        .select('*, profiles(first_name, last_name, user_name), post_replies(count)')
        .eq('community_id', communityId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Post.fromSupabase(json)).toList();
  }

  // Create Top-Level Post
  Future<void> createPost(String communityId, String title, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('posts').insert({
      'community_id': communityId,
      'user_id': userId,
      'title': title, // Default title
      'content': content,
    });
  }

  // Fetch Replies for a Post
  Future<List<PostReply>> fetchReplies(String postId) async {
    final response = await _supabase
        .from('post_replies')
        .select('*, profiles(first_name, last_name, user_name)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => PostReply.fromSupabase(json)).toList();
  }

  // Create a Reply
  Future<void> createReply(String postId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('post_replies').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }
}