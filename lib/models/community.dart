enum CommunityLevel {
  intimate,
  closed,
  open,
}

enum CommunityRole {
  member,
  admin,
  owner,
  pending, // For users who have requested to join but haven't been approved yet
}

class Community {
  final String id;
  final String name;
  final String description;
  final CommunityLevel level;
  final int members;
  final int posts;
  final bool isJoined;
  final String? createdBy;
  final CommunityRole? currentUserRole; 

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    this.members = 0,
    this.posts = 0,
    required this.isJoined,
    this.createdBy,
    this.currentUserRole,
  });


  // Parse JSON data to create a Community instance.
  factory Community.fromJson(Map<String, dynamic> json, {CommunityRole? role}) {
    
    // Helper function to convert string to CommunityLevel enum.
    CommunityLevel parseCommunityLevel(String level) {
      // to lower case jic to match enum.
      switch (level.toLowerCase()) {
        case 'intimate':
          return CommunityLevel.intimate;
        case 'closed':
          return CommunityLevel.closed;
        case 'open':
          return CommunityLevel.open;
        default:
          throw ArgumentError('Invalid community level: $level');
      }
    }

    return Community(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      level: parseCommunityLevel(json['level']),
      isJoined: role != null && role != CommunityRole.pending, // If they have a role, they are joined
      currentUserRole: role,
      members: json['member_count']?[0]?['count'] ?? 0, 
      posts: 0, 
    );
  }
}