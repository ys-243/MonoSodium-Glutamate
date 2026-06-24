class Event {
  final String id;
  final String communityId;
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
  final String organizer;
  final bool isRegistered;

  Event({
    required this.id,
    required this.communityId,
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
    required this.organizer,
    required this.isRegistered,
  });

  factory Event.fromSupabase(Map<String, dynamic> map, {
      required int attendees,
      required bool isRegistered,
    }) {
      final startTime = DateTime.parse(map['start_time'] as String).toLocal();

      final endTime = map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String).toLocal()
          : null;

    return Event(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      createdBy: map['created_by'] as String,
      title: map['title'] as String? ?? 'Untitled Event',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? 'No location provided',
      date: startTime,
      time: _formatTimeRange(startTime, endTime),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      category: map['category'] as String? ?? 'Social',
      capacity: map['capacity'] as int? ?? 0,
      organizer: map['organizer'] as String? ?? 'Community Member',
      isRegistered: isRegistered,
      attendees: attendees
    );
  }

  static String _formatTimeRange(DateTime startTime, DateTime? endTime) {
    final start = _formatTime(startTime);

    if (endTime == null) {
      return start;
    }

    final end = _formatTime(endTime);
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