enum CommunityLevel {
  intimate,
  closed,
  open,
}

class Community {
  final String id;
  final String name;
  final String description;
  final CommunityLevel level;
  final int members;
  final int posts;
  final bool isJoined;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.members,
    required this.posts,
    required this.isJoined,
  });
}