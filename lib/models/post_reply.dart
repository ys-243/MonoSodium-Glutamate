class PostReply {
  final String id;
  final String postId;
  final String creatorName;
  final String content;
  final DateTime createdAt;

  PostReply({
    required this.id,
    required this.postId,
    required this.creatorName,
    required this.content,
    required this.createdAt,
  });

  factory PostReply.fromSupabase(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    String name = 'Unknown User'; //fallback
    if (profile != null) {
      final userName = profile['user_name'] as String?;
      final firstName = profile['first_name'] as String? ?? '';
      final lastName = profile['last_name'] as String? ?? '';
      name = (userName != null && userName.isNotEmpty) ? userName : '$firstName $lastName'.trim();
    }

    return PostReply(
      id: map['id'],
      postId: map['post_id'],
      creatorName: name.isNotEmpty ? name : 'Unknown User',
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']).toLocal(),
    );
  }
}