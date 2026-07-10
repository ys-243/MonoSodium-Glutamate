class Post {
  final String id;
  final String communityId;
  final String creatorId;
  final String creatorName;
  final String title;
  final String content;
  final DateTime createdAt;
  final int repliesCount; 

  Post({
    required this.id,
    required this.communityId,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.repliesCount = 0,
  });

  factory Post.fromSupabase(Map<String, dynamic> map) {
    // Parse creator name
    final profile = map['profiles'] as Map<String, dynamic>?;
    String name = 'Unknown User';
    if (profile != null) {
      final userName = profile['user_name'] as String?;
      final firstName = profile['first_name'] as String? ?? '';
      final lastName = profile['last_name'] as String? ?? '';
      name = (userName != null && userName.isNotEmpty) ? userName : '$firstName $lastName'.trim();
    }

    // Parse reply count (Supabase returns counts as [{count: X}])
    int parsedRepliesCount = 0;
    final repliesData = map['post_replies'] as List?;
    if (repliesData != null && repliesData.isNotEmpty) {
      parsedRepliesCount = repliesData[0]['count'] ?? 0;
    }

    return Post(
      id: map['id'],
      communityId: map['community_id'],
      creatorId: map['user_id'],
      creatorName: name.isNotEmpty ? name : 'Unknown User',
      title: map['title'] ?? 'Untitled Post',
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      repliesCount: parsedRepliesCount,
    );
  }
}