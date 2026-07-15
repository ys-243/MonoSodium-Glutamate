class Event {
  final String id;
  final String communityId;
  final String communityName;
  final String communityLevel;
  final String createdBy;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String time;
  final DateTime createdAt;
  final String category;
  final int capacity;
  final int attendees;
  final String organiser;
  final bool isRegistered;

  Event({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.communityLevel,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.createdAt,
    required this.category,
    required this.capacity,
    required this.attendees,
    required this.organiser,
    required this.isRegistered,
  });

  factory Event.fromSupabase(Map<String, dynamic> map, 
  {required int attendees, required bool isRegistered}) {
    final startTime = DateTime.parse(map['start_time'] as String).toLocal();

    final endTime = map['end_time'] != null
      ? DateTime.parse(map['end_time'] as String).toLocal()
      : null;


    final createdAtStr = map['created_at'] as String?;

    // Defensive: If supabase now() function fails, then this is backup.
    final createdAt = createdAtStr != null 
      ? DateTime.parse(createdAtStr).toLocal() 
      : DateTime.now();

    // Extract the Joined Data
    final communityData = map['communities'] as Map<String, dynamic>?;
    final profileData = map['profiles'] as Map<String, dynamic>?;

    // Parse organiser name from profile data, with fallback to 'Community Member'
    String organiserName = 'Community Member';
    if (profileData != null) {
      final userName = profileData['user_name'] as String?;
      final firstName = profileData['first_name'] as String? ?? '';
      final lastName = profileData['last_name'] as String? ?? '';

      organiserName = (userName != null && userName.isNotEmpty)
          ? userName
          : '$firstName $lastName'.trim(); // Fallback to first and last name if username is not available

      // If somehow the organiserName is still empty, fallback to 'Community Member'.
      if (organiserName.isEmpty) {
        organiserName = 'Community Member';
      }
    }

    return Event(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      communityName: communityData?['name'] as String? ?? 'Unknown Community',
      communityLevel: communityData?['level'] as String? ?? 'open',
      createdBy: map['created_by'] as String,
      title: map['title'] as String? ?? 'Untitled Event',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? 'No location provided',
      date: startTime,
      time: _formatTimeRange(startTime, endTime),
      createdAt: createdAt,
      category: map['category'] as String? ?? 'Social',
      capacity: map['capacity'] as int? ?? 0,
      organiser: organiserName,
      isRegistered: isRegistered,
      attendees: attendees
    );
  }

  static String _formatTimeRange(DateTime startTime, DateTime? endTime) {
    final start = _formatTime(startTime.toLocal());

    if (endTime == null) {
      return start;
    }

    final end = _formatTime(endTime.toLocal());
    return '$start - $end';
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 
                          ? hour - 12 
                          : hour == 0 
                            ? 12 
                            : hour;

    return '$formattedHour:$minute $period';
  }
}